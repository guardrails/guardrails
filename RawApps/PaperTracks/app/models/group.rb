class Group < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :roles
  has_many :log_items
  validates_presence_of :groupname
  validates_uniqueness_of :groupname
  def profile_link
    if self.admin
      self.groupname
    else
      "<a href='/groups/show/" + self.id.inspect + "'>" + self.groupname + "</a>"
    end
  end
  def allpapers
    @papers = Array.new
    self.users.each do |usr|
      @papers = @papers + usr.papers
    end
    return @papers
  end

  def allpapers_at(time)
    @logs = Array.new
    allpapers.each do |ppr|
      @log = ppr.get_log_at(time)
      if @log
        @logs << @log
      end
    end
    return @logs
  end

  def users_with_usersr(force_reload = false)
    guardlog = Logger.new('guardlog.txt')
    guardlog.debug("Read all users at " + Time.new.inspect)
    users_without_usersr(force_reload)
  end
#  alias_method_chain :users, :usersr

  def users_with_usersw=(associate)
    guardlog = Logger.new('guardlog.txt')
    guardlog.debug("Wrote to users at " + Time.new.inspect + " -- " + associate.inspect)
    self.users_without_usersw = associate
  end
#  alias_method_chain :users=, :usersw

  def user_ids_with_usersir
    guardlog = Logger.new('guardlog.txt')
    guardlog.debug("Read user ids at " + Time.new.inspect)
    user_ids_without_usersir
  end
#  alias_method_chain :user_ids, :usersir

  def user_ids_with_usersiw=(ids)
    guardlog = Logger.new('guardlog.txt')
    guardlog.debug("Wrote to user ids at " + Time.new.inspect)
    self.user_ids_without_usersir(ids)
  end
#  alias_method_chain :user_ids=, :usersiw
end


