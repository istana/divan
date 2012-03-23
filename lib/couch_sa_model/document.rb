# -*- encoding : utf-8 -*-
require "couchrest"
class Document
  attr_accessor :database, :type, :doc, :errors

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
  def initialize
    # set type
    @type = self.class.to_s.downcase
    @database = CouchRest.database(load_config_database)
    @doc = {}
    @errors = []
  end

  def save
    begin
      response = @database.save_doc(@doc)
    rescue => e
      puts e.response
      @errors += e.response + " (databáza/resource neexistuje)"
    end
  end
  
  def new?
    @doc.include?(:_rev)
  end
  
  # design doc (via @type), view, optional - key/startkey+endkey, descending (true), group (true), include_docs (true)  
  def dget(view)
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
  
  
end 
