module JSONLogic
  ITERABLE_KEY = "".freeze

  class Operation
    LAMBDAS = {
      'var' => ->(v, d) do
        if !(d.is_a?(Hash) || d.is_a?(Array))
          d
        else
          if v == [JSONLogic::ITERABLE_KEY]
            if d.is_a?(Array)
              d
            else
              d[JSONLogic::ITERABLE_KEY]
            end
          else
            d.deep_fetch(*v)
          end
        end
      end,
      'missing' => ->(v, d) { v.select { |val| d.deep_fetch(val).nil? } },
      'missing_some' => ->(v, d) {
        present = v[1] & d.keys
        present.size >= v[0] ? [] : LAMBDAS['missing'].call(v[1], d)
      },
      'some' => -> (v,d) do
        return false unless v[0].is_a?(Array)

        v[0].any? do |val|
          interpolated_block(v[1], val).truthy?
        end
      end,
      'filter' => -> (v,d) do
        return [] unless v[0].is_a?(Array)

        v[0].select do |val|
          interpolated_block(v[1], val).truthy?
        end
      end,
      'substr' => -> (v,d) do
        limit = -1
        if v[2]
          if v[2] < 0
            limit = v[2] - 1
          else
            limit = v[1] + v[2] - 1
          end
        end

         v[0][v[1]..limit]
      end,
      'none' => -> (v,d) do

        v[0].each do |val|
          this_val_satisfies_condition = interpolated_block(v[1], val)
          if this_val_satisfies_condition
            return false
          end
        end

        return true
      end,
      'all' => -> (v,d) do
        # Difference between Ruby and JSONLogic spec ruby all? with empty array is true
        return false if v[0].empty?

        v[0].all? do |val|
          interpolated_block(v[1], val)
        end
      end,
      'reduce' => -> (v,d) do
        return v[2] unless v[0].is_a?(Array)
        v[0].inject(v[2]) { |acc, val| interpolated_block(v[1], { "current": val, "accumulator": acc })}
      end,
      'map' => -> (v,d) do
        return [] unless v[0].is_a?(Array)
        v[0].map do |val|
          interpolated_block(v[1], val)
        end
      end,
      'if' => ->(v, d) {
        v.each_slice(2) do |condition, value|
          return condition if value.nil?
          return value if condition.truthy?
        end
      },
      '=='    => ->(v, d) { v[0].to_s == v[1].to_s },
      '==='   => ->(v, d) { v[0] === v[1] },
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
      '>'     => ->(v, d) { v.map(&:to_f).each_cons(2).all? { |i, j| i > j } },
      '>='    => ->(v, d) { v.map(&:to_f).each_cons(2).all? { |i, j| i >= j } },
      '<'     => ->(v, d) { v.map(&:to_f).each_cons(2).all? { |i, j| i < j } },
      '<='    => ->(v, d) { v.map(&:to_f).each_cons(2).all? { |i, j| i <= j } },
      'max'   => ->(v, d) { v.map(&:to_f).max },
      'min'   => ->(v, d) { v.map(&:to_f).min },
      '+'     => ->(v, d) { v.map(&:to_f).reduce(:+) },
      '-'     => ->(v, d) { v.map!(&:to_f); v.size == 1 ? -v.first : v.reduce(:-) },
      '*'     => ->(v, d) { v.map(&:to_f).reduce(:*) },
      '/'     => ->(v, d) { v.map(&:to_f).reduce(:/) },
      '%'     => ->(v, d) { v.map(&:to_i).reduce(:%) },
      '^'     => ->(v, d) { v.map(&:to_f).reduce(:**) },
      'merge' => ->(v, d) { v.flatten },
      'in'    => ->(v, d) { interpolated_block(v[1], d).include? v[0] },
      'cat'   => ->(v, d) { v.map(&:to_s).join },
      'log'   => ->(v, d) { puts v }
    }

    def self.interpolated_block(block, data)
      # Make sure the empty var is there to be used in iterator
      JSONLogic.apply(block, data.is_a?(Hash) ? data.merge({"": data}) : { "": data })
    end

    def self.perform(operator, values, data)
      # If iterable, we can only pre-fill the first element, the second one must be evaluated per element.
      # If not, we can prefill all.

      if is_iterable?(operator)
        interpolated = [JSONLogic.apply(values[0], data), *values[1..-1]]
      else
        interpolated = values.map { |val| JSONLogic.apply(val, data) }
      end

      interpolated.flatten!(1) if interpolated.size == 1           # [['A']] => ['A']

      return LAMBDAS[operator.to_s].call(interpolated, data) if is_standard?(operator)
      send(operator, interpolated, data)
    end

    def self.is_standard?(operator)
      LAMBDAS.key?(operator.to_s)
    end

    # Determine if values associated with operator need to be re-interpreted for each iteration(ie some kind of iterator)
    # or if values can just be evaluated before passing in.
    def self.is_iterable?(operator)
      ['filter', 'some', 'all', 'none', 'in', 'map', 'reduce'].include?(operator.to_s)
    end

    def self.add_operation(operator, function)
      self.class.send(:define_method, operator) do |v, d|
        function.call(v, d)
      end
    end
  end
end
