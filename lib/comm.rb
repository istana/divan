

require 'restclient'
module Divan::Comm

  def assemble_dbresult(result, headers, args, code, errors)
    newresult = {}
    
    result.jsondecode.each {|k,v| newresult[k.to_sym] = v} unless result.nil?
    
    newresult.define_singleton_method :headers, lambda { headers }
    newresult.define_singleton_method :args, lambda { args }
    newresult.define_singleton_method :code, lambda { code }
    newresult.define_singleton_method :errors, lambda { errors }
    newresult
  end
  
  def assemble_error(exception)
    errors = {}
    exception.http_body.jsondecode.each {|k,v| errors[k.to_sym] = v}
    errors.merge(:message => exception.message)
    errors
  end
  
  def rawget(query, params = {})
    begin
      result =  ::RestClient.get(query, {:params => params, :accept => 'application/json'})
      
      assemble_dbresult(result, result.headers, result.args, result.code, nil)
    rescue ::RestClient::ResourceNotFound => e
      puts "bla not found"
      errors = assemble_error(e)
      assemble_dbresult(nil, nil, nil, e.http_code, errors)
      #{'errors' => errors, 'code' => e.http_code}
    rescue ::RestClient::Forbidden => e
      puts "bla forbidden"
      errors = assemble_error(e)
      assemble_dbresult(nil, nil, nil, e.http_code, errors)
    rescue ::RestClient::Conflict => e
      puts "bla conflict"
      errors = assemble_error(e)
      assemble_dbresult(nil, nil, nil, e.http_code, errors)
    end
  end
  
  def rawput(query, payload={:foo=>'bar'})# :content_type => :json, 
    begin
      result = 	::RestClient.put(query, payload.jsonencode, {:accept => 'application/json'})
      
      assemble_dbresult(result, result.headers, result.args, result.code, nil)
    rescue ::RestClient::ResourceNotFound => e
      puts "bla not found"
      errors = assemble_error(e)
      assemble_dbresult(nil, nil, nil, e.http_code, errors)
    rescue ::RestClient::Forbidden => e
      puts "bla forbidden"
      errors = assemble_error(e)
      assemble_dbresult(nil, nil, nil, e.http_code, errors)
    rescue ::RestClient::Conflict => e
      puts "bla conflict"
      errors = assemble_error(e)
      assemble_dbresult(nil, nil, nil, e.http_code, errors)
    end
  end
end 
