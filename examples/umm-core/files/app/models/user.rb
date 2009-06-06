# This is a default user class used to activate merb-auth.  Feel free to change from a User to
# Some other class, or to remove it altogether.  If removed, merb-auth may not work by default.
#
# Don't forget that by default the salted_user mixin is used from merb-more
# You'll need to setup your db as per the salted_user mixin, and you'll need
# To use :password, and :password_confirmation when creating a user
#
# see merb/merb-auth/setup.rb to see how to disable the salted_user mixin
#
# You will need to setup your database and create a user.
class User
  include DataMapper::Resource
  # include Merb::Authentication::Mixins::SaltedUser
  is_paginated

  property :id,            Serial
  property :login,         String, :nullable=>false, :unique => true
  property :created_at, DateTime
  property :updated_at, DateTime

  attr_accessor :old_password, :new_password, :confirm_password

  # # Authenticates a user by their login name and cleartext password. Returns a User or nil.
  # def self.authenticate(login, password)
  #  if user = self.first(:login => login)
  #    if validate_password(password, user.crypted_password, user.salt)
  #      return user
  #    end
  #  end
  #  false
  # end
  #
  # # returns true if the password is correct
  # def self.validate_password(password, crypted_password, salt)
  #  crypted_password == OpenSSL::Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  # end

  def to_s
    self.login
  end

  def self.reset
    u = User.new(:login => 'royw')
    u.password = u.password_confirmation = "sekrit"
    u.save
  end
end
