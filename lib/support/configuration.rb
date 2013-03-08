require 'yaml'

# Class for Couch database configuration
module Divan
	module Support

		class Configuration
			class << self
				attr_accessor :config

				def load_config(path = nil)
					confpath = File.join('config', 'couchdb.yaml')
					file ||= path

					if defined?(Rails) && File.exists?(File.join(Rails.root.to_s, confpath))
						file ||= File.join(Rails.root.to_s, confpath)
					end

					if defined?(Sinatra::Application)
						if File.exists?(File.join(Sinatra::Application.root, confpath))
							file ||= File.join(Sinatra::Application.root, confpath)
						end
					end

					if defined?(APP_ROOT) && File.exists?(File.join(APP_ROOT, confpath))
						file ||= File.join(APP_ROOT, confpath)
					end

					if file.nil?
						raise("Configuration file '#{file}' doesn't exist")
					end

					self.config = ::YAML::load_file(file)
					return self
				end
   
				# NOTE: not using OpenStruct for speed
				def extract_config(user = 'reader')
					user = user.to_s.dup
					env = ENV['RACK_ENV'] || 'development'
					env = Rails.env if defined? Rails

					if !config.include?(user)
						raise("User '#{user}' doesn't exist.")
					elsif	!config[user].include?(env)
						raise("Section '#{env}' for '#{user}' not found.")
					elsif config[user][env].nil?
						conf = {}
					else
						conf = config[user][env]
					end

					{
						'protocol' => conf['protocol'] || 'http',
					 	'username' => conf['username'] || '',
						'password' => conf['password'] || '',
						'host' => conf['host'] || 'localhost',
						'port' =>  conf['port'] || 5984,
						'database' => conf['database'] || "divan-#{env}"
					}
				end

				# Returns database name for user
				def database(user = 'reader')
					extract_config(user)['database']
				end

				def uri(user = 'reader')
					db = extract_config(user)
					if db['username'].empty?
						loginseq = ''
					elsif !db['username'].empty? && db['password'].empty?
						loginseq = db['username'] + '@'
					elsif !db['username'].empty? && !db['password'].empty?
						loginseq = db['username']+':'+db['password']+'@'
					end

					db['protocol']+'://'+loginseq+db['host']+':'+db['port'].to_s+'/'+db['database']+'/'
				end
			end
			self.config = {}
		end

	end
end

