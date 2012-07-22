require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Document do
  before :all do
    class Foo < Divan::Document; end
    Divan::DBAdmin.database!
  end
  
  after :all do
    #HTTParty.delete @conf.dbstring('dbadmin')
  end
  
  before :each do
    @doc = Foo.neo({'foo' => 'bar', 'key' => [1,2]})
  end
  
  it 'tests "generated" document' do
    @doc.document.length.should == 4
    @doc.document.should have_key('_id')
    @doc.document['_id'].should_not be_empty
    @doc.document['foo'].should == 'bar'
    @doc.document['key'].should == [1,2]
    @doc.document['type'].should == 'Foo'
  end
  
  it 'tests new?' do
    @doc.new?.should == true
  end
  
  it 'saves/fetch the document' do
    @doc.save.should == true
    d=Divan::Document.fetch(@doc._id)
    d.class.name.should == 'Foo'
    d.instance_variable_get(:@foo).should == 'bar'
    d.foo.should == 'bar'
  end
  
  it 'isn\'t document deleted' do
    @doc.deleted?.should == false
  end
  
  it 'checks design document name' do
    @doc.design.should == 'FooDesign'
  end
  
  it 'checks type' do
    @doc.class.type.should == 'Foo'
  end
=begin  
  it 'dget (document get)' do
    database = Divan::Configuration.new.dbstring
    #database.should == "http://localhost:5984/ionorchis-development/"
    res = CouchSaModel::Document.dget(database, '919156c7f24bb77528e409eb0a1f951c')
    res.should == 2
  end
=end



end

