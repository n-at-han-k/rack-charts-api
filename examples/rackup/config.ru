require "bundler/setup"
require "rack/charts_api"
require "json"

# ── Demo landing page ──────────────────────────────────────────────────
#
# Visit http://localhost:9292 to see the demo.
# Charts are served by the middleware at /charts.

SAMPLE_DATA = {
  single:  { "Jan" => 12, "Feb" => 24, "Mar" => 18, "Apr" => 30, "May" => 22 },
  multi:   [
    { "name" => "Revenue",  "data" => { "Q1" => 4200, "Q2" => 5800, "Q3" => 7100, "Q4" => 9300 } },
    { "name" => "Expenses", "data" => { "Q1" => 3100, "Q2" => 4200, "Q3" => 5400, "Q4" => 6200 } },
  ],
  pie:     { "Ruby" => 45, "Python" => 30, "Go" => 15, "Rust" => 10 },
}.freeze

demo_app = lambda do |env|
  request = Rack::Request.new(env)

  if request.path_info == "/"
    body = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>rack-charts-api demo</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 960px; margin: 2rem auto; padding: 0 1rem; color: #222; }
          h1 { border-bottom: 2px solid #333; padding-bottom: .5rem; }
          h2 { margin-top: 2rem; }
          .row { display: flex; gap: 1rem; flex-wrap: wrap; margin: 1rem 0; }
          a { color: #0366d6; }
          img { border: 1px solid #ddd; border-radius: 4px; }
          iframe { border: 1px solid #ddd; border-radius: 4px; }
          code { background: #f0f0f0; padding: 2px 6px; border-radius: 3px; font-size: 0.9em; }
          pre { background: #f6f6f6; padding: 1rem; border-radius: 6px; overflow-x: auto; }
        </style>
      </head>
      <body>
        <h1>rack-charts-api demo</h1>
        <p>The middleware is mounted at <code>/charts</code>. Every chart below
        is served by it -- <code>.png</code> for images, <code>.html</code> for
        interactive Chart.js pages in iframes.</p>

        <h2>PNG charts (server-rendered via Gruff)</h2>
        <div class="row">
          <div>
            <p><a href="/charts.png?data=#{u SAMPLE_DATA[:single].to_json}&w=450&h=280&title=Monthly">Line</a></p>
            <img src="/charts.png?data=#{u SAMPLE_DATA[:single].to_json}&w=450&h=280&title=Monthly" width="450" height="280" />
          </div>
          <div>
            <p><a href="/charts.png?data=#{u SAMPLE_DATA[:single].to_json}&w=450&h=280&type=bar&title=Monthly">Bar</a></p>
            <img src="/charts.png?data=#{u SAMPLE_DATA[:single].to_json}&w=450&h=280&type=bar&title=Monthly" width="450" height="280" />
          </div>
        </div>
        <div class="row">
          <div>
            <p><a href="/charts.png?data=#{u SAMPLE_DATA[:multi].to_json}&w=450&h=280&type=area&title=Revenue+vs+Expenses">Multi-series area</a></p>
            <img src="/charts.png?data=#{u SAMPLE_DATA[:multi].to_json}&w=450&h=280&type=area&title=Revenue+vs+Expenses" width="450" height="280" />
          </div>
          <div>
            <p><a href="/charts.png?data=#{u SAMPLE_DATA[:pie].to_json}&w=280&h=280&type=pie&title=Languages">Pie</a></p>
            <img src="/charts.png?data=#{u SAMPLE_DATA[:pie].to_json}&w=280&h=280&type=pie&title=Languages" width="280" height="280" />
          </div>
        </div>

        <h2>HTML charts (interactive Chart.js in iframes)</h2>
        <div class="row">
          <iframe src="/charts.html?data=#{u SAMPLE_DATA[:single].to_json}&w=450&h=280&type=line&title=Monthly" width="460" height="290" frameborder="0"></iframe>
          <iframe src="/charts.html?data=#{u SAMPLE_DATA[:multi].to_json}&w=450&h=280&type=bar&title=Revenue+vs+Expenses" width="460" height="290" frameborder="0"></iframe>
        </div>

        <h2>JSON links</h2>
        <pre>GET <a href="/charts.png?data=#{u SAMPLE_DATA[:single].to_json}&w=600&h=300">/charts.png?data=...&w=600&h=300</a>
GET <a href="/charts.html?data=#{u SAMPLE_DATA[:single].to_json}&type=bar">/charts.html?data=...&type=bar</a></pre>
      </body>
      </html>
    HTML

    [200, { "content-type" => "text/html; charset=utf-8" }, [body]]
  else
    [404, { "content-type" => "text/plain" }, ["not found"]]
  end
end

def u(str) = Rack::Utils.escape(str)

use Rack::ChartsApi
run demo_app
