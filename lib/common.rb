

module Divan::Common
  # accessors use is needed for it to work both in include and extend style
  def dbinfo
    rawget(database)
  end
  
  def database?
    res = rawget(database)
    puts res.inspect
    # TODO watch
    res.errors.nil?
  end
  
  def database!
    res = rawget(database)
    puts res.inspect
    if res.code == 404
      res_created_db = rawput(database)
      if res_created_db.errors.nil? && res_created_db.result['ok']==true
        true
      else
        false
      end
    else
      false
    end
  end
end

class String
  def jsondecode
    MultiJson.load(self.strip)
  end
end

class Hash
  def jsonencode
    MultiJson.dump(self)
  end
end
