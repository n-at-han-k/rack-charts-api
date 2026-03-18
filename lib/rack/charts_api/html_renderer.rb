require 'json'
require 'securerandom'

module Rack
  class ChartsApi
    module HtmlRenderer
      CHARTKICK_CDN = 'https://unpkg.com/chartkick@5.0.1/dist/chartkick.js'
      CHARTJS_CDN   = 'https://unpkg.com/chart.js@4/dist/chart.umd.js'
      DATE_ADAPTER  = 'https://unpkg.com/chartjs-adapter-date-fns@3/dist/chartjs-adapter-date-fns.bundle.js'

      # Map our type names to chartkick JS class names
      JS_CHART_TYPES = {
        'line' => 'LineChart',
        'bar' => 'ColumnChart',
        'column' => 'ColumnChart',
        'pie' => 'PieChart',
        'area' => 'AreaChart',
        'scatter' => 'ScatterChart',
        'side_bar' => 'BarChart',
        'stacked_bar' => 'ColumnChart',
        'dot' => 'LineChart',
        'spider' => 'LineChart'
      }.freeze

      module_function

      # Renders a standalone HTML page containing a Chart.js chart via
      # chartkick.js.  Designed to be loaded in an <iframe>.
      #
      # @param raw_data  the original parsed JSON data (any chartkick format)
      # @param opts      [Hash] :type, :w, :h, :title, :colors
      # @return [String]  HTML document
      def render(raw_data, opts = {})
        chart_id = "chart-#{SecureRandom.hex(4)}"
        js_type  = JS_CHART_TYPES.fetch(opts[:type].to_s, 'LineChart')
        width    = opts[:w] || 800
        height   = opts[:h] || 600

        js_options = {}
        js_options['title']   = opts[:title]  if opts[:title]
        js_options['colors']  = opts[:colors] if opts[:colors]
        js_options['stacked'] = true          if opts[:type].to_s == 'stacked_bar'

        # For the JS side, pass the raw data exactly as chartkick expects.
        # chartkick.js handles Hash, Array-of-pairs, and multi-series natively.
        chart_data_json    = raw_data.to_json
        chart_options_json = js_options.to_json

        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { font-family: system-ui, -apple-system, sans-serif; }
              ##{chart_id} { width: #{width}px; height: #{height}px; max-width: 100%; }
            </style>
            <script src="#{CHARTJS_CDN}"></script>
            <script src="#{DATE_ADAPTER}"></script>
            <script src="#{CHARTKICK_CDN}"></script>
          </head>
          <body>
            <div id="#{chart_id}"></div>
            <script>
              new Chartkick.#{js_type}("#{chart_id}", #{chart_data_json}, #{chart_options_json});
            </script>
          </body>
          </html>
        HTML
      end
    end
  end
end
