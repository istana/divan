require './spec_helper' 

describe Divan::Document do
	before :all do
		class Foo < Divan::Document; end
		dburi = Divan::Support::Configuration.uri('admin')
		puts 'Database: ' + dburi.inspect
		Typhoeus.delete(dburi)
		res = Typhoeus.put(dburi)
		raise('Problem creating database') if !res.success?
	end

	after :all do
		#HTTParty.delete Divan::Configuration.dbstring('dbadmin')
	end

	describe 'New document' do
		context 'without type class' do
			it 'should be instance of Divan::Document' do
				d = Divan::Document.new(foo: 'bar')
				d.should be_an_instance_of(Divan::Document)
			end

			it 'creates new document without _id' do
				d = Divan::Document.new(foo: 'bar')
				d._id.should be_nil
				d.foo.should == 'bar'
				d.type.should be_nil
				d.nonexistent.should be_nil
			end

			it 'creates new document with _id' do
				d = Divan::Document.new(_id: 'I luv myself', foo: 'bar')
				d._id.should == 'I luv myself'
				d.foo.should == 'bar'
				d.type.should be_nil
				d.nonexistent.should be_nil
			end
		end
		
		context 'spawned from non-default class' do
			it 'should be instance of class' do
				d = Foo.new(foo: 'bar')
				d.should be_an_instance_of(Foo)
			end

			it 'creates new document without _id' do
				d = Foo.new(foo: 'bar')
				d._id.should be_nil
				d.foo.should == 'bar'
				d.type.should == 'Foo'
				d.nonexistent.should be_nil
			end

			it 'creates new document with _id' do
				d = Foo.new(_id: 'I luv myself', foo: 'bar')
				d._id.should == 'I luv myself'
				d.foo.should == 'bar'
				d.type.should == 'Foo'
				d.nonexistent.should == nil
			end
		end

		it 'creates more complex document' do
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

		it 'is new' do
			Divan::Document.new(foo: 'bar').new?.should == true
		end

		it "isn't deleted" do
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

	describe 'save document' do
		context 'new document' do
			it 'without id' do
				d = Divan::Document.new(foo: 'bar')
				d.save.should == true
				d._id.should_not be_nil
				d._rev.should_not be_nil
			end

			it 'with id' do
				d = Divan::Document.new(_id: 'sneaky id', foo: 'bar')
				d.save.should == true
				d._id.should == 'sneaky id'
				d._rev.should_not be_nil
			end
		end

		context 'existing document' do

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

	it 'tests revisions' do
		@doc.latest?.should == true
		@doc.return_latest_revision.should == false

		@doc.save.should == true
		# saved with another way, newer revision
		result = @doc.class.put('/' + @doc['_id'], :body => MultiJson.dump(@doc.fields), :query => {:_rev => @doc['_rev']})
		result.success?.should == true
		newer_revision = result.parsed_response['rev']

		@doc.latest?.should == false
		@doc['_rev'].should_not == newer_revision
		@doc.return_latest_revision.should == newer_revision

		@doc.refresh_revision
		@doc['_rev'].should == newer_revision
	end

	it 'tests conflict' do
		# save to database
		@doc.save.should == true
		# change revision +1
		result = @doc.class.put('/'+@doc['_id'], :body => MultiJson.dump(@doc.fields), :query => {:_rev => @doc['_rev']})
		result.success?.should == true
		# save with old revision
		expect{@doc.save}.to raise_error(RuntimeError, 'Document conflict!')
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
