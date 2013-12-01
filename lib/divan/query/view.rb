require_relative '../helpers.rb'

module Divan
	module Query
		class View
			include ::Divan::Helpers

			def initialize(database, design, name)
				@database = database
				@design = design
				@view = name
				@params = {}
				@raw = false
				@mapwith = 'Divan::Document'
				return self
			end
			
			def full_url
				@database.uri('reader') + '_design/' + uri_encode(@design) + '/_view/' + uri_encode(@view)
			end
			
			def raw
				@raw = true
				self
			end
			
			def map_with(model)
			  if model.safe_constantize
			    @mapwith = model
			  else
			    raise(model + ' is not defined')
			  end
			  self
			end
			
			def docmap(view_result)
				if view_result.success?
					body = view_result.from_json
					res = body['rows'].reduce([]) do |result, row|
						result << @mapwith.constantize.new(row['doc'])
					end
					res
				else
					raise('Error' + view_result.body.inspect + view_result.code.inspect)
				end
			end
			
			# directly into the CouchDB
			def params(opts = {})
				@params.merge!(opts)
				self
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
				conn_handler do
					# convert key of @params to JSON for CouchDB
					@params.merge!(include_docs: true, key: MultiJson.dump(name))
					handle_raw(Typhoeus.get(full_url, params: @params))
				end
			end
			
			def keys(arg = [])
				conn_handler do
					@params.merge!(keys: arg)
					handle_raw(Typhoeus.post(full_url, body: @params))
				end
			end

			def go
				conn_handler do
					convert(Typhoeus.get(full_url, params: @params))
				end
			end
			
			def all
				conn_handler do
					@params.merge!(include_docs: true)
					handle_raw(Typhoeus.get(full_url, params: @params))
				end
			end
			
			private
			def conn_handler(&code)
				data = code.call
				flush_chain_variables
				return data
			end
			
			def handle_raw(result)
				if @raw
					convert(result)
				else
					docmap(result)
				end
			end
			
			def flush_chain_variables
				@raw = false
				@params = {}
			end
		end
	end
end 
 
