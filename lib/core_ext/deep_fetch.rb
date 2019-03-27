class Hash
  def deep_fetch(key, default = nil)
    keys = key.to_s.split('.')
    value = dig(*keys) rescue default
    value.nil? ? default : value  # value can be false (Boolean)
  end
end

class Array
  def deep_fetch(index, default = nil)
    indexes = index.to_s.split('.').map(&:to_i)
    value = dig(*indexes) rescue default
    value.nil? ? default : value  # value can be false (Boolean)
  end
end
