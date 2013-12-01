require 'yaml'

# Class for Couch database configuration
module Divan
	class Configuration
		def full
			@config
		end
		
		alias_method :to_h, :full
		alias_method :to_hash, :full
		
		def initialize(something = nil)
			# hashlike
			if something.respond_to?(:[])
				@config = something
				# treat as filepath
			else
				@config = self.class.load_config(something)
			end
			populate
		end

		def uri(user = 'reader', env = nil)
			env ||= Rails.env if defined? Rails
			env ||= ENV['RACK_ENV'] || 'development'

			db = process(@config[user][env], env)
			if db['username'].blank?
				loginseq = ''
			elsif !db['username'].blank? && db['password'].blank?
				loginseq = db['username'] + '@'
			elsif !db['username'].blank? && !db['password'].blank?
				loginseq = db['username'] + ':' + db['password'] + '@'
			end

			db['protocol']+'://'+loginseq+db['host']+':'+db['port'].to_s+'/'+db['database']+'/'
		end
		
		def populate
			users = ['admin', 'reader']
			envs = ['development', 'production', 'test']
			for user in users
				if !@config.include?(user)
					@config[user] = {}
				end

				for env in envs
					if !@config[user].include?(env)
						@config[user][env] = {}
					end
				end
			end
		end
		
		def process(hash, env)
			{
				'protocol' => hash['protocol'] || 'http',
				'username' => hash['username'] || nil,
				'password' => hash['password'] || nil,
				'host' => hash['host'] || 'localhost',
				'port' =>  hash['port'] || 5984,
				'database' => hash['database'] || "divan-#{env}"
			}
		end
		private :populate, :process
		
		def self.load_config(options = {})
			if options.respond_to? :[]
				basepath = options[:basepath] || options ['basepath']
				confpath = options[:confpath] || options['confpath']
			end
			
			msg = ''
			if defined?(Rails)
				basepath ||= Rails.root.to_s
				msg = 'Rails detected'
			elsif defined?(Sinatra::Application)
				basepath ||= Sinatra::Application.root
				msg = 'Sinatra detected'
			elsif defined?(APP_ROOT)
				basepath ||= APP_ROOT
				msg = 'APP_ROOT detected'
			else
				basepath ||= '.'
				msg = 'current directory as base path is used'
			end
					
			confpath ||= File.join('config', 'couchdb.yaml')

			file = File.join(basepath, confpath)
			if !File.exists?(file)
				if defined?(logger)
				 logger.info("Configuration file '#{file}' doesn't exist (#{msg})")
				end
				# defaults
				return {}
			else
				return ::YAML::load_file(file)
			end
		end
		
	end
end

