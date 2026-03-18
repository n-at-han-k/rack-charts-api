require_relative 'test_helper'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  SINGLE_SERIES = { 'Jan' => 10, 'Feb' => 20, 'Mar' => 30 }.freeze
  MULTI_SERIES = [
    { 'name' => 'red', 'data' => { 'a' => 1, 'b' => 2 } },
    { 'name' => 'blue', 'data' => { 'a' => 3, 'b' => 4 } }
  ].freeze

  def app
    build_app
  end

  # -- Routing / middleware delegation ------------------------------------

  def test_non_chart_path_falls_through
    get '/other'
    assert_equal 404, last_response.status
    assert_equal 'not found', last_response.body
  end

  def test_custom_mount_path
    custom_app = build_app(path: '/api/charts')
    req = Rack::MockRequest.new(custom_app)
    resp = req.get("/api/charts.html?data=#{Rack::Utils.escape(SINGLE_SERIES.to_json)}")
    assert_equal 200, resp.status
  end

  # -- Error handling -----------------------------------------------------

  def test_missing_data_returns_400
    get '/charts.png'
    assert_equal 400, last_response.status
    body = JSON.parse(last_response.body)
    assert body.key?('error')
  end

  def test_invalid_json_data_returns_400
    get '/charts.png', data: 'not-json'
    assert_equal 400, last_response.status
  end

  # -- PNG via GET --------------------------------------------------------

  def test_png_via_get
    get '/charts.png', data: SINGLE_SERIES.to_json
    assert_equal 200, last_response.status
    assert_equal 'image/png', last_response.content_type
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  def test_png_with_dimensions
    get '/charts.png', data: SINGLE_SERIES.to_json, w: '400', h: '200'
    assert_equal 200, last_response.status
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  def test_png_with_type
    get '/charts.png', data: SINGLE_SERIES.to_json, type: 'bar'
    assert_equal 200, last_response.status
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  def test_png_multi_series
    get '/charts.png', data: MULTI_SERIES.to_json
    assert_equal 200, last_response.status
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  # -- PNG via POST -------------------------------------------------------

  def test_png_via_post_json_body
    payload = { data: SINGLE_SERIES, type: 'line', w: 600, h: 300 }.to_json
    post '/charts.png', payload, 'CONTENT_TYPE' => 'application/json'
    assert_equal 200, last_response.status
    assert_equal 'image/png', last_response.content_type
    assert last_response.body.b.start_with?("\x89PNG".b)
  end

  # -- HTML via GET -------------------------------------------------------

  def test_html_via_get
    get '/charts.html', data: SINGLE_SERIES.to_json
    assert_equal 200, last_response.status
    assert last_response.content_type.include?('text/html')
    assert last_response.body.include?('Chartkick')
  end

  def test_html_is_default_format
    get '/charts', data: SINGLE_SERIES.to_json
    assert_equal 200, last_response.status
    assert last_response.content_type.include?('text/html')
  end

  def test_html_with_chart_type
    get '/charts.html', data: SINGLE_SERIES.to_json, type: 'pie'
    assert_equal 200, last_response.status
    assert last_response.body.include?('PieChart')
  end

  def test_html_with_title
    get '/charts.html', data: SINGLE_SERIES.to_json, title: 'My+Report'
    assert_equal 200, last_response.status
    assert last_response.body.include?('My+Report')
  end

  # -- HTML via POST ------------------------------------------------------

  def test_html_via_post_json_body
    payload = { data: MULTI_SERIES, type: 'area' }.to_json
    post '/charts.html', payload, 'CONTENT_TYPE' => 'application/json'
    assert_equal 200, last_response.status
    assert last_response.body.include?('AreaChart')
  end

  # -- Accept header routing -----------------------------------------------

  def test_png_via_accept_header
    get '/charts', { data: SINGLE_SERIES.to_json }, 'HTTP_ACCEPT' => 'image/png'
    assert_equal 200, last_response.status
    assert_equal 'image/png', last_response.content_type
  end

  private

  # Allow overriding @app for the custom mount path test
  def build_app_override
    @app || build_app
  end
end
