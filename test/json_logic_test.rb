require 'test_helper'
require 'json'
require 'open-uri'

class JSONLogicTest < Minitest::Test
  tests = JSON.parse(open('http://jsonlogic.com/tests.json').read)
  tests.each_with_index do |pattern, index|
    next unless pattern.is_a?(Array)
    define_method("test_#{index}") do
      result = JSONLogic.apply(pattern[0], pattern[1])
      msg = "#{pattern[0].inspect} (data: #{pattern[1].inspect})"
      assert_equal(pattern[2], result, msg)
    end
  end
end
