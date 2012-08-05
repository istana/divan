require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Document do
  before :all do
    class Foo < Divan::Document; end
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
    Divan::DBAdmin.database!
  end
  
  after :all do
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
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
    # after save it should
    @doc.should respond_to(:_rev)
    d=Divan::Document.fetch(@doc._id)
    d.class.name.should == 'Foo'
    d.should be_an_instance_of(Foo)
    d.instance_variable_get(:@foo).should == 'bar'
    d.foo.should == 'bar'
    d.should respond_to(:_rev)
  end
  
  it 'isn\'t document deleted' do
    @doc.deleted?.should == false
  end
  
  it 'checks design document name' do
    @doc.design.should == 'FooDesign'
  end
  
  it 'checks type' do
    @doc.class.type.should == 'Foo'
    
    doc2=Divan::Document.neo({'foox' => 'barx', 'key' => [3,5]})
    doc2.class.type.should == 'Divan::Document'
    # no type set, when instantiating from Divan::Document
    expect{doc2.type}.to raise_error(NoMethodError)
  end
  
  it 'tests field deletion' do
    @doc.remove_field(:foo)
    @doc.should_not respond_to(:foo)
    @doc.instance_variable_defined?(:@foo).should == false
  end
  
  it 'tests field addition' do
    expect{@doc.add_field(:foo, 'bar2')}.to raise_error(ArgumentError, 'This field exists already')
    @doc.add_field(:geralt, 'Gwynnbleid')
    @doc.instance_variable_defined?(:@geralt).should == true
    @doc.should respond_to(:geralt)
  end
  
  it 'tests revisions' do
    @doc.latest?.should == true
    @doc.return_latest_revision.should == false
    
    @doc.save.should == true
    # saved with another way
    result = @doc.class.put('/'+@doc._id, :body => MultiJson.dump(@doc.document), :query => {:_rev => @doc._rev})
    result.success?.should == true
    
    @doc.latest?.should == false
    @doc._rev.should_not == result.parsed_response['rev']
    @doc.return_latest_revision.should == result.parsed_response['rev']
    
    @doc.refresh_revision
    @doc._rev.should == result.parsed_response['rev']
  end

  it 'tests conflict' do
    # save to database
    @doc.save.should == true
    # change revision +1
    result = @doc.class.put('/'+@doc._id, :body => MultiJson.dump(@doc.document), :query => {:_rev => @doc._rev})
    expect{@doc.save}.to raise_error(RuntimeError, 'Document conflict!')
    @doc.conflict?.should == true
  end
  
  it 'tests removal of document' do
    @doc.save.should == true
    d = @doc.destroy
    expect{Divan::Document.fetch(d._id)}.to raise_error{RuntimeError}
  end
  
  ## TODO: test deleted document in database
  
  it 'gets original document (without changes)' do
    @doc.save
    @doc.add_field(:geralt, 'witcher')
    @doc.foo = 'baz'
    
    orig = @doc.return_original
    orig.should_not respond_to(:geralt)
    orig.foo.should == 'bar'
  end
  
  it 'tests attachments' do
    @doc.attachments?.should == false
    @doc.attachments.should == {}
    expect{@doc.attachment("attach")}.to raise_error(RuntimeError)
    
    @doc.add_attachment("attachment1", "This is attachment").should == true
    @doc.attachment("attachment1").should == "This is attachment"
    
    File.open("the_painter_insomnia_stock.jpg") do |img|
      @doc.add_attachment("the_painter.jpg", img, :mime => 'image/jpeg').should == true
    end
    File.open("after_soranamae.png") do |img|
      @doc.add_attachment("after.png", img, :mime => 'image/png').should == true
    end
    @doc._attachments['the_painter.jpg']['content_type'].should == 'image/jpeg'
    @doc._attachments['the_painter.jpg']['length'].should == 4173074

    @doc.delete_attachment('the_painter.jpg').should == true
    expect{@doc.attachment('the_painter.jpg')}.to raise_error(RuntimeError)
    
    @doc.attachments.should have_key('after.png')
    @doc.attachments.should have_key('attachment1')
    @doc.attachments.length.should == 2
  end
  
  it 'tests security' do
    @doc.save.should == true
    ['', "\t", "\n\t  "].each do |str|
      # doc._id non-blank
      expect{@doc.save(str, "I'm blank string")}.to raise_error(ArgumentError)
      expect{@doc.add_field(str, "I'm blank string")}.to raise_error(ArgumentError)
      expect{@doc.remove_field(str, "I'm blank string")}.to raise_error(ArgumentError)
      expect{@doc.attachment(str, "I'm blank string")}.to raise_error(ArgumentError)
      expect{@doc.add_attachment(str, "I'm blank string")}.to raise_error(ArgumentError)
      expect{@doc.delete_attachment(str, "I'm blank string")}.to raise_error(ArgumentError)
      # doc._id blank
      @doc._id = str
      expect{@doc.return_latest_revision}.to raise_error(ArgumentError)
      expect{@doc.attachment("juhu")}.to raise_error(ArgumentError)
      expect{@doc.add_attachment("attachment1", "This is attachment")}.to raise_error(ArgumentError)
      expect{@doc.delete_attachment("some_attachment")}.to raise_error(ArgumentError)
    end
  end
end

