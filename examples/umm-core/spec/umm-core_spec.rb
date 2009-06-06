# umm-core_spec.rb
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# "should" are requirements
# "may" are optional

describe "UMM Core" do
  describe "Main features" do
    it "should run as a service/daemon"
    it "should optionally run in the foreground with console logging for debugging"
    it "should not have a gui"
  end
  describe "Command Line Options" do
    it "should support command line option: -h|--help"
    it "should support command line option: -v|--version"
    it "should support command line option: -d|--daemon"
    it "should support command line option: --log [DEBUG|INFO|WARN|ERROR]"
    it "should support command line option: --logfile filespec"
  end
  describe "UPnP Server" do
    # ref: http://xbmc.org/forum/showthread.php?t=50926
    # XBMC uses: http://sourceforge.net/projects/platinum/
    # still under discussion
    it "may provide a UPnP server"
    it "may serve media"
    it "may serve media meta data"
  end
  describe "Web Service" do
    it "should have a documented and versioned web api"
    it "should support configuring the web service port"
    it "should support authentication to the web service"
    it "should support authentication to other services"
  end
  describe "Background Scanning" do
    it "should support background scanning"
    it "should support triggering on filesystem notifies on linux"
    it "should support periodic polling"
    it "should support setting the polling interval"
  end
  describe "Logging" do
    it "should support logging"
    it "should use syslog on linux systems"
    it "should use syslog on mac OS X systems"
    it "should use ? on windows systems"
    it "should use ? on XBox systems"
    it "should also log to console when ran in the foreground mode"
  end
  describe "Plug-ins" do
    it "should support plug-ins"
  end
  describe "Helper Applications" do
    it "should support running helper applications"
    it "should use image magick for image manipulation if image magick is installed"
    it "should return unchanged images if image magick is not installed"
  end
  describe "Databases" do
    it "should use database abstraction like ODBC"
    it "should have a well defined naming convention"
    it "may use an ORM abstraction layer"
    it "may support interfacing to the XBMC database"
    it "may use it's own database"
    it "may use XBMC's source.xml if source.xml is accessible"
  end
  describe "File Systems" do
    it "should support the same filesystems as XBMC"
    it "should support NFS NAS"
    it "should support CIFS NAS"
    it "should support legacy SMB NAS"
  end
  describe "Scrapers" do
    it "should support XBMC's scrapers"
    it "should support caching pages from the network"
    it "should support clearing the cache"
    it "should support expiring the cache"
    it "should support checking the cache using HTTP headers"
    it "should support selecting scraper by language (English, German, French,...)"
    it "may support additional scrapers"
    describe "Additional Scrapers" do
      it "may support DVD Profiler's exported collection.xml"
    end
  end
  describe "Contributing Back" do
    it "may allow contributing meta data to TheTVDB.com"
    it "may allow contributing meta data to TheMovieDB.com"
    it "may allow new submissions"
    it "may allow diff submissions"
    it "may allow user authentication with participating sites"
    it "may allow registering with participating sites"
  end
  describe "Cross Platform Support" do
    it "should run on linux (source distribution)"
    it "should run on linux (ubuntu distribution)"
    it "should run on Mac OS X 10.5+"
    it "should run on Windows XP"
    it "should run on Windows Vista"
    it "should run on Windows 7"
    it "should run on XBox (under discussion)"
    it "may run on other consoles (under discussion)"
    it "should OS dependent character sets (internationalization)"
    it "may support multiple languages"
  end
  describe "Media" do
    it "should read information from existing .nfo files"
    it "should be able to regognize changes in media folders and automatically update / create *.nfo files"
    it "should be able to recognize existing posters / covers / fanart"
    it "should be able to select what to scrape (info only, fanart only....)"
    it "should support file searching"
    it "should support movies"
    it "should support TV-Series"
    it "should support Music"
    it "may support Games (don't know if this makes sense yet cause XBMC doesn't support it yet)"
    describe "Media Organization" do
      it "should support single file medium"
      it "should support directory medium"
      it "should support a mixture of single file and directory media"
      it "should support media in sub-directories"
      it "should support media in multiple depth sub-directories"
      it "should support extracting media information from the medium files (MediaInfo library)"
      it "should be possible to set the desired scraping language for each folder/file" do
        # example: I've got one folder containing movies with english language, and another
        # one containing movies with german language. As XBMC doesn't support sorting movies
        # per language, I use to distinguish between them by the plot language. With the
        # existing media managers is a little lavish to do this
      end
      it "should support multiple media naming conventions"
      describe "Media Naming Conventions" do
      end
      describe "clean filenames" do
        # ref: http://xbmc.org/forum/showpost.php?p=333349&postcount=10
        it "should clean filenames before importing them into the database"
        it "should remove /\[.*?\]/"
        it "should remove /\{.*?\}/"
        it "may remove special characters reserved by the shell ($*?/\><)"
        it "should remove excessive spaces (/(\s+)/ => ' ')"
        it "should be able to detect and save the production year if it is given in the filename"
        it "should be able to detect and save the medium source (DVD,HD,BD) if it is given in the filename" do
          # ref: http://xbmc.org/forum/showthread.php?t=50915
        end
        it "should be able to detect and save the medium resolution (480i,480p,720i,720p,1080i,1080p) if it is given in the filename"
        it "should be able to detect and save the medium aspect (Normal, Widescreen, Anamorphic) if it is given in the filename"
        it "may copy the existing routines of xbmc"
      end
    end
    describe "Music Support" do
      it "should read MP3 Tags into a database"
      it "should be able to write / change MP3 Tags"
      it "should be able to extract covers from ID3 Tags and save them as folder icon"
      it "should be able to resize covers and save them in the ID3 Tag"
      it "should be able to download lyrics and save them in the ID3 Tag (ID3v2 supports lyrics. I don't know if xbmc supports embedded lyrics, or enough users need them to be worth the effort)"
      it "should be able to create a music brainz compatible Album Hash"
      it "should be able to get ID3 Tags from freedb.org"
      it "should be able to set a personal rating for mp3 files / albums"
      it "should support fanart"
      it "should support covers"
      it "may support karaoke"
    end
    describe "Movie Support" do
      it "should read File information (Codec, Bitrate, Resolution) into the database"
      it "should clean Filenames and use year tag for better search results"
      it "may use movie length for better search result"
      it "should fetch only a limited number of genres (limit is configurable)"
      it "should be able to generate thumbs from video files"
      it "should be able to set a personal rating for a movie"
      it "should support theMovieDB.com"
      it "should support imdb.com"
      it "should support fanart"
      it "should support covers"
    end
    describe "TV Show Support" do
      it "should read File information (Codec, Bitrate, Resolution) into the database"
      it "should be able to generate thumbs from video files"
      it "should be able to set a personal rating for a show / season / episode"
      it "should support theTVDB.com"
      it "should support fanart"
      it "should support covers"
    end
    describe "Music Videos" do
      # some help would be nice here as it's been two decades since I've watched a music video...
      it "should read File information (Codec, Bitrate, Resolution) into the database"
      it "should be able to generate thumbs from video files"
      it "should try to extract the Artist and Song from the filename"
      it "should enable the user to tell UMM his own naming rules to improve scraping results" do
        #  I use [Artist] - [Song] - [Year], others might use [Song].[Artist] etc
      end
      it "should support MTV.com" do
        # I think this is the site XBMC uses, have never used the Music video feature
      end
    end
    describe "Subtitles" do
      it "should be able to download subtitles"
      it "should be able to accept new subtitle sources"
      it "may allow upload subtitles to central database (sublight?)"
      it "may allow matching subtitles to video files (based hash, i.e. video fingerprinting) to central database (sublight?)"
    end
    describe "Fanart" do
      it "should support fanart"
      it "should support multiple fanart files per medium"
      it "should support multiple resolutions of fanart images"
      it "should support multiple fanart sites"
      it "should support user selectable fanart naming conventions"
    end
  end
end
