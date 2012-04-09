# -*- encoding : utf-8 -*-

require_relative './common.rb'

class Divan::Document
  include ::Divan::Common
  attr_accessor :database, :type, :doc, :messages

##steal
=begin
          # defines the getter for the property (and optional aliases)
          def create_property_getter(property)
            define_method(property.name) do
              read_attribute(property.name)
            end

            if ['boolean', TrueClass.to_s.downcase].include?(property.type.to_s.downcase)
              define_method("#{property.name}?") do
                value = read_attribute(property.name)
                !(value.nil? || value == false)
              end
            end

            if property.alias
              alias_method(property.alias, property.name.to_sym)
            end
          end

          # defines the setter for the property (and optional aliases)
          def create_property_setter(property)
            name = property.name

            define_method("#{name}=") do |value|
              write_attribute(name, value)
            end

            if property.alias
              alias_method "#{property.alias}=", "#{name}="
            end
          end
=end
  def design
    self.class.to_s.downcase
  end

  def initialize(options = {})
    # set type
    @type = self.class.to_s.downcase
    @database = Divan::Configuration.dbstring
    @doc = options['doc'] || {}
    # errors, notices, ...
    @messages = options['messages'] || []
    # debug
    @metadata = options['metadata'] || {}
  end

  def save
  ## todo!
    begin
      response = @database.save_doc(@doc)
    rescue => e
      puts e.response
      @messages += e.response + " (databáza/resource neexistuje)"
    end
  end
  
  def new?
    @doc.include?(:_rev)
  end
  
  # Document class, will have save available
  def self.dget(database, id)
    doc = rawget(database+id)
    Document.new('doc' => doc['result'], 'metadata' => doc.headers, 'messages' => doc['errors'])
  end
  
  #hash todo class method
  def dgetraw(id)
    @doc = rawget(@database+id)['doc']
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
  
  def self.rawget(query, params = {})
    begin
      result =  RestClient.get(query, {:params => params}, :accept => 'application/json')
      {'result' => result.jsondecode, 'headers' => result.headers}
    rescue RestClient::ResourceNotFound => e 
      puts "bla not found"
      {'errors' => e.response.jsondecode, 'headers' => result.headers}
    rescue RestClient::Forbidden => e
      puts "bla forbidden"
      {'errors' => e.response.jsondecode, 'headers' => result.headers}
    rescue RestClient::Conflict => e
      puts "bla conflict"
      {'errors' => e.response.jsondecode, 'headers' => result.headers}
    end
  end
  # design doc (via @type), view, optional - key/startkey+endkey, descending (true), group (true), include_docs (true)
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
  
end 
