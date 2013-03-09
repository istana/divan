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
	
	def byId(id, options = {})
		pacify_blank(id)
		defaults = {deleted: true, conflicts: true}
		if options.has_key?(:all)
			options.delete(:all)
			defaults.merge(revs: true, revs_info: true, deleted_conflicts: true, local_seq: true)
		end

		doc = ::Typhoeus.get(@dburi + uri_encode(id), params: options.merge(defaults))
		if doc.success?
			body = ::MultiJson.load(doc.body)
			type = body['type']
			if !type.nil? && !const_defined?(type)
				const_get(type).new(body)
			else
				::Divan::Document.new(body)
			end
		else
			raise("Document retrieval error, code: ", doc.code.to_s)
		end
	end
end

