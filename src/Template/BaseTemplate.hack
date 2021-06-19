
namespace HHEvaluation\Template;

use type Facebook\XHP\HTML\{body, doctype, head, html, link, meta, title};

final class BaseTemplate {
  public static function render(\XHPChild $child): Awaitable<string> {
    $index =
      <doctype>
        <html lang="en">
          <head>
            <title>HHEvaluation</title>
            <meta charset="utf-8" />
            <meta
              name="viewport"
              content="width=device-width, initial-scale=1.0"
            />
            <meta
              name="description"
              content="HHEvaluation - Evaluate Hack code."
            />
            <link
              href="https://unpkg.com/tailwindcss@^2/dist/tailwind.min.css"
              rel="stylesheet"
              type="text/css"
            />
            <link
              href="https://unpkg.com/@tailwindcss/forms@0.3.3/dist/forms.css"
              rel="stylesheet"
              type="text/css"
            />
            <link href="/public/css/main.css" rel="stylesheet" />
          </head>
          <body class="bg-gray-100 font-sans leading-normal tracking-normal">
          </body>
        </html>
      </doctype>;

    $index->getFirstChildx() as html
      |> $$->getLastChildx() as body
      |> $$->appendChild($child);

    return $index->toStringAsync();
  }
}
