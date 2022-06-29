require 'minitest/autorun'
require 'minitest/pride'

require 'json'
require 'open-uri'

require 'json_logic'

class JSONLogicTest < Minitest::Test
  test_suite_url = 'http://jsonlogic.com/tests.json'
  tests = JSON.parse(open(test_suite_url).read)
  count = 1
  tests.each do |pattern|
    next unless pattern.is_a?(Array)
    define_method("test_#{count}") do
      result = JSONLogic.apply(pattern[0], pattern[1])
      msg = "#{pattern[0].to_json} (data: #{pattern[1].to_json})"

      if pattern[2].nil?
        assert_nil(result, msg)
      else
        assert_equal(pattern[2], result, msg)
      end
    end
    count += 1
  end

  def test_filter
    filter = JSON.parse(%Q|{">": [{"var": "id"}, 1]}|)
    data = JSON.parse(%Q|[{"id": 1},{"id": 2}]|)

    assert_equal([{ 'id' => 2 }], JSONLogic.filter(filter, data))
  end

  def test_symbol_operation
    logic = {'==': [{ var: "id" }, 1]}
    data = JSON.parse(%Q|{"id": 1}|)

    assert JSONLogic.apply(logic, data)
  end

  def test_false_value
    logic = { '==': [{ var: "flag" }, false] }
    data = JSON.parse(%Q|{"flag": false}|)

    assert JSONLogic.apply(logic, data)
  end

  def test_add_operation
    new_operation = ->(v, d) { v.map { |x| x + 5 } }
    JSONLogic.add_operation('fives', new_operation)
    rules = JSON.parse(%Q|{"fives": {"var": "num"}}|)
    data = JSON.parse(%Q|{"num": 1}|)

    assert_equal([6], JSONLogic.apply(rules, data))
  end

  def test_exponent_operation
    exp = JSON.parse(%Q|{"^": [{"var": "num"}, 3]}|)
    data1 = JSON.parse(%Q|{"num": 2}|)
    data2 = JSON.parse(%Q|{"num": 3}|)
    data3 = JSON.parse(%Q|{"num": 4}|)

    assert_equal(8, JSONLogic.apply(exp, data1).to_i)
    assert_equal(27, JSONLogic.apply(exp, data2).to_i)
    assert_equal(64, JSONLogic.apply(exp, data3).to_i)
  end

  def test_array_with_logic
    assert_equal [1, 2, 3], JSONLogic.apply([1, { "var" => "x" }, 3], { "x" => 2 })

    assert_equal [42], JSONLogic.apply(
      {
        "if" => [
          { "var" => "x" },
          [{ "var" => "y" }],
          99
        ]
      },
      { "x" => true, "y" => 42 }
    )
  end

  def test_in_with_variable
    assert JSONLogic.apply(
      {
        "in" => [
          { "var" => "x" },
          { "var" => "x" }
        ]
      },
      { "x" => "foo" }
    )

    refute JSONLogic.apply(
      {
        "in" => [
          { "var" => "x" },
          { "var" => "y" }
        ]
      },
      { "x" => "foo", "y" => "bar" }
    )
  end

  def test_filter_with_non_array
    assert_empty JSONLogic.apply(
      {
        "filter" => [
          { "var" => "x" },
          { "==": ["x", "y"] }
        ]
      },
      nil
    )
  end

  def test_uses_data
    assert_equal ["x", "y"], JSONLogic.uses_data(
      {
        "in" => [
          { "var" => "x" },
          { "var" => "y" }
        ]
      }
    )
  end

  def test_uses_data_missing
    vars = JSONLogic.uses_data(
      {
        "in" => [
          { "var" => "x" },
          { "var" => "y" }
        ]
      }
    )

    provided_data_missing_y = { x: 3 }
    provided_data_missing_x = { y: 4 }

    assert_equal ["y"], JSONLogic.apply({ "missing": [vars] }, provided_data_missing_y)
    assert_equal ["x"], JSONLogic.apply({ "missing": [vars] }, provided_data_missing_x)
  end

  def test_in_with_non_array
    logic = { "in" => ["searchable_elem", { "var" => "non_array" }] }

    refute JSONLogic.apply(logic, { "non_array" => nil })
    refute JSONLogic.apply(logic, nil)
  end
end
