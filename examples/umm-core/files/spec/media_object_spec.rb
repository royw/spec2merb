require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe("MediaObject") do
  describe("adding associations") do
    before(:each) do
      DataMapper.auto_migrate!
      @media_object = MediaObject.create
    end
    it "should allow appending single title" do
      @media_object.titles.length.should == 0
      @media_object << {:exact_title => 'Hitch'}
      @media_object.save.should be_true
      @media_object.titles.length.should == 1
      @media_object.titles.first.exact_title.should == 'Hitch'
    end
    it "should allow appending mulitiple titles" do
      @media_object.titles.length.should == 0
      @media_object << {:exact_title => ['Hitch', 'Bewitched']}
      @media_object.save.should be_true
      @media_object.titles.length.should == 2
      @media_object.titles.first(:exact_title => 'Hitch').should_not be_nil
      @media_object.titles.first(:exact_title => 'Bewitched').should_not be_nil
      t1 = Title.first(:exact_title => 'Hitch')
      t1.should_not be_nil
      t2 = Title.first(:exact_title => 'Bewitched')
      t2.should_not be_nil
      t1.media_object.should_not be_nil
      t1.media_object.id.should == @media_object.id
      t2.media_object.should_not be_nil
      t2.media_object.id.should == @media_object.id
    end
    it "should allow appending objects with extra attributes" do
      @media_object.identifications.length.should == 0
      @media_object << {:identifications => ['1234567890'], :name => 'ISBN'}
      @media_object << {:identifications => ['tt01234567'], :name => 'IMDB'}
      @media_object.save.should be_true
      @media_object.identifications.length.should == 2
      @media_object.identifications.first(:value => '1234567890').should_not be_nil
      @media_object.identifications.first(:value => 'tt01234567').should_not be_nil
      id1 = Identification.first(:name => 'ISBN', :value => '1234567890')
      id1.should_not be_nil
      id2 = Identification.first(:name => 'IMDB', :value => 'tt01234567')
      id2.should_not be_nil
      id1.media_objects.first(:id => @media_object.id).should_not be_nil
      id2.media_objects.first(:id => @media_object.id).should_not be_nil
    end
    
    it "should allow appending mulitiple directors" do
      @media_object.identifications.length.should == 0
      Role.all.length.should == 0
      @media_object << {:directors => ['Joe Bob', 'Billy Bob', 'Earl Bob', 'Bob']}
      @media_object.save.should be_true
      Role.all(:name => 'Director').length.should == 1
      director_role = Role.first(:name => 'Director')
      director_role.people.length.should == 4
      p1 = Person.first(:name => 'Joe Bob')
      p1.should_not be_nil
      p1.roles.first(:name => 'Director').should_not be_nil
    end
    
    it "should allow appending multiple actors" do
      @media_object.identifications.length.should == 0
      Role.all.length.should == 0
      @media_object << {:actor => 'Joe Ray', :character => 'JR'}
      @media_object << {:actor => 'Billy Ray', :character => 'BR'}
      @media_object << {:actor => 'Earl Ray', :character => 'ER'}
      @media_object.save.should be_true

      Role.all(:name => 'Actor').length.should == 1
      actor_role = Role.first(:name => 'Actor')
      actor_role.people.length.should == 3
      p1 = Person.first(:name => 'Joe Ray')
      p1.should_not be_nil
      p1.roles.first(:name => 'Actor').should_not be_nil
    end
  end
end

