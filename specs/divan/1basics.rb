require File.expand_path("../../spec_helper", __FILE__)

describe 'Core methods of Divan' do
  class Foo < Divan::Document
    
  end
  
  before(:all) do
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
  end
  
  after(:all) do
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
  end
  
  it 'creates database' do
    create = Divan::DBAdmin.database!
    create.should == true
  end


  

end

