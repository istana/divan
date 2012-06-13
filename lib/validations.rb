# javascript validations for design document
# logic is bit hard to understand
module Divan::Validations
  def validates_acceptance_of(attr, options = {})
    conditions ||= []
    add_conditions(conditions, options)
    
    allow_null = options[:allow_null]
    accept = options[:accept]    
    accept ||= true
    message = options[:message]
    message ||= "TODO Attribute #{attr} must be set to true"
    
    # acceptance_of
    validation =  "doc.#{attr} === #{accept}"
    gen_validation(conditions, validation, attr, message, allow_null)
  end

  def validates_exclusion_of(attr, options ={})
    conditions ||= []
    add_conditions(conditions, options)
    
    allow_null = options[:allow_null]
    allow_blank = options[:allow_blank]
    message = options[:message]
    message ||= "TODO Attribute #{attr} is reserved"

    
    
    # Array, Range and Hash supported, Enumerable
    # javascript doesn't have Range and Hash
    # TODO range can be emulated in javascript easily,
    # how to define own functions in couch outside?
    # range, hash and enumerable....convert to array
    
    enum = options[:in]
    array = [];
    enum.each_with_index do |val, index|
      array << val
    end
    jsarray = array.to_s 
    
    validation = '#{jsarray}.indexOf(#{attr})==-1'
    gen_validation(conditions, validation, attr, message, allow_null, allow_blank)
  end
  
  def validates_inclusion_of(attr, options = {})
    conditions ||= []
    add_conditions(conditions, options)
    
    allow_null = options[:allow_null]
    allow_blank = options[:allow_blank]
    message = options[:message]
    message ||= "TODO Value #{attr} is not included in the list."

    enum = options[:in]
    array = [];
    enum.each_with_index do |val, index|
      array << val
    end
    jsarray = array.to_s 
    
    validation = '#{jsarray}.indexOf(#{attr})!=-1'
    gen_validation(conditions, validation, attr, message, allow_null, allow_blank)
  end
  
  def validates_presence_of(attr, options = {})
    conditions ||= []
    add_conditions(conditions, options)
    
    allow_null = options[:allow_null]
    allow_blank = options[:allow_blank]
    message = options[:message]
    message ||= "TODO Attribute #{attr} can't be blank"
    validation = '#{attr} != null && #{attr} != false && #{attr}.length != 0 && /[\s| ]+/.test(#{attr})'
  end

   ### low level functions
    # if :on && :if && :unless - if all (defined) true, proceed validation
    #    if allow_nil==false - do not skip validation
    #      if !validation
    #           error
    # allow_null == true ---> null || notnull is always true, neg (when error occurs): null && notnull is always false
    # need to check when allow_null == false
    
    def gen_validation(validation, attr, msg, conditions=[], allow_null=false, allow_blank=false)
      allow_null = false if allow_null.nil?
      allow_blank = false if allow_null.nil?
      
      val = ""
      msgerr = "errors.push(\"#{msg}\")"
      # validation
      val = "if(!(" + validation + ")) { " + msgerr + " }"
      # allow_null #{allow_null} && (doc.#{attr} == null) if allow_null is true, no need to be there
      # so basically if allow null is true and attr isn't null, validate, otherwise skip...this will be hard to remember
      (val = "if(doc.#{attr} != null) {" + val + "}") if allow_null==true
      # spidermonkey has lazy eval of logic operators
      (val = "if(" + conditions.join(" && ") + ") { #{val} }") unless conditions.size == 0
      val
    end
    

    # if, unless and on conditions are together  
    def add_conditions(conditions, options)
      if options.has_key?(:if)
        conditions << "(#{options[:if]})"
      end
      
      if options.has_key?(:unless)
        conditions << "(!(#{options[:unless]}))"
      end
      
      if options.has_key?(:on)
        if options[:on] == "create"
          conditions << "(oldDoc == null)"
        elsif options[:on] == "update"
          conditions << "(oldDoc != null)"
        end
      end
    end
    
    def jsblank(attr)
      '#{attr} != null && #{attr} != false && #{attr}.length != 0 && /[^\s ]+/.test(#{attr})'
    end
  
end  
  
