require 'core_ext/deep_fetch'

require 'json_logic/truthy'
require 'json_logic/operation'
require 'json_logic/rule_set'
require 'json_logic/version'

module JSONLogic
  def self.apply(logic, data = {})
    RuleSet.new(logic, data).evaluate
  end
end
