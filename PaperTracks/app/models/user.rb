require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  has_and_belongs_to_many :roles
  has_many :permissions, :through => :roles
  has_and_belongs_to_many :groups
  has_many :papers
  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :profile



  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  def authen_check(group, permission)
    self.roles.each do |role|
      if role.group
        if role.group.groupname == group
          role.permissions.each do |perm|
           if perm.permissionname == permission
             return true
           end
          end
        end
      end
    end
   return false
  end
  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def has_role?(rolename)
    self.roles.find_by_rolename(rolename) ? true : false
  end

  def profile_link
    "<a href='/users/show/" + self.id.inspect + "'>" + self.login + "</a>"
  end

  def paper_logs_at(time)
    @logs = Array.new
    self.papers.each do |ppr|
      @log = ppr.get_log_at(time)
      if @log
        @logs << @log
      end
    end
    return @logs
  end
  protected


end
