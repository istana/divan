module Divan::Misc
  def dbinfo
    self.get('').parsed_response
  end
  
  def database?
    res = self.get('')
    res.success?
  end
  
end

class Divan::DBAdmin
  include HTTParty
  
  base_uri Divan::Configuration.dbstring('dbadmin')
  
  headers 'Accept' => 'application/json'
  format :json
  
  def self.database!
    base_uri Divan::Configuration.dbstring('dbadmin')
    res = self.get('')
    if res.code == 404
      created_db = self.put('')
      if created_db.success? && created_db.parsed_response['ok']==true
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
    return true if self.respond_to?(:empty?) && self.empty?
    return true if self.is_a?(String) && /\A\s*\z/.match(self)
    false 
  end
end

