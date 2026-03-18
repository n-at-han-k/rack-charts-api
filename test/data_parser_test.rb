require_relative 'test_helper'

class DataParserTest < Minitest::Test
  Parser = Rack::ChartsApi::DataParser

  def test_normalize_single_series_hash
    input = { 'Jan' => 10, 'Feb' => 20, 'Mar' => 30 }
    result = Parser.normalize_data(input)
    assert_equal input, result
  end

  def test_normalize_array_of_pairs
    input = [['Jan', 10], ['Feb', 20]]
    result = Parser.normalize_data(input)
    assert_equal({ 'Series' => [10, 20] }, result)
  end

  def test_normalize_multi_series
    input = [
      { 'name' => 'A', 'data' => [['x', 1], ['y', 2]] },
      { 'name' => 'B', 'data' => [['x', 3], ['y', 4]] }
    ]
    result = Parser.normalize_data(input)
    assert_equal({ 'A' => [1, 2], 'B' => [3, 4] }, result)
  end

  def test_normalize_multi_series_with_hash_data
    input = [
      { 'name' => 'Sales', 'data' => { 'Q1' => 100, 'Q2' => 200 } }
    ]
    result = Parser.normalize_data(input)
    assert_equal({ 'Sales' => [100, 200] }, result)
  end

  def test_normalize_flat_array
    input = [10, 20, 30]
    result = Parser.normalize_data(input)
    assert_equal({ 'Series' => [10, 20, 30] }, result)
  end

  def test_normalize_nil
    assert_nil Parser.normalize_data(nil)
  end

  def test_extract_options_defaults
    opts = Parser.extract_options({})
    assert_equal 'line', opts[:type]
    assert_equal 800, opts[:w]
    assert_equal 600, opts[:h]
  end

  def test_extract_options_overrides
    opts = Parser.extract_options('type' => 'bar', 'w' => '1024', 'h' => '512', 'title' => 'Hello')
    assert_equal 'bar', opts[:type]
    assert_equal 1024, opts[:w]
    assert_equal 512, opts[:h]
    assert_equal 'Hello', opts[:title]
  end
end
