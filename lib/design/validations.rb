# javascript validations for design document
# logic is bit hard to understand
module Divan::Design::Validations
  def validates_acceptance_of(attr, options = {})
    options.delete_if do |key, value|
      # validation condition cannot be changed
      !([:message, :allow_null, :accept, :if, :unless, :on].include?(key))
    end
    
    options = {
      :accept => true,
      :validation => "doc[#{attr}] === #{accept}"
    }.merge(options)
    options[:message] ||= "#{attr} must be set to "+options[:accept]+'.'
    
    generate_validation(options)
  end

  def validates_exclusion_of(attr, options ={})
    options.delete_if do |key, value|
      !([:message, :allow_null, :allow_blank, :in, :if, :unless, :on].include?(key))
    end
    
    raise(":in is mandatory") unless options.has_key?(:in)
    options[:in] = options[:in].to_s if options[:in].is_a?(Array)
    
    options = {
      :message => "#{attr} cannot be of this value (list).",
      :validation => options[:in]+".indexOf(doc[#{attr}])==-1"
    }.merge(options)
    
    generate_validation(options)
  end
  
  def validates_inclusion_of(attr, options = {})
    options.delete_if do |key, value|
      !([:message, :allow_null, :allow_blank, :in, :if, :unless, :on].include?(key))
    end
    
    raise(":in is mandatory") unless options.has_key?(:in)
    options[:in] = options[:in].to_s if options[:in].is_a?(Array)
    
    options = {
      :message => "#{attr} is not included in the list.",
      :validation => options[:in]+".indexOf(doc[#{attr}])!=-1"
    }.merge(options)
    
    generate_validation(options)
  end
  
  def validates_presence_of(attr, options = {})
    options.delete_if do |key, value|
      !([:message, :if, :unless, :on].include?(key))
    end
    
    options = {
      :message => "Attribute #{attr} can't be blank.",
      # TODO: repair regexp for something like [[::graph::]]
      :validation => "(doc[#{attr}] != null) && (doc[#{attr}] != false) && (doc[#{attr}].length != 0) && (/[\s| ]+/.test(doc[#{attr}]))"
    }.merge(options)
    
    generate_validation(options)
  end
  
  def validates_format_of(attr, options = {})
    options.delete_if do |key, value|
      !([:message, :allow_null, :allow_blank, :with, :without, :if, :unless, :on].include?(key))
    end
    
    raise(":with or :without is required") unless (options.has_key(:with) || options.has_key(:without))
     
    options = {
      :message => "#{attr} is invalid."
    }.merge(options)
    
    validations = []
    (validations << (options[:with] + ".test(doc[#{attr}])")) unless options[:with].nil?
    (validations << "!(" + options[:without] + ".test(doc[#{attr}])" + ")") unless options[:without].nil?
    options[:validation] = validations.join(" && ")
    
    generate_validation(options)
  end
  
   ### low level functions
    # if :on && :if && :unless - if all (defined) true, proceed validation
    #    if allow_nil==false - do not skip validation
    #      if !validation
    #           error
    # allow_null == true ---> null || notnull is always true, neg (when error occurs): null && notnull is always false
    # need to check when allow_null == false
    
    def generate_validation(options)
      conditions = run_conditions(options)
    
    end
    
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
    
    # conditions when validation is run
    # if, unless and on conditions are together  
    def run_conditions(options)
      conditions = []
      conditions << "(#{options[:if]})" if options.has_key?(:if)
      conditions << "(!(#{options[:unless]}))" if options.has_key?(:unless)
      conditions << "(oldDoc == null)" if options[:on] == "create"
      conditions << "(oldDoc != null)" if options[:on] == "update"
    end
end  
  
