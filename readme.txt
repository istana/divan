##### Implementation decisions

CouchDB returns JSON by default. It is nicely converted to Hash.

Divan::Document
- handled through method_missing. This is slow, but convenient. Can type doc.authors.[0].name.

doc.author.picture.thumb
doc['author']['picture'].thumb

# painfuuul
if doc && doc['author'] && doc['author']['picture']
...
end






This software is alpha and changing.

- For ruby 1.9
using define_singleton_method and require_relative
using securerandom

##### What works
Divan::Document works pretty well

##### Documentation
See specs or source

##### TODO
Document (simple) associations, pagination and security functions
Design document fuctionality and server side validations
Parallel connections 8/2012 - Typhoeus - currently unstable, faraday - unusable,
eventmachine or httparty in threads are probably best option


##### Changes
cca 20.08. 2012 Rewritten Divan::Document to be more document way - mapping attributes
to methods was removed and [], []= is used

##### Configuration

## dbreader
Defined per database. They can read all types of documents from
the DB, and they can write (and edit) documents to the DB except
for design documents.

## dbadmin
Defined per database. They have all the privileges readers have
plus the privileges: write (and edit) design documents,
add/remove database admins and readers, set the database revisions
limit (/somedb/_revs_limit API) and execute temporary views against
the database (/somedb/_temp_view API). They can not create a database
and neither delete a database. 


##### Document

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
  #
  # + option rev=34BD7C, which gets certain revision
  # save probably raise conflict
  # can't be used in views
  # Replication only replicates the last version of a document,
  # so it will be impossible to access, on the destination database,
  # previous versions of a document that was stored on the source database.
  # - open_revs is not supported
  
##### Attachments
Changes to document will be lost when attachment is added.
In very concurrent environment attachment can be lost before displaying.
