module Divan::Common


end

class String
  def jsondecode
    MultiJson.decode(self.strip)
  end
end

class Hash
  def jsonencode
    MultiJson.encode(self)
  end
end
