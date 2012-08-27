require File.expand_path("../../spec_helper", __FILE__)

describe 'Document functionality linked with Design' do
  
  before :all do
    class FooDesign < Divan::Design;
    end
    class Foo < Divan::Document; end
    HTTParty.delete Divan::Configuration.dbstring('dbadmin')
    Divan::DBAdmin.database!
  end
  
  # rails style
  it 'tests attributes security' do
    Foo.neo({:geralt => 'rivia', :secret => 'victoria', :secret3 => 'monkey island', :box => 'blue'})
  
    class FooDesign
      attr_protected :secret
      attr_protected :secret2, :secret3
      attr_accessible :box
      attr_accessible :box2, :box3
    end
    
    Foo.neo({:geralt => 'rivia', :secret => 'bar', :secret3 => 'baz', :box =})
  end
end 
