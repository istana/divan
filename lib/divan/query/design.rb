require_relative '../helpers.rb'

module Divan
	module Query
		class Design
			include ::Divan::Helpers
			
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
		end
	end
end 
