# -*- encoding : utf-8 -*-

require_relative '../support/essential.rb'
require_relative '../support/helpers.rb'

module Divan::Document::CouchDB

	include ::Divan::Support::Helpers

	#  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'

	def new?
		_rev == nil
	end

	def deleted?
		_deleted == true
	end

	def design_string
		type.nil? ? 'Divan::Design' : self.class.name + "Design"
	end

	def design
		ActiveSupport::Inflector.constantize(design_string)
	end

	def design?
		begin  
			design
		rescue Exception 
			return false
		end
		true
	end

	# Revisions
	#
	def return_latest_revision
		return nil if self.new?
		pacify_blank(_id)

		req = Typhoeus.head(@dburi+uri_encode(_id))

		if req.success?
			return req.headers['ETag'].gsub('"', '')
		else
			# Document is no longer in database, or id was changed
			return nil
		end
	end

	def latest?
		return true if self.new?
		_rev == return_latest_revision
	end

	def refresh_revision
		self._rev = return_latest_revision unless self.new?
	end

	def save(options = {})
		# Assigning ID here is important to prevent
		# CouchDB to assign different UUIDs
		# in case of more same requests
		if !_id
			self._id = SecureRandom.uuid
		end

		doc = self.to_h
		id = doc.delete(:_id)
		pacify_blank(id)

		res = Typhoeus.put(@dburi + '/' + uri_encode(id),
									params: options,
									body: MultiJson.dump(doc)
								)

		body =  MultiJson.load(res.body)
		# Conflict
		if res.code == 409
			raise('Document conflict')
		elsif res.success? && body['ok'] == true
			self._rev = body['rev'] 
			return true
		else
			raise('Error saving document, code: ' + res.code.to_s)
		end
	end

	def destroy
		return self if self.new?
		raise("Revision is old!") unless self.latest?
		@last_request = self.class.delete('/' + uri_encode(@doc['_id']), :query => {:rev => @doc['_rev']})
		raise("Error destroying document!") unless @last_request.success?
		self
	end

	def attachments?
		!_attachments.nil?
	end

	def attachment(id)
		id = id.to_s
		pacify_blank(id, self._id)
		res = Typhoeus.get(@dburi + uri_encode(self._id) + '/' + uri_encode(id), headers: { Accept: '*/*' })

		if res.success?
			return result.body
		else
			raise("Attachment retrieval error, code: " + res.code.to_s)
		end
	end

	def add_attachment(id, file, options = {})
		id = id.to_s
		pacify_blank(id, self._id)

		if file.is_a?(File) || file.is_a?(StringIO)
			file = file.read
		end

		raise(ArgumentError, "Cannot call 'bytesize' on object") if !(file.respond_to? :bytesize)

		mimetype = options[:mime] || 'text/plain'

		query = (self.new? ? {} : {rev: self._rev})
		res = Typhoeus.put(@dburi + uri_encode(self._id) + '/' + uri_encode(id),
											 headers: { 'Content-Type' => mimetype },
											 params: query,
											 body: file
											)
		if res.success? && MultiJson.load(res.body)['ok'] == true
			#TODO: update rev
			return true
		else
			raise('Error saving attachment, code: ', res.code)
		end
	end

	def delete_attachment(id)
		id = id.to_s
		pacify_blank(id, self._id)

		query = (self.new? ? {} : {rev: self._rev})
		res = Typhoeus.delete(@dburi + uri_encode(self._id) + '/' + uri_encode(id), params: query)
		body = MultiJson.load(res.body)

		if res.success? && body['ok'] == true
			self._rev = body['rev']
			self._attachments.delete(id)
		else
			raise('Error deleting attachment, code: ', res.code)
		end
	end
end

