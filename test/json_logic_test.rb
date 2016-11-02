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
      assert_equal(pattern[2], result, msg)
    end
    count += 1
  end
end
