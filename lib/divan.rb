  require 'multi_json'
  require 'securerandom'
  require 'httparty'
  
  require 'active_support/inflector'
  MultiJson.engine = :yajl

  module Divan
    # expand_path because of rspec!
    #require File.expand_path("../couch_sa_model/validations.rb", __FILE__)
    #require_relative("couch_sa_model/validations.rb")
    #extend CouchSaModel::Validations
    
    require_relative './configuration.rb'
    require_relative './common.rb'
    require_relative './design.rb'
    require_relative './document.rb'
    #require_relative './validations.rb'
  end
