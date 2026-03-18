require 'gruff'

module Rack
  class ChartsApi
    module PngRenderer
      CHART_TYPES = {
        'line' => Gruff::Line,
        'bar' => Gruff::Bar,
        'pie' => Gruff::Pie,
        'area' => Gruff::Area,
        'side_bar' => Gruff::SideBar,
        'stacked_bar' => Gruff::StackedBar,
        'dot' => Gruff::Dot,
        'spider' => Gruff::Spider
      }.freeze

      # Map chartkick type names to gruff equivalents
      TYPE_ALIASES = {
        'column' => 'bar',
        'scatter' => 'line'
      }.freeze

      module_function

      # @param data [Hash{String => Array}]  normalised series data
      # @param opts [Hash]                   :w, :h, :type, :title, :labels, :colors
      # @return [String] binary PNG blob
      def render(data, opts = {})
        width  = opts[:w] || 800
        height = opts[:h] || 600
        type   = resolve_type(opts[:type] || 'line')

        chart = type.new("#{width}x#{height}")
        chart.title = opts[:title] if opts[:title]

        if opts[:labels]
          chart.labels = case opts[:labels]
                         when Hash then opts[:labels].transform_keys(&:to_i)
                         when Array
                           opts[:labels].each_with_index.to_h { |l, i| [i, l.to_s] }
                         else
                           {}
                         end
        end

        colors = opts[:colors]
        data.each_with_index do |(name, points), i|
          color = colors[i] if colors.is_a?(Array)
          chart.data(name.to_s, Array(points), color)
        end

        chart.to_image.to_blob
      end

      def resolve_type(name)
        key = TYPE_ALIASES.fetch(name.to_s.downcase, name.to_s.downcase)
        CHART_TYPES.fetch(key, Gruff::Line)
      end
    end
  end
end
