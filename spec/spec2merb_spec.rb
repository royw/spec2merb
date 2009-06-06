# umm-core_spec.rb
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

require 'spec2merb'
require 'fileutils'

TMPDIR = File.dirname(__FILE__) / '..' / 'tmp'
mkdir_p TMPDIR

# "should" are requirements
# "may" are optional

describe "spec2merb" do
  describe "ModelEditor" do
    BASE_MODEL = <<END_BASE_MODEL
class TestModel
  include DataMapper::Resource
  property id, serial
end
END_BASE_MODEL

    CLASS_COMMENT_MODEL = <<END_CLASS_COMMENT_MODEL
# This is a test model.
class TestModel
  include DataMapper::Resource
  property id, serial
end
END_CLASS_COMMENT_MODEL

    RELATIONSHIP_MODEL = <<END_RELATIONSHIP_MODEL
class TestModel
  include DataMapper::Resource
  property id, serial
  has n, :foobars
end
END_RELATIONSHIP_MODEL
    
    before(:each) do
      tf = Tempfile.new('test_model', TMPDIR)
      @tempfile = tf.path + '.rb'
      tf.unlink
      File.open(@tempfile, 'w') { |file| file.puts BASE_MODEL }
      @editor = ModelEditor.new(@tempfile)
    end

    it "should insert comment before class" do
      @editor.insert(Spec2Merb::BEFORE_CLASS, '# This is a test model.')
      IO.read(@tempfile).should == CLASS_COMMENT_MODEL
    end
    
    it "should insert relationship after properties" do
      @editor.insert(Spec2Merb::AFTER_PROPERTIES, '  has n, :foobars')
      IO.read(@tempfile).should == RELATIONSHIP_MODEL
    end
  end
  
  describe 'Spec2Merb' do
    LIST_TEST_SPEC =<<END_LIST_TEST_SPEC
describe('test') do
  describe('Foo Model') do
    it "should have a relationship of one or more bars (primary bar is the first item in the list) [has 1:n Bar via BarFoo]"
  end
  describe('Bar Model') do
    it "should have a name [CHAR(40)]"
    it "should have a relationship of zero or more foos [has 0:n Foo via BarFoo]"
  end
  describe('BarFoo Model') do
    it "should reference foo [belongs_to Foo]"
    it "should have a relationship of one bar [has 1 Bar]"
    it "should declare a list of the foo [list]"
  end
end
END_LIST_TEST_SPEC

    it "should generate has n relationships"
    it "should generate has 1..n relationships"

    describe "for list 0..n relationships" do
      before(:all) do
        if @app.nil?
          @app = Spec2Merb.new('list_test')
          @app.generate(LIST_TEST_SPEC)
          @foo_rb = IO.read('list_test/app/models/foo.rb')
          @bar_rb = IO.read('list_test/app/models/bar.rb')
          @bar_foo_rb = IO.read('list_test/app/models/bar_foo.rb')
        end
      end

      # Foo model"
      it "should generate the foo.rb model file" do
        @foo_rb.should_not be_nil
      end
      it "should generate a has many through relationship for the Foo model" do
        @foo_rb.should =~ /has 1\.\.n, \:bars, \:through => \:bar_foos/
      end
      it "should generate the join table relationship for the Foo model" do
        @foo_rb.should =~ /has n, \:bar_foos/
      end
        
      # Bar model
      it "should generate the bar.rb model file" do
        @bar_rb.should_not be_nil
      end
      it "should generate a has many through relationship for the Bar model" do
        @bar_rb.should =~ /has 0\.\.n, \:foos, \:through => \:bar_foos/
      end
      it "should generate the join table relationship for the Bar model" do
        @bar_rb.should =~ /has n, \:bar_foos/
      end
      it "should generate the name property for the Bar model" do
        @bar_rb.should =~ /property \:name, String, \:length => 40/
      end

      # the join table BarFoo model
      it "should generate the bar_foo.rb join model file" do
        @bar_foo_rb.should_not be_nil
      end
      it "should generate a belongs_to :foo for the BarFoo model" do
        @bar_foo_rb.should =~ /belongs_to \:foo[^s]/
      end
      it "should generate a belongs_to :bar for the BarFoo model" do
        @bar_foo_rb.should =~ /belongs_to \:bar[^s]/
      end
      it "should generate a is list for the BarFoo model" do
        @bar_foo_rb.should =~ /is \:list, \:scope => \[\:foo_id\]/
      end
    end
    
  end
end
