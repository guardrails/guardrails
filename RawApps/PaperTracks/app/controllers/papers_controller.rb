class PapersController < ApplicationController
  layout 'core'
  require 'mechanize'
  before_filter :login_required, :except => [:show, :citations_graph]
#  before_filter :check_owner, :except => [:mypapers, :citations_graph, :show]
  def mypapers
    @sort = params[:sort]
    @order = 'title ASC'
    if @sort
      if @sort == "alpha"
        @order = 'title ASC'
      end
      if @sort == "alpha2"
        @order = 'title DESC'
      end
      if @sort == "fav"
        @order = 'favorite DESC, title ASC'
      end
      if @sort == "cits"
        @order = 'last_citations DESC'
      end
    end
    @allpapers = current_user.papers.find(:all, :order => @order)
    if params[:index]
      @display_index = Integer(params[:index])
    else
      @display_index = 0
    end
    @papers = Array.new
    @count = 0
    while @count < 4
      if (@count + @display_index) < @allpapers.size
        @papers << @allpapers[@count + @display_index]
        @allpapers[@count + @display_index].pull_citations
      end
      @count += 1
    end
    render :template => 'papers/mypapers', :layout => 'core'
  end

  def make_favorite
    @paper_id = params[:id]
    Paper.find(@paper_id).update_attributes({:favorite => true})
    redirect_to :action => :mypapers, :sort => params[:sort], :index => params[:index]
  end
  def remove_favorite
    @paper_id = params[:id]
    Paper.find(@paper_id).update_attributes({:favorite => false})
    redirect_to :action => :mypapers, :sort => params[:sort], :index => params[:index]
  end

  def show
    @paper=Paper.find(params[:id])
    @paper.pull_citations
    render :template => 'papers/show', :layout => 'core'
  end

  def edit
    @paper = Paper.find(params[:id])
  end

  def update
    @paper = Paper.find(params[:id])
    if @paper.update_attributes(params[:paper])
      flash[:notice] = 'Paper added successfully!'
      redirect_to myPapers_path
    else
      redirect_to edit_paper_path
    end
  end

  def del #delete
    @paper = Paper.find(params[:id])
    @paper.destroy
    respond_to do |format|
      flash[:notice] = 'Paper has been deleted'
      format.html { redirect_to(myPapers_path) }
      format.xml  { head :ok }
    end
  end

  def citations_graph
    @paper = Paper.find(params[:id])
    @points = 13
    ### TODO: This 'Integer' call is a problem!!!
    if params[:points]
      @points = Integer(params[:points])
    end
    value_graph(@paper.log_items,@paper.citations,lambda{|log| log.value },@points,4,"Number of Citations", params[:color])
  end

  def find_paper
    @mypaper = params[:paper][:title]#.pull_string
    count = 0
    n = 0
    @myarray = Array.new
    @midarray = Array.new
    @finalarray = Array.new
    agent = Mechanize::Mechanize.new
    page = agent.get("http://scholar.google.com/")
    google_form = page.forms.first
    google_form.q = @mypaper
    page = agent.submit(google_form)
    page.search(".gs_r").each do |ll|
      @myarray << ll
    end
    while count < 5
      @midarray << @myarray[count].to_s
      count += 1
    end
    while n < 5
      @finalarray << @midarray[n].gsub("/scholar?", "http://scholar.google.com/scholar?").encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "?")
      n += 1
    end
  end

  #basically repeat things again to gain access to css
  def associate_paper
    @paper = params[:pname]
    @data = Paper.new.pull_info(@paper, Integer(params[:index]))
    @paper = create_paper(@data[:title], @data[:titlelink], @data[:citations], @data[:author])
    redirect_to :action => :edit, :id => @paper.id
  end


  def create_paper(title, url, cited_by, author)
    @paper = Paper.new(:title => title.to_s, :true_title => title.to_s, :last_citations => cited_by, :url => url, :favorite => false, :author => author)
    @paper.save
    current_user.papers << @paper
    return @paper
  end

  # def find_paper
  #   @myarray = Array.new
  #   @mypaper = params[:paper][:title]
  #   agent = WWW::Mechanize.new
  #   agent.get("http://scholar.google.com/")
  #   form = agent.page.forms.first
  #   form.q = @mypaper
  #   form.submit
  #   @myarray << agent.page.search(".gs_r")
  #   @myarray[1] = @myarray[0].to_s()
  # end

 private
  def check_owner
    if Paper.find(params[:id]).user == current_user
      true
    else
      controller_check("Administration","Modify Papers")
    end
  end
end
