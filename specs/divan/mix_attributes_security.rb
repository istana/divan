require File.expand_path("../../spec_helper", __FILE__)

describe 'Attributes security (accessible, protected)' do
  
  before :all do
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
    Divan::DBAdmin.database!
  end
  
  before :each do
    class FooDesign < Divan::Design;
    end
    class Foo < Divan::Document; end
    
    @doc = Foo.neo({'geralt' => 'rivia', :secret => 'victoria', :secret3 => 'monkey island', :box => 'blue'})
  end
  
  after :each do
    # does not work, one cannot simply remove constant, it is defined forever
    #Object.send :remove_const, :FooDesign
    #class FooDesign < Divan::Design;
    #end
    FooDesign.instance_variable_set :@protected_fields, {}
    FooDesign.instance_variable_set :@accessible_fields, {}
  end
  
  # rails style
  it 'tests basics' do
    class FooDesign
      attr_protected :secret
      attr_protected :secret2, :secret3
      attr_protected :foo, :as => 'admin'
      attr_protected :bar, :baz, :as => 'admin'
      
      attr_accessible :box, :boy
      attr_accessible :boz
      attr_accessible :foo, :as => 'admin'
      attr_accessible :bar, :baz, :as => 'admin'
    end
    
    (FooDesign.protected_fields).should == {'default' => [:secret, :secret2, :secret3], 'admin' => [:foo, :bar, :baz]}
    (FooDesign.accessible_fields).should == {'default' => [:box, :boy, :boz], 'admin' => [:foo, :bar, :baz]}
  end
  
  it 'tests no accessible or protected fields defined' do
    # all are accessible
    @doc['geralt'].should == 'rivia'
    @doc['foo'] = 'bar'
    @doc.attr_protected?('geralt').should == false
    @doc.attr_protected?('foo').should == false
  end
  
  it 'tests only accessible fields defined' do
    # others are protected
    class FooDesign
      attr_accessible 'geralt'
    end
    @doc.attr_protected?('geralt').should == false
    @doc.attr_protected?('secret').should == true
  end
  
  it 'tests only protected fields defined' do
    # others are accessible
    class FooDesign
      attr_protected 'secret'
    end
    @doc.attr_protected?('geralt').should == false
    @doc.attr_protected?('secret').should == true
  end
  
  it 'tests when field is both protected and accessible' do
    class FooDesign
      attr_protected 'geralt'
      attr_accessible 'geralt'
    end
    @doc.attr_protected?('geralt').should == true
  end
  
  it 'tests classic usage' do
    class FooDesign
      attr_protected 'secret', 'secret3'
      attr_accessible 'geralt', 'nonexistent'
    end
    @doc.attr_protected?('secret').should == true
    @doc.attr_protected?('secret3').should == true
    @doc.attr_protected?('geralt').should == false
    @doc.attr_protected?('nonexistent').should == false
  end
  
  it 'tests nonexistent design document' do
    class Bar < Divan::Document; end
    @doc = Bar.neo({'foo' => 'bar'})
    @doc.attr_protected?('foo').should == false
    @doc.attr_protected?('nonexistent').should == false
  end
  
  it 'tests other group' do
    class FooDesign
      attr_protected 'secret', 'secret3', :as => 'admin'
      attr_accessible 'geralt', 'nonexistent', :as => 'admin'
      attr_protected 'mysecret'
      attr_accessible 'lounge'
    end
    @doc.attr_protected?('secret').should == false
    @doc.attr_protected?('secret3').should == false
    @doc.attr_protected?('secret', :as => 'admin').should == true
    @doc.attr_protected?('secret3', :as => 'admin').should == true
    
    @doc.attr_protected?('nonexistent', :as => 'admin').should == false
    @doc.attr_protected?('nonexistent').should == false
    
    @doc.attr_protected?('mysecret').should == true
    @doc.attr_protected?('lounge').should == false
    @doc.attr_protected?('mysecret', :as => 'admin').should == false
    @doc.attr_protected?('lounge', :as => 'admin').should == false
  end
  
  it 'tests application of attributes security on new document' do
    class FooDesign
      attr_protected 'secret', 'secret3'
      attr_accessible 'geralt', 'nonexistent'
    end
    new_doc = Foo.neo('some' => 'field', 'secret' => 'victoria', 'geralt' => 'rivia')
    new_doc['geralt'].should == 'rivia'
    lambda {new_doc['secret']}.should raise_exception(RuntimeError, 'Field does not exist')
    
    new_doc2 = Foo.neo({'some' => 'field', 'secret' => 'victoria', 'geralt' => 'rivia'}, :without_protection => true)
    new_doc2['geralt'].should == 'rivia'
    new_doc2['secret'].should == 'victoria'
  end
  
  it 'tests attributes assignment' do
    class FooDesign
      attr_protected 'secret', 'secret3'
      attr_accessible 'geralt', 'nonexistent'
    end
    
    new_doc = Foo.neo
    new_doc.assign_attributes({'secret' => 'victoria', 'geralt' => 'rivia'}, :without_protection => true)
    new_doc['secret'].should == 'victoria'
    new_doc['geralt'].should == 'rivia'
    
    # overwriting protected attribute keeps old value
    new_doc.assign_attributes({'secret' => 'victoria2', 'secret3' => 'xxx'})
    new_doc['secret'].should == 'victoria'
    lambda {new_doc['secret3']}.should raise_exception(RuntimeError, 'Field does not exist')
    
    # another group does not have influence on group
    new_doc2 = Foo.neo
    new_doc2.assign_attributes({'secret' => 'victoria', 'geralt' => 'rivia'}, :as => 'admin')
    new_doc2['secret'].should == 'victoria'
    new_doc2['geralt'].should == 'rivia'
  end
end 
