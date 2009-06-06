# umm-core-db-schema_spec.rb

# there are some constraints in how these specs are written to be able
# to work with the spec2gen script for generating a merb project directly
# from this spec.
#
# First the string passed to describe must end in " Model" to define a model,
# example:  describe("AiredDate Model") do
#
# Second when specing the properties the 'it' property should have the
# following format:
#   it "should have a ... variable_name [SQL_DATA_TYPE;MODIFER]
# where:
#   the variable_name should be singular
#   the SQL_DATA_TYPE is a standard SQL data type such as CHAR(40), TEXT, TINYINT, ...
#   The seperator between the SQL_DATA_TYPE and any modifiers can not be:
#     a whitespace, a colon, a comma, a single or double quote.  I recommend
#     using a vertical bar '|'.
#   each MODIFIER is a key value pair with a format of key=value.  No spaces
#     are allowed.  Supported keys are:  index, key, length, minimum, maximum
#     nullable, format, default.  Note that if you assign a proc block to
#     default it must not have any whitespace.
#
# Third when specing relationships the 'it' spec should have the following
# format:
#   it "should have a relationship ... variable_name [REL CARDINALITY MODEL]
# where:
#   the variable_name should be either singular or plural appropriate to the
#     the relationship (has 1 should be singular, has 0:n should be plural)
#   the REL is either 'has' or 'belongs_to'.
#   the CARDINALITY can be:  1, n, 1:3, 0:n
#   The MODEL is the model that the relationship is with.
#
# Forth any other 'it' spec will be placed as a comment in the model.

# This is a stub used to attach information about a model to the spec.
def synopsis(*args)
end

