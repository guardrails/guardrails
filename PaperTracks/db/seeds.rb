admin = Group.create(:groupname => 'Administration', :admin => true)
g1 = Group.create(:groupname => 'University of Virginia', :description => "Professors from Mr. Jefferson's University", :approved => true)
g2 = Group.create(:groupname => 'University of Maryland', :description => "Home of the Terps", :approved => true)
g3 = Group.create(:groupname => 'National High Energy Physics Association', :description => "Exploring the Mysteries of the Universe", :approved => true)
g4 = Group.create(:groupname => 'NeoTechnus', :description => "Technology for the Future", :approved => false)
RoleType.create(:typename => 'Administrator')
RoleType.create(:typename => 'Group Leader')
p1 = Permission.create(:permissionname => 'Modify User Roles', :admin => true)
p2 = Permission.create(:permissionname => 'Modify Roles', :admin => true)
p3 = Permission.create(:permissionname => 'Modify Permissions', :admin => true)
p4 = Permission.create(:permissionname => 'Modify Groups', :admin => true)
p5 = Permission.create(:permissionname => 'Edit User Profiles', :admin => true)
p6 = Permission.create(:permissionname => 'Modify Papers', :admin => true)
q1 = Permission.create(:permissionname => 'View Group Profile')
q2 = Permission.create(:permissionname => 'Edit Group Profile')
q3 = Permission.create(:permissionname => 'Delete Group')
q4 = Permission.create(:permissionname => 'Remove Members')
q5 = Permission.create(:permissionname => 'Remove Papers')
q6 = Permission.create(:permissionname => 'Control Group Roles')
adminrole = Role.create(:rolename => 'Full Administrator', :group => admin)
uvarole = Role.create(:rolename => 'UVA Group Leader', :group => g1)
Role.create(:rolename => 'UMD Group Leader', :group => g2)
Role.create(:rolename => 'Techno Leader', :group => g4)
Role.find(adminrole).permissions << p1
Role.find(adminrole).permissions << p2
Role.find(adminrole).permissions << p3
Role.find(adminrole).permissions << p4
Role.find(adminrole).permissions << p5
Role.find(adminrole).permissions << p6
Role.find(uvarole).permissions << q1
Role.find(uvarole).permissions << q2
Role.find(uvarole).permissions << q3
Role.find(uvarole).permissions << q4
Role.find(uvarole).permissions << q5
Role.find(uvarole).permissions << q6
adminuser = User.create!(:login => 'admin', :password => 'admin0', :password_confirmation => 'admin0', :email => 'admin@papertracks.com')
User.find(adminuser).roles << adminrole
weakeruser = User.create!(:login => 'basicuser', :password => '123123', :password_confirmation => '123123', :email => 'weakuser@papertracks.com')
User.find(weakeruser).roles << uvarole
User.find(weakeruser).groups << g1
adminuser.groups << g1

s = Scheduler.create!(:current_index => 1)
#Don't Seed in January or will try to set original time to month 0
starttime = LogItem.create!(:value => Time.new.year, :value2 => Time.new.month-1, :schedule_index => 0)
s.log_items << starttime
