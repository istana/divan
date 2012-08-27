

module Divan::Design::Associations
  # ONE TO MANY
  # separate documents
  # TODO: embedded documents - sorting problems
  # embedded: sort must be done before save
  @@associations_has_many = []
  @@associations_views_ass = {}
  
  def self.extended(base)
    p "Divan::Design::Associations extended in #{base}"
    base.class_eval {
      # class variables fun
      @@has_many = @@associations_has_many
      @@views = @@associations_views_ass
    }
  end
  
  def has_many(what, options = {})
    what = what.to_s  
    
    # key format - [group0, group1, ..., doc.foreign_key, has_many.length+1, sort0, sort1, ...]
    couch_key = []; params_options = {}
    
    # grouping
    if options[:group].is_a? String
      couch_key << options[:group]
      params_options[:group_level] = 1
    elsif options[:group].is_a? Array
      couch_key = options[:group]
      params_options[:group_level] = options[:group].length
    end
    
    # foreign_key
    couch_key << (options.has_key?(:foreign_key) ? options[:foreign_key] : what+'_id')
    
    # index | 0 - parent; 1,2, ... - associations
    couch_key << (@@has_many.length+1)
    
    couch_key << options[:sort] if options[:sort].is_a? String
    couch_key + options[:sort] if options[:sort].is_a? Array
    ###
    # there may be more variants of sorting, grouping on one attibute
    name = options[:name] || what
    @@has_many << {:name => name, :couch_key => couch_key, :params => params_options}
    # regenerate views
    generate_has_many_view
  end
  
  def generate_has_many_view
    map =
      "function(doc) {
        if(doc.type == '#{self.document}') {
          emit(doc._id, null);
        }"
        
    @@has_many.each do |association|
      #association_model = ActiveSupport::Inflector.singularize(ass[:attr])
      association_model = association[:name].singularize.camelize
      map +=
        " else if(doc.type == '#{association_model}')
            emit(" + association[:couch_key].to_s + ", null);
        }"
    end
    map += "\n}"
    
    puts 'rujgioesrjgoesjgixx: ' + @@views.inspect
    
    @@views[:divan_association] = {:map => map}
    puts 'rujgioesrjgoesjgixx: ' + @@views.inspect
    #, :reduce => reduce}
  end
end
