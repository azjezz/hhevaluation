extern crate futures;
extern crate serde_json;
extern crate shiplift;
extern crate tokio;

use futures::{future, StreamExt};
use serde_json::json;
use shiplift::{tty::TtyChunk, Container, ContainerOptions, Docker, Exec, ExecContainerOptions};
use std::{env, fs::File, io::Read, str, string::String, time::Duration};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let version: String = env::args().nth(1).expect("No version is provided.");
    let code: String = env::args().nth(2).expect("No Hack file is provided.");
    let ini: String = env::args().nth(3).expect("No ini config file is provided.");
    let hh: String = env::args().nth(4).expect("No hh config file is provided.");

    let docker = Docker::unix("/var/run/docker.sock");

    let container_configuration =
        ContainerOptions::builder(&format!("hhvm/hhvm:{}", version).to_owned())
            .working_dir("/home")
            .memory(1024 * 1024 * 150)
            .auto_remove(true)
            .tty(true)
            .stop_timeout(Duration::from_secs(120))
            .build();

    let container_information = docker
        .containers()
        .create(&container_configuration)
        .await
        .expect("Failed to create docker container.");

    let container = docker.containers().get(container_information.id);

    container.start().await?;

    let (hh_version, hhvm_version) = future::join(
        container_exec(&docker, &container, vec!["hh_client", "--version"]),
        container_exec(&docker, &container, vec!["hhvm", "--version"]),
    )
    .await;

    future::join4(
        container_copy(&container, code, "/home/main.hack".to_owned()),
        container_copy(&container, ini, "/home/configuration.ini".to_owned()),
        container_copy(&container, hh, "/home/.hhconfig".to_owned()),
        container_exec(
            &docker,
            &container,
            vec!["hhvm", "hh_server", "-d", "/home"],
        ),
    )
    .await;

    let (hh_results, hhvm_results) = future::join(
        container_exec(&docker, &container, vec!["hh_client"]),
        container_exec(
            &docker,
            &container,
            vec!["hhvm", "-c", "configuration.ini", "main.hack"],
        ),
    )
    .await;

    container.kill(None).await?;

    let json = json!({
        "runtime":  {
            "detailed_version": hhvm_version.1,
            "exit_code": hhvm_results.0,
            "stdout": hhvm_results.1,
            "stderr": hhvm_results.2,
        },
        "type_checker":  {
            "detailed_version": hh_version.1,
            "exit_code": hh_results.0,
            "stdout": hh_results.1,
            "stderr": hh_results.2,
        },
    });

    print!("{}", json.to_string());

    Ok(())
}

async fn container_copy(container: &Container<'_>, from: String, to: String) {
    let mut file = File::open(&from).expect(&format!("Failed to open file '{}'.", from));
    let mut bytes = Vec::new();
    file.read_to_end(&mut bytes)
        .expect("Cannot read file on the localhost.");

    if let Err(e) = container.copy_file_into(to, &bytes).await {
        panic!("Failed to copy file into the container: {}", e)
    }
}

async fn container_exec(
    docker: &Docker,
    container: &Container<'_>,
    args: Vec<&str>,
) -> (u64, String, String) {
    let options = ExecContainerOptions::builder()
        .cmd(args)
        .attach_stdout(true)
        .attach_stderr(true)
        .build();

    let exec = Exec::create(docker, container.id(), &options)
        .await
        .expect(&format!("Failed to start command {:?}", options));

    let mut stream = exec.start();

    let mut stdout: String = "".to_owned();
    let mut stderr: String = "".to_owned();

    while let Some(result) = stream.next().await {
        let chunk = result.expect("Failed to retrieve result.");

        match chunk {
            TtyChunk::StdOut(bytes) => stdout.push_str(str::from_utf8(&bytes).unwrap()),
            TtyChunk::StdErr(bytes) => stderr.push_str(str::from_utf8(&bytes).unwrap()),
            TtyChunk::StdIn(_) => unreachable!(),
        }
    }

    let inspection = exec
        .inspect()
        .await
        .expect(&format!("Failed to inspect command {:?}.", options));

    (
        inspection.exit_code.expect(&format!(
            "Failed to retrieve status code for command {:?}.",
            options
        )),
        stdout,
        stderr,
    )
}
