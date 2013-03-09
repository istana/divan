require File.expand_path("../../spec_helper", __FILE__)

describe Divan::Validations do
  class Test
  end

  before :each do 
    @test_class = Test.new
    @test_class.extend(Divan::Validations)
  end
  
  it 'cond_on should return condition on update (oldDoc != null) + add to array test' do
    conditions = ["sss"]
    options = {:on => "update"}
    @test_class.cond_on(conditions, options)
    conditions[1].should == "(oldDoc != null)"
  end
  
  it 'cond_on should return condition on create (oldDoc == null) + add to array test' do
    conditions = ["aaa"]
    options = {:on => "create"}
    @test_class.cond_on(conditions, options)
    conditions[1].should == "(oldDoc == null)"
  end
  
  it 'cond_on should return empty conditions array' do
    conditions = []
    options = {:on => "foo", :foo => "bar"}
    @test_class.cond_on(conditions, options)
    conditions.should == []
  end
  
  it 'cond_unless should return "(!(#{options[:unless]}))" + add to array test' do
    conditions = ["aaa"]
    options = {:unless => "1==1", :foo => "bar"}
    @test_class.cond_unless(conditions, options)
    conditions[1].should == "(!(1==1))"
  end

  it 'cond_unless should return empty conditions array' do
    conditions = []
    options = {:on => "foo", :foo => "bar"}
    @test_class.cond_unless(conditions, options)
    conditions.should == []
  end
  
  it 'cond_if should return "(!(#{options[:if]}))" + add to array test' do
    conditions = ["aaa"]
    options = {:if => "1==1", :foo => "bar"}
    @test_class.cond_if(conditions, options)
    conditions[1].should == "(1==1)"
  end

  it 'cond_unless should return empty conditions array' do
    conditions = []
    options = {:on => "foo", :foo => "bar"}
    @test_class.cond_if(conditions, options)
    conditions.should == []
  end
  
  it 'gen_validation should contain more than two ifs when allow_null is false' do
    aaa = @test_class.gen_validation(["condition1", "condition2"], 'validation', "animal", "error message", false)
    aaa.should =~ /.*if.*if.*/
  end
  
  it 'gen_validation should contain more than two ifs when allow_null is true' do
    aaa = @test_class.gen_validation(["condition1", "condition2"], 'validation', "animal", "error message", true)
    aaa.should =~ /.*if.*if.*if.*/
  end
  
end
