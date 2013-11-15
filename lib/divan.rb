require 'multi_json'
require 'securerandom'
require 'typhoeus'

require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
MultiJson.engine = :oj

module Divan
	require_relative './support/helpers.rb'
	require_relative './configuration.rb'
	require_relative './database.rb'
	require_relative './query/design.rb'
	require_relative './query/view.rb'
#	require_relative './common.rb'
#	require_relative './design.rb'
	require_relative './document.rb'
	
#	def byId(*args)
#		Document.byId(args)
#	end
end

class Typhoeus::Response
	def from_json
		MultiJson.load(self.body)
	end
end
