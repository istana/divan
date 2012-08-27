

module Divan::Document::Revisions
  def return_latest_revision
    return false if self.new?
    pacify_blank @doc['_id']
    
    http_response = self.class.head('/' + uri_encode(@doc['_id']))
    (return http_response['etag'].gsub('"', '')) if http_response.success?
      
     # well, this should exists always unless played with _id
     raise("Document could not be fetched from CouchDB")
  end
  
  def latest?
    return true if self.new?
    @doc['_rev'] == return_latest_revision
  end
  
  def refresh_revision
    @doc['_rev'] = return_latest_revision unless self.new?
  end
end 
