module Rack
  class ChartsApi
    # Extracts chart data and options from either the query string or a JSON
    # request body.  Supports chartkick-compatible data formats:
    #
    #   Single series hash:   {"Jan": 10, "Feb": 20}
    #   Array of pairs:       [["Jan", 10], ["Feb", 20]]
    #   Multi-series array:   [{"name": "A", "data": {...}}, ...]
    #
    # Query-string mode (GET with short payloads):
    #   ?data=URL-ENCODED-JSON&type=line&w=800&h=400&title=Hello
    #
    # JSON body mode (POST with large payloads):
    #   POST body: {"data": ..., "type": "line", "options": {"w": 800}}
    #
    module DataParser
      module_function

      # Returns [chart_data, options_hash]
      def parse(env)
        request = Rack::Request.new(env)
        params  = request.params # merged GET + POST form params

        if request.post? && json_content?(env)
          parse_json_body(env, params)
        else
          parse_query(params)
        end
      end

      def json_content?(env)
        ct = env['CONTENT_TYPE'].to_s
        ct.include?('application/json') || ct.include?('text/json')
      end

      def parse_json_body(env, params)
        body = env['rack.input'].read
        env['rack.input'].rewind
        payload = JSON.parse(body)

        chart_data = payload['data']
        opts = extract_options(payload.merge(params))
        [normalize_data(chart_data), opts]
      rescue JSON::ParserError
        [nil, {}]
      end

      def parse_query(params)
        raw = params['data']
        return [nil, {}] unless raw

        chart_data = begin
          JSON.parse(raw)
        rescue JSON::ParserError
          nil
        end

        [normalize_data(chart_data), extract_options(params)]
      end

      # Normalise chartkick-format data into a consistent internal format:
      #   { "series_name" => [values...], ... }
      #
      # This is used by PngRenderer (Gruff).  HtmlRenderer passes the raw
      # JSON straight through to chartkick.js which handles all formats
      # natively.
      def normalize_data(data)
        return nil if data.nil?

        case data
        when Hash
          # { "Jan" => 10, "Feb" => 20 } -- single series hash
          data
        when Array
          if data.first.is_a?(Hash) && data.first.key?('name')
            # Multi-series: [{"name": "A", "data": [...]}, ...]
            data.each_with_object({}) do |series, h|
              name = series['name'] || 'Series'
              values = series['data']
              h[name] = case values
                        when Hash then values.values
                        when Array
                          values.map { |v| v.is_a?(Array) ? v.last : v }
                        else
                          Array(values)
                        end
            end
          elsif data.first.is_a?(Array)
            # Array of pairs: [["Jan", 10], ["Feb", 20]]
            { 'Series' => data.map(&:last) }
          else
            # Flat array of numbers
            { 'Series' => data }
          end
        end
      end

      def extract_options(params)
        {
          type: params['type'] || 'line',
          w: (params['w']    || params.dig('options', 'w') || 800).to_i,
          h: (params['h']    || params.dig('options', 'h') || 600).to_i,
          title: params['title'] || params.dig('options', 'title'),
          colors: params['colors'] || params.dig('options', 'colors'),
          labels: params['labels'] || params.dig('options', 'labels')
        }.compact
      end
    end
  end
end
