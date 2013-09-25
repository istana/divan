require_relative 'spec_helper'

describe Divan::Document do
	before :all do
		class Foo < Divan::Document; end
		@dburi = Divan::Support::Configuration.uri('admin')
		puts 'Database: ' + @dburi.inspect
		Typhoeus.delete(@dburi)
		res = Typhoeus.put(@dburi)
		raise('Problem creating database') if !res.success?
	end

	after :all do

		#HTTParty.delete Divan::Configuration.dbstring('dbadmin')
	end

	before :each do 
		@d = Divan::Document.new(foo: 'bar')
	end
	context 'Basics' do
		describe '.new' do
			it 'without "_id"' do
				d = Divan::Document.new(foo: 'bar')
				d._id.should be_nil
				d.foo.should == 'bar'
				d.type.should be_nil
				d.nonexistent.should be_nil
			end

			it 'with "_id"' do
				d = Divan::Document.new(_id: 'I luv myself', foo: 'bar')
				d._id.should == 'I luv myself'
				d.foo.should == 'bar'
				d.type.should be_nil
				d.nonexistent.should be_nil
			end

			context 'instantiated from Divan::Document (default)' do
				it 'should be instance of Divan::Document' do
					d = Divan::Document.new(foo: 'bar')
					d.should be_an_instance_of(Divan::Document)
				end
			end

			context 'instantiated from Foo' do
				subject {Foo.new(foo: 'bar')}
				it { should be_instance_of Foo }
				its(:type) { should == 'Foo' }
			end

			it 'tests more complex document' do
				d = Divan::Document.new(_id: 'how to fly',
																categories: ['Mountaineering', 'Telekinesis'],
																show: true,
																points: 38.2,
																snippets: {
																	Levitation: 'levitation howto',
																	'How to climb mount Everest' => 'bar'
																}
															 )
				d._id.should == 'how to fly'
				d.categories.should == ['Mountaineering', 'Telekinesis']
				d.show.should == true
				d.points.should == 38.2
				d.snippets.to_h.should == {
					Levitation: 'levitation howto',
					:'How to climb mount Everest' => 'bar'
				}
				d.snippets.Levitation.should == 'levitation howto'
				d.snippets.send(:'How to climb mount Everest').should == 'bar'
				d.nonexistent.should be_nil
			end

			it 'document is new' do
				Divan::Document.new(foo: 'bar').new?.should == true
			end

			it "document isn't deleted" do
				Divan::Document.new(foo: 'bar').deleted?.should == false
			end
		end

		it 'is possible to write fields' do
			d = Divan::Document.new(foo: 'bar')
			d.xxx = 'bla'
			d.xxx.should == 'bla'
			d.nonexistent.should be_nil

			d.ha = {my: 'love', moja: 'laska'}
			d.ha.to_h.should == {my: 'love', moja: 'laska'}
			d.ha.my.should == 'love'
			d.ha.moja.should == 'laska'
		end
	end

	context 'New document' do
		subject { Divan::Document.new(foo: 'bar') }

		describe '.save' do
			context 'without id - add UUID as "_id"' do
				subject do
					d =  Divan::Document.new(foo: 'bar')
					raise("Document couldn't be saved") if !d.save
					d
				end
				its(:_id) { should_not be_nil }
				its(:_rev) { should_not be_nil }
			end

			context 'with "_id"' do
				before :each do
					@d =  Divan::Document.new(_id: 'sneaky id', foo: 'bar')
					raise("Document couldn't be saved") if !@d.save
				end
				subject {@d}
				its(:_id) { should == 'sneaky id' }
				its(:_rev) { should_not be_nil }
			end
		end

		describe 'Revision' do
			its(:latest_revision) { should be_nil }
			it { should be_latest }
			it { subject.refresh_revision.should == false }
		end
	end

	context 'Saved document' do

	end

	context 'Saved document with old revision' do

	end


	describe 'Revisions' do

		context 'existing document' do
			before :each do
				@d.save
			end

			it '_rev is not nil' do
				@d._rev.should_not be_nil
			end

			it 'is latest' do
				@d.latest?.should == true
			end

			it 'latest revision is current revision' do
				@d.latest_revision.should == @d._rev
			end

			it 'refreshes the same revision' do
				@d.refresh_revision.should == @d._rev
			end
		end

		context 'document with old revision' do
			before :each do
				x = @d.save
				raise("Document couldn't be saved") if !x
				@d.test = 'bar'
				hash = @d.to_h
				res = Typhoeus.put(@dburi + '/' + hash.delete(:_id),
										 body: MultiJson.dump(hash),
										 params: {_rev: hash['_rev']}
										)
				raise("Error") if !res.success?
				@new_revision = MultiJson.load(res.body)['rev']
			end

			it '_rev is not nil' do
				@d._rev.should_not be_nil
			end

			it 'is latest' do
				@d.latest?.should == false
			end

			it 'latest revision is current revision' do
				@d.latest_revision.should == @new_revision
			end

			it 'refreshes the same revision' do
				@d.refresh_revision
				@d._rev.should == @new_revision
			end

			it 'throws conflict when saved' do
				expect { @d.save }.to raise_error(/conflict/)
			end
		end

	end
