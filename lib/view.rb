class Divan

	class View
		def database
			Divan::Support::Configuration.uri
		end
		
		
  
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
  format :json
  base_uri Divan::Configuration.dbstring
  
  def self.fetch(design, view, options)
    view_docs = ::Typhoeus.get(database + '/_design/' + uri_encode(design) + '/_view/' + uri_encode(view), params: options)
    
    if view_docs.success?
    	::MultiJson.load(view_docs.body)
    else
    	raise("Error getting view #{view} from design #{design}")
    end
  end
  
  def self.fetch_mapped(*args)
  	result = fetch(args)
  	result.map {|doc| Document.new(doc) }
  end
  
  	def initialize(request, options = {})
		@documents = []
		@metadata = OpenStruct.new
		@docmap = options[:docmap] || true
	
		for document in request.delete['rows']
			if @docmap
				@documents << ::Divan::Document.new(document)
			else
				@documents << document
			end
		end
# TODO slice (whitelist metadata in request)
		request.each_pair do |meta, data|
			@metadata.meta = data
		end
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
end