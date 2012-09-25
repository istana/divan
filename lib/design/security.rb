

module Divan::Design::Security
  def self.extended(base)
    # this sets variables in Divan::Design
    base.instance_variable_set :@protected_fields, {}
    base.instance_variable_set :@accessible_fields, {}
    
    # this sets variables when some class inherit from Divan::Design
    def base.inherited(subclass)
      super
      subclass.instance_variable_set :@protected_fields, {}
      subclass.instance_variable_set :@accessible_fields, {}
    end
  end
  
  # NOTE
  # These methods are executed in context of class, where it is extended
  # so class level instance variables need to exist in that class, not here in module
  def accessible_fields
    @accessible_fields
  end
  
  def protected_fields
    @protected_fields
  end
  
  def attr_accessible(*args)
    arguments = split_arguments(args)
    as = arguments[:options][:as] || 'default'
    @accessible_fields[as] = [] if @accessible_fields[as].nil?
    @accessible_fields[as] += arguments[:fields]
    @accessible_fields
  end
  
  def attr_protected(*args)
    arguments = split_arguments(args)
    as = arguments[:options][:as] || 'default'
    @protected_fields[as] = [] if @protected_fields[as].nil?
    @protected_fields[as] += arguments[:fields]
    @protected_fields
  end
    
  private
    
  def split_arguments(args)
    if args.last.is_a? Hash
      *fields, options = args
    else
      options = {}
      fields = args
    end
    return {:options => options, :fields => fields}
  end
  
  # TODO:
  #@@max_fields = 50
  #@@max_attachments = 30
  # 10MB
  #@@attachment_limit = 10485760
  #@@doc_json_max_length = 65536
end
