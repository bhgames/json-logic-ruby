require 'core_ext/deep_fetch'
require 'core_ext/stringify_keys'
require 'json_logic/truthy'
require 'json_logic/operation'
module JSONLogic
  def self.apply(logic, data)
    if logic.is_a?(Array)
      return logic.map { |val| apply(val, data) }
    end

    return logic unless logic.is_a?(Hash)                  # pass-thru

    data = data.stringify_keys if data.is_a?(Hash)         # Stringify keys to keep out problems with symbol/string mismatch
    operator, values = logic.first                         # unwrap single-key hash
    values = [values] unless values.is_a?(Array)           # syntactic sugar
    Operation.perform(operator, values, data || {})
  end

  def self.uses_data(logic)
    collection = []

    operator, values = logic.first
    values = [values] unless values.is_a?(Array)
    if operator == 'var'
      collection.append(values[0])
    else
      values.each { |val|
        collection.concat(uses_data(val))
      }
    end

    return collection.uniq
  end

  def self.filter(logic, data)
    data.select { |d| apply(logic, d) }
  end

  def self.add_operation(operator, function)
    Operation.class.send(:define_method, operator) do |v, d|
      function.call(v, d)
    end
  end
end

require 'json_logic/version'