# NOTES
# * NVARCHAR should be used for fields that can contain non-english content.
# * Database should be configured for Unicode
describe("UMM Core Database Schema") do
  # the following describe blocks are organized for models/tables

  describe("AiredDate Model") do
    synopsis("This is when the media was first aired and is primarily for TV shows.")
    # attributes
    it "should have a 'when' date [DATETIME]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("AudioType Model") do
    synopsis("This encapsulates the media's audio type, such as AC5, DTS, Dolby...")
    # attributes
    it "should have a name (AC5, DTS, Dolby, Dolby Digital, PCM,...) [[NVARCHAR(20)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Certification Model") do
    synopsis("This describes a certification by some organization, for example PG-13 by the MPAA.")
    # attributes
    it "should have a value [NVARCHAR(20)]"
    it "should have a body [NVARCHAR(40)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Character Model") do
    synopsis("This is the name of a character in the media, for example the character",
             "\"George Washington McLintock\" in the movie \"McLintock!\" played by",
             "\"John Wayne\"")
    # attributes
    it "should have a name [NVARCHAR(60)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    it "should have a relationship of zero or more people [has 0:n Person]"
  end

  describe("Command Model") do
    synopsis("This model is used to run commands on the core such as scanning or scraping.")
    # attributes
    it "should have a name [NVARCHAR(60)|UNIQUE]"
    it "should have a watchdog_timeout (seconds, 0 for unlimited timeout) [INT]"
    it "should have a schedule (now, @02:00, every 30 minutes,...) [TEXT]"
    it "should have a background process (scan, scrape, db backup,...) [NVARCHAR(60)]"
    it "should have a string parameter (which source,...) [TEXT]"
    it "should have a status (scheduled, running 22% complete, finished, error...) [TEXT]"
    it "should have a started_at [DATETIME|NULL=true]"
    it "should have a finished_at [DATETIME|NULL=true]"
    # relationships
    # other
    describe("Scan Command") do
      it "should require one or more Source.name in the parameter field"
      it "should require a parameter format string of:  'Source.name{,Source.name{,...}}'"
    end
    describe("Scrape Command") do
      it "should require one or more Scraper.name in the parameter field"
      it "should require one or more Source.name in the parameter field"
      it "should require a parameter format string of:  'Scraper.name{,Scraper.name{,...}}|Source.name{,Source.name{,...}}'"
    end
    describe("DB Backup Command") do
      it "should require a filespec to the backup destination in the parameter field"
      it "should require a parameter format string of:  '/path/to/backup/file'"
    end
  end

  describe("Filespec Model") do
    synopsis("This model holds a path and filename, one of which may be empty or null.")
    # attributes
    it "should have an relative pathspec [TEXT]"
    it "should have a filename [NVARCHAR(256)]"
    # relationships
    it "should have a relationship of multiple images [has n Image]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    it "should have a relationship to a path [has 1 Path]"
    it "should have a relationship of multiple subtitles [has n Subtitle]"
    it "should have a relationship of multiple trailers [has n Trailer]"

    it "should return a relative pathspec given a source pathspec"
  end

  describe("Genre Model") do
    synopsis("This model holds genre names, for example: Comedy, Action,...")
    # attributes
    it "should have a name (Comedy, Action, Drama,...) [NVARCHAR(30)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end
  
  describe("Identification Model") do
    synopsis("This model holds any identifications such as IMDB ID, TheMoveDB ID, ISBN,...")
    it "should have a name (IMDB, TheMovieDB, ISBN) [NVARCHAR(40)]"
    it "should have a value (the ID as a string) [NVARCHAR(60)]"
    
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Image Model") do
    synopsis("This model encapulates the information about an image.")
    # attributes
    it "should have a name [NVARCHAR(40)]"
    it "should have a pixel width [SMALLINT|MIN=0]"
    it "should have a pixel height [SMALLINT|MIN=0]"
    it "should have a color_depth (number of bits) [TINYINT|MIN=1|MAX=32]"
    # relationships
    it "should have a relationship to a filespec [has 1 Filespec]"
    it "should have a relationship of one or more image_types [has 1:n ImageType]"
    it "should have a relationship of zero or one languages [has 0:n Language]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    it "should have a relationship of zero or more people [has 0:n Person]"
  end

  describe("ImageType Model") do
    synopsis("This model describes the type of an image, for example: Thumbnail, Cover,...")
    # attributes
    it "should have a name (Thumbnail, Cover, Poster, Fanart) [NVARCHAR(20)]"
    it "should have a description [TEXT]"
    # relationships
    it "should have a relationship of zero or more images [has 0:n Image]"
    it "should have a relationship to one language [has 1 Language]"
    it "should have a relationship of zero or more trailers [has 0:n Trailer]"
  end

  describe("Language Model") do
    synopsis("This model holds a languange name such as: English, Deutsch,...")
    # attributes
    it "should have a label [NVARCHAR(40)]" do
      # The label should be in the language that it describes: English, Deutch, ...
      # A special label of 'ALL' should match any language
    end
    # relationships
    it "should have a relationship of zero or more images [has 0:n Image]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    it "should have a relationship of multiple reviews [has n Review]"
    it "should have a relationship of multiple scrapers [has n Scraper]"
    it "should have a relationship of multiple subtitles [has n Subtitle]"
    it "should have a relationship of multiple titles [has n Title]"
  end

  describe("MediaObject Model") do
    synopsis("This model binds all the parts for a single media such as a movie, song,...")
    # attributes
    # relationships
    # encapsulates a medium such as a movie, tv show, song, etc.
    it "should have a relationship of zero or more aired_dates [has 0:n AiredDate]"
    it "should have a relationship of zero or more audio_types [has 0:n AudioType]"
    it "should have a relationship of zero or more certifications [has 0:n Certification]"
    it "should have a relationship of zero or more characters [has 0:n Character]"
    it "should have a relationship of one or more filespecs (*.cd1.*,*.cd2.*) [has 1:n Filespec]"
    it "should have a relationship of zero or more genres [has 0:n Genre]"
    it "should have a relationship of zero or more identifications [has 0:n Identification]"
    it "should have a relationship of zero or more images [has 0:n Images]"
    it "should have a relationship of zero or more languages [has 0:n Language]"
    it "should have a relationship of one or more media_types [has 1:n MediaType]"
    it "should have a relationship of zero or more people [has 0:n Person]"
    it "should have a relationship of zero or more plots [has 0:n Plot]"
    it "should have a relationship of zero or more production_years [has 0:n ProductionYear]"
    it "should have a relationship of zero or more ratings [has 0:n Rating]"
    it "should have a relationship of zero or more released_years [has 0:n ReleasedYear]"
    it "should have a relationship of zero or more reviews [has 0:n Review]"
    it "should have a relationship of zero or one runtimes [has 0:n Runtime]"
    it "should have a relationship of zero or more scrapers [has 0:n Scraper]"
    it "should have a relationship of zero or more source_types [has 0:n SourceType]"
    it "should have a relationship of zero or more subtitles [has 0:n Subtitle]"
    it "should have a relationship of zero or more taglines [has 0:n Tagline]"
    # it "should have a relationship of one or more titles (primary title is the first item in the list) [has 1:n Title via MediaObjectTitle]"
    it "should have a relationship of one or more titles (primary title is the first item in the list) [has n Title]"
    it "should have a relationship of zero or more trailers [has 0:n Trailer]"
    it "should have a relationship of zero or more viewed_dates [has 0:n ViewedDate]"
    it "should have a relationship of zero or one primary years [has 0:n Year]"
    # other
    it "should have return the first title as the primary_title"
    it "should allow selecting one of the titles to be the primary_title"
  end
  
  # describe("MediaObjectTitle Model") do
  #   synopsis("This is a join table between MediaObject and Title that supports the title being a list")
  #   it "should have a relationship of one media_object [has 1 MediaObject]"
  #   it "should have a relationship of one title [has 1 Title]"
  #   it "should declare a list of the title [list]"
  # end

  describe("MediaType Model") do
    synopsis("This model holds the media type such as movie, tv show, game,...")
    # attributes
    it "should have a name (movie, tv show, audio, karaoke, game,...) [NVARCHAR(20)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Name Model") do
    synopsis("This is the name for an object.")
    # attributes
    it "should have a value [TEXT]"
    # relationships
    it "should have a relationship of multiple audio_types [has n AudioType]"
    it "should have a relationship of multiple characters [has n Character]"
    it "should have a relationship of multiple genres [has n Genre]"
    it "should have a relationship of zero or more images [has 0:n Image]"
    it "should have a relationship of multiple image_types [has n ImageType]"
    it "should have a relationship to one language [has 1 Language]"
    it "should have a relationship of multiple media_types [has n MediaType]"
    it "should have a relationship of multiple sources [has n Source]"
    it "should have a relationship of multiple ratings [has n Rating]"
    it "should have a relationship of multiple roles [has n Role]"
    it "should have a relationship of zero or more scrapers [has 0:n Scraper]"
    it "should have a relationship of multiple source_types [has n SourceType]"
    it "should have a relationship of zero or more trailers [has 0:n Trailer]"
  end

  describe("Path Model") do
    synopsis("Fully described path located either remotely or locally")
    # attributes
    it "should have a read_url (where the files are located) [TEXT]"
    it "should have a publish_url (where we say the files are located) [TEXT]"
    it "should have a local mount (where we access the files) [TEXT]"
    # relationships
  end

  describe("Person Model") do
    synopsis("This model describes a person who participated in a media, ",
             "such as a director or actor")
    # attributes
    it "should have a name [NVARCHAR(40)]"
    # relationships
    it "should have a relationship of zero or more characters [has 0:n Character]"
    it "should have a relationship of zero or more images [has 0:n Image]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    it "should have a relationship of one or more roles [has 1:n Role]"
    # other
  end

  describe("Plot Model") do
    synopsis("This model binds a plot description to media.")
    # attributes
    it "should have a description [TEXT]"
    # relationships
    it "should have a relationship to one language [has 1 Language]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("ProductionYear Model") do
    synopsis("This model contains a year that a media was produced in.",
             "Note that a media may have multiple production years.")
    # attributes
    it "should have a value [SMALLINT]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Rating Model") do
    synopsis("This model holds the rating for a media.  This allows mulitiple",
             "rating sources, such as mine, my wife's, IMDB,...")
    # attributes
    it "should have a value [NVARCHAR(20)]"
    it "should have a name (Mine, Wifes, IMDB,...) [NVARCHAR(30)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("ReleasedYear Model") do
    synopsis("This model contains a year that a media was released in.",
             "Note that a media may have multiple released years.")
    # attributes
    it "should have a value [SMALLINT]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Review Model") do
    synopsis("This model encapsulates a media review.  The review may be either stored",
             "in the model or just a URL to the review, or both.")
    # attributes
    it "should have a url [TEXT]"
    it "should have a write_up [TEXT]"
    # relationships
    it "should have a relationship to one language [has 1 Language]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    # other
    it "should have a non-empty url or a non-empty write_up"
  end

  describe("Role Model") do
    synopsis("This model holds a person's role in a media, such as: actor, directory,...")
    # attributes
    it "should have a name (actor, director, writer) [NVARCHAR(30)]"
    # relationships
    it "should have a relationship of zero or more people [has 0:n Person]"
  end

  describe("Runtime Model") do
    synopsis("This model holds a media's runtime in seconds.")
    # attributes
    it "should have a runtime in seconds [SMALLINT]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Scraper Model") do
    synopsis("This model describes a scraper.")
    # attributes
    it "should have a name (TheMovieDB, IMDB,...) [NVARCHAR(30)]"
    # relationships
    it "should have a relationship to one language [has 1 Language]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
    # other
    it "should have whatever is needed to hook to the corresponding scraper"
  end

  describe("Source Model") do
    synopsis("This model binds a name to one or more media sources.")
    # attributes
    it "should have a name (MyMovies, 60sRock,...) [NVARCHAR(30)]"
    # relationships
    it "should have a relationship of zero or more paths [has 0:n Path]"
  end
  
  describe("SourceType Model") do
    synopsis("This model describes where a media file originated, such as: CD, DVD, BD,...")
    # attributes
    it "should have a name (CD, DVD, LD, HD, BD,...) [NVARCHAR(20)]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Subtitle Model") do
    synopsis("This model binds the information about an audio subtitle file and language.")
    # attributes
    # relationships
    it "should have a relationship to a filespec [has 1 Filespec]"
    it "should have a relationship to a language [has 1 Language]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Tagline Model") do
    synopsis("This model holds a short description of a media.")
    # attributes
    it "should have a description [TEXT]"
    # relationships
    it "should have a relationship to one language [has 1 Language]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Title Model") do
    synopsis("This model holds both the exact title and the match title for a media ",
             "for a language.")
    # attributes
    it "should have a exact_title [TEXT]"
    it "should have a match_title [TEXT]"
    # relationships
    it "should have a relationship to one language [has 1 Language]"
    # it "should have a relationship of zero or more media_objects [has 0:n MediaObject via MediaObjectTitle]"
    it "should have a relationship of zero or one media_object [has 1 MediaObject]"
    it "should declare a list of the media_object [list]"
  end

  describe("Trailer Model") do
    synopsis("This model encapsulates the information about a trailer for a media.")
    # attributes
    it "should have a pixel width [SMALLINT|MIN=0]"
    it "should have a pixel height [SMALLINT|MIN=0]"
    it "should have a color_depth (number of bits) [TINYINT|MIN=1|MAX=32]"
    it "should have a name [NVARCHAR(60)]"
    # relationships
    it "should have a relationship to a filespec [has 1 Filespec]"
    it "should have a relationship of one or more image_types [has 1:n ImageType]"
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("ViewedDate Model") do
    synopsis("This model holds when a media was last played.")
    # attributes
    it "should have a when [DATETIME]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

  describe("Year Model") do
    synopsis("This model holds the year of a media.  This year should be the last year ",
             "of production.")
    # attributes
    it "should have a value [SMALLINT]"
    # relationships
    it "should have a relationship of zero or more media_objects [has 0:n MediaObject]"
  end

end

