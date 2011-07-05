class GroupsController < ApplicationController

  before_filter :login_required, :except => [:show, :citations_graph, :papers_graph]
  before_filter :groups_check, :except =>
    [:mygroups, :join, :leave, :show, :edit, :update, :remove_user, :destroy, :new, :create, :citations_graph, :papers_graph]
  before_filter :edit_check, :only => [:edit, :update]
  before_filter :remove_user_check, :only => [:remove_user]
  before_filter :destroy_check, :only => [:destroy]
  before_filter :new_check, :only => [:new]
  before_filter :create_check, :only => [:create]

  layout 'admincore'

  # mygroups
  # --------------------------------------------------
  # defines the page where users view what groups they are in
  # and can join new groups. Also provides access for group admins to
  # view the profiles of their groups where they can make administrative
  # edits like adding new roles or removing members"
  #
  # ** Any logged on user can view this page

  def mygroups
    if current_user
      @usergroups = current_user.groups
      @sort = params[:sort]
      @order = 'groupname ASC'
      if @sort
        if @sort == "alpha"
          @order = 'groupname ASC'
        end
        if @sort == "alpha2"
          @order = 'groupname DESC'
        end
      end
      @allgroups = Group.find(:all, :order => @order)
      render :template => "groups/mygroups", :layout => 'core'
    else
      redirect_to root_path
    end
  end

  # join
  # --------------------------------------------------
  # action triggered from 'mygroups' or 'index' (for admins only)
  # that causes the current_user to join the group specified as the
  # :id parameter
  #
  # ** Any logged in user can perform this action

  def join
    @group = Group.find(params[:id])
    if current_user.groups.find_by_groupname(@group.groupname)
      @debug = "Already Added"
    else
      current_user.groups << @group
      @debug = "Success"
    end
    @allgroups = Group.all
    @usergroups = current_user.groups
    render :template => "groups/mygroups", :layout => 'core', :sort => params[:sort]
  end

  # leave
  # --------------------------------------------------
  # action opposite to 'join', currently accessible only from
  # 'mygroups'. removes the current_user from the group specified
  # as the :id parameter
  #
  # ** Any logged in user can perform this action

  def leave
    @group = Group.find(params[:id])
    if current_user.groups.find_by_groupname(@group.groupname)
      current_user.groups.delete(@group)
      @debug = "Success"
    else
      @debug = "Failed. Not a member of that group."
    end
    @allgroups = Group.all
    @usergroups = current_user.groups
    render :template => "groups/mygroups", :layout => 'core', :sort => params[:sort]
  end

  # remove_user
  # --------------------------------------------------
  # action that removes a user specified by :id parameter from
  # the group specified as :id2 parameter
  #
  # ** Only users who have 'Delete Members' privilege in the group
  # or 'Modify Groups' Administrators can use this function
  # ** enforced by the remove_user_check before_filter

  def remove_user
    @group = Group.find(params[:id2])
    @user = User.find(params[:id])
    if @user.groups.find_by_groupname(@group.groupname)
      @user.groups.delete(@group)
      @debug = "Success"
    else
      @debug = "Failed. Not a member of that group."
    end
    if !current_user.authen_check("Administration","Modify Groups")
      render :template => "groups/edit", :layout => 'core'
    else
      render :template => "groups/edit", :layout => 'admincore'
    end
  end

  # index
  # --------------------------------------------------
  # default index listing of all of the groups displayed in the
  # 'Groups' tab of the administration panel.
  #
  # ** Only accessible to 'Modify Groups' administrators

  def index
    @sort = params[:sort]
    @order = 'groupname ASC'
    if @sort
      if @sort == "alpha"
        @order = 'groupname ASC'
      end
      if @sort == "alpha2"
        @order = 'groupname DESC'
      end
      if @sort == "apprv"
        @order = 'approved ASC, groupname ASC'
      end
    end
    @groups = Group.find(:all, :order => @order)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # show
  # --------------------------------------------------
  # the group profile for the group specified by the :id
  # parameter.
  #
  # ** Accessible to everyone

  def show
    @group = Group.find(params[:id])
    @gpapers = @group.allpapers
    render :template => "groups/show", :layout => 'core'
  end

  # new
  # --------------------------------------------------
  # the page where a user can create a new group.  will appear
  # with the admin panel if the action is called with a non-nil
  # :id param (should be "0" if non-nil). this version is triggered
  # by the admin panel, while the non-admin version is called
  # elsewhere and appears with the normal panel
  #
  # ** Accessible to any logged in user

  def new
    @group = Group.new
    @admin = params[:id]
    if @admin
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @group }
      end
    else
      render :template => "groups/new", :layout => 'core'
    end
  end

  # edit
  # --------------------------------------------------
  # the page where a user can edit the profile, description, or users
  # of a group depending on their permissions. Appears with admin panel
  # if the user is an admin with 'Modify Groups' permission, otherwise
  # will be the normal panel
  #
  # ** Accessible to admins with 'Modify Groups' permission or users
  # who have 'Remove Members' or 'Edit Group Profile' permissions for
  # the group

  def edit
    @group = Group.find(params[:id])
    if !current_user.authen_check("Administration","Modify Groups")
      render :template => "groups/edit", :layout => 'core'
    end
  end

  # create
  # --------------------------------------------------
  # action triggered from the 'new' page to create the new group.
  # the group will only be approved here if the :extra/:status
  # parameter (a hidden field in the form) is 'admin', which occurs
  # if 'new' was called from the admin panel
  #
  # ** Accessible to all logged in users

  def create
    @group = Group.new(params[:group])
    if params[:extra][:status] == "admin"
      @group.approved = true
    else
      @group.approved = false
    end
    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        if current_user.authen_check("Administration","Modify Groups")
          format.html { render :action => "new" }
        else
          format.html { render :action => "new", :layout => "core" }
        end
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # update
  # --------------------------------------------------
  # action triggered by the 'edit' page to update the group.
  #
  # ** Can only be performed by admins with 'Modify Groups' permission
  # or users with 'Edit Group Profile' permission for the group in
  # question

  def update
    @group = Group.find(params[:id])
    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # destroy
  # --------------------------------------------------
  # deletes the group specified by the :id parameter.  Also
  # destroys any roles pertaining to the deleted group to avoid
  # null-pointer issues
  #
  # ** Action can be performed by 'Modify Groups' admins and users
  # who have the 'Delete Group' permission

  def destroy
    @group = Group.find(params[:id])
    @group.roles.each do |role_to_delete|
      role_to_delete.destroy
    end
    @group.destroy
    respond_to do |format|
      flash[:notice] = 'Group has been deleted'
      format.html { redirect_to(root_path) }
      format.xml  { head :ok }
    end
  end

  # approve/suspend
  # --------------------------------------------------
  # actions to alter the 'approved' property of a group. Called
  # from the admin panel, 'Groups' tab
  #
  # ** Can only be performed by a 'Modify Groups' admin

  def approve
    @group_id = params[:id]
    Group.find(@group_id).update_attributes({:approved => true})
    redirect_to :action => :index, :sort => params[:sort]
  end
  def suspend
    @group_id = params[:id]
    Group.find(@group_id).update_attributes({:approved => false})
    redirect_to :action => :index, :sort => params[:sort]
  end

  def papers_graph
    @group = Group.find(params[:id])
    value_graph(@group.log_items,@group.allpapers.size,lambda {|log| log.value},6,1,"Total Number of Papers",params[:color])
  end

  def citations_graph
    @group = Group.find(params[:id])
    @c_val = 0
    @group.allpapers.each do |paper|
      @c_val += paper.citations
    end
    value_graph(@group.log_items,@c_val,lambda{|log| log.value2},6,1,"Total Number of Citations", params[:color])
  end

 private
  # Before_filter checkers
  # --------------------------------------------------
  def groups_check
    controller_check("Administration","Modify Groups")
  end

  def edit_check
    @g = Group.find(params[:id])
    if current_user.authen_check("Administration", "Modify Groups")
      return true
    end
    if current_user.authen_check(@g.groupname, "Edit Group Profile") ||
        current_user.authen_check(@g.groupname, "Remove Members")
      return true
    else
      flash_redirect(joinGroup_path,"You do not have permission to edit that group")
    end
  end

  def remove_user_check
    @g = Group.find(params[:id2])
    if current_user.authen_check("Administration", "Modify Groups")
      return true
    end
    if current_user.authen_check(@g.groupname, "Remove Members")
      return true
    else
      flash_redirect(joinGroup_path)
    end
  end

  def destroy_check
    @g = Group.find(params[:id])
    if current_user.authen_check("Administration", "Modify Groups")
      return true
    end
    if current_user.authen_check(@g.groupname, "Delete Group")
      return true
    else
      flash_redirect(joinGroup_path)
    end
  end

  def new_check
    @admin = params[:id]
    if @admin
      if current_user.authen_check("Administration", "Modify Groups")
        true
      else
        redirect_to "/groups/new"
      end
    end
  end

  def create_check
    @admin = params[:extra][:status]
    if current_user.authen_check("Administration", "Modify Groups")
      return true
    else
      if @admin == "admin"
        flash_redirect
      end
    end
  end
end
