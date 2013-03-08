require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Support::Configuration do
  before :all do
    # custom location
    @config_file = File.expand_path('../../data/config/couchdb.yaml', __FILE__)
		@app_root = File.expand_path('../../data/', __FILE__)
		@fresh_config_data = {
      'reader' => {
        'test' => {
          'protocol' => 'https',
          'host' => 'example.org',
          'port' => 5986,
          'database' => 'softdivan',
          'username' => 'login',
          'password' => 'password1'
        },
        'development' =>  {
				 	'foo' => 'bar'
				},
        'production' => {
					'lounge' => 'on divan'
				}
      },
      'admin' => {
        'development' => nil,
        'test' => {
					'protocol' => 'http',
					'host' => 'example.net',
				 	'port' => 1111,
					'database' => 'harddivan',
					'username' => 'login',
					'password' => 'password2'
			 	}
      } 
    }
  end
  
  before(:each) do
		@config_data = Marshal.load(Marshal.dump(@fresh_config_data))
		@conf = Divan::Support::Configuration.load_config(@config_file)
		ENV['RACK_ENV'] = 'test'
  end
  
  after(:all) do
    # recreate couchdb.yaml (needed if some of test fails)
    File.open(@config_file, 'w') do |out|
      YAML.dump(@fresh_config_data, out)
    end
  end
  
  describe 'configuration parsing' do
    it 'returns configuration as reader (default role)' do
      @conf.extract_config.should == @config_data['reader']['test']
    end
  
    it 'returns configuration as admin (specified role)' do
      @conf.extract_config('admin').should == @config_data['admin']['test']
    end

    it 'is possible to pass symbol as role' do
      @conf.extract_config(:admin).should == @config_data['admin']['test']
    end

    it 'raises exception for non-existent role' do
      expect {@conf.extract_config('foo')}.to raise_error(/User/)
    end

    it 'raises exception for non-existent env section for user' do
      ENV['RACK_ENV'] = 'production'
      expect {@conf.extract_config('admin')}.to raise_error(/Section/)
    end
	end
 

	context 'user.env is nil' do
    it 'returns defaults settings' do
      ENV['RACK_ENV'] = 'development'
      @conf.extract_config('admin').should == {
        'protocol' => 'http',
        'username' => '',
        'password' => '', 
        'host' => 'localhost',
        'port' => 5984,
        'database' => 'divan-development'
      }
    end
	end

  it 'persists configuration in "config" variable' do
    dupconf = Marshal.load(Marshal.dump(@conf.config))
    dupconf['reader']['development']['foo'].should == 'bar'
    
    dupconf['reader']['development']['foo'] = 'baz'
    File.open(@config_file, 'w') do |out|
      YAML.dump(dupconf, out)
    end
    @conf.config['reader']['development']['foo'].should == 'bar'
    
    File.open(@config_file, 'w') do |out|
      YAML.dump(@config_data, out)
    end
  end
  
	describe 'database uri' do
    it 'returns string as default role (user)' do
      @conf.uri.should == 'https://login:password1@example.org:5986/softdivan/'
    end
  
    it 'returns string as specified role (admin)' do
      @conf.uri('admin').should == 'http://login:password2@example.net:1111/harddivan/'
    end
	end

 
	describe 'correct output of database name' do
    it 'returns string as default role (user)' do
      @conf.database.should == 'softdivan'
    end

    it 'returns string as specified role (admin)' do
      @conf.database('admin').should == 'harddivan'
    end
	end

	describe 'loading of configuration file' do
		it 'when Sinatra exists' do
      stub_const('Sinatra::Application', Class.new)
		  Sinatra::Application.stub(:root).and_return(@app_root)
		  @conf.load_config
		  @conf.database.should == 'softdivan'
	  end

	  it 'when Rails exists' do
      stub_const('Rails', Class.new)
      Rails.stub(:root).and_return(@app_root)
      Rails.stub(:env).and_return('test')
      @conf.load_config
      @conf.database.should == 'softdivan'
    end

		it 'when APP_ROOT is defined' do
			stub_const('APP_ROOT', @app_root)
			@conf.load_config
			@conf.database.should == 'softdivan'
		end

		it 'when path was specified' do
      @conf.config.should == @config_data
    end
	end

end
