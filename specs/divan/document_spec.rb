require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Document do
  class Testdoc < CouchSaModel::Document
    
  end
  
  before :each do
    @testdoc = Testdoc.new
  
  end
  
  it 'dget (document get)' do
    database = Divan::Configuration.new.dbstring
    #database.should == "http://localhost:5984/ionorchis-development/"
    res = CouchSaModel::Document.dget(database, '919156c7f24bb77528e409eb0a1f951c')
    res.should == 2
  end
  



end

