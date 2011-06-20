class RoleTypesController < ApplicationController
  # GET /role_types
  # GET /role_types.xml
  def index
    @role_types = RoleType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @role_types }
    end
  end

  # GET /role_types/1
  # GET /role_types/1.xml
  def show
    @role_type = RoleType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @role_type }
    end
  end

  # GET /role_types/new
  # GET /role_types/new.xml
  def new
    @role_type = RoleType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @role_type }
    end
  end

  # GET /role_types/1/edit
  def edit
    @role_type = RoleType.find(params[:id])
  end

  # POST /role_types
  # POST /role_types.xml
  def create
    @role_type = RoleType.new(params[:role_type])

    respond_to do |format|
      if @role_type.save
        flash[:notice] = 'RoleType was successfully created.'
        format.html { redirect_to(@role_type) }
        format.xml  { render :xml => @role_type, :status => :created, :location => @role_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @role_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /role_types/1
  # PUT /role_types/1.xml
  def update
    @role_type = RoleType.find(params[:id])

    respond_to do |format|
      if @role_type.update_attributes(params[:role_type])
        flash[:notice] = 'RoleType was successfully updated.'
        format.html { redirect_to(@role_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /role_types/1
  # DELETE /role_types/1.xml
  def destroy
    @role_type = RoleType.find(params[:id])
    @role_type.destroy

    respond_to do |format|
      format.html { redirect_to(role_types_url) }
      format.xml  { head :ok }
    end
  end
end
