module CouchSaModel::Validations
  def validates_acceptance_of(attr, options = {})
    conditions ||= []
    
    message = "TODO Attribute #{attr} must be set to true"
    message ||= options[:message]
    
    accept = "true"
    accept ||= options[:accept]
    
#    js = "if(#{attr} !== #{accept})
#    {
#      errors.push(#{message})
#    }"

    allow_nil = cond_allow_nil(attr, options)
    
    cond_on(conditions, options)
    cond_if(conditions, options)
    conf_unless(conditions, options)
    
    # acceptance
    conditions << "(doc.#{attr} !== #{accept})"
    
    gen_validation(conditions, allow_nil, message)
  end
  
  private
    def gen_validation(conditions, msg)
      val = ""
      conditions.each do |cond|
        val += "!(" + cond + ")"
      end unless conditions.size == 0
    end
    
    def cond_allow_nil(attr, options)
      if options.has_key?(:allow_nil) && options[:allow_nil]==true
        #js = "if(#{attr} != null) {" + js + "}"
        conditions << "(doc.#{attr} != null) || (doc.#{attr} == null)"
      end
    end
    
    # if unless and on conditions are together
    def cond_if(conditions, options)
      if options.has_key?(:if)
        #js = "if(#{options[:if]}) {" + js + "}"
        conditions << "(#{options[:if]})"
      end
    end
    
    def cond_unless(conditions, options)
      if options.has_key?(:unless)
        #js = "if(!(#{options[:unless]})) {" + js + "}"
        conditions << "(!(#{options[:unless]}))"
      end
    end
    
    def cond_on(conditions, options)
      if options.has_key?(:on)
        if options[:on] == "create"
          conditions << "(oldDoc == null)"
        elsif options[:on] == "update"
          #js = "if(oldDoc != null) {" + js + }
          conditions << "(oldDoc != null)"
        end
      end
    end
  
end  
  
