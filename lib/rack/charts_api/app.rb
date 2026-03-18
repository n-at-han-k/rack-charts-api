module Rack
  class ChartsApi
    # The core Rack application.  Can be used standalone or behind the
    # ChartsApi middleware.
    #
    # Response format is determined by the URL extension:
    #
    #   GET /charts.png?data=...&w=800&h=400   -> PNG image
    #   GET /charts.html?data=...              -> HTML page with Chart.js chart
    #   GET /charts?data=...                   -> HTML (default)
    #   POST /charts.png  (JSON body)          -> PNG image
    #   POST /charts.html (JSON body)          -> HTML page
    #
    class App
      def call(env)
        data, opts = DataParser.parse(env)

        unless data
          return [
            400,
            { 'content-type' => 'application/json' },
            ['{"error":"Missing or invalid chart data. Pass a `data` param (JSON) or POST a JSON body with a `data` key."}']
          ]
        end

        format = detect_format(env)

        case format
        when :png
          render_png(data, opts)
        else
          render_html(env, data, opts)
        end
      rescue StandardError => e
        [
          500,
          { 'content-type' => 'application/json' },
          [{ error: e.message }.to_json]
        ]
      end

      private

      def detect_format(env)
        path = env['PATH_INFO'].to_s

        if path.end_with?('.png')
          :png
        elsif path.end_with?('.html')
          :html
        else
          # Check Accept header
          accept = env['HTTP_ACCEPT'].to_s
          if accept.include?('image/png')
            :png
          else
            :html
          end
        end
      end

      def render_png(data, opts)
        blob = PngRenderer.render(data, opts)
        [
          200,
          {
            'content-type' => 'image/png',
            'content-length' => blob.bytesize.to_s,
            'content-disposition' => 'inline; filename="chart.png"',
            'cache-control' => 'no-cache'
          },
          [blob]
        ]
      end

      def render_html(env, data, opts)
        # For the HTML renderer, we want the original chartkick-compatible
        # JSON, not the normalised hash.  Re-parse to get the raw data.
        raw_data = extract_raw_data(env)
        html = HtmlRenderer.render(raw_data || data, opts)
        [
          200,
          {
            'content-type' => 'text/html; charset=utf-8',
            'content-length' => html.bytesize.to_s,
            'cache-control' => 'no-cache'
          },
          [html]
        ]
      end

      def extract_raw_data(env)
        request = Rack::Request.new(env)

        if request.post? && DataParser.json_content?(env)
          body = env['rack.input'].read
          env['rack.input'].rewind
          payload = JSON.parse(body)
          payload['data']
        else
          raw = request.params['data']
          raw ? JSON.parse(raw) : nil
        end
      rescue JSON::ParserError
        nil
      end
    end
  end
end
