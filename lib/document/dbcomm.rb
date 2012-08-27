

module Divan::Document::Dbcomm
  # reasonable option: batch=ok
  # it seems format of HTTParty doesn't work on instance
  def save(options = {})
    doc = @doc.dup
    id = doc.delete('_id')
    pacify_blank(id)
    @last_request = self.class.put('/' + uri_encode(id), :query => options, :body => MultiJson.dump(doc))
    
    #TODO:logger.debug '('+self.base_uri+') Document save:' + @last_request
    
    if @last_request.conflict?
      raise("Document conflict!")
      return false
    end
    
    if @last_request.success? && @last_request.parsed_response['ok']==true
      @doc['_rev'] = @last_request.parsed_response['rev']
      return true
    end
    raise("Error saving document!")
  end
  
  def destroy
    return self if self.new?
    raise("Revision is old!") unless self.latest?
    @last_request = self.class.delete('/' + uri_encode(@doc['_id']), :query => {:rev => @doc['_rev']})
    raise("Error destroying document!") unless @last_request.success?
    self
  end
end
