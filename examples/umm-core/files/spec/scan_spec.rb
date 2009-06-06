require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe("Scan") do
  before(:each) do
    DataMapper.auto_migrate!
    
    movies_dir = File.expand_path(File.dirname(__FILE__) / '../data/movies')
    read_url = URI.parse('file:/' + movies_dir)
    publish_url = URI.join('nfs://umm-core', 'media/movies')
    path = Path.create(:read_url => read_url.to_s, :publish_url => publish_url.to_s, :mount => movies_dir)
    
    source = Source.create(:name => 'Movies')
    source.paths << path
    source.save
    
    @cmd = Command.create(:process => 'Scan', :name => 'testing', :parameter => 'Movies')
  end
  
  it "should scan the nfo files in the data/movies directory" do
    @cmd.started_at = DateTime.now
    @cmd.finished_at = nil
    @cmd.status = 'Running'
    @cmd.save
    process = BackgroundProcess::Scan.new(@cmd)
    process.run
    
    titles = [
      Title.first(:exact_title => 'Bewitched'),
      Title.first(:exact_title => 'Click'),
      Title.first(:exact_title => 'Big Daddy')
    ]
    titles.each {|title| title.should_not be_nil}
    
    medias = titles.collect{|title| title.media_object}
    medias.each {|media| media.should_not be_nil}
    
    debugger
    
    medias[0].identifications.length.should == 2
    medias[1].identifications.length.should == 2
    medias[2].identifications.length.should == 2
    
    medias[0].identifications.first(:name => 'ISBN').value.should == "043396102101"
    medias[0].identifications.first(:name => 'IMDB').value.should == "tt0374536"
    medias[1].identifications.first(:name => 'ISBN').value.should == "043396148383"
    medias[1].identifications.first(:name => 'IMDB').value.should == "tt0389860"
    medias[2].identifications.first(:name => 'ISBN').value.should == "043396039223"
    medias[2].identifications.first(:name => 'IMDB').value.should == "tt0142342"
  end
  
end
