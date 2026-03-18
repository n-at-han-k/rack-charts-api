require 'bundler/setup'
require 'minitest/autorun'
require 'rack'
require 'rack/builder'
require 'rack/test'
require 'json'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  TEST_DATA = { 'Jan' => 10, 'Feb' => 20, 'Mar' => 30 }.freeze

  def app
    @app ||= Rack::Builder.parse_file(File.expand_path('config.ru', __dir__))
  end

  def test_landing_page_returns_200
    get '/'
    assert_equal 200, last_response.status
  end

  def test_landing_page_is_html
    get '/'
    assert last_response.content_type.include?('text/html')
    assert last_response.body.include?('rack-charts-api demo')
  end

  def test_png_endpoint_returns_valid_png
    get '/charts.png', data: TEST_DATA.to_json
    assert_equal 200, last_response.status
    assert_equal 'image/png', last_response.content_type
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  def test_html_endpoint_returns_chartkick_page
    get '/charts.html', data: TEST_DATA.to_json
    assert_equal 200, last_response.status
    assert last_response.content_type.include?('text/html')
    assert last_response.body.include?('Chartkick')
  end

  def test_png_with_type_and_dimensions
    get '/charts.png', data: TEST_DATA.to_json, type: 'bar', w: '400', h: '200'
    assert_equal 200, last_response.status
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  def test_missing_data_returns_400
    get '/charts.png'
    assert_equal 400, last_response.status
  end
end
