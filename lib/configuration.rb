require 'yaml'

class Divan::Configuration
  def self.load_config(path=nil)
    file ||= path
    file ||= File.join(Rails.root,'config/couchdb.yaml') if (defined? Rails) && File.exists?(File.join(Rails.root,'config/couchdb.yaml'))
    file ||= File.join(File.dirname(__FILE__),'config/couchdb.yaml') if File.exists?(File.join(File.dirname(__FILE__),'config/couchdb.yaml'))
    file ||= 'couchdb.yaml' if File.exists?('couchdb.yaml')

    @@config = ::YAML::load(File.open(file)) unless file==nil
    @@config = {} if file==nil  
  end
  
  def self.config
    @@config
  end
  
  # holds content of YML configuration file
  @@config
  # meant to load YML file only once
  # note: 100% is ran only once
  load_config
  
  def self.database(usertype='dbreader')
    db = process_config(usertype) 
    db['db']
  end
   
  def self.dbstring(usertype='dbreader')
    db = process_config(usertype)
    if db['username'].empty?
        loginseq = ''
    elsif !db['username'].empty? && db['password'].empty?
        loginseq = db['username'] + '@'
    elsif !db['username'].empty? && !db['password'].empty?
        loginseq = db['username']+':'+db['password']+'@'
    end
    
    db['protocol']+'://'+loginseq+db['host']+':'+db['port']+'/'+db['db']+'/'
  end


  
  def self.process_config(usertype='dbreader')
    env = ENV['RACK_ENV'] || 'development'
    env = Rails.env if defined? Rails
    
    if @@config==nil || !@@config.include?(usertype) || !@@config[usertype].include?(env) || @@config[usertype][env].nil?
      databaseuri = {'protocol'=>'http', 'username'=>'', 'password'=>'', 'host'=>'localhost', 'port'=>'5984', 'db'=>'divan'}
    else
      par = @@config[usertype][env]
      protocol = par['protocol'] || 'http'
      host = par['host'] || 'localhost'
      port = par['port'].to_s || '5984'
      prefix = par['prefix'] || 'divan'
      suffix = par['suffix'] || ''
      db = (suffix.empty? ? prefix : prefix+'-'+suffix)
      username = par['username'] || ''
      password = par['password'] || ''

      databaseuri = {'protocol'=>protocol, 'username'=>username, 'password'=>password, 'host'=>host, 'port'=>port, 'db'=>db}
    end
  end


end
