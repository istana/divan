require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Document do
  before :all do
    class Foo < Divan::Document; end
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
    Divan::DBAdmin.database!
  end
  
  after :all do
    #HTTParty.delete Divan::Configuration.dbstring('dbadmin')
  end
  
  before :each do
    @doc = Foo.neo({'foo' => 'bar', 'key' => [1,2]})
  end
  
  it 'creates new document instance' do
    doc = Foo.neo({'foo' => 'bar', 'key' => [1,2]})
    # doc behaves as quasi-hash without most functions
    # doc.fields[] and doc[] are equivalent
    doc['_id'].should_not be_empty
    doc['foo'].should == 'bar'
    doc['key'].should == [1,2]
    doc['type'].should == 'Foo'
    doc.length.should == 4
    
    lambda { doc['nonexistent'] }.should raise_exception(RuntimeError, 'Field does not exist')
    
    doc2 = Divan::Document.neo({'_id' => 'some_id', 'foo' => 'bar', 'key' => [1,2]})
    doc2.fields.should == {'foo' => 'bar', 'key' => [1,2], '_id' => 'some_id'}
  end
  it 'tests field write' do
    @doc['foo'] = 'baz'
    @doc['foo'].should == 'baz'
    @doc['nonexistent'] = 'a'
    @doc['nonexistent'].should == 'a'
  end
  
  it 'tests field deletion' do
    @doc.delete('foo').should == 'bar'
    lambda { @doc.delete('foo') }.should raise_exception(RuntimeError, 'Field does not exist')
    lambda { @doc.delete('nonexistent') }.should raise_exception(RuntimeError, 'Field does not exist')
  end
  
  it 'saves/fetch the document' do
    @doc['_id'] = 'some/sneaky id'
    @doc.save.should == true
    # after save it should
    @doc.fields.should have_key('_rev')
    d = Divan::Document.fetch(@doc['_id'])
    d.type.should == 'Foo'
    d.should be_an_instance_of(Foo)
    d['foo'].should == 'bar'
    d.fields.should have_key('_rev')
  end
  
  it 'tests new?' do
    @doc.new?.should == true
  end
  it 'isn\'t document deleted' do
    @doc.deleted?.should == false
  end
  
  it 'checks type' do
    @doc.class.type.should == 'Foo'
    @doc.type.should == 'Foo'
    
    @doc['type'] = 'Bar'
    @doc.class.type.should == 'Foo'
    @doc.type.should == 'Bar'
    
    doc2=Divan::Document.neo({'foox' => 'barx', 'key' => [3,5]})
    doc2.class.type.should == 'Divan::Document'
    doc2.type.should == 'Divan::Document'
    expect{doc2['type']}.to raise_error(RuntimeError, 'Field does not exist')
  end
  # FUCK FUCK
  it 'checks design document name' do
    class FooDesign; end
    @doc.design.should == FooDesign
    Object.send :remove_const, :FooDesign
    
    doc2 = Divan::Document.neo({'foo' => 'bar', 'key' => [1,2]})
    doc2.design.should == Divan::Design
  end
  
  it 'checks design?' do
    @doc.design?.should == false
    # constant must be set, type not important
    FooDesign = 'Something'
    @doc.design?.should == true
    Object.send :remove_const, :FooDesign
  end
  
  it 'tests revisions' do
    @doc.latest?.should == true
    @doc.return_latest_revision.should == false
    
    @doc.save.should == true
    # saved with another way, newer revision
    result = @doc.class.put('/' + @doc['_id'], :body => MultiJson.dump(@doc.fields), :query => {:_rev => @doc['_rev']})
    result.success?.should == true
    newer_revision = result.parsed_response['rev']
    
    @doc.latest?.should == false
    @doc['_rev'].should_not == newer_revision
    @doc.return_latest_revision.should == newer_revision
    
    @doc.refresh_revision
    @doc['_rev'].should == newer_revision
  end

  it 'tests conflict' do
    # save to database
    @doc.save.should == true
    # change revision +1
    result = @doc.class.put('/'+@doc['_id'], :body => MultiJson.dump(@doc.fields), :query => {:_rev => @doc['_rev']})
    result.success?.should == true
    # save with old revision
    expect{@doc.save}.to raise_error(RuntimeError, 'Document conflict!')
  end
  
  it 'tests removal of document' do
    @doc.save.should == true
    d = @doc.destroy
    lambda { Divan::Document.fetch(d['_id']) }.should raise_exception(RuntimeError, /Document could not be fetched from CouchDB, status/)
  end
  
  ## TODO: test deleted document in database
  
  it 'tests attachments' do
    @doc.attachments?.should == false
    @doc.attachments.should == {}
    
    lambda{@doc.attachment("nonexistent attachment")}.should raise_exception(RuntimeError, /Attachment doesn't exist/)
    
    @doc.add_attachment("attachment1", "This is attachment").should == true
    @doc.attachment("attachment1").should == "This is attachment"
    
    File.open("the_painter_insomnia_stock.jpg") do |img|
      @doc.add_attachment("the_painter.jpg", img, :mime => 'image/jpeg').should == true
    end
    File.open("after_soranamae.png") do |img|
      @doc.add_attachment("after.png", img, :mime => 'image/png').should == true
    end
    
    @doc.attachments.should == @doc['_attachments']
    
    @doc['_attachments']['the_painter.jpg']['content_type'].should == 'image/jpeg'
    @doc['_attachments']['the_painter.jpg']['length'].should == 4173074

    @doc.delete_attachment('the_painter.jpg').should == true
    expect{@doc.attachment('the_painter.jpg')}.to raise_error(RuntimeError)

    @doc['_attachments'].should have_key('after.png')
    @doc['_attachments'].should have_key('attachment1')
    @doc['_attachments'].length.should == 2
  end
  
  it 'tests security' do
    @doc.save.should == true
    ['', "\t", "\n\t  "].each do |str|
      # doc._id non-blank
      expect { @doc[str] }.to raise_error(ArgumentError)
      expect { @doc[str] = "I'm blank string"}.to raise_error(ArgumentError)
      expect { @doc.delete(str) }.to raise_error(ArgumentError)
      expect { @doc.attachment(str, "I'm blank string") }.to raise_error(ArgumentError)
      expect { @doc.add_attachment(str, "I'm blank string") }.to raise_error(ArgumentError)
      expect { @doc.delete_attachment(str, "I'm blank string") }.to raise_error(ArgumentError)
      # doc._id blank
      @doc['_id'] = str
      expect{ @doc.return_latest_revision }.to raise_error(ArgumentError)
      expect{ @doc.attachment("juhu") }.to raise_error(ArgumentError)
      expect{ @doc.add_attachment("attachment1", "This is attachment") }.to raise_error(ArgumentError)
      expect{ @doc.delete_attachment("some_attachment") }.to raise_error(ArgumentError)
    end
  end
  
  it 'tests uri escaping' do
    @doc['_id'] = "geralt. of/rivia"
    identifier = "/book/Richard A. Knaak/Kingdom of Shadow (2002).some_extension"
    
    @doc.save.should == true
    doc2 = Divan::Document.fetch(@doc['_id'])
    doc2['_id'].should == "geralt. of/rivia"
    
    @doc.add_attachment(identifier, "This is Sparta!")
    @doc.attachment(identifier).should == "This is Sparta!"
    @doc.delete_attachment(identifier).should == true
  end
end

