# rack-charts-api

Rack middleware that turns a JSON hash into a chart. Add one line to your
app, then request any URL under `/charts` -- append `.png` for a
server-rendered image, or `.html` for an interactive Chart.js page you can
drop into an `<iframe>`.

Data formats are compatible with [chartkick](https://github.com/ankane/chartkick).

## Install

```ruby
gem "rack-charts-api"
```

ImageMagick is required on the host for PNG rendering.

## Setup

One line. Pick whichever matches your app:

```ruby
# Rails -- config/application.rb
config.middleware.use Rack::ChartsApi

# config.ru -- Sinatra, Roda, or bare Rack
require "rack/charts_api"
use Rack::ChartsApi
run MyApp
```

That mounts the chart endpoint at `/charts`. To change it:

```ruby
use Rack::ChartsApi, path: "/api/v1/charts"
```

## Quick examples

### PNG image

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}
```

Returns a `800x600` PNG line chart.

### HTML page

```
GET /charts.html?data={"Jan":10,"Feb":20,"Mar":30}
```

Returns a self-contained HTML document with an interactive Chart.js chart.
No extension defaults to HTML.

### Resize

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}&w=600&h=300
```

### Change chart type

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}&type=bar
GET /charts.html?data={"Jan":10,"Feb":20,"Mar":30}&type=pie
```

### Add a title

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}&type=bar&title=Monthly+Sales
```

### Combine everything

```
GET /charts.png?data={"Jan":10,"Feb":20,"Mar":30}&w=1024&h=512&type=area&title=Revenue
```

## Data formats

The `data` param is JSON. All [chartkick](https://github.com/ankane/chartkick#data)
formats work.

### Hash (single series)

```
?data={"Jan":10,"Feb":20,"Mar":30}
```

### Array of pairs

```
?data=[["Jan",10],["Feb",20],["Mar",30]]
```

### Multiple series

```
?data=[{"name":"Revenue","data":{"Q1":100,"Q2":200}},{"name":"Costs","data":{"Q1":80,"Q2":150}}]
```

### Flat array

```
?data=[10,20,30,40,50]
```

## POST for large payloads

When the data is too big for a query string, POST a JSON body instead.
The structure is the same -- put chart data under a `"data"` key and
options at the top level:

```bash
curl -X POST http://localhost:3000/charts.png \
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
  }' \
  -o report.png
```

Works for HTML too:

```bash
curl -X POST http://localhost:3000/charts.html \
  -H "Content-Type: application/json" \
  -d '{"data": {"Chrome": 65, "Firefox": 15, "Safari": 10}, "type": "pie"}'
```

## Embed in an iframe

The `.html` endpoint is a complete page -- no extra CSS or JS needed on
your side. Just point an iframe at it:

```erb
<iframe
  src="/charts.html?data=<%= URI.encode_www_form_component(@data.to_json) %>&type=line&w=700&h=350"
  width="700"
  height="350"
  frameborder="0">
</iframe>
```

## Use from a Rails controller

The middleware runs alongside your app. Your controllers can redirect to
it or build URLs for views:

```ruby
class ReportsController < ApplicationController
  def sales_chart
    data = Order.group_by_month(:created_at, last: 6).sum(:total)
    redirect_to "/charts.png?#{chart_params(data, type: :bar, title: "Sales")}"
  end

  private

  def chart_params(data, **opts)
    { data: data.to_json, **opts }.to_query
  end
end
```

```erb
<%# In a view -- inline chart image %>
<img src="/charts.png?<%= { data: @data.to_json, type: :line, w: 600, h: 300 }.to_query %>" />

<%# Interactive version in an iframe %>
<iframe
  src="/charts.html?<%= { data: @data.to_json, type: :line, w: 600, h: 300 }.to_query %>"
  width="600" height="300" frameborder="0">
</iframe>
```

## Save a PNG with curl

```bash
curl -G http://localhost:3000/charts.png \
  --data-urlencode 'data={"Jan":10,"Feb":20,"Mar":30}' \
  --data-urlencode 'type=bar' \
  --data-urlencode 'w=800' \
  --data-urlencode 'h=400' \
  --data-urlencode 'title=Monthly Sales' \
  -o chart.png
```

## Content negotiation

Without a file extension, the response format depends on the `Accept`
header:

```bash
# Returns PNG
curl http://localhost:3000/charts?data=... -H "Accept: image/png" -o chart.png

# Returns HTML (default)
curl http://localhost:3000/charts?data=...
```

## Parameters

| Param    | Default | Description |
|----------|---------|-------------|
| `data`   | --      | **Required.** Chart data as JSON. |
| `type`   | `line`  | `line` `bar` `column` `pie` `area` `scatter` `side_bar` `stacked_bar` `dot` |
| `w`      | `800`   | Width in pixels. |
| `h`      | `600`   | Height in pixels. |
| `title`  | --      | Chart title. |
| `colors` | --      | JSON array of hex color strings. |
| `labels` | --      | JSON hash or array of x-axis labels. |

## Chart types

| `type`         | PNG renderer         | HTML renderer              |
|----------------|----------------------|----------------------------|
| `line`         | `Gruff::Line`        | `Chartkick.LineChart`      |
| `bar`          | `Gruff::Bar`         | `Chartkick.ColumnChart`    |
| `column`       | `Gruff::Bar`         | `Chartkick.ColumnChart`    |
| `pie`          | `Gruff::Pie`         | `Chartkick.PieChart`       |
| `area`         | `Gruff::Area`        | `Chartkick.AreaChart`      |
| `scatter`      | `Gruff::Line`        | `Chartkick.ScatterChart`   |
| `side_bar`     | `Gruff::SideBar`     | `Chartkick.BarChart`       |
| `stacked_bar`  | `Gruff::StackedBar`  | `Chartkick.ColumnChart`    |

## Running tests

```
bundle install
bundle exec rake test
```
