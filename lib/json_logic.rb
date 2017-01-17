require 'core_ext/deep_fetch'
require 'json_logic/truthy'
require 'json_logic/operation'

module JSONLogic
  def self.apply(logic, data)
    return logic unless logic.is_a?(Hash)                # pass-thru
    operator, values = logic.first                       # unwrap single-key hash
    values = [values] unless values.is_a?(Array)         # syntactic sugar
    new_vals = values.map { |value| apply(value, data) } # recursion step
    new_vals.flatten!(1) if new_vals.size == 1           # [['A']] => ['A']
    if Operation.is_standard?(operator)                  # perform operation if standard
      return Operation.perform(operator, new_vals, data || {})
    end
    JSONLogic.send(operator, new_vals, data || {})       # perform custom operation
  end

  def self.filter(logic, data)
    data.select { |d| apply(logic, d) }
  end

  def self.add_operation(operator, function)
    self.class.send(:define_method, operator) do |v, d|
      function[v, d]
    end
  end
end

require 'json_logic/version'
