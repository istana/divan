require_relative "design/validations.rb"

# move upper, choose yajl

require 'multi_json'
require 'digest/sha1'
require 'digest/md5'

class CouchSaModel::Design
  extend Validations
  
  attr_reader :_id, :language, :validations, :views, :shows
  
  def initialize
    @_id='_design/'+self.class
    @language='javascript'
    @views={}
    @validations=[]
    @shows={}
    @uberdoc={}
  end
  
  def validate_doc_update
    @validations.join("\n")
  end
  
  class String
    def jsondecode
      MultiJson.decode(self.strip)
    end
    def jsonencode
      MultiJson.encode(self.strip)
    end
  end
  
  def views
  
  end

  def info
    RestClient.get(dbstring+'_design/'+@type+'/_info').jsondecode
  end
  
  def dbinfo
    RestClient.get(dbstring).jsondecode
  end
  
  def sync
    shaofdesign=Digest::SHA1.hexdigest(@uberdoc.jsonencode)
    md5ofdesign=Digest::MD5.hexdigest(@uberdoc.jsonencode)
    
    design = RestClient.get(dbstring+@_id).jsondecode rescue nil
    if design == nil
      sync = true
    else
      checksum = design._rev.gsub(/\A\d+-/, '')
      sync = (md5ofdesign==checksum ? false : true)
    end
    
    if sync
      @uberdoc['_rev'] = design['_rev'] unless design.nil?
      RestClient.post dbstring, @uberdoc.jsonencode, :content_type => :json, :accept => :json
      return true
    else
      return false
    end
  end
end 
