# -*- encoding : utf-8 -*-

require_relative './common.rb'

require 'httparty'
class Document
  include HTTParty
  
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  
  ### require './divan.rb'; a=Document.fetch "919156c7f24bb77528e409eb0a7c25a9"
  ### a=HTTParty.get "http://localhost:5984/ionorchis_development/919156c7f24bb77528e409eb0a7c25a9"
  
  # set parsing to JSON (uses multi_json)
  # best choice is to choose yajl as JSON parser
  # because is written in C and is fast
  # TODO make benchmarks
  format :json
  #base_uri Divan::Configuration.dbstring
  # better beahaviour with no trailing /
  base_uri 'http://localhost:5984/ionorchis_development'
            #Divan::Configuration.dbstring
            
  
  
  
  
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
  # this adds some overhead TODO only in size of JSON or also compute power?
  # if false or empty, it isn't present in document
  default_params :deleted => true, :attachments => true, :conflicts => true
  
  # new record, which is not in database
  # random unique ID is assigned, if not given
  # can also call Divan::Document.new with hash
  # which contains type and id
  def vanilla(type, fields = {})
    if !fields.has_key?('_id')
      fields['_id'] = SecureRandom.uuid
    end
    fields['type'] = type
    self.new(fields)
  end
  
  def initialize(doc)
    @mapped_fields = []
    
    # hash with fields, to be able to return loaded document
     @original_doc = (doc.respond_to?(:parsed_response) ? doc.parsed_response : doc)
    
    # HTTParty object
    # to access request, status code and like that
    @last_request = @original_doc
    
    # confl because conflict could exist as field of document
    @confl = false
    populate
  end
  
  class << self
    # want to call them from outside in save
    #protected :get, :post, :put, :delete, :head
  end
  
  # HTTParty object
  # can call request, code, response, parsed_response, headers, message (like OK or Object not found)
  # or success?, forbidden? (see HTTParty documentation (or better specs))
  def lrq
    @last_request
  end

  
  def reloaded
    if new?
      return self.class.new(@original_doc)
    else
      return self.class.fetch(@original_doc['_id'])
    end
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

  
  def save
    doc = self.document
    doc.delete('_id')
    @last_request = self.class.put('/'+@_id, :body => doc)
    
    if @last_request.conflict?
      @confl = true
      raise("Conflict", "Document conflict!")
    end
    
    if result.success? && result.body['ok']==true
      instance_variable_set rev.body['_rev']
    else
      return false
    end
  end

  
  def populate
    @original_doc.each do |key, value|
      add_field(key, value)
    end
  end


  # TODO attr_protected
  def add_field(f, val)
    f = f.to_s
    unless f.empty? || instance_variable_defined?("@#{f}")
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
    else
      raise("ArgumentError", "field name cannot be nil or this field exists already")
    end
    @mapped_fields << f.to_s
  end
  
  def remove_field(f)
    f = f.to_s
    unless f.empty?
      #class << self
        remove_method "#{f}=".to_sym
        remove_method f.to_sym
      #end
      remove_instance_variable "@#{f}".to_sym
    end
  end
  

  # options - see special fields in default_params
  # another options is :all => whatever, which fetches all (available) special fields
  def self.fetch(id, options = {})
    if options.has_key? :all
      options = {:revs => true, :revs_info => true, :deleted_conflicts => true, :local_seq => true}
    end
    
    d = self.class.get('/'+id, :query => options)
    if d.success?
      Document.new(d)
    else
      raise("DivanDocumentRetrievalError", "Document could not be fetched from CouchDB")
    end
  end
  
  
  def document
    doc = {}
    @mapped_fields.each do |field|
      # to have more levels of hash correct
      #doc = doc.merge({field => self.send(field.to_sym)})
      doc[field] = self.send field.to_sym
    end
    doc
  end
  
  def design
    self.class.to_s
  end
  
  def attachment_put
  
  end
  
  def attachment_delete
  
  end
end

