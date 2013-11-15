:class Divan
	class Doc

		def initialize(url, id)
			@id = id
			@url = url
			@full_url = @url + urlencode(@id)
		end

		def exists

		end

		def info
			Typhoeus.head(@full_url)
		end

		def fetch(options)
			::Divan::Document(Typhoeus.get(@full_url).parsed_response)
		end

		def create(content)
			Typhoeus.put(@full_url, params: {rev}
		end

		def delete
			Typhoeus.delete(@full_url)
		end

		def copy

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

		def





	end
end 
