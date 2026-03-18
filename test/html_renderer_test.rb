require_relative 'test_helper'

class HtmlRendererTest < Minitest::Test
  DATA = { 'Jan' => 10, 'Feb' => 20, 'Mar' => 30 }.freeze

  def test_returns_html_document
    html = Rack::ChartsApi::HtmlRenderer.render(DATA)
    assert html.include?('<!DOCTYPE html>')
    assert html.include?('</html>')
  end

  def test_includes_chart_js_cdn
    html = Rack::ChartsApi::HtmlRenderer.render(DATA)
    assert html.include?('chart.js@4')
  end

  def test_includes_chartkick_cdn
    html = Rack::ChartsApi::HtmlRenderer.render(DATA)
    assert html.include?('chartkick@5')
  end

  def test_includes_date_adapter
    html = Rack::ChartsApi::HtmlRenderer.render(DATA)
    assert html.include?('chartjs-adapter-date-fns')
  end

  def test_default_chart_type_is_line
    html = Rack::ChartsApi::HtmlRenderer.render(DATA)
    assert html.include?('Chartkick.LineChart')
  end

  def test_bar_chart_maps_to_column_chart
    html = Rack::ChartsApi::HtmlRenderer.render(DATA, type: 'bar')
    assert html.include?('Chartkick.ColumnChart')
  end

  def test_pie_chart_type
    html = Rack::ChartsApi::HtmlRenderer.render(DATA, type: 'pie')
    assert html.include?('Chartkick.PieChart')
  end

  def test_includes_title_in_options
    html = Rack::ChartsApi::HtmlRenderer.render(DATA, type: 'line', title: 'My Title')
    assert html.include?('"title":"My Title"')
  end

  def test_chart_data_is_json_encoded
    html = Rack::ChartsApi::HtmlRenderer.render(DATA)
    assert html.include?(DATA.to_json)
  end

  def test_multi_series_data
    multi = [
      { 'name' => 'A', 'data' => { 'x' => 1, 'y' => 2 } },
      { 'name' => 'B', 'data' => { 'x' => 3, 'y' => 4 } }
    ]
    html = Rack::ChartsApi::HtmlRenderer.render(multi)
    assert html.include?('"name":"A"')
    assert html.include?('"name":"B"')
  end

  def test_dimensions_in_style
    html = Rack::ChartsApi::HtmlRenderer.render(DATA, w: 500, h: 250)
    assert html.include?('width: 500px')
    assert html.include?('height: 250px')
  end
end
