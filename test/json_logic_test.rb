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
    assert_equal([{'id' => 2}], JSONLogic.filter(filter, data))
  end

  def test_symbol_operation
    logic = {'==': [{var: "id"}, 1]}
    data = JSON.parse(%Q|{"id": 1}|)
    assert_equal(true, JSONLogic.apply(logic, data))
  end

  def test_add_operation
    new_operation = ->(v, d) { v.map { |x| x + 5 } }
    JSONLogic.add_operation('fives', new_operation)
    rules = JSON.parse(%Q|{"fives": {"var": "num"}}|)
    data = JSON.parse(%Q|{"num": 1}|)
    assert_equal([6], JSONLogic.apply(rules, data))
  end

  def test_array_with_logic
    assert_equal [1, 2, 3], JSONLogic.apply([1, {"var" => "x"}, 3], {"x" => 2})

    assert_equal [42], JSONLogic.apply(
      {
        "if" => [
          {"var" => "x"},
          [{"var" => "y"}],
          99
        ]
      },
      { "x" => true, "y" => 42}
    )
  end
end
