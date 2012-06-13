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
  #default_params :output => 'json'
  
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

  
  def save
    result = self.class.put('/'+id, :body => self.to_s)
    
    if result.conflict?
      @confl = true
      return false
    end
    
    if result.success? && result.body['ok']==true
      instance_variable_set rev.body['rev']
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
      alias_method "alias_#{f}", f if self.respond_to? f.to_sym
      # accessor
      self.define_singleton_method f do
        instance_variable_get "@#{f}".to_sym
      end
      # writer
      self.define_singleton_method "#{f}=".to_sym do |param1|
        instance_variable_set "@#{f}".to_sym, param1
      end
    else
      #raise("ArgumentError", "field name cannot be nil or this field exists already")
    end
    @mapped_fields << f.to_s
  end
=begin  
  def remove_field(f)
    f = f.to_s
    unless f.empty?
      #class << self
        remove_method "#{f}=".to_sym
        remove_method f.to_sym
      #end
      remove_instance_variable "@#{f}".to_sym
      
      if self.respond_to? "alias_#{f}".to_sym
        alias_method f, "alias_#{f}"
        remove_method "alias_#{f}".to_sym
      end
    end
  end
=end

  
  def self.fetch(id, options = {})
    #TODO specialized fields
    d = self.get('/'+id)
    if d.success?
      Document.new(d)
    else
      raise("DivanDocumentRetrievalError", "Document could not be fetched from CouchDB")
    end
  end

  def to_s
    doc = {}
    @mapped_fields.each do |field|
      # to have more levels of hash correct
      #doc = doc.merge({field => self.send(field.to_sym)})
      doc[field] = self.send field.to_sym
    end
    doc
  end
end









=begin
class Divan::Document
  include ::Divan::Common
  attr_accessor :database, :type, :doc, :messages

  def design
    self.class.to_s
  end
  
  #hash todo class method
  def dgetraw(id)
    @doc = rawget(@database+id)
  end

  # todo class method, todo _all_docs, todo 404 error
  # probably array of Documents, design doc name is calculated
  def dsget(view, options={})
    resultraw = rawget(@database+'_/design/'+design+'/_view/'+view)
    result = resultraw['result']['rows']
    docs = []
    result['rows'].each do |doc|
      docs << Document.new('doc' => result['rows'])
    end
    
    metadata = resultraw['result']
    metadata.delete('rows')
    metadata.merge(resultraw['headers'])
    
    docs.define_singleton_method :metadata, lambda { metadata }
    docs 
  end
  
  # only hash
  def dsgetraw(view, options={})
    resultraw = rawget(@database+'_/design/'+design+'/_view/'+view)
    docs = resultraw['result']['rows']
    
    metadata = resultraw['result']
    metadata.delete('rows')
    metadata.merge(resultraw['headers'])
    
    docs.define_singleton_method :metadata, lambda { metadata }
    docs
  end
  
  # design doc (via @type), view, optional - key/startkey+endkey, descending (true), group (true), include_docs (true)
=end
=begin
  def dget(view, options = {})
key
keys
startkey
startkey_docid
endkey
endkey_docid
limit
stale
descending
skip
group
group_level
reduce
include_docs
inclusive_end
update_seq 
    
  end
=end 
