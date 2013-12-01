require_relative "./divan/version.rb"

require 'multi_json'
require 'securerandom'
require 'typhoeus'

require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
MultiJson.engine = :oj

module Divan
	require_relative './divan/helpers.rb'
	require_relative './divan/configuration.rb'
	require_relative './divan/database.rb'
	require_relative './divan/query/design.rb'
	require_relative './divan/query/view.rb'
	require_relative './divan/document.rb'
end

# monkey patch for now
class Typhoeus::Response
	def from_json
		MultiJson.load(self.body)
	end
end
