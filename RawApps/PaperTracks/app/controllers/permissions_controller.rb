class PermissionsController < ApplicationController

  before_filter :login_required
  before_filter :permission_check

  layout 'admincore'

  def index
    @permissions = Permission.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @permissions }
    end
  end

  def show
    @permission = Permission.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @permission }
    end
  end

  def new
    @permission = Permission.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @permission }
    end
  end

  def edit
    @permission = Permission.find(params[:id])
  end

  def create
    @permission = Permission.new(params[:permission])
    respond_to do |format|
      if @permission.save
        @permissions = Permission.all
        flash[:notice] = 'Permission was successfully created.'
        format.html { render :action => "index"}
        format.xml  { render :xml => @permission, :status => :created, :location => @permission }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @permission.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @permission = Permission.find(params[:id])

    respond_to do |format|
      if @permission.update_attributes(params[:permission])
        @permissions = Permission.all
        flash[:notice] = 'Permission was successfully updated.'
        format.html { render :action => "index" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @permission.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @permission = Permission.find(params[:id])
    @permission.destroy
    respond_to do |format|
      format.html { redirect_to(permissions_url) }
      format.xml  { head :ok }
    end
  end

private
  def permission_check
    controller_check("Administration","Modify Permissions")
  end
end
