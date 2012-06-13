require 'digest/sha1'
require 'digest/md5'
require_relative './validations.rb'
require_relative './common.rb'
require_relative './comm.rb'

class Divan::Design
  #include Validations
  #include Common
  extend ::Divan::Comm
  extend ::Divan::Common
  
  #attr_reader :id, :language, :validations, :views, :shows
  #attr_accessor :database
  
  
  @@id='_design/'+self.class.to_s
  @@language='javascript'
  @@views={}
  @@validations=[]
#    @shows={}
#    @uberdoc={}
  @@database = ::Divan::Configuration.dbstring('dbadmin')
  
  # generates json of whole design document
  def self.uberdoc
    {
      #'_id' => @id,
      :language => @@language,
      # should return string
      :validate_doc_update => ''
    }
=begin
<<EOT
(function (newDoc, oldDoc, userCtx, secObj) {


})
EOT
=end
  end
  
  def self.database
    @@database
  end
  
  
  def self.validate_doc_update
    @@validations.join("\n\n")
  end
  
  
  def self.avail_views
    @@views.keys
  end

  def self.info
    rawget(@@database+'_design/'+@@type+'/_info')
  end
  

  
  def self.sync?
    # TODO use HEAD?
    design = rawget(@@database+@@id)
    if design.code == 404
      return true
    elsif !design.errors.nil?
      raise("TODO some error")
    else
      # cannot use mvcc checksum, because it takes into account
      # previous versions (hashes) of document
      checksum_local = Digest::SHA256.hexdigest(uberdoc.jsonencode)
      checksum_remote = design[:divanchecksum]
      return true if checksum_remote.nil?
      return (checksum_remote==checksum_local ? false : true)
    end
  end
  
  def self.sync
    if sync?
      checksum = Digest::SHA256.hexdigest(uberdoc.jsonencode)
      design = uberdoc.merge({:divanchecksum=>checksum})
      design_remote = rawget(@@database+@@id)
      design = design.merge({:_rev=>design_remote[:_rev]}) if design_remote.errors.nil?
      result = rawput(@@database+@@id, design)
      return result[:ok]==true ? result : false
    else
      return false
    end
  end
end 
