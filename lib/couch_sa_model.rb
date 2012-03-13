  require 'multi_json'
  MultiJson.engine = :yajl
  #require 'validations.rb'

  class CouchSaModel
    # expand_path because of rspec!
    #require File.expand_path("../couch_sa_model/validations.rb", __FILE__)
    #require_relative("couch_sa_model/validations.rb")
    #extend CouchSaModel::Validations
  
  end
