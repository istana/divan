#require "bundler/setup"
require "rubygems"
require "rspec"
#require "ruby-debug19"

ENV['RACK_ENV']='test'
require File.join(File.dirname(__FILE__), '..','lib','divan.rb')
Divan::Configuration.load_config(File.join(File.dirname(__FILE__), '..','lib','couchdb.yaml'))
# Replenish configuration for parts, that uses HTTParty
Divan::Document.base_uri Divan::Configuration.dbstring
Divan::DBAdmin.base_uri Divan::Configuration.dbstring('dbadmin')
#Divan::Design.base_uri Divan::Configuration.dbstring
#require File.join(File.dirname(__FILE__), '..','lib','design.rb')


#require File.join(File.dirname(__FILE__), '..','lib','validations.rb')
