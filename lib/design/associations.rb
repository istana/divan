

module Divan::Design::Associations
  # ONE TO MANY
  # separate documents
  # TODO: embedded documents - sorting problems
  # embedded: sort must be done before save
  
  def inherited(subclass)
    super
    subclass.instance_variable_set :@has_many, []
    subclass.instance_variable_set :@many_to_many, []
  end
  
  # adds quadruplet to @has_many with association details
  def has_many(ofwhat, options = {})
    ofwhat = ofwhat.to_s  
    puts "has_many"+@has_many.inspect
    
    # identifier of association
    # is possible have more has_many :apples with different sorting, ...
    name = options[:name] || ofwhat
    
    # child type
    # used when create new child
    type = ofwhat
    
    ### KEY ASSEMBLING
    # key format - [doc.foreign_key, has_many.length+1, sort0/group0, sort1/group1, ...]
    couch_key = [];
    
    # foreign_key of parent
    foreign_key = (options.has_key?(:foreign_key) ? options[:foreign_key] : self.document.camelize+'_id')
    couch_key << foreign_key 
    
    # index of association | 0 - parent; 1,2, ...
    number = @has_many.length+1
    couch_key << number
    
    # when multiple sort values, it can still be sort only in ascending or descending order
    # I mean no mixed sorting
    couch_key << options[:sort] if options[:sort_by].is_a? String
    couch_key + options[:sort] if options[:sort_by].is_a? Array
    ###
    
    @has_many << {:name => name, :type => type.singularize.camelize, :couch_key => couch_key,
    :place => number, :foreign_key => foreign_key}
    # regenerate views
    generate_has_many_views
  end
  
  # generate views from associations variables
  def generate_has_many_views
    # emit parent document
    map =
      "function(doc) {
        if(doc.type == '#{self.document}') {
          emit([doc._id, 0], null);
        }"
        
    @has_many.each do |association|
      map +=
        "else if(doc.type == " + association[:type] +")
            emit(" + association[:couch_key].to_s + ", null);
        }"
    end
    map += "\n}"
    
    @views[:has_many_associations] = {:map => map}
  end
end
