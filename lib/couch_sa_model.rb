  require 'multi_json'
  MultiJson.engine = :yajl
  #require 'validations.rb'

  class CouchSaModel
    # expand_path because of rspec!
    require File.expand_path("../validations.rb", __FILE__)
    extend CouchSaModel::Validations
  
  end
