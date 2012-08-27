class Divan::View
  include HTTParty
  
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  format :json
  base_uri Divan::Configuration.dbstring
  
  def self.fetch(design, view, options)
    result = get('/_design/' + design + '/_view/' + view, :params => options)
    if result.success?
      return result.parsed_response
    end
    raise('View couldn\'t be saved')
  end
  
  def self.fetch_mapped(design, view, options)
    result = get('/_design/' + design + '/_view/' + view, :params => options)
    if result.success?
      mapped = []
      result.parsed_response.each do |doc|
        mapped << Divan::Document.neo(doc)
      end
      mapped
    end
    raise('View couldn\'t be saved')
  end
# TODO create methods returning raw result(s)?  
# design doc, view, optional - key/startkey+endkey, descending (true), group (true), include_docs (true)
=begin
key
keys
startkey
startkey_docid
endkey
endkey_docid
limit
stale
descending
skip
group
group_level
reduce
include_docs
inclusive_end
update_seq 
=end
end 
