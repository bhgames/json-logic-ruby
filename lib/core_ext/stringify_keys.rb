class Hash
  # Stolen from ActiveSupport
  def transform_keys
    return enum_for(:transform_keys) { size } unless block_given?

    result = {}
    each_key do |key|
      result[yield(key)] = self[key]
    end

    result
  end

  # Returns a new hash with all keys converted to strings.
  #
  #   hash = { name: 'Rob', age: '28' }
  #
  #   hash.stringify_keys
  #   # => {"name"=>"Rob", "age"=>"28"}
  def stringify_keys
    transform_keys(&:to_s)
  end
end