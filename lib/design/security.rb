

module Divan::Design::Security
  @@protected_fields = {}
  @@accessible_fields = {}
  
  def attr_accessible(*args)
    if args.last.is_a? Hash
      *fields, options = args
    else
      options = {}
      fields = args
    end
    as = options[:as] || 'default'
    @@accessible_fields[as] += args
  end
  
  def attr_protected(*args)
    if args.last.is_a? Hash
      *fields, options = args
    else
      options = {}
      fields = args
    end
    as = options[:as] || 'default'
    @@protected_fields[as] += args
  end
  
  # TODO:
  #@@max_fields = 50
  #@@max_attachments = 30
  # 10MB
  #@@attachment_limit = 10485760
  #@@doc_json_max_length = 65536
end
