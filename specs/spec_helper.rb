require "rspec"
#require "ruby-debug19"

ENV['RACK_ENV'] = 'test'
require_relative "../lib/divan.rb"
dbfile = File.join(File.dirname(__FILE__), "couchdb.yaml")
::Divan::Support::Configuration.load_config(dbfile)

