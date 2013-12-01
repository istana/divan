module Divan
	class Database

		def initialize(url = nil)
			@database = Divan::Configuration.new(url)
		end

		def exists?
			q = ::Typhoeus.head(@url)
			if q.code == 404
				return false
			elsif q.code == 200
				return true
			else
				raise('Weird http code %s', q.code)
			end
		end

		def info
			::Typhoeus.get(@url).parsed_response 
		end

		def create!
			q = ::Typhoeus.post(@url)
			if q.code == 201
				return true
			else
				return false
			end
		end

		def delete!
			q = ::Typhoeus.delete(@url)
			if q.code == 200
				return true
			else
				return false
			end
		end

		# modules
		def design(name)
			Divan::Query::Design.new(@database, name)
		end

	end
end 
