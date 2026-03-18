# rack-charts-api

Rack middleware that serves charts as PNG images or interactive HTML pages.
Pass chart data via URL params or JSON body, get back a Gruff-rendered PNG
or a standalone HTML page with a [chartkick](https://github.com/ankane/chartkick)/Chart.js
chart you can embed in an `<iframe>`.

## Install

```ruby
# Gemfile
gem "rack-charts-api"
```

Requires ImageMagick on the host (Gruff depends on RMagick).

## Mount it

### Rails

```ruby
# config/application.rb
config.middleware.use Rack::ChartsApi
```

### config.ru (Sinatra, Roda, bare Rack)

```ruby
require "rack/charts_api"
use Rack::ChartsApi
run MyApp
```

### Custom mount path

```ruby
use Rack::ChartsApi, path: "/api/charts"
```

Default path is `/charts`.

## Data formats (chartkick-compatible)

All formats that [chartkick](https://github.com/ankane/chartkick) accepts
work here. The `data` parameter is always JSON.

### Single series -- hash

```json
{"Jan": 10, "Feb": 20, "Mar": 30}
```

### Single series -- array of pairs

```json
[["Jan", 10], ["Feb", 20], ["Mar", 30]]
```

### Multiple series

```json
[
  {"name": "Revenue", "data": {"Q1": 100, "Q2": 200, "Q3": 300}},
  {"name": "Expenses", "data": {"Q1": 80, "Q2": 150, "Q3": 250}}
]
```

### Flat array of numbers

```json
[10, 20, 30, 40, 50]
```

## Get a PNG

Pass `data` as a query param. The response is a binary PNG.

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}
```

With dimensions and chart type:

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}&w=600&h=300&type=bar&title=Sales
```

### PNG from curl

```bash
curl -G "http://localhost:3000/charts.png" \
  --data-urlencode 'data={"Jan":10,"Feb":20,"Mar":30}' \
  --data-urlencode 'type=bar' \
  --data-urlencode 'w=800' \
  --data-urlencode 'h=400' \
  -o chart.png
```

## Get an HTML page (for iframes)

Same interface, different extension:

```
GET /charts.html?data={"Jan":10,"Feb":20,"Mar":30}&type=line
```

Returns a self-contained HTML document that loads Chart.js and chartkick
from CDN and renders an interactive chart. No other dependencies needed.

### Embed in an iframe

```html
<iframe
  src="/charts.html?data=%7B%22Jan%22%3A10%2C%22Feb%22%3A20%7D&type=line&w=600&h=300"
  width="600"
  height="300"
  frameborder="0">
</iframe>
```

### Default format

Requesting `/charts` without an extension returns HTML:

```
GET /charts?data={"Jan":10,"Feb":20}
```

You can also force PNG via the `Accept` header:

```
GET /charts?data=... -H "Accept: image/png"
```

## POST with JSON body

When the data is too large for a query string, POST it:

```bash
curl -X POST "http://localhost:3000/charts.png" \
  -H "Content-Type: application/json" \
  -d '{
    "data": [
      {"name": "Revenue", "data": {"Q1": 100, "Q2": 200, "Q3": 300}},
      {"name": "Expenses", "data": {"Q1": 80, "Q2": 150, "Q3": 250}}
    ],
    "type": "area",
    "w": 1024,
    "h": 512,
    "title": "Quarterly Report"
  }'
  -o report.png
```

HTML works the same way:

```bash
curl -X POST "http://localhost:3000/charts.html" \
  -H "Content-Type: application/json" \
  -d '{"data": {"Chrome": 65, "Firefox": 15, "Safari": 10}, "type": "pie"}'
```

## All parameters

| Param   | Default | Description                                                    |
|---------|---------|----------------------------------------------------------------|
| `data`  | --      | Chart data (JSON). Required.                                   |
| `type`  | `line`  | Chart type: `line`, `bar`, `column`, `pie`, `area`, `scatter`, `side_bar`, `stacked_bar`, `dot` |
| `w`     | `800`   | Width in pixels                                                |
| `h`     | `600`   | Height in pixels                                               |
| `title` | --      | Chart title                                                    |
| `colors`| --      | Array of hex color strings (JSON)                              |
| `labels`| --      | X-axis labels as hash or array (JSON)                          |

## Chart type mapping

The `type` param maps to different backends depending on the response format:

| `type`         | PNG (Gruff)          | HTML (chartkick.js)   |
|----------------|----------------------|-----------------------|
| `line`         | `Gruff::Line`        | `Chartkick.LineChart`    |
| `bar`          | `Gruff::Bar`         | `Chartkick.ColumnChart`  |
| `column`       | `Gruff::Bar`         | `Chartkick.ColumnChart`  |
| `pie`          | `Gruff::Pie`         | `Chartkick.PieChart`     |
| `area`         | `Gruff::Area`        | `Chartkick.AreaChart`    |
| `scatter`      | `Gruff::Line`        | `Chartkick.ScatterChart` |
| `side_bar`     | `Gruff::SideBar`     | `Chartkick.BarChart`     |
| `stacked_bar`  | `Gruff::StackedBar`  | `Chartkick.ColumnChart` (stacked) |

## Use from a Rails controller

```ruby
class ReportsController < ApplicationController
  def chart
    data = { "Q1" => 100, "Q2" => 200, "Q3" => 300 }

    redirect_to "/charts.png?data=#{URI.encode_www_form_component(data.to_json)}&type=bar&w=600&h=300"
  end
end
```

Or embed it:

```erb
<iframe
  src="/charts.html?data=<%= URI.encode_www_form_component(@chart_data.to_json) %>&type=line&w=700&h=350"
  width="700" height="350" frameborder="0">
</iframe>
```

## Running tests

```
bundle install
bundle exec rake test
```
