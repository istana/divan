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
    def gen_validation(conditions, allow_null, validation, msg)
      val = ""
      msgerr = "errors.push(#{msg})"
      
      val = "if(!(" + validation + ")) { " + msgerr + " }"
      # wrap allow_null TODO
      (val = "if(#{allow_null} && (doc.#{attr} == null)) {" + val + "}") unless allow_null.nil? || allow_null.empty?
      # spidermonkey has lazy eval of logic operators
      (val = "if(" + conditions.join(" && ") + ") { #{msgerr} }") unless conditions.size == 0

      val
    end
    
    ###
    ## asi netreba, staci to v gen_validation, bude tam jedna podmienka niekedy navyse, no
    def cond_allow_null(attr, options)
      if options.has_key?(:allow_null)
        if options[:allow_null] || = true
        if options[:allow_null]==true
        #conditions << "(doc.#{attr} != null) || (doc.#{attr} == null)"
        # nothing - null || notnull is always true, neg (when error occurs): null && notnull is always false
        ""
        else
        "(doc.#{attr} == null)"
        end
      else
        ""
      end
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
  
