require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Configuration do
  before :all do
    # custom location
    @config_file = File.join(File.dirname(__FILE__), 'couchdb-custom-path.yaml')
    @conf = Divan::Configuration.load_config(@config_file)
  end
  
  after :each do
    @conf.load_config(@config_file)
  end
  
  after :all do
    # recreate couchdb-custom-path.yaml (needed if some of test fails)
    
    dbconfig = {
      'dbreader' => {
        'test' => {
          'protocol' => 'https',
          'host' => 'example.org',
          'port' => 5986,
          'database' => 'softdivan',
          'username' => 'login',
          'password' => 'password1'
        },
        'development' => { 'foo' => 'bar'},
        'production' => {'lounge' => 'on divan'}
      },
      'dbadmin' => {
        'development' => nil,
        'test' => {'port' => 1111}
      } 
    }
    
    File.open('couchdb-custom-path.yaml', 'w') do |out|
      YAML.dump(dbconfig, out )
    end
  end
  
  
  it 'checks Configuration' do
    @conf.config.should_not == nil
    @conf.config.class.should == Hash
  end
  
  it 'checks file from custom path has been loaded properly' do
    @conf.config.should == 
    {
      'dbreader' => {
        'test' => {
          'protocol' => 'https',
          'host' => 'example.org',
          'port' => 5986,
          'database' => 'softdivan',
          'username' => 'login',
          'password' => 'password1'
        },
        'development' => { 'foo' => 'bar'},
        'production' => {'lounge' => 'on divan'}
      },
      'dbadmin' => {
        'development' => nil,
        'test' => {'port' => 1111}
      } 
    }
  end
  
  it 'tests procession (process_config) config file as dbreader (default)' do
    confhash = @conf.process_config
    confhash.should == {
      'protocol'=>'https', 'username'=>'login', 'password'=>'password1',
      'host'=>'example.org', 'port'=>5986, 'db'=>'softdivan'
    }
  end
  
  it 'tests procession (process_config) of config file as dbadmin and fallback settings' do
    confhash = @conf.process_config('dbadmin')
    confhash.should == {
      'protocol'=>'http', 'username'=>'', 'password'=>'', 
      'host'=>'localhost', 'port'=>1111, 'db'=>'divan-test'
    }
  end
  
  it 'tests nonexistent settings in file' do
    ENV['RACK_ENV'] = 'production'
    confhash = @conf.process_config('dbadmin')
    confhash.should == {
      'protocol'=>'http', 'username'=>'', 'password'=>'', 
      'host'=>'localhost', 'port'=>5984, 'db'=>'divan-production'
    }
    ENV['RACK_ENV'] = 'test'
  end
  
  it 'checks persistence of loaded configuration file' do
    # wholeconf = @conf.config/dup/clone
    # wholeconf ={};wholeconf.merge(@conf.config) too
    # this modifies config and @@config!
    # (depends on dimensions of hash)
    
    dupconf = Marshal.load(Marshal.dump(@conf.config))
    dupconf['dbreader']['development']['foo'].should == 'bar'
    
    dupconf['dbreader']['development']['foo'] = 'baz'
    File.open(@config_file, 'w') do |out|
      YAML.dump(dupconf, out)
    end
    @conf.config['dbreader']['development']['foo'].should == 'bar'
    
    dupconf['dbreader']['development']['foo'] = 'bar'
    File.open(@config_file, 'w') do |out|
      YAML.dump(dupconf, out)
    end
  end
  
  it 'checks correct output of dbstring (default)' do
    @conf.dbstring.should == 'https://login:password1@example.org:5986/softdivan/'
  end
  
  it 'checks correct output of dbstring (dbadmin-fallback)' do
    @conf.dbstring('dbadmin').should == 'http://localhost:1111/divan-test/'
  end
  
  it 'checks correct output of database (default)' do
    @conf.database.should == 'softdivan'
  end

  it 'checks correct output of database dbadmin (fallback)' do
    @conf.database('dbadmin').should == 'divan-test'
  end
end
