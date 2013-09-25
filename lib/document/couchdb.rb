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
	def latest_revision
		return nil if self.new?
		pacify_blank(_id)

		req = Typhoeus.head(database + uri_encode(_id))

		if req.success?
			return req.headers['ETag'].gsub('"', '')
		else
			# Document is no longer in database, or id was changed
			return nil
		end
	end

	def latest?
		return true if self.new?
		_rev == latest_revision
	end

	def refresh_revision
		if self.new?
			false
		else
			self._rev = latest_revision
		end
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

		res = Typhoeus.put(database + '/' + uri_encode(id),
									params: options,
									body: MultiJson.dump(doc)
							)

		res_body =  MultiJson.load(res.body)
		# Conflict
		if res.code == 409
			raise('Document conflict')
		elsif res.success? && res_body['ok'] == true
			self._rev = res_body['rev'] 
			return true
		else
			raise('Error saving document, code: ' + res.code.to_s)
		end
	end

	def destroy
		return self if self.new?
		raise("Revision is old!") unless self.latest?
		res = Typhoeus.delete(database + '/' + uri_encode(_id),
										params: { rev: @doc['_rev'] }
							)
		raise("Error destroying document!") unless res.success?
		self
	end

	def attachments?
		!!_attachments
	end

	def attachment(id)
		id = id.to_s
		pacify_blank(id, _id)
		res = Typhoeus.get(database + uri_encode(_id) + '/' + uri_encode(id), params: { 'Accept' => '*/*' })

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
		res = Typhoeus.put(database + uri_encode(self._id) + '/' + uri_encode(id),
											 headers: { 'Content-Type' => mimetype },
											 params: query,
											 body: file
											)
		if res.success? && res.parsed_response['ok'] == true
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
		res = Typhoeus.delete(database + uri_encode(self._id) + '/' + uri_encode(id), params: query)
		body = res.parsed_response

		if res.success? && body['ok'] == true
			self._rev = body['rev']
			self._attachments.delete(id)
		else
			raise('Error deleting attachment, code: ', res.code)
		end
	end
end

