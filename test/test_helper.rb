require 'bundler/setup'
require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'rack/charts_api'

# A no-op downstream app for the middleware
DOWNSTREAM_APP = ->(_env) { [404, { 'content-type' => 'text/plain' }, ['not found']] }

# Build a middleware stack for testing
def build_app(path: '/charts')
  Rack::ChartsApi.new(DOWNSTREAM_APP, path: path)
end
