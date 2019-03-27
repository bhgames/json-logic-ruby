# JsonLogic truthy / falsy logic
# Cf. http://jsonlogic.com/truthy.html

class Object
  def truthy?
    !falsy?
  end

  def falsy?
    false
  end
end

class NilClass
  def falsy?
    true
  end
end

class FalseClass
  def falsy?
    true
  end
end

class String
  def falsy?
    empty?
  end
end

class Integer
  def falsy?
    zero?
  end
end

class Float
  def falsy?
    zero?
  end
end

class Array
  def falsy?
    empty?
  end
end
