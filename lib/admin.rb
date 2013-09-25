class Divan::Admin
	class << self
		req = Typhoeus::Request.new
		res = Typhoeus.get(::Divan::Configuration.dbstring('dbadmin'))
		if res.code == 404
			db = Typhoeus.put
		end

	end
end
