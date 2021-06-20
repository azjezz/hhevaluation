
namespace HHEvaluation\Template;

use type Facebook\XHP\HTML\{
  body,
  doctype,
  head,
  html,
  link,
  meta,
  title,
  script,
  a,
  br,
  code,
  div,
  h2,
  hr,
  option,
  pre,
  select,
  span,
  textarea,
};

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
            <script src="/public/js/main.js" />
          </head>
          <body class="bg-gray-100 font-sans leading-normal tracking-normal">
            <div class="h-screen container w-full mx-auto px-10 py-8">
              <div
                class=
                  "w-full px-4 md:px-6 text-xl text-gray-800 leading-normal">
                <h2 class="text-xl">
                  <a href="/">HHEvaluation</a>
                  <span class="text-gray-600 text-base"> by <a
                    class="underline"
                    href="https://github.com/azjezz">azjezz</a>
                  </span>
                </h2>
                <hr class="border border-red-500 mb-8 mt-4" />
                {$child}
              </div>
            </div>
          </body>
        </html>
      </doctype>;

    return $index->toStringAsync();
  }
}
