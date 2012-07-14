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
  
  def flush_database
  #TODO
  #  _ensure_full_commit
  end
  
  def changes
  #TODO
  #_changes
  end
end

class Object
  def blank?
    return true if self.nil?
    return true if self == false
    return true if self.respond_to? :empty? && self.empty?
    return true if self.is_a? String && /\A\s*\z/.match(self)
    false 
  end
end

