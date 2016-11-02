module JSONLogic
  class RuleSet
    def initialize(logic, data)
      @logic = logic
      @data = data || {}
    end

    def evaluate(logic = @logic)
      return logic unless logic.is_a?(Hash)
      operator, values = logic.first # unwrap hash with single key
      values = [values] unless values.is_a? Array
      evaluated_values = values.map { |value| evaluate(value) }
      evaluated_values.flatten!(1) if evaluated_values.size == 1 # [['A']] => ['A']
      Operation.perform(operator, evaluated_values, @data)
    end
  end
end
