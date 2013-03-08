# Taken from Tire::Results::Item
# but modified
require 'active_model'
require 'securerandom'

module Divan
    class Document
      extend  ActiveModel::Naming
      include ActiveModel::Conversion

			require_relative './document/couchdb.rb'
			include CouchDB

      # Create new instance, recursively converting all Hashes to Item
      # and leaving everything else alone.
      #
      def initialize(args={})
        raise ArgumentError, "Please pass a Hash-like object" unless args.respond_to?(:each_pair)
        @attributes = {}
        args.each_pair do |key, value|
          if value.is_a?(Array)
            @attributes[key.to_sym] = value.map { |item| @attributes[key.to_sym] = item.is_a?(Hash) ? Document.new(item.to_hash) : item }
          else
            @attributes[key.to_sym] = value.is_a?(Hash) ? Document.new(value.to_hash) : value
          end
        end

				# Assigning ID here is important to prevent
				# CouchDB to assign different UUIDs
				# in case of more same requests
				if @attributes[:_id]
					@attributes[:_id] = SecureRandom.uuid
				end

				if self.type.nil? && self.class.name != 'Divan::Document'
					@attributes[:type] = self.class.name
				end
      end

      # Delegate method to a key in underlying hash, if present, otherwise return +nil+.
      #
      def method_missing(method_name, *arguments)
				# write attribute
				if method_name.to_s[-1] == '=' && arguments.size == 1
					attribute = method_name.to_s.chop
					value = arguments.first
					@attributes[attribute.to_sym] = value.is_a?(Hash) ? Document.new(value) : value
				end
        @attributes[method_name.to_sym]
      end

      def respond_to?(method_name, include_private = false)
				# answering to any write method
				if method_name.to_s[-1] == '='
					return true
				end
        @attributes.has_key?(method_name.to_sym) || super
      end

      def [](key)
        @attributes[key.to_sym]
      end

      def id
        @attributes[:_id]
      end

      def type
        @attributes[:type]
      end

      def persisted?
        !!id
      end

      def errors
        ActiveModel::Errors.new(self)
      end

      def valid?
        true
      end

      def to_key
        persisted? ? [id] : nil
      end

      def to_hash
        @attributes.reduce({}) do |sum, item|
          sum[ item.first ] = item.last.respond_to?(:to_hash) ? item.last.to_hash : item.last
          sum
        end
      end

			alias_method :to_h, :to_hash

      def as_json(options=nil)
        hash = to_hash
        hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access.as_json(options) : hash.as_json(options)
      end

      def to_json(options=nil)
        as_json.to_json(options)
      end
      alias_method :to_indexed_json, :to_json

      # Let's pretend we're someone else in Rails
      #
      def class
        defined?(::Rails) && @attributes[:type] ? @attributes[:type].camelize.constantize : super
      rescue NameError
        super
      end

      def inspect
        s = []; @attributes.each { |k,v| s << "#{k}: #{v.inspect}" }
        %Q|<Item#{self.class.to_s == 'Tire::Results::Item' ? '' : " (#{self.class})"} #{s.join(', ')}>|
      end
    end
end
