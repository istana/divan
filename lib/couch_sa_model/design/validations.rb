# javascript validations for design document
module Validations
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

    allow_null = cond_allow_null(attr, options)
    
    cond_on(conditions, options)
    cond_if(conditions, options)
    conf_unless(conditions, options)
    
    # acceptance_of, 
    validation =  "doc.#{attr} === #{accept}"
    
    gen_validation(conditions, allow_null, validation, message)
  end




   ### low level functions
    # if :on && :if && :unless - if all (defined) true, proceed validation
    #    if allow_nil==false - do not skip validation
    #      if !validation
    #           error
    # allow_null == true ---> null || notnull is always true, neg (when error occurs): null && notnull is always false
    # need to check when allow_null == false
    
    def gen_validation(conditions, validation, attr, msg, allow_null = false)
      val = ""
      msgerr = "errors.push(#{msg})"
      # validation
      val = "if(!(" + validation + ")) { " + msgerr + " }"
      # allow_null #{allow_null} && (doc.#{attr} == null) if allow_null is true, no need to be there
      # so basically if allow null is true and attr isn't null, validate...this will be hard to remember
      (val = "if(doc.#{attr} != null) {" + val + "}") if allow_null==true
      # spidermonkey has lazy eval of logic operators
      (val = "if(" + conditions.join(" && ") + ") { #{val} }") unless conditions.size == 0
      val
    end
    

    # if unless and on conditions are together
    
    def cond_if(conditions, options)
      if options.has_key?(:if)
        conditions << "(#{options[:if]})"
      end
    end
    
    def cond_unless(conditions, options)
      if options.has_key?(:unless)
        conditions << "(!(#{options[:unless]}))"
      end
    end
    
    def cond_on(conditions, options)
      if options.has_key?(:on)
        if options[:on] == "create"
          conditions << "(oldDoc == null)"
        elsif options[:on] == "update"
          conditions << "(oldDoc != null)"
        end
      end
    end
  
end  
  
