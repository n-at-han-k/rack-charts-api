require_relative 'test_helper'

class PngRendererTest < Minitest::Test
  DATA = { 'red' => [10, 20, 30], 'blue' => [30, 20, 10] }.freeze

  def test_renders_valid_png
    blob = Rack::ChartsApi::PngRenderer.render(DATA)
    assert blob.start_with?("\x89PNG".b)
  end

  def test_custom_dimensions
    blob = Rack::ChartsApi::PngRenderer.render(DATA, w: 400, h: 200)
    assert blob.start_with?("\x89PNG".b)
  end

  def test_bar_type
    blob = Rack::ChartsApi::PngRenderer.render(DATA, type: 'bar')
    assert blob.start_with?("\x89PNG".b)
  end

  def test_pie_type
    blob = Rack::ChartsApi::PngRenderer.render({ 'A' => [60], 'B' => [40] }, type: 'pie')
    assert blob.start_with?("\x89PNG".b)
  end

  def test_column_alias_maps_to_bar
    klass = Rack::ChartsApi::PngRenderer.resolve_type('column')
    assert_equal Gruff::Bar, klass
  end

  def test_unknown_type_falls_back_to_line
    klass = Rack::ChartsApi::PngRenderer.resolve_type('nonexistent')
    assert_equal Gruff::Line, klass
  end

  def test_with_title
    blob = Rack::ChartsApi::PngRenderer.render(DATA, title: 'Test')
    assert blob.start_with?("\x89PNG".b)
  end

  def test_with_labels
    blob = Rack::ChartsApi::PngRenderer.render(DATA, labels: { 0 => 'A', 1 => 'B', 2 => 'C' })
    assert blob.start_with?("\x89PNG".b)
  end
end
