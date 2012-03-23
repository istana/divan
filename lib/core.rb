require 'yaml'

module AAcore
  def dbstring(usertype='dbreader')
    db = load_config(usertype)
    
    if db['username'].empty?
        loginseq = ''
    elsif !db['username'].empty? && db['password'].empty?
        loginseq = username + '@'
    elsif !db['username'].empty? && !db['password'].empty?
        loginseq = username+':'+password+'@'
    end
    database = db['protocol']+'://'+loginseq+db['host']+':'+db['port']+'/'+db['db']+'/'
    database
  end

  def load_config(usertype='dbreader')
    # load database
    file ||= File.join(Rails.root,'config/couchdb.yml') if (defined? Rails) && File.exists?(File.join(Rails.root,'config/couchdb.yml'))
    file ||= File.join(File.dirname(__FILE__),'config/couchdb.yml') if File.exists?(File.join(File.dirname(__FILE__),'config/couchdb.yml'))
    file ||= 'couchdb.yml' if File.exists?('couchdb.yml')
    
    env = ENV['RACK_ENV'] || 'development'
    env = Rails.env if defined? Rails
    # DEBUG
    puts file
    config = ::YAML::load(File.open(file)) unless file==nil

    if config==nil || !config.include?(usertype) || !config[usertype].include?(env)
      databaseuri = {'protocol'=>'http', 'username'=>'', 'password'=>'', 'host'=>'localhost', 'port'=>'5984', 'db'=>'sa'}
    else
      par = config[usertype][env]
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
