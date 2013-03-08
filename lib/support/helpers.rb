require 'cgi'

module Divan
	module Support
		module Helpers
			def pacify_blank(*objects)
				for object in objects
					if object.blank?
						raise(ArgumentError, 'Object cannot be blank')
					end
				end
				true
			end

			def uri_encode(what)
				if what.respond_to?(:to_s)
					what = what.to_s
				else
					raise(ArgumentError, 'Argument cannot be converted to string')
				end
				# URI::encode(what) doesn't encode slash
				::CGI.escape(what)
			end
			# Can call it directly
			module_function :uri_encode
			# If function is module_function, in mixin it is private
			public :uri_encode
		end
	end
end
