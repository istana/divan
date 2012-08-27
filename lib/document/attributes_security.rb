

module Divan::Document::AttributesSecurity
  def attr_protected?(attribute, options = {})
    # design document is defined
    if design?
      group = options[:as] || 'default'
      fprot = design.class_variable_get :@@protected_fields
      faccess = design.class_variable_get :@@accessible_fields 
      
      # group even doesn't exist
      # do not modify original variables
      if !fprot.has_key? group
        fprot = Marshal.load(Marshal.dump(fprot))
        fprot[group] = []
      end
      
      if !faccess.has_key? group
        faccess = Marshal.load(Marshal.dump(faccess))
        faccess[group] = []
      end
      
      accessible_fields = faccess[group]
      protected_fields = fprot[group]
      # rails style
      # both empty, unprotected
      if protected_fields.empty? && accessible_fields.empty?
        return false
      # only accessible fields defined, others are protected
      elsif protected_fields.empty? && !accessible_fields.empty?
        # protected if not in accessible fields
        return (accessible_fields.include?(attribute) ? false : true)
      # only protected fields defined, others are accessible
      elsif !protected_fields.empty? && accessible_fields.empty?
        return (protected_fields.include?(attribute) ? true : false)
      else
        # say, if both - protected wins
        return true if protected_fields.include?(attribute)
        return false if accessible_fields.include?(attribute)
        
        # otherwise is accessible
        return false
      end
    else
      # if no design document defined, accessible it is
      false
    end
  end
  
  def assign_attributes(fields = {}, options = {})
    noprotection = options[:without_protection]
    
    fields.each do |key, value|
      if noprotection || !attr_protected?(key, :as => options[:as])
        @doc[key] = value
      end
    end
  end
end 
