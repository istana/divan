require File.expand_path("../../spec_helper", __FILE__)

describe String do
   it 'checks jsondecode of String works properly' do
    str = "{\"_id\":\"919156c7f24bb77528e409eb0a1f951c\",
              \"_rev\":\"1-c7958ef80b275748764d4b53835ee495\",
              \"coolid\":\"aaa\",
              \"name\":\"meno\",
              \"short_description\":\"dfj awd jfaidf ioasd dfa sdfa afsd \",
              \"type\":\"CosmicShip\"}\n"
              
    str.jsondecode.should ==
        {"_id"=>"919156c7f24bb77528e409eb0a1f951c",
         "_rev"=>"1-c7958ef80b275748764d4b53835ee495",
         "coolid"=>"aaa", "name"=>"meno",
         "short_description"=>"dfj awd jfaidf ioasd dfa sdfa afsd ",
         "type"=>"CosmicShip"} 
    end
end

describe Hash do
    it 'checks jsonencode works properly' do
      hash = {"_id"=>"919156c7f24bb77528e409eb0a1f951c",
              "_rev"=>"1-c7958ef80b275748764d4b53835ee495",
              "coolid"=>"aaa", "name"=>"meno",
              "short_description"=>"dfj awd jfaidf ioasd dfa sdfa afsd ",
              "type"=>"CosmicShip"}
      hash.jsonencode.should == '{"_id":"919156c7f24bb77528e409eb0a1f951c","_rev":"1-c7958ef80b275748764d4b53835ee495","coolid":"aaa","name":"meno","short_description":"dfj awd jfaidf ioasd dfa sdfa afsd ","type":"CosmicShip"}'
    end
end

