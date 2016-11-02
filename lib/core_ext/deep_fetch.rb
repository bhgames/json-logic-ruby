class Hash
  def deep_fetch(key, default = nil)
    keys = key.to_s.split('.')
    dig(*keys) || default rescue default
  end
end

class Array
  def deep_fetch(index, default = nil)
    indexes = index.to_s.split('.').map(&:to_i)
    dig(*indexes) || default rescue default
  end
end
