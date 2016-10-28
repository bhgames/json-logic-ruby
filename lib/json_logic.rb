require 'json_logic/version'

module JSONLogic
  OPERATIONS = {
    # Accessing Data
    # 'var'
    # 'missing'
    # 'missing_some'
    # Logic and Boolean Operations
    'if'           => ->(args) { args[0] ? args[1] : args[2] },
    '=='           => ->(args) { args[0] == args[1] },
    '==='          => ->(args) { args[0] === args[1] },
    '!='           => ->(args) { args[0] != args[1] },
    '!=='          => ->(args) { args[0] != args[1] },
    '!'            => ->(args) { !args[0] },
    '!!'           => ->(args) { !!args[0] },
    'or'           => ->(args) { args.reduce(false) { |a, e| a || e } },
    'and'          => ->(args) { args.reduce(true) { |a, e| a && e } },
    '?:'           => ->(args) { args[0] ? args[1] : args[2] },
    # Numeric Operations
    '>'            => ->(args) { args.map(&:to_i).each_cons(2).all? { |i, j| i > j } },
    '>='           => ->(args) { args.map(&:to_i).each_cons(2).all? { |i, j| i >= j } },
    '<'            => ->(args) { args.map(&:to_i).each_cons(2).all? { |i, j| i < j } },
    '<='           => ->(args) { args.map(&:to_i).each_cons(2).all? { |i, j| i <= j } },
    'max'          => ->(args) { args.map(&:to_i).max },
    'min'          => ->(args) { args.map(&:to_i).min },
    '+'            => ->(args) { args.map(&:to_i).reduce(:+) },
    '-'            => ->(args) { args.map!(&:to_i); args.size == 1 ? -args.first : args.reduce(:-) },
    '*'            => ->(args) { args.map(&:to_i).reduce(:*) },
    '/'            => ->(args) { args.map(&:to_i).reduce(:/) },
    '%'            => ->(args) { args.map(&:to_i).reduce(:%) },
    # Array Operations
    'merge'        => ->(args) { args.flatten },
    'in'           => ->(args) { args[1].include? args[0] },
    # String Operations
    'in'           => ->(args) { args[1].include? args[0] },
    'cat'          => ->(args) { args.map(&:to_s).join },
    # Miscellaneous
    'log'          => ->(args) { puts args }
  }

  def self.apply(rule, data)
    return rule unless rule.is_a?(Hash)
    operator, values = rule.first
    OPERATIONS[operator].call(Array(values))
  end
end
