module JSONLogic
  class Operation
    LAMBDAS = {
      'var' => ->(v, d) {
        val, default = v
        descend = val.to_s.split('.')
        result = if d.is_a?(Hash)
          d.dig(*descend)
        elsif d.is_a?(Array)
          descend.map!(&:to_i)
          descend.each do |i|
            d = d[i]
          end
          d
        end
        result || default
      },
      'missing' => ->(v, d) { v - d.keys },
      'missing_some' => ->(v, d) {
        present = v[1] & d.keys
        present.size >= v[0] ? [] : LAMBDAS['missing'].call(v[1], d)
      },
      'if' => ->(v, d) {
        v.each_slice(2) do |condition, value|
          return condition if value.nil?
          return value if condition
        end
      },
      '=='    => ->(v, d) { v[0] == v[1] },
      '==='   => ->(v, d) { v[0] === v[1] },
      '!='    => ->(v, d) { v[0] != v[1] },
      '!=='   => ->(v, d) { v[0] != v[1] },
      '!'     => ->(v, d) { !v[0] },
      '!!'    => ->(v, d) { !!v[0] },
      'or'    => ->(v, d) { v.reduce(false) { |a, e| a || e } },
      'and'   => ->(v, d) { v.reduce(true) { |a, e| a && e } },
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
      '/'     => ->(v, d) { v.map(&:to_i).reduce(:/) },
      '%'     => ->(v, d) { v.map(&:to_i).reduce(:%) },
      'merge' => ->(v, d) { v.flatten },
      'in'    => ->(v, d) { v[1].include? v[0] },
      'cat'   => ->(v, d) { v.map(&:to_s).join },
      'log'   => ->(v, d) { puts v }
    }

    def self.perform(operator, values, data)
      LAMBDAS[operator].call(values, data)
    end
  end
end
