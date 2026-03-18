require 'rack'
require 'json'

require_relative 'charts_api/version'
require_relative 'charts_api/data_parser'
require_relative 'charts_api/png_renderer'
require_relative 'charts_api/html_renderer'
require_relative 'charts_api/app'

module Rack
  # Rack middleware that intercepts requests to a chart endpoint and returns
  # either a PNG image or an HTML page with an interactive Chart.js chart.
  #
  #   # config.ru or Rails application.rb
  #   use Rack::ChartsApi
  #   use Rack::ChartsApi, path: "/charts"   # custom mount path
  #
  class ChartsApi
    DEFAULT_PATH = '/charts'

    def initialize(app, path: DEFAULT_PATH)
      @app = app
      @path = path.chomp('/')
      @charts_app = App.new
    end

    def call(env)
      if env['PATH_INFO']&.start_with?(@path)
        @charts_app.call(env)
      else
        @app.call(env)
      end
    end
  end
end
