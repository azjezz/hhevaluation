extern crate futures;
extern crate rustc_serialize;
extern crate tokio;

use futures::future;
use rustc_serialize::json;
use std::env;
use std::str;
use std::string::String;
use tokio::process::Command;
use tokio::time;

#[derive(RustcDecodable, RustcEncodable)]
pub struct RuntimeResultStruct {
    detailed_version: String,
    exit_code: i32,
    stdout: String,
    stderr: String,
}

#[derive(RustcDecodable, RustcEncodable)]
pub struct TypeCheckerResultStruct {
    detailed_version: String,
    exit_code: i32,
    stdout: String,
    stderr: String,
}

#[derive(RustcDecodable, RustcEncodable)]
pub struct ResultStruct {
    runtime: RuntimeResultStruct,
    type_checker: TypeCheckerResultStruct,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let version: String = env::args().nth(1).expect("No version is provided.");
    let code: String = env::args().nth(2).expect("No Hack file is provided.");
    let ini: String = env::args().nth(3).expect("No ini config file is provided.");
    let hh: String = env::args().nth(4).expect("No hh config file is provided.");

    let result: (i32, String, String) = docker(vec![
        "run",
        "--rm",
        "-d",
        "-it",
        "--memory-reservation=150m",
        "--memory=180m",
        &format!("hhvm/hhvm:{}", version).to_owned(),
    ])
    .await;

    let container_id: &str = result.1.trim();

    let (hh_version, hhvm_version) = future::join(
        docker(vec!["exec", container_id, "hh_client", "--version"]),
        docker(vec!["exec", container_id, "hhvm", "--version"]),
    )
    .await;

    future::join4(
        docker(vec![
            "cp",
            &code,
            &format!("{}:{}", container_id, "/home/main.hack").to_owned(),
        ]),
        docker(vec![
            "cp",
            &ini,
            &format!("{}:{}", container_id, "/home/configuration.ini").to_owned(),
        ]),
        docker(vec![
            "cp",
            &hh,
            &format!("{}:{}", container_id, "/home/.hhconfig").to_owned(),
        ]),
        docker(vec!["exec", container_id, "hh_server", "-d", "/home"]),
    )
    .await;

    let (hh_results, hhvm_results) = future::join(
        docker(vec!["exec", "-w", "/home", container_id, "hh_client"]),
        docker(vec![
            "exec",
            "-w",
            "/home",
            container_id,
            "hhvm",
            "-c",
            "configuration.ini",
            "main.hack",
        ]),
    )
    .await;

    docker(vec!["kill", container_id]).await;

    let result = ResultStruct {
        runtime: RuntimeResultStruct {
            detailed_version: hhvm_version.1,
            exit_code: hhvm_results.0,
            stdout: hhvm_results.1,
            stderr: hhvm_results.2,
        },
        type_checker: TypeCheckerResultStruct {
            detailed_version: hh_version.1,
            exit_code: hh_results.0,
            stdout: hh_results.1,
            stderr: hh_results.2,
        },
    };

    let encoded = json::encode(&result).unwrap();

    print!("{}", encoded);

    Ok(())
}

async fn docker(args: Vec<&str>) -> (i32, String, String) {
    let mut command = Command::new("docker");
    for argument in args {
        command.arg(argument);
    }

    let output_future = command.output();
    let output = time::timeout(time::Duration::from_secs(20), output_future)
        .await
        .expect("Execution timedout.")
        .expect("Failed executing docker command.");

    (
        output
            .status
            .code()
            .expect("Failed to retrieve status code."),
        str::from_utf8(output.stdout.as_slice())
            .expect("Failed to retrieve stdout content;")
            .to_owned(),
        str::from_utf8(output.stderr.as_slice())
            .expect("Failed to retrieve stdout content;")
            .to_owned(),
    )
}
