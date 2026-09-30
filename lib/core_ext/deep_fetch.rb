require 'backport_dig' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')

module DeepFetchable
  def deep_fetch(key, default = nil)
    keys = key.to_s.split('.')
    value = keys.inject(self) { |current, k| current.nil? ? nil : deep_fetch_step(current, k) }
    value.nil? ? default : value # value can be false (Boolean)
  rescue StandardError
    default
  end

  private

  def deep_fetch_step(current, k)
    case current
    when Hash
      current[k]
    when Array
      deep_fetch_array_step(current, k)
    end
  end

  # A numeric key indexes the array directly. A non-numeric key against a
  # single-element array transparently descends into that element, since a
  # non-repeating section is still wrapped in a one-element array upstream;
  # against an array with more (or zero) elements the key is ambiguous, so it
  # resolves to nil rather than guessing which element was meant.
  def deep_fetch_array_step(current, k)
    return current[k.to_i] if k =~ /\A-?\d+\z/
    return deep_fetch_step(current.first, k) if current.size == 1

    nil
  end
end

class Hash
  include DeepFetchable
end

class Array
  include DeepFetchable
end
