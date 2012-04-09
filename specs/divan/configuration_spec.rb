require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Configuration do
  before :all do
    # load_config called
    @conf = Divan::Configuration
    ENV['RACK_ENV'] = 'test'
  end
  
  after :each do
    @conf.load_config
  end
  
  after :all do
    # recreate couchdb-custom-path.yaml (needed if some of test fails)
    dbcustompath = {"dbreader"=>{"development"=>{"foo"=>"bar"}, "test"=>{"foo"=>"bar"}, "production"=>{"protocol"=>"https"}}, "dbadmin"=>{"development"=>nil, "test"=>nil, "production"=>{"prefix"=>"test", "username"=>"aaa", "password"=>"bbb"}}}
    
    File.open('couchdb-custom-path.yaml', 'w') do |out|
      YAML.dump(dbcustompath, out )
    end
  end
  
  
  it 'checks loaded YAML configuration file from default locations' do
    yamlconf=@conf.config
    yamlconf.class.to_s.should == 'Hash'
    yamlconf.should have_key 'dbreader'
    yamlconf['dbreader'].should have_key 'development'
    yamlconf['dbreader']['development'].should == {"protocol"=>"https", "host"=>"example.org", "port"=>5986, "prefix"=>"nihaimau", "suffix"=>"development", "username"=>"login", "password"=>"password"}
    yamlconf['dbreader'].should have_key 'test'
    yamlconf['dbreader']['test'].should == {"protocol"=>"https", "host"=>"example.org", "port"=>5986, "prefix"=>"nihaimau", "suffix"=>"test", "username"=>"login", "password"=>"password"}
    yamlconf['dbreader'].should have_key 'production'
    yamlconf['dbreader']['production'].should == {"protocol"=>"http", "host"=>"localhost", "port"=>5984, "prefix"=>"equuleus", "suffix"=>"production", "username"=>"root", "password"=>123}
    
    yamlconf.should have_key 'dbadmin'
    yamlconf['dbadmin'].should have_key 'development'
    yamlconf['dbadmin'].should have_key 'test'
    yamlconf['dbadmin'].should have_key 'production'
    
    yamlconf['dbadmin']['development'].should == {"protocol"=>"https", "username"=>nil, "password"=>nil}
    
    yamlconf['dbadmin']['test'].should == nil
    
    yamlconf['dbadmin']['production'].should == {"prefix"=>"test", "username"=>"aaa", "password"=>"bbb"}
     
  end
  
  it 'loads YAML config file from custom location' do
    @conf.load_config('couchdb-custom-path.yaml')
    @conf.config.should_not == nil
  end
  
  it 'checks custom file to be loaded properly' do
    @conf.load_config('couchdb-custom-path.yaml')
    @conf.config.should == {"dbreader"=>{"development"=>{"foo"=>"bar"}, "test"=>{"foo"=>"bar"}, "production"=>{"protocol"=>"https"}}, "dbadmin"=>{"development"=>nil, "test"=>nil, "production"=>{"prefix"=>"test", "username"=>"aaa", "password"=>"bbb"}}}
  end
  
  it 'tests procession (process_config) of loaded config file as default (dbreader)' do
    confarr = @conf.process_config
    confarr['protocol'].should == 'https'
    confarr['host'].should == 'example.org'
    confarr['port'].should == '5986'
    confarr['db'].should == 'nihaimau-test'
    confarr['username'].should == 'login'
    confarr['password'].should == 'password'
  end
  
  it 'tests procession (process_config) of loaded config file as dbadmin and default settings' do
    confarr = @conf.process_config('dbadmin')
    confarr['protocol'].should == 'http'
    confarr['host'].should == 'localhost'
    confarr['port'].should == '5984'
    confarr['db'].should == 'divan'
    confarr['username'].should == ''
    confarr['password'].should == ''
  end
  
  it 'checks persistence of loaded configuration file' do
    @conf.load_config('couchdb-custom-path.yaml')
    # no, this modifies config and @@config!
    # wholeconf = @conf.config or dup or clone
    # wholeconf ={};wholeconf.merge(@conf.config) too
    # (depends on dimensions of hash)
    wholeconf = Marshal.load(Marshal.dump(@conf.config))
    wholeconf['dbreader']['test']['foo'].should == 'bar'
    wholeconf['dbreader']['test']['foo'] = 'baz'
    File.open('couchdb-custom-path.yaml', 'w') do |out|
      YAML.dump(wholeconf, out )
    end
    @conf.config['dbreader']['test']['foo'].should == 'bar'
    wholeconf['dbreader']['test']['foo'] = 'bar'
    File.open('couchdb-custom-path.yaml', 'w') do |out|
      YAML.dump(wholeconf, out )
    end
  end
  
  it 'checks correct output of dbstring (default)' do
    @conf.dbstring.should == 'https://login:password@example.org:5986/nihaimau-test/'
  end
  
  it 'checks correct output of dbstring (dbadmin)' do
    @conf.dbstring('dbadmin').should == 'http://localhost:5984/divan/'
  end
  
  it 'checks correct output of database (default)' do
    @conf.database.should == 'nihaimau-test'
  end

  it 'checks correct output of database (default)' do
    @conf.database.should == 'nihaimau-test'
  end


end
