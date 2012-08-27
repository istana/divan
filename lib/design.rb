require 'digest/sha1'

class Divan::Design
  include HTTParty
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  format :json
  base_uri Divan::Configuration.dbstring('dbadmin')
  
  
  @@views = {}
  @@validations = []
#    @shows={}    
  
  ['associations', 'security'
  ].each do |file|
    require_relative File.join('.', 'design', file + '.rb')
  end
  
  extend Associations
  include Security
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
      :validate_doc_update => '',
      :views => @@views
    }
=begin
<<EOT
(function (newDoc, oldDoc, userCtx, secObj) {


})
EOT
=end
  end
  
  def self.validate_doc_update
    @@validations.join("\n\n")
  end
  
  
  def self.views
    @@views.keys
  end

  def self.info
    x = get('/_design/'+type+'/_info')
    return x.parsed_response if x.success?
    raise("Database info cannot be find out, HTTP code: " + x.code.to_s)
  end
  
  def self.sync?
    design = get('/' + _id)
    
    return true if design.code == 404 && design.parsed_response['reason'] == 'missing'
    raise("Design document cannot be fetched") unless design.success?
    
    # cannot use mvcc checksum, because it takes into account
    # previous versions (hashes) of document
    checksum_local = Digest::SHA256.hexdigest(MultiJson.dump(uberdoc))
    checksum_remote = design.parsed_response['divanchecksum']
    
    return true if checksum_remote.nil?
    return (checksum_remote==checksum_local ? false : true)
  end
  
  def self.sync
    if sync?
      checksum = Digest::SHA256.hexdigest(MultiJson.dump(uberdoc))
      design = uberdoc.merge({'divanchecksum' => checksum})
      
      design_remote = get('/' + _id)
      
      if design_remote.code == 404
        # design don't exists in database
        if design_remote.parsed_response['reason'] == 'no_db_file'
          raise("Database doesn't exist")
        end
        
        result = put('/' + _id, :body => MultiJson.dump(design))
        return true if result.success?
      elsif design_remote.success?
        rev = design_remote.parsed_response['_rev']
        result = put('/' + _id, :query => {:rev => rev}, :body => MultiJson.dump(design))
        return result.parsed_response['rev'] if result.success?
      end
    end
    return false
  end
end 
