class RolesController < ApplicationController
  layout "admincore"

  before_filter :login_required
  before_filter :rolecheck, :except => [:show, :new, :create, :update, :edit]
  before_filter :specialrolecheck, :only => [:show, :new, :edit]

  def index
    @roles = Role.all
    @group_id = "0"
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roles }
    end
  end

  def show
    @roles = Role.all
    if specific_group?
      @roles = Role.find(:all, :conditions => ['group_id = ' + @group_id])
      @group = Group.find(@group_id)
      @users = @group.users
    end
    render :template => 'roles/index'
  end

  def new
    @role = Role.new
    @groups = Group.all
    if specific_group?
      @groups = Array.new
      @groups << Group.find(params[:id])
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @role }
    end
  end

  def edit
    @role = Role.find(params[:id2])
    @permissions = Permission.all
    @mypermissions = @role.permissions
  end

  def create
    @group = Group.find(params[:extra][:groupid])
    @role = Role.new(params[:role])
    if @role.save
      @group.roles << @role
      flash[:notice] = 'Role was successfully created.'
      redirect_to '/roles/' + params[:extra][:redirectgroup]
    else
      redirect_to '/roles/new/' + params[:extra][:redirectgroup]
    end
  end

  def update
    @role = Role.find(params[:id])
    @permissions = params[:perms]
    @role.permissions.clear
    @permissions.each do |key, choice|
      if choice == "1"
        @role.permissions << Permission.find(key)
      end
    end
      if @role.update_attributes(params[:role])
        flash[:notice] = 'Role was successfully updated.'
        @roles = Role.all
        redirect_to '/roles/' + params[:extra][:redirectgroup]
      else
        redirect_to '/roles/edit/' + params[:extra][:redirectgroup] + "/" + @role.id
 #       format.html { render :action => "edit" }
 #       format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
  end

  def destroy
    @role = Role.find(params[:id])
    @role.destroy
    respond_to do |format|
      format.html { redirect_to(roles_url) }
      format.xml  { head :ok }
    end
  end

private
  def rolecheck
    return controller_check("Administration","Modify Roles")
  end

  def specialrolecheck
    @group_id = params[:id]
    if !specific_group?
      controller_check("Administration","Modify Roles")
      return true
    end
    @group = Group.find(@group_id)
    if (current_user.authen_check(@group.groupname,"Control Group Roles") ||
        current_user.authen_check("Administration","Modify Roles"))
      true
    else
        flash_redirect(root_path, 'You do not have access to that page')
    end
  end
end
