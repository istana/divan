require 'multi_json'
require 'securerandom'
require 'typhoeus'

require 'active_support/inflector'
MultiJson.engine = :oj

module Divan
	require_relative './support/configuration.rb'
#	require_relative './common.rb'
#	require_relative './design.rb'
	require_relative './document.rb'
	
	def byId(*args)
		Document.byId(args)
	end
end

class Typhoeus::Response
	def parsed_response
		MultiJson.load(self.body)
	end
end
