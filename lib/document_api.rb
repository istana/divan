module ::Divan::DocumentApi::Base
  include ::Divan::Comm
  def getdoc(id, params = {}, specials=false)
    database = Divan::Configuration.dbstring
    
    params = params.merge({:attachments => true,
      :deleted => true, :revs => true, :revs_info => true,
      :conflicts => true, :deleted_conflicts => true,
      :local_seq => true}) if specials
    doc = rawget(database+id, params)
    
    document = ::Divan::Document.new(:doc=>doc)
    
    doc.define_singleton_method :_attachments, 
    
    
    
  end
  
  def 
end

module ::Divan::DocumentApi::Model < ::Divan::DocumentApi::Base
  def getdoc(id)
    
  end
  
  # special fields
  # _id - unique identifier (mandatory and immutable)
  # _rev - mvcc revision  (mandatory and immutable)
  # _attachments - attachments metadata
  # _deleted has been deleted?
  # And previous revisions will be removed on next compaction run
  # _revisions - revision history of the document
  # _revs_info - list of revisions of the document, and their availability
  # _conflicts - information about conflicts
  # _deleted_conflicts - information about conflicts
  # _local_seq - sequence number of the revision in the database (as found in the _changes feed) 
  # curl -X GET 'http://localhost:5984/my_database/my_document?conflicts=true'
  # The query parameter for the _revisions special field is revs 
  def deleted?
    if @doc.respond_to? :deleted
      @doc.deleted == true
    else
      false
    end
  end
end 
