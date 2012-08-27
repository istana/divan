

module Divan::Document::Attachments
  ###
  ### ATTACHMENTS
  def attachments?
    @doc.key? '_attachments'
  end
  
  def attachments
    return {} unless attachments?
    @doc['_attachments']
  end
  
  def attachment(identifier)
    identifier = identifier.to_s
    pacify_blank(identifier)
    pacify_blank(@doc['_id'])
    result = self.class.get('/' + uri_encode(@doc['_id']) + '/' + uri_encode(identifier), :headers => {'Accept'=>'*/*'})
    
    (return result.body) if result.success?
    raise("Attachment doesn't exist (probably) code:"+result.code.to_s)
  end
  
  def add_attachment(identifier, file, options = {})
    identifier = identifier.to_s
    pacify_blank(identifier)
    pacify_blank(@doc['_id'])
    
    if file.is_a?(File) || file.is_a?(StringIO)
      file = file.read
    end
    
    # HTTParty (or something inside) calls bytesize on object
    raise(ArgumentError, "Cannot call 'bytesize' on object") if !(file.respond_to? :bytesize)
    
    mimetype = options[:mime]
    mimetype ||= 'text/plain'
    
    query = (self.new? ? {} : {:rev => @doc['_rev']})
    result = self.class.put('/' + uri_encode(@doc['_id']) + '/' + uri_encode(identifier),
                            :headers => {'Content-Type' => mimetype}, :query => query, :body => file
                            )
    
    if result.success? && result.parsed_response['ok']==true
      new_doc = self.class.get('/' + uri_encode(@doc['_id']))
      if new_doc.success?
        @doc = {}
        populate_fields(new_doc.parsed_response)
        return true
      end
    end
    raise("Error saving attachment")
  end
  
  def delete_attachment(identifier)
    identifier = identifier.to_s
    pacify_blank(identifier)
    pacify_blank(@doc['_id'])
    
    query = (self.new? ? {} : {:rev => @doc['_rev']})
    result = self.class.delete('/' + uri_encode(@doc['_id']) +'/' + uri_encode(identifier), :query => query)
    
    if result.success? && result.parsed_response['ok']==true
      @doc['_rev'] = result.parsed_response['rev']
      @doc['_attachments'].delete(identifier)
      return true
    end
    raise("Error removing attachment")
  end
end 