=begin
	it 'is possible to fetch document by id' do

		 doc = Divan::Document.new(_id: 'sneaky id', foo: 'bar')
		 doc.save.should == true
		 
		 d = Divan.byId('sneaky id')

	end

	it 'saves/fetch the document' do
		@doc.fields.should have_key('_rev')
		d = Divan::Document.fetch(@doc['_id'])
		d.type.should == 'Foo'
		d.should be_an_instance_of(Foo)
		d['foo'].should == 'bar'
		d.fields.should have_key('_rev')
	end

	# FUCK FUCK
	it 'checks design document name' do
		class FooDesign; end
		@doc.design.should == FooDesign
		Object.send :remove_const, :FooDesign

		doc2 = Divan::Document.neo({'foo' => 'bar', 'key' => [1,2]})
		doc2.design.should == Divan::Design
	end

	it 'checks design?' do
		@doc.design?.should == false
		# constant must be set, type not important
		FooDesign = 'Something'
		@doc.design?.should == true
		Object.send :remove_const, :FooDesign
	end

	it 'tests removal of document' do
		@doc.save.should == true
		d = @doc.destroy
		lambda { Divan::Document.fetch(d['_id']) }.should raise_exception(RuntimeError, /Document could not be fetched from CouchDB, status/)
	end

	## TODO: test deleted document in database

	it 'tests attachments' do
		@doc.attachments?.should == false
		@doc.attachments.should == {}

		lambda{@doc.attachment("nonexistent attachment")}.should raise_exception(RuntimeError, /Attachment doesn't exist/)

		@doc.add_attachment("attachment1", "This is attachment").should == true
		@doc.attachment("attachment1").should == "This is attachment"

		File.open("the_painter_insomnia_stock_small.jpg") do |img|
			@doc.add_attachment("the_painter.jpg", img, :mime => 'image/jpeg').should == true
		end
		File.open("after_soranamae_small.png") do |img|
			@doc.add_attachment("after.png", img, :mime => 'image/png').should == true
		end

		@doc.attachments.should == @doc['_attachments']

		@doc['_attachments']['the_painter.jpg']['content_type'].should == 'image/jpeg'
		@doc['_attachments']['the_painter.jpg']['length'].should == 145880

		@doc.delete_attachment('the_painter.jpg').should == true
		expect{@doc.attachment('the_painter.jpg')}.to raise_error(RuntimeError)

		@doc['_attachments'].should have_key('after.png')
		@doc['_attachments'].should have_key('attachment1')
		@doc['_attachments'].length.should == 2
	end

	it 'tests security' do
		@doc.save.should == true
		['', "\t", "\n\t  "].each do |str|
			# doc._id non-blank
			expect { @doc[str] }.to raise_error(ArgumentError)
			expect { @doc[str] = "I'm blank string"}.to raise_error(ArgumentError)
			expect { @doc.delete(str) }.to raise_error(ArgumentError)
			expect { @doc.attachment(str, "I'm blank string") }.to raise_error(ArgumentError)
			expect { @doc.add_attachment(str, "I'm blank string") }.to raise_error(ArgumentError)
			expect { @doc.delete_attachment(str, "I'm blank string") }.to raise_error(ArgumentError)
			# doc._id blank
			@doc['_id'] = str
			expect{ @doc.return_latest_revision }.to raise_error(ArgumentError)
			expect{ @doc.attachment("juhu") }.to raise_error(ArgumentError)
			expect{ @doc.add_attachment("attachment1", "This is attachment") }.to raise_error(ArgumentError)
			expect{ @doc.delete_attachment("some_attachment") }.to raise_error(ArgumentError)
		end
	end

	it 'tests uri escaping' do
		@doc['_id'] = "geralt. of/rivia"
		identifier = "/book/Richard A. Knaak/Kingdom of Shadow (2002).some_extension"

		@doc.save.should == true
		doc2 = Divan::Document.fetch(@doc['_id'])
		doc2['_id'].should == "geralt. of/rivia"

		@doc.add_attachment(identifier, "This is Sparta!")
		@doc.attachment(identifier).should == "This is Sparta!"
		@doc.delete_attachment(identifier).should == true
	end
=end
end
