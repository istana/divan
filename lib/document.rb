require 'active_support/core_ext/string/inflections'
require 'securerandom'
require 'dotted_hash'

module Divan
    class Document < ::DottedHash
    	include ::Divan::Support::Helpers
    	
    	def full_url
				@database.uri('reader')
			end
			
			require_relative './document/couchdb.rb'
			include CouchDB
      
			def initialize(object)
				super(object)
				self.type ||= self.class.to_s.underscore
				self._id ||= SecureRandom.uuid
				@database = Divan::Configuration.new
      end
      
      def id
      	@attributes[:_id]
      end

      def persisted?
        !!_rev
      end
      
      def new?
      	!persisted?
      end

      def valid?
				# TODO
        true
      end

      def to_key
        persisted? ? [id] : nil
      end
      
    end
end
