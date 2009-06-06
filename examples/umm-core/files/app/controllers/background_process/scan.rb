module BackgroundProcess
  class Scan
    def initialize(command)
      @command = command
    end
    
    def run
      unless @command.parameter.nil?
        @command.parameter.split(',').each do |source_name|
          source = Source.first(:name => source_name)
          unless source.nil? || source.paths.blank?
            source.paths.each do |path|
              begin
                Merb.logger.info { 'Source => ' + source.to_s}
                scan_path(source.name, path.mount)
              rescue Exception => e
                Merb.logger.error {e}
                Merb.logger.error {e.backtrace.join("\n")}
                raise e
              end
            end
          end
        end
      end
    end
    
    protected
    
    def scan_path(source_name, pathspec)
      Dir.chdir(pathspec) do
        cnt = 0
        Dir.glob("**/*.m4v").each do |media_filespec|
          cnt += 1
          media_pathspec = pathspec / File.dirname(media_filespec)
          media_filename = File.basename(media_filespec)
          filespec = Filespec.first(:pathspec => media_pathspec, :filename => media_filename)
          if filespec.nil?
            filespec = Filespec.create(:pathspec => media_pathspec, :filename => media_filename)
            filespec.save
          end
          @command.status = "Scanning Source: #{source_name}, media files: #{cnt}"
          @command.save
        end
        cnt = 0
        Dir.glob("**/*.nfo").each do |nfo_filespec|
          cnt += 1
          nfo = XbmcInfo.new(nfo_filespec)
          unless nfo.nil?
            Merb.logger.info {"***** Title => #{nfo.movie.inspect}"}
            english_language ||= Language.first(:label => 'English') || Language.create(:label => 'English')
            begin
              media_object = MediaObject.create
              media_object << {:exact_title     => nfo.movie['title']}
              media_object << {:ratings         => nfo.movie['rating'], :name => 'NFO'}
              media_object << {:certifications  => nfo.movie['mpaa'], :body => 'MPAA'}
              media_object << {:identifications => nfo.movie['isbn'], :name => 'ISBN'}
              media_object << {:identifications => nfo.movie['id'], :name => 'IMDB'}
              media_object << {:years           => nfo.movie['year']}
              media_object << {:genres          => nfo.movie['genre']}
              media_object << {:plots           => nfo.movie['plot']}
              media_object << {:taglines        => nfo.movie['tagline']}

              runtime_seconds = (nfo.movie['runtime'].first.to_i * 60.0).to_i
              media_object << {:runtimes        => [runtime_seconds]}

              # nfo.movie['director'] => ["director name",...]
              nfo.movie['director'].each do |directors|
                directors.each do |director_name|
                  media_object << {:directors => director_name}
                end
              end
            
              nfo.movie['actor'].each do |description|
                media_object << {:actor => description['name'], :character => description['role']}
              end
              raise SaveException.new(media_object, "Error saving media_object in Scan.scan_path") unless media_object.save
            rescue Exception => e
              Merb.logger.error{"***** Error: " + e.to_s}
            end
          end
          @command.status = "Scanning Source: #{source_name}, nfo files: #{cnt}"
          @command.save
        end
      end
    end
    
  end
  
end
