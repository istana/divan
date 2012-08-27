# -*- encoding : utf-8 -*-

require_relative './common.rb'

require 'httparty'

class Divan::Document
  include HTTParty

  ['attachments.rb', 'dbcomm.rb', 'revisions.rb',
   'attributes_security.rb', 'associations.rb'
  ].each do |file|
    require_relative File.join('.', 'document', file)
  end
  include Attachments
  include Dbcomm
  include Revisions
  include AttributesSecurity
  include Associations
  include ::Divan::Support
  
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  format :json
  base_uri Divan::Configuration.dbstring
  
  # new record, which is not in database
  # or mapped document from view
  # random unique ID is assigned, if not given
  # can also call Divan::Document.new with hash
  # which contains type and id
  def self.neo(fields = {})
    if !fields.has_key?('_id') || fields['_id'].blank?
      fields['_id'] = SecureRandom.uuid
    end
    
    # automatically add type, if not set to stock class name
    if !fields.has_key?('type') && self.type != "Divan::Document"
      fields['type'] = self.type
    end
    self.new(fields)
  end
  
  # options - see special fields
  # another options is :all => whatever, which fetches all (available) special fields
  def self.fetch(id, options = {})
    params = {:deleted => true, :conflicts => true}
    if options.has_key? :all
      options = {:revs => true, :revs_info => true, :deleted_conflicts => true, :local_seq => true}
    end
    
    d = get('/' + Divan::Support.uri_encode(id), :query => options.merge(params))
    if d.success?
        type = d.parsed_response['type'] || 'Divan::Document'
        const_defined?(type) ? const_get(type).new(d, :without_protection => true) : Document.new(d, :without_protection => true)
    else
      raise("Document could not be fetched from CouchDB, status:"+d.code.to_s+"message:"+d.message)
    end
  end
  
  def initialize(doc, options = {})
    @doc = {}
    
    # HTTParty object
    # to access request, status code and like that
    @last_request = doc
    
    #populate_associations
    populate_fields(doc, options)
  end
  
  # HTTParty object
  # can call request, code, response, parsed_response, headers, message (like OK or Object not found)
  # or success?, forbidden? (see HTTParty specs)
  def lastreq
    @last_request
  end

  def new?
    not @doc.key?('_rev')
  end
  
  def deleted?
     @doc.key? '_deleted' && @doc['_deleted'] == true
  end
    
  ###
  def populate_fields(doc, options = {})
    # this is for documents fetched from database
    if options[:without_protection] == true
      @doc = doc
    else
      # protection against mass assignment
      # like in rails use assign_attributes for using other roles
      doc.delete_if { |key, value| attr_protected?(key) }
      @doc = doc
    end
  end

  ######
  
  def fields
    @doc
  end
  
  def field(name)
    name = name.to_s
    pacify_blank(name)
    if @doc.has_key? name
      @doc[name]
    else
      raise('Field does not exist')
    end
  end
  
  alias_method '[]'.to_sym, :field
  
  def field=(name, value)
    pacify_blank(name)
    @doc[name] = value
  end
  
  alias_method '[]='.to_sym, 'field='.to_sym
  
  def length
    @doc.length
  end
  
  def delete(field)
    field = field.to_s
    pacify_blank(field)
    if @doc.has_key? field
      @doc.delete(field)
    else
      raise('Field does not exist')
    end
  end
  ######
  def self.type
    self.to_s
  end
  def type
    (@doc['type'] rescue nil) || self.class.type
  end
  
  def design_string
    if type == 'Divan::Document'
      x = 'Divan::Design'
    else
      x = type + "Design"
    end
    x
  end
  
  def design
    # NameError:
    # wrong constant name Divan::Design
    #self.class.const_get(design_string)
    ActiveSupport::Inflector.constantize(design_string)
  end
  
  def design?
    begin  
      design
    rescue Exception => e
      return false
    end
    true
  end
end

