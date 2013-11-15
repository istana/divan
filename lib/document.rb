
require 'active_model'
require 'securerandom'
require 'dotted_hash'

module Divan
    class Document < ::DottedHash
    	def database
    		Divan::Support::Configuration.uri
    	end

			require_relative './document/couchdb.rb'
			include CouchDB
      
			def initialize(object)
				super(object)
      end

      def persisted?
        !!_rev
      end

      def valid?
				# TODO
        true
      end

      def to_key
        persisted? ? [id] : nil
      end
      
      def self.byId(id, options = {})
		pacify_blank(id)
		defaults = {deleted: true, conflicts: true}
		if options.has_key?(:all)
			options.delete(:all)
			defaults.merge(revs: true, revs_info: true, deleted_conflicts: true, local_seq: true)
		end

		doc = ::Typhoeus.get(database + uri_encode(id), params: options.merge(defaults))
		if doc.success?
			body = doc.parsed_response
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
end
