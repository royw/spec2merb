#web-api_spec.rb
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# "should" are requirements
# "may" are optional
# note, medium is singular of media
# Resources are named using plurals.  The corresponding
# data models are named using the singular.

describe "Web API" do
  it "should provide a documented Web API"
  describe "CRUD Commands" do
    describe "CRUD" do
      it "should return an index of items" do
        # example:
        # curl -X GET -H 'Accept: application/xml' http://localhost:4000/items
      end
      it "should return a single item" do
        # example:
        # curl -X GET -H 'Accept: application/xml' http://localhost:4000/items/15
      end
      it "should modify an existing item " do
        # example:
        # curl -i -X PUT -H 'Content-Type: application/xml' -H 'Accept: application/xml' \
        # -d '<item><path>/foo/bar</path></item>' http://localhost:4000/items/15
      end
      it "should delete an existing item" do
        # example:
        # curl -X DELETE -H 'Accept: application/xml' http://localhost:4000/items/15
      end
      it "should create a new item" do
        # example:
        # curl -i -X POST -H 'Content-Type: application/xml' -H 'Accept: application/xml' \
        # -d '<item><path>/foo/bar</path></item>' http://localhost:4000/items/
      end
    end

    # these are the CRUD resources.  They each need to inherit
    # the requirements in the "CRUD" block above.
    it "should have Sources CRUD routes"
    it "should have Media CRUD routes"
    it "should have Scrapers CRUD routes"
    it "should have Genres CRUD routes"
    it "should have Actors CRUD routes"
    it "should have Icons CRUD routes"
    it "should have Covers CRUD routes"
    it "should have Posters CRUD routes"
    it "should have Fanarts CRUD routes"
    it "should have Trailers CRUD routes"
    it "should have Reviews CRUD routes"
    it "should have Subtitles CRUD routes"
    it "should have Web_Databases CRUD routes"
    it "should have Schedules CRUD routes"

    # special processing actions are controlled by modifying
    # attributes in the resources
    it "should start a background scan of all medias in a source by Sources edit"
    it "should allow enabling a scraper by Scraper edit"
    it "should allow disabling a scraper by Scraper edit"
    it "should allow registering with the web database by Web_Databases edit"
    it "should allow sending diffs to a web database by Media edit"

    # specify acceptable resource route nesting
    # NOTE these are very rough and are meant to start discussion
    it "should route /sources"
    it "should route /sources/id"
    it "should route /sources/id/media"
    it "should route /sources/id/scrapers"
    it "should route /sources/id/schedules"
    it "should route /sources/id/web_databases"

    it "should route /schedules"
    it "should route /schedules/id"
    it "should route /schedules/id/sources"
    it "should route /schedules/id/scrapers"

    it "should route /scrapers"
    it "should route /scrapers/id"
    it "should route /scrapers/id/media"
    it "should route /scrapers/id/sources"

    it "should route /web_databases"
    it "should route /web_databases/id"
    it "should route /web_databases/id/media"
    it "should route /web_databases/id/sources"

    # NOTE we could support multiple id types here
    # by the format of the id.  For example:
    #   /^[0-9]+$/  => id in media table
    #   /^tt.+/     => IMDB ID
    #   /^isbn.+/   => ISBN
    it "should route /media/id/genres"
    it "should route /media/id/genres/id"
    it "should route /media/id/actors"
    it "should route /media/id/actors/id"
    it "should route /media/id/icons"
    it "should route /media/id/icons/id"
    it "should route /media/id/covers"
    it "should route /media/id/covers/id"
    it "should route /media/id/posters"
    it "should route /media/id/posters/id"
    it "should route /media/id/fanarts"
    it "should route /media/id/fanarts/id"
    it "should route /media/id/trailers"
    it "should route /media/id/trailers/id"
    it "should route /media/id/reviews"
    it "should route /media/id/reviews/id"
    it "should route /media/id/web_databases"
    it "should route /media/id/web_databases/id"
    it "should route /media/id/scrapers"
    it "should route /media/id/scrapers/id"

    it "should route /subtitles"
    it "should route /subtitles/id"
    it "should route /subtitles/id/media"

    # NOTE we could support ids and names by
    # the formate of the id.  For example:
    #   /^[0-9]+$/  => id in media table
    #   /^=(.+)/    => name
    it "should route /genres"
    it "should route /genres/id"
    it "should route /genres/id/media"
    it "should route /genres/id/icons"
    it "should route /genres/id/fanarts"

    # NOTE we could support ids and names by
    # the formate of the id.  For example:
    #   /^[0-9]+$/  => id in media table
    #   /^=(.+)/    => name
    it "should route /actors"
    it "should route /actors/id"
    it "should route /actors/id/media"
    it "should route /actors/id/icons"
    it "should route /actors/id/fanarts"

    # I'm not sure best way to handle resolution and depths
    it "should route /icons"
    it "should route /icons/id"
    it "should route /icons/id/media"

    # I'm not sure best way to handle resolution and depths
    it "should route /covers"
    it "should route /covers/id"
    it "should route /covers/id/media"

    # I'm not sure best way to handle resolution and depths
    it "should route /posters"
    it "should route /posters/id"
    it "should route /posters/id/media"

    # I'm not sure best way to handle resolution and depths
    it "should route /fanarts"
    it "should route /fanarts/id"
    it "should route /fanarts/id/media"

    # I'm not sure best way to handle resolution and depths
    it "should route /trailers"
    it "should route /trailers/id"
    it "should route /trailers/id/media"

    # I'm not sure best way to handle resolution and depths
    it "should route /reviews"
    it "should route /reviews/id"
    it "should route /reviews/id/media"

  end
end

