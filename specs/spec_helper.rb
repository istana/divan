require "rspec"
#require "ruby-debug19"

ENV['RACK_ENV'] = 'test'
require_relative "../lib/divan.rb"
::Divan::Support::Configuration.load_config("./data/config/couchdb.yaml")

