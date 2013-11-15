module Divan
	module Query
		class Design
			include ::Divan::Support::Helpers
			
			def initialize(database, name)
				raise('Design name cannot be blank') if name.blank?
				@database = database
				@design = name
				@params = {}
				return self
			end
			
			def full_url
				@database.uri('reader') + '_design/' + uri_encode(@design)
			end
			
			def view(name)
				raise('View name of design document cannot be blank') if name.blank?
				#@view = name
				View.new(@database, @design, name)
			end
			
			# directly into the CouchDB
			def params(opts = {})
				@params.merge!(opts)
			end
			
			# cool methods
			def key(name)
				@params.merge!(key: name)
			end
			
			def go
				
			end
		end
	end
end 
