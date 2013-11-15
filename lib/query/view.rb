require 'ostruct'
module Divan
	module Query
		class View
			include ::Divan::Support::Helpers

			def initialize(database, design, name)
				@database = database
				@design = design
				@view = name
				@params = {}
				@raw = false
				return self
			end
			
			def full_url
				@database.uri('reader') + '_design/' + uri_encode(@design) + '/_view/' + uri_encode(@view)
			end
			
			def raw
				@raw = true
				self
			end
			
			def docmap(view_result)
				
				
			
				puts view_result.headers.inspect
				if view_result.success?
					body = view_result.from_json
					res = body['rows'].reduce([]) do |result, row|
						puts row.inspect
						result << Divan::Document.new(row['doc'])
					end
					res
					
=begin				x = OpenStruct.new
				x.code = view_result.response_code
				b = view_result.from_json
				x.offset = b['offset']
				x.total_rows = b['total_rows']
				x.docs = b['rows'].reduce([]) do |result, row|
					puts row.inspect
					result << Divan::Document.new(row['doc'])
				end
				x
=end
				else
					raise('Error' + view_result.body.inspect + view_result.code.inspect)
				end
			end
			
			# directly into the CouchDB
			def params(opts = {})
				@params.merge!(opts)
				self
			end
			
			# go params
			def go
				r = Typhoeus.get(full_url, params: @params)
				obj = r.from_json
				x = obj.delete('rows')
				obj.each_pair do |key, value|
					x.define_singleton_method key do
						value
					end
				end
				x
			end
			
			
			def convert(response)
				obj = response.from_json
				x = obj.delete('rows')
				obj.each_pair do |key, value|
					x.define_singleton_method key do
						value
					end
				end
				x
			end
			private :convert
			# cool methods
			def key(name, options = {})
				# convert key of @params to JSON for CouchDB
				@params = {include_docs: true, key: MultiJson.dump(name)}
				# bit of a hack
#				if name.is_a?(String) || name.is_a?(Symbol)
#					@params.merge!(key: "\"#{name}\"")
#				else
#					@params.merge!(key: name)
#				end
				
				puts 'PARAMS ' + @params.inspect
				puts 'FULL_URL ' + full_url
				
				req = Typhoeus.get(full_url, params: @params)
				puts 'KEY RESPONSE ' + req.inspect
				if @raw
					r = convert(req)
				else
					r = docmap(req)
				end
				
				flush_chain_variables
				return r
			end
			
			def keys(arg = [])
				@params.merge!(keys: arg)
				req = Typhoeus.post(full_url, body: @params)
				if @raw
					convert(req)
				else
					docmap(req)
				end
			end
			
			def flush_chain_variables
				@raw = false
				@params = {}
			end
		end
	end
end 
 
