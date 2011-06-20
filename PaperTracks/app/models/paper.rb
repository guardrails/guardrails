class Paper < ActiveRecord::Base
	require 'rubygems'
    require 'mechanize'
   belongs_to :user
   has_many :log_items
   def get_log_at(time)
     return self.log_items.find(:all, :conditions => ["schedule_index = ?", time])
   end
   def citations
     if self.last_citations
       return self.last_citations
     else
       return 0
     end
   end
  def pull_citations
    if self.last_update && (Time.now - self.last_update) < 90
      return
    end
    @paper = self
    logger.debug "Pulling Citations for " + @paper.true_title
    @paper.last_citations = pull_info(@paper.true_title,0)[:citations]
    @paper.last_update = Time.new
    @paper.save
  end
  def pull_info(paper, pick_index)
    @anotherArray = Array.new
    @cited = Array.new
    @myhtml = Array.new
    @authors = Array.new
    agent = Mechanize::Mechanize.new
    page = agent.get("http://scholar.google.com")
    google_form = page.forms.first
    google_form.q = paper
    page = agent.submit(google_form)
    #all the cited links in @myhtml
    test = page.parser.xpath("//span[@class='gs_fl']//a[1]")
    @myhtml = test.to_a
    page.search(".gs_fl").each do |xx|
      @cited << xx
    end
    #all titles
    page.search("h3, a").each do |ll|
      @anotherArray << ll
    end
    page.search(".gs_a").each do |author|
      @authors << author
    end
    @title = @anotherArray[pick_index].to_s.gsub(/\[.*\]/,"").gsub("\n","").strip
    @titlelink = @title.clone
    @titlelink = @titlelink.gsub(/">.*<\/a>/,"").gsub(/<a href="/, "").gsub(/<h3>/,"").gsub(/<\/h3>/,"")
    @title = @title.gsub(/<(.|\n)*?>/,"").strip
    @citations = (@myhtml[pick_index].to_s.gsub(/<a href.*>Cited by/,"").gsub(/<\/a>/,"")).to_i
    @author = @authors[pick_index].to_s.split("-")[0].gsub(/<(.|\n)*?>/,"").strip
    return {:title => @title, :titlelink => @titlelink, :citations => @citations, :author => @author}
  end
end
