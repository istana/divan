require 'digest/sha1'
require 'digest/md5'
require_relative './validations.rb'
require_relative './common.rb'


class Divan::Design
  include Validations
  include Common
  
  attr_reader :id, :language, :validations, :views, :shows
  
  def initialize
    @id='_design/'+self.class.to_s
    @language='javascript'
    @views={}
    @validations=[]
#    @shows={}
#    @uberdoc={}
  end
  
  # generates json of whole design document
  def uberdoc
    {
      'id' => @id,
      'language' => @language,
      # should return string
      'validate_doc_update' =>
<<EOT
(function (newDoc, oldDoc, userCtx, secObj) {


})    
EOT
  end
  
  def validate_doc_update
    @validations.join("\n\n")
  end
  
  
  def avail_views
    @views.keys
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
