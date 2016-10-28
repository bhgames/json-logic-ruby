require 'test_helper'
require 'json'

class JSONLogicTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  path = File.join(File.dirname(__FILE__), 'patterns.json')
  patterns = JSON.parse(File.read(path))
  patterns.each_with_index do |pattern, index|
    next unless pattern.is_a?(Array)

    define_method("test_#{index}") do
      logic = pattern[0]
      data = pattern[1]
      expected = pattern[2]
      result = JSONLogic.apply(logic, data)
      message = "logic: #{logic}, data: #{data}, expected: #{expected}, but was: #{result}"
      assert_equal(expected, result, message)
    end
  end
end
