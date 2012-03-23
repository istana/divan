require_relative "design/validations.rb"
class CouchSaModel::Design
  extend Validations
  
  
  class String
    def jsondecode
      MultiJson.decode(self.strip)
    end
  end
  
  def rawget(uri, options={})
      
  end
  
  def info
    RestClient.get @database+@type+'_info'
  end
end 
