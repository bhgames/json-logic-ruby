require 'json_logic/truthy'
require 'json_logic/operation'
require 'json_logic/rule_set'
require 'json_logic/version'

class Hash
  def get(key)
    keys = key.to_s.split('.')
    dig(*keys) rescue nil
  end
end

class Array
  def get(index)
    indexes = index.to_s.split('.').map(&:to_i)
    result = self
    while indexes.size > 0
      result = result.fetch(indexes.shift)
    end
    result
  end
end

module JSONLogic
  def self.apply(logic, data)
    RuleSet.new(logic, data).evaluate
  end
end
