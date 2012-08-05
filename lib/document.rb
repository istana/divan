# -*- encoding : utf-8 -*-

require_relative './common.rb'

require 'httparty'
class Divan::Document
  include HTTParty
  
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  format :json
  base_uri Divan::Configuration.dbstring
  
  # special fields
  # _id - unique identifier (mandatory and immutable)
  # _rev - mvcc revision  (mandatory and immutable)
  # _attachments - attachments metadata
  # _deleted has been deleted?
  # And previous revisions will be removed on next compaction run
  # _revisions - revision history of the document
  # _revs_info - list of revisions of the document, and their availability
  # _conflicts - information about conflicts
  # _deleted_conflicts - information about conflicts
  # _local_seq - sequence number of the revision in the database (as found in the _changes feed) 
  # curl -X GET 'http://localhost:5984/my_database/my_document?conflicts=true'
  # The query parameter for the _revisions special field is revs
  #
  # + option rev=34BD7C, which gets certain revision
  # save probably raise conflict
  # can't be used in views
  # Replication only replicates the last version of a document,
  # so it will be impossible to access, on the destination database,
  # previous versions of a document that was stored on the source database.
  # - open_revs is not supported
  #
  
  # new record, which is not in database
  # random unique ID is assigned, if not given
  # can also call Divan::Document.new with hash
  # which contains type and id
  def self.neo(fields = {})
    if !fields.has_key?('_id') || fields['_id'].blank?
      fields['_id'] = SecureRandom.uuid
    end
    
    if self.type != "Divan::Document"
      fields['type'] = self.type
    end
    self.new(fields)
  end
  
  # options - see special fields
  # another options is :all => whatever, which fetches all (available) special fields
  # option :raw => whatever returns HTTParty object, get to doc with obj.parsed_response
  def self.fetch(id, options = {})
    params = {:deleted => true, :conflicts => true}
    if options.has_key? :all
      options = {:revs => true, :revs_info => true, :deleted_conflicts => true, :local_seq => true}
    end
    
    d = get('/'+id, :query => options.merge(params))
    if d.success?
      if options.has_key?(:raw)
        d
      else
        type = d.parsed_response['type'] || 'Document'
        const_defined?(d.parsed_response['type']) ? const_get(type).new(d) : Document.new(d)
      end
    else
      raise("Document could not be fetched from CouchDB, status:"+d.code.to_s+"message:"+d.message)
    end
  end
  
  
  def initialize(doc)
    @fields = []
    
    # hash with fields, to be able to return loaded document
     @original_doc = (doc.respond_to?(:parsed_response) ? doc.parsed_response : doc)
    
    # HTTParty object
    # to access request, status code and like that
    @last_request = @original_doc
    
    # confl because conflict could exist as field of document
    @confl = false
    populate
  end
  
  def clone
  #TODO:
  end
  
  class << self
    # want to call them from outside in save
    #protected :get, :post, :put, :delete, :head
  end
  
  # HTTParty object
  # can call request, code, response, parsed_response, headers, message (like OK or Object not found)
  # or success?, forbidden? (see HTTParty specs)
  def lastreq
    @last_request
  end

  def conflict?
    @confl
  end

  def new?
    !instance_variable_defined? '@_rev'.to_sym
  end
  
  def deleted?
    self.respond_to? :_deleted
  end
  

  # reasonable option: batch=ok
  # it seems format of HTTParty doesn't work on instance
  def save(options = {})
    doc = self.document
    id = doc.delete('_id')
    pacify_blank(id)
    @last_request = self.class.put('/'+id, :query => options, :body => MultiJson.dump(doc))
    
    #TODO:logger.debug '('+self.base_uri+') Document save:' + @last_request
    
    if @last_request.conflict?
      @confl = true
      raise("Document conflict!")
      return false
    end
    
    if @last_request.success? && @last_request.parsed_response['ok']==true
      if self.respond_to? :_rev
        instance_variable_set :@_rev, @last_request.parsed_response['rev']
      else
       add_field(:_rev, @last_request.parsed_response['rev'])
      end
      return true
    end
    raise("Error saving document!")
  end
  
  def destroy
    return self if self.new?
    raise("Revision is old!") unless self.latest?
    @last_request = self.class.delete('/'+@_id, :query => {:rev => @_rev})
    raise("Error destroying document!") unless @last_request.success?
    self
  end
    
  # I don't expect to use this much, so this primitivity would be enough
  def return_original
    if new?
      return self.class.new(@original_doc)
    else
      return self.class.fetch(@original_doc['_id'])
    end
  end

  ###
  def populate
    # deep copy
    doc = Marshal.load(Marshal.dump(@original_doc))
    doc.each do |key, value|
      add_field(key, value)
    end
  end

  # TODO attr_protected
  def add_field(f, val)
    f = f.to_s
    pacify_blank(f)
    unless instance_variable_defined?("@#{f}")
      self.instance_variable_set "@#{f}", val
      # probably not
      #alias_method "alias_#{f}", f if self.respond_to? f.to_sym
      # accessor
      self.define_singleton_method f do
        instance_variable_get "@#{f}".to_sym
      end
      # writer
      self.define_singleton_method "#{f}=".to_sym do |param1|
        instance_variable_set "@#{f}".to_sym, param1
      end
      @fields << f.to_s
    else
      raise(ArgumentError, "This field exists already")
    end
  end
  
  def remove_field(f)
    f = f.to_s
    pacify_blank(f)
    if self.respond_to?(f.to_sym) && self.respond_to?("#{f}=".to_sym) && instance_variable_defined?("@#{f}".to_sym)
      eigenclass = ( class << self; self; end )
      eigenclass.send(:"undef_method", "#{f}=".to_sym)
      eigenclass.send(:"undef_method", f.to_sym)
       
      remove_instance_variable "@#{f}".to_sym
      @fields.delete(f.to_s)
    else
      raise(ArgumentError, "This field doesn't exist")
    end
  end
  
  ###
  
  def document
    doc = {}
    @fields.each do |field|
     doc[field] = self.send field.to_sym
    end
    doc
  end
  
  def design
    self.type+"Design"
  end
  
  def self.type
    self.to_s
  end
  
  ###
  ### REVISIONS
  def return_latest_revision
    return false if self.new?
    pacify_blank @_id
    
    http_response = self.class.head('/'+@_id)
    (return http_response['etag'].gsub('"', '')) if http_response.success?
      
     # well, this should exists always unless played with _id
     raise("Document could not be fetched from CouchDB")
  end
  
  def latest?
    return true if self.new?
    @_rev == return_latest_revision
  end
  
  def refresh_revision
    @_rev = return_latest_revision unless self.new?
  end
  
  ###
  ### ATTACHMENTS
  def attachments?
    self.respond_to? :_attachments
  end
  
  def attachments
    if self.instance_variable_defined? '@_attachments'.to_sym
      return @_attachments
    else
      return {}
    end
  end
  
  def attachment(identifier)
    identifier = identifier.to_s
    pacify_blank(identifier)
    pacify_blank(@_id)
    result = self.class.get('/'+@_id+'/'+identifier, :headers => {'Accept'=>'*/*'})
    
    (return result.body) if result.success?
    raise("Attachment doesn't exist (probably) code:"+result.code.to_s)
  end
  
  def add_attachment(identifier, file, options = {})
    identifier = identifier.to_s
    pacify_blank(identifier)
    pacify_blank(@_id)
    
    if file.is_a?(File) || file.is_a?(StringIO)
      file = file.read
    end
    
    # HTTParty (or something inside) calls bytesize on object
    raise(ArgumentError, "Cannot call 'bytesize' on object") if !(file.respond_to? :bytesize)
    
    mimetype = options[:mime]
    mimetype ||= 'text/plain'
    
    query = (self.new? ? {} : {:rev => @_rev})
    
    result = self.class.put('/'+@_id+'/'+identifier, :headers => {'Content-Type' => mimetype}, :query => query, :body => file)
    
    if result.success? && result.parsed_response['ok']==true
      # replenish revision
      instance_variable_set :@_rev, result.parsed_response['rev']
      # not sure, how populate attachments better...
      # there are properties like length and digest, which are calculated by server
      # not updating whole document
      new_doc = self.class.get('/'+@_id, :query => {:rev=>@_rev})
      if new_doc.success?
        remove_field(:_attachments) if self.respond_to?(:_attachments)
        add_field(:_attachments, new_doc.parsed_response['_attachments'])
      else
        # has to be very busy day
        raise("This revision doesn't exists in database. Document is old and you should reload it completely.")
      end
      return true
    end
    raise("Error when saving attachment")
  end
  
  def delete_attachment(identifier)
    identifier = identifier.to_s
    pacify_blank(identifier)
    pacify_blank(@_id)
    
    query = (self.new? ? {} : {:rev => @_rev})
    result = self.class.delete('/'+@_id+'/'+identifier, :query => query)
    
    if result.success? && result.parsed_response['ok']==true
      instance_variable_set :@_rev, result.parsed_response['rev']
      
      @_attachments.delete(identifier)
      return true
    end
    raise("Error removing attachment")
  end
  
  ##############
  def pacify_blank(what)
    raise(ArgumentError, 'String cannot be blank') if what.blank?
    true
  end
end

