module JSONLogic
  class Operation
    LAMBDAS = {
      'var' => ->(v, d) { d.deep_fetch(*v) },
      'missing' => ->(v, d) { v.select { |val| d.deep_fetch(val).nil? } },
      'missing_some' => ->(v, d) {
        present = v[1] & d.keys
        present.size >= v[0] ? [] : LAMBDAS['missing'].call(v[1], d)
      },
      'if' => ->(v, d) {
        v.each_slice(2) do |condition, value|
          return condition if value.nil?
          return value if condition.truthy?
        end
      },
      '=='    => ->(v, d) { v[0].to_s == v[1].to_s },
      '==='   => ->(v, d) { v[0] == v[1] },
      '!='    => ->(v, d) { v[0].to_s != v[1].to_s },
      '!=='   => ->(v, d) { v[0] != v[1] },
      '!'     => ->(v, d) { v[0].falsy? },
      '!!'    => ->(v, d) { v[0].truthy? },
      'or'    => ->(v, d) { v.find(&:truthy?) || v.last },
      'and'   => ->(v, d) {
        result = v.find(&:falsy?)
        result.nil? ? v.last : result
      },
      '?:'    => ->(v, d) { LAMBDAS['if'].call(v, d) },
      '>'     => ->(v, d) { v.map(&:to_i).each_cons(2).all? { |i, j| i > j } },
      '>='    => ->(v, d) { v.map(&:to_i).each_cons(2).all? { |i, j| i >= j } },
      '<'     => ->(v, d) { v.map(&:to_i).each_cons(2).all? { |i, j| i < j } },
      '<='    => ->(v, d) { v.map(&:to_i).each_cons(2).all? { |i, j| i <= j } },
      'max'   => ->(v, d) { v.map(&:to_i).max },
      'min'   => ->(v, d) { v.map(&:to_i).min },
      '+'     => ->(v, d) { v.map(&:to_i).reduce(:+) },
      '-'     => ->(v, d) { v.map!(&:to_i); v.size == 1 ? -v.first : v.reduce(:-) },
      '*'     => ->(v, d) { v.map(&:to_i).reduce(:*) },
      '/'     => ->(v, d) { v.map(&:to_f).reduce(:/) },
      '%'     => ->(v, d) { v.map(&:to_i).reduce(:%) },
      'merge' => ->(v, d) { v.flatten },
      'in'    => ->(v, d) { v[1].include? v[0] },
      'cat'   => ->(v, d) { v.map(&:to_s).join },
      'log'   => ->(v, d) { puts v }
    }

    def self.perform(operator, values, data)
      return LAMBDAS[operator].call(values, data) if is_standard?(operator)
      send(operator, values, data)
    end

    def self.is_standard?(operator)
      LAMBDAS.keys.include?(operator)
    end

    def self.add_operation(operator, function)
      self.class.send(:define_method, operator) do |v, d|
        function.call(v, d)
      end
    end
  end
end
