# javascript validations for design document
module CouchSaModel::Validations
  def validates_acceptance_of(attr, options = {})
    conditions ||= []
    
    message = options[:message]
    message ||= "TODO Attribute #{attr} must be set to true"
    accept = options[:accept]    
    accept ||= true
    allow_null = options[:allow_null]
    allow_null ||= false
    
    cond_on(conditions, options)
    cond_if(conditions, options)
    cond_unless(conditions, options)
    # acceptance_of
    validation =  "doc.#{attr} === #{accept}"
    
    gen_validation(conditions, validation, attr, message, allow_null)
  end

  def validates_exclusion_of(attr, options ={})
    conditions ||= []
    
    message = options[:message]
    message ||= "TODO Attribute #{attr} is reserved"
    allow_blank = options[:allow_blank]    
    allow_blank ||= false
    allow_null = options[:allow_null]
    allow_null ||= false
    
    enumin = options[:in]
    
    # Array, Range and Hash supported, Enumerable
    # javascript doesn't have Range and Hash
    
    bla = "["
    enuminl = enumin.length
    enumin.each_with_index do |val, index|
      bla << "val"
      if index != (enuminl-1)
        bla << ", "
      end
    end
    bla 
    
    myarray.indexOf(value)
    
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
      msgerr = "errors.push(\"#{msg}\")"
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
  
