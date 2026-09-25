module JSONLogic
  ITERABLE_KEY = "".freeze

  class Operation
    LAMBDAS = {
      'var' => ->(v, d) do
        if !(d.is_a?(Hash) || d.is_a?(Array))
          d
        else
          if v == [JSONLogic::ITERABLE_KEY]
            d.is_a?(Array) ? d : d[JSONLogic::ITERABLE_KEY]
          else
            d.deep_fetch(*v)
          end
        end
      end,
      'missing' => ->(v, d) { v.select { |val| d.deep_fetch(val).nil? } },
      'missing_some' => ->(v, d) do
        present = v[1] & d.keys
        present.size >= v[0] ? [] : LAMBDAS['missing'].call(v[1], d)
      end,
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
        return v[0][v[1]..-1] unless v[2]

        limit = v[2] < 0 ? v[2] - 1 : v[1] + v[2] - 1

        v[0][v[1]..limit]
      end,
      'none' => -> (v,d) do
        v[0].none? { |val| interpolated_block(v[1], val).truthy? }
      end,
      'all' => -> (v,d) do
        # Difference between Ruby and JSONLogic spec ruby all? with empty array is true
        return false if v[0].empty?

        v[0].all? do |val|
          interpolated_block(v[1], val).truthy?
        end
      end,
      'reduce' => -> (v,d) do
        initial = JSONLogic.apply(v[2], d)
        return initial unless v[0].is_a?(Array)

        v[0].inject(initial) do |acc, val|
          interpolated_block(v[1], { "current": val, "accumulator": acc })
        end
      end,
      'map' => -> (v,d) do
        return [] unless v[0].is_a?(Array)

        v[0].map do |val|
          interpolated_block(v[1], val)
        end
      end,
      'if' => ->(v, d) do
        v.each_slice(2) do |condition_and_value|
          # A trailing single-element slice is the final "else" value.
          if condition_and_value.size == 1
            return condition_and_value.first
          else
            condition, value = condition_and_value
            return value if condition.truthy?
          end
        end
        nil
      end,
      '=='    => ->(v, d) { loose_equal?(v[0], v[1]) },
      '==='   => ->(v, d) { v[0] === v[1] },
      '!='    => ->(v, d) { !loose_equal?(v[0], v[1]) },
      '!=='   => ->(v, d) { v[0] != v[1] },
      '!'     => ->(v, d) { v[0].falsy? },
      '!!'    => ->(v, d) { v[0].truthy? },
      'or'    => ->(v, d) { v.find(&:truthy?) || v.last },
      'and'   => ->(v, d) do
        result = v.find(&:falsy?)
        result.nil? ? v.last : result
      end,
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
      'in'    => ->(v, d)  do
        result = interpolated_block(v[1], d)&.include? v[0]
        result.nil? ? false : result
      end,
      'cat'   => ->(v, d) { v.map(&:to_s).join },
      'log'   => ->(v, d) { puts v }
    }

    CUSTOM_LAMBDAS = {}

    def self.interpolated_block(block, data)
      # Make sure the empty var is there to be used in iterator
      JSONLogic.apply(block, data.is_a?(Hash) ? data.merge({"": data}) : { "": data })
    end

    def self.perform(operator, values, data)
      # If iterable, we can only pre-fill the first element, the second one must be evaluated per element.
      # If not, we can prefill all.

      interpolated =  if is_iterable?(operator)
        [JSONLogic.apply(values[0], data), *values[1..-1]]
      else
        values.map { |val| JSONLogic.apply(val, data) }
      end

      interpolated.flatten!(1) if interpolated.size == 1           # [['A']] => ['A']

      return LAMBDAS[operator.to_s].call(interpolated, data) if is_standard?(operator)
      return CUSTOM_LAMBDAS[operator.to_s].call(interpolated, data) if is_custom?(operator)
      raise ArgumentError, "Unknown operator #{operator}"
    end

    def self.is_standard?(operator)
      LAMBDAS.key?(operator.to_s)
    end

    # Loose ("soft") equality, mirroring JS `==` semantics per the JsonLogic spec.
    # `nil` (e.g. from a `var` lookup on a missing key) only equals `nil`/`undefined`,
    # never a coerced string/number, since `null == ""` and `null == 0` are both false in JS.
    def self.loose_equal?(a, b)
      return a.nil? && b.nil? if a.nil? || b.nil?

      a = a ? 1 : 0 if [true, false].include?(a)
      b = b ? 1 : 0 if [true, false].include?(b)

      if a.is_a?(Numeric) || b.is_a?(Numeric)
        af = numeric_value(a)
        bf = numeric_value(b)
        return false if af.nil? || bf.nil?
        return af == bf
      end

      a.to_s == b.to_s
    end

    def self.numeric_value(value)
      return value.to_f if value.is_a?(Numeric)
      return nil unless value.is_a?(String)
      return 0.0 if value.strip.empty?

      Float(value) rescue nil
    end

    def self.is_custom?(operator)
      CUSTOM_LAMBDAS.key?(operator.to_s)
    end

    # Determine if values associated with operator need to be re-interpreted for each iteration(ie some kind of iterator)
    # or if values can just be evaluated before passing in.
    def self.is_iterable?(operator)
      ['filter', 'some', 'all', 'none', 'in', 'map', 'reduce'].include?(operator.to_s)
    end

    def self.add_operation(operator, function)
      CUSTOM_LAMBDAS[operator.to_s] = function
    end
  end
end
