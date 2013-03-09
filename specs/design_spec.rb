require File.expand_path("../../spec_helper", __FILE__)

describe 'Design document of Divan' do
    
  before :all do
    class FooDesign < Divan::Design; end
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
    Divan::DBAdmin.database!
  end
  
  after :all do
    #HTTParty.delete Divan::Configuration.dbstring('dbadmin')
  end
  
  it 'tests what type is' do
    FooDesign.type.should == 'FooDesign'
    FooDesign.document.should == 'Foo'
  end
  
  it 'tests which document belongs to' do
    Divan::Design.type.should == 'Divan::Design'
    Divan::Design.document.should == 'Divan::Document'
  end
  
  it 'tests design document synchronization' do
    FooDesign.sync?.should == true
    FooDesign.sync.should_not == false
    FooDesign.sync?.should == false
    
    FooDesign.has_many :apples
    FooDesign.sync?.should == true
    FooDesign.sync.should_not == false
  end
  
  it 'tests database info' do
    FooDesign.sync
    FooDesign.info.is_a?(Hash).should == true 
  end
  
  ### ASSOCIATIONS
end

