require 'yaml'

class CouchSaModel::Configuration
  attr_reader :config
  
  def initialize
    @config = load_config
  end 
  
  def dbstring(usertype='dbreader')
    db = process_config(usertype)
    
    if db['username'].empty?
        loginseq = ''
    elsif !db['username'].empty? && db['password'].empty?
        loginseq = username + '@'
    elsif !db['username'].empty? && !db['password'].empty?
        loginseq = username+':'+password+'@'
    end
    
    db['protocol']+'://'+loginseq+db['host']+':'+db['port']+'/'+db['db']+'/'
  end

  def load_config
    # load database
    file ||= File.join(Rails.root,'config/couchdb.yml') if (defined? Rails) && File.exists?(File.join(Rails.root,'config/couchdb.yml'))
    file ||= File.join(File.dirname(__FILE__),'config/couchdb.yml') if File.exists?(File.join(File.dirname(__FILE__),'config/couchdb.yml'))
    file ||= 'couchdb.yml' if File.exists?('couchdb.yml')
    
    @config = ::YAML::load(File.open(file)) unless file==nil  
  end
  
  def process_config(usertype='dbreader')
    env = ENV['RACK_ENV'] || 'development'
    env = Rails.env if defined? Rails
  
    if @config==nil || !@config.include?(usertype) || !@config[usertype].include?(env)
      databaseuri = {'protocol'=>'http', 'username'=>'', 'password'=>'', 'host'=>'localhost', 'port'=>'5984', 'db'=>'sa'}
    else
      par = @config[usertype][env]
      protocol = par['protocol'] || 'http'
      host = par['host'] || 'localhost'
      port = par['port'].to_s || '5984'
      prefix = par['prefix'] || 'sa'
      suffix = par['suffix'] || ''
      db = (suffix.empty? ? prefix : prefix+'-'+suffix)
      username = par['username'] || ''
      password = par['password'] || ''

      databaseuri = {'protocol'=>protocol, 'username'=>username, 'password'=>password, 'host'=>host, 'port'=>port, 'db'=>db}
    end
  end
end
