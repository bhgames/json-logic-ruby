require 'core_ext/deep_fetch'
require 'json_logic/truthy'
require 'json_logic/operation'

module JSONLogic
  def self.apply(logic, data)
    return logic unless logic.is_a?(Hash)             # pass-thru
    operator, values = logic.first                    # unwrap single-key hash
    values = [values] unless values.is_a?(Array)      # syntactic sugar
    values.map! { |value| apply(value, data) }        # recursion step
    values.flatten!(1) if values.size == 1            # [['A']] => ['A']
    Operation.perform(operator, values, data || {})   # perform operation
  end
end

require 'json_logic/version'
