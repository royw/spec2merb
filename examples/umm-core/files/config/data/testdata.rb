
movies_dir = File.expand_path(File.dirname(__FILE__) / '../../data/movies')
read_url = URI.parse('file:/' + movies_dir)
publish_url = URI.join('nfs://umm-core', 'media/movies')
path = Path.create(:read_url => read_url.to_s, :publish_url => publish_url.to_s, :mount => movies_dir)

source = Source.create(:name => 'Movies')
source.paths << path
source.save


