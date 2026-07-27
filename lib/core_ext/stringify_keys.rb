class Hash
  # Only define transform_keys when the native method is unavailable (Ruby < 2.5).
  # Defining it unconditionally clobbers the native version, which also accepts a
  # mapping hash, so downstream `transform_keys(a: :b)` calls raise ArgumentError.
  unless method_defined?(:transform_keys)
    def transform_keys
      return enum_for(:transform_keys) { size } unless block_given?
      result = {}
      each_key do |key|
        result[yield(key)] = self[key]
      end
      result
    end
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