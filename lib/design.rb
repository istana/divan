require 'digest/sha1'

class Divan::Design
  ['associations', 'security'
  ].each do |file|
    require_relative File.join('.', 'design', file + '.rb')
  end
  
  #### THIS HAS TO BE ABOVE HTTParty
  # HTTParty cannot handle self.inferited(self)
  extend Security
  extend Associations
  
  def self.inherited(subclass)
    super
    subclass.instance_variable_set :@views, {}
    subclass.instance_variable_set :@validations, {}
  end
  
   # this calls inherited method on Divan::Design
  # inherited would be only called on subclass
  # but need to initialize variables for Design too
  self.inherited(self)
  ###
  include HTTParty
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  format :json
  base_uri Divan::Configuration.dbstring('dbadmin')
  
  
#  @views = {}
  @validations = []
#    @shows={}
  
  #include Validations
  #include Common
  #extend ::Divan::Comm
  #extend ::Divan::Common
  
   def self.type
    self.to_s
  end
  
  def self._id
    '_design/'+self.type
  end
  
  def self.document
    return 'Divan::Document' if type == 'Divan::Design'
    type.gsub('Design', '')
  end
  
  def self.language
    'javascript'
  end
    


  # generates json of whole design document
  def self.uberdoc
    {
      #'_id' => @id,
      :language => language,
      # should return string
      :validate_doc_update => 'function (newDoc, oldDoc, userCtx, secObj) {}',
      :views => @views
    }
=begin
<<EOT
(function (newDoc, oldDoc, userCtx, secObj) {


})
EOT
=end
  end
  
  def self.validate_doc_update
    @validations.join("\n\n")
  end
  
  
  def self.views
    @views.keys
  end

  def self.info
    result = ::Typhoeus.get(database + '/_design/' + uri_encode(type) + '/_info')
    
    if result.success?
    	MultiJson.load(result.body)
    else
    	raise("Database info cannot be find out, HTTP code: " + x.code.to_s)
    end
  end
  
  def self.synchronized?
    design = ::Typhoeus.get(database + uri_encode(_id))
    
    if design.code == 404 && design.parsed_response['reason'] == 'missing'
    	return false
    elsif !design.success?
    	raise("Design document cannot be fetched")
    end
    
    # cannot use mvcc checksum, because it takes into account
    # previous versions (hashes) of document
    checksum_local = Digest::SHA256.hexdigest(MultiJson.dump(uberdoc))
    checksum_remote = MultiJson.load(design)['divan_checksum']
    
    return false if checksum_remote.nil?
    return (checksum_remote == checksum_local ? true : false)
  end
  
  def self.synchronize
    if !synchronized?
      checksum = Digest::SHA256.hexdigest(MultiJson.dump(uberdoc))
      design = uberdoc.merge('divanchecksum' => checksum)
      design_remote = ::Typhoeus.get(database + uri_encode(_id))
      
      if design_remote.code == 404
        if design_remote.parsed_response['reason'] == 'no_db_file'
          raise("Database doesn't exist")
        end
        
        result = ::Typhoeus.put(database + uri_encode(_id), body: MultiJson.dump(design))
        
        if result.success?
        	return result.parsed_response['rev']
        else
        	raise("Error synchronizing database")
        end
        
      elsif design_remote.success?
        revision = design_remote.parsed_response['_rev']
        response = ::Typhoeus.put(database + uri_encode(_id), params: {rev: rev}, body: MultiJson.dump(design))
        
        if response.success?
        	return result.parsed_response['rev']
        else
        	raise("Error synchronizing database")
        end
      end
    end
    
    false
  end
end 
