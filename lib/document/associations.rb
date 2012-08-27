

module Divan::Document::Associations
  def associations
    has_many_list + many_to_many_list
  end
  
  def populate_associations
    association.to_s
    if associations.include? association
      default_params = design.class_variable_get(:has_many)[association.to_sym][:params]
      ::Divan::View.fetch(self.type, association, default_params.merge(options))
    else
      []
    end
    associations.each do |association|
      self.define_singleton_method :association do
        
      end
    end
  end
  
  def has_many_list
    if design.class_variable_defined?(:has_many)
      hasm = []
      design.class_variable_get(:has_many).each do |ass|
        hasm << ass[:attr]
      end
      hasm
    else
      []
    end
  end
  
  def many_to_many_list
    # TODO:
    []
  end
end
