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

  it 'creates new document instance - also test of populate and add_field' do
    doc = Foo.neo({'foo' => 'bar', 'key' => [1,2]})
 
    doc.should respond_to :_id
    doc.instance_variable_get('@_id'.to_sym).should_not be_empty
    doc.should respond_to :foo
    doc.instance_variable_get(:@foo).should == 'bar'
    doc.should respond_to :key
    doc.instance_variable_get(:@key).should == [1,2]
  end
end

