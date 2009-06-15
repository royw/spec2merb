# This is a stub used to attach information about a model to the spec.
def synopsis(*args)
end

# NOTES
# * NVARCHAR should be used for fields that can contain non-english content.
# * Database should be configured for Unicode
describe("Locationbook Database Schema") do
  describe("Person Model") do
    synopsis("This model describes a person in the address book")
    # attributes
    it "should have a name [TEXT]"
    it "should have a honorific [NVARCHAR(4)]"
    # relationships
    it "should have a relationship of zero or more companies [has 0:n Company]"
    it "should have a relationship of zero or more locations [has 0:n Location]"
    it "should have a relationship of zero or more phones [has 0:n Phone]"
    it "should have a relationship of zero or more emails [has n Email]"
    # additional required methods
  end
  describe("Company Model") do
    synopsis("This model describes a company or business in the address book")
    # attributes
    it "should have a name [NVARCHAR(255)]"
    # relationships
    it "should have a relationship of zero or more people [has 0:n Person]"
    it "should have a relationship of zero or more locations [has 0:n Location]"
    it "should have a relationship of zero or more phones [has 0:n Phones]"
    it "should have a relationship of zero or more emails [has n Email]"
    # additional required methods
  end
  describe("Location Model") do
    synopsis("This model describes a mailing address or location.", 
             "Note a bug in datamapper is letting me use the name that I would prefer, 'Address'")
    # attributes
    it "should have a street_location (including apt or suite number) [NVARCHAR(255)]"
    it "should have a city [NVARCHAR(80)]"
    it "should have a state [NVARCHAR(2)]"
    # relationships
    it "should have a relationship of zero or more people [has 0:n Person]"
    it "should have a relationship of zero or more companies [has 0:n Company]"
    # additional required methods
    it "should return the full mailing location"
  end
  describe("Phone Model") do
    synopsis("This model encapsulates phone numbers")
    # attributes
    it "should have a number [NVARCHAR(14)]"
    # relationships
    it "should have a relationship of zero or more people [has 0:n Person]"
    it "should have a relationship of zero or more companies [has 0:n Company]"
    # additional required methods
    it "should return the area code"
    it "should return the exchange"
  end
  describe("Email Model") do
    synopsis("This model encapsulates email addresses")
    # attributes
    it "should have an location [NVARCHAR(255)]"
    # relationships
    it "should have a relationship to a person [has 1 Person]"
    it "should have a relationship to a company [has 1 Company]"
    # additional required methods
    it "should return the account (ex: return 'foo' when location is 'foo@bar.com')"
    it "should return the host service (ex: return 'bar.com' when adress is 'foo@bar.com')"
  end
end
