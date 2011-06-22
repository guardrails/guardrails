require 'find'
require 'rubygems'
require 'ruby_parser'
require 'ruby2ruby'
require 'GTransformer'
require 'GParser'

class MyRubyProcess < Ruby2Ruby
  
  def initialize
    super
  end
  
  def process_dstr(exp)
    "\"#{util_dthing2(:dstr, exp)}\""
  end

  def util_dthing2(type, exp)
    s = []

    # first item in sexp is a string literal
    s << dthing_escape(type, exp.shift)

    until exp.empty?
      pt = exp.shift
      case pt
      when Sexp then
        case pt.first
        when :str then
          s << dthing_escape(type, pt.last)
        when :evstr then         
          s << '"+(' << process(pt) << ').to_s()+"' # do not use interpolation here
        else
          raise "unknown type: #{pt.inspect}"
        end
      else
        # HACK: raise "huh?: #{pt.inspect}" -- hitting # constants in regexps
        # do nothing for now
      end
    end

    s.join
  end

  def process_nth_ref(exp)
    "$gr_#{exp.shift}"
  end

  def process_grhtml(exp)
    #p exp
    ans="%>"+exp[2][1][1]+"<%"
    exp.shift until exp.empty?
    return ans
  end

  def process_grhtmlputs(exp)
    ans="%><%="+process(exp[1])+"%><%"
    exp.shift until exp.empty?
    return ans
  end
end

class GCompiler
  def initialize
    @parser 		= RubyParser.new
    @ruby2ruby 	= MyRubyProcess.new
    @gparser    = GParser.new

    @file_dirs		 	= {}

    @asts = {}
    @asts[:model] 			= {}
    @asts[:controller] 	= {}
    @asts[:view] 			= {}
    @asts[:migration] 	= {}
    @asts[:helper]			= {}
    @asts[:library]={}
  end

  def get_path(filename)
    path = @file_dirs[filename]
    subpath = path[path.index("app")..-1]
    return subpath
  end

  def process(dir, *args)
    build_asts(dir)

    # Get all the annotations from model files
    ann_lists = {}
    for filename in @asts[:model].keys do
      ann_lists[filename] = @gparser.get_annotations("#{dir}/#{get_path(filename)}")
    end
    puts "*************Annotations Discovered:*************"
    ann_lists.each_pair do |key, val|
      puts "#{key} => #{val.inspect}"
      #               val.each do |val2|
      ##             puts " --- #{val2.inspect} + #{val2.lambda.class}"
      #                end
    end
    puts "*************************************************"
    # Get the list of models that extend ActiveRecord::Base
    model_names = []
    model_files = []
    get_models(model_names, model_files)

    config(dir)
    # Handle transformations
    GTransformer.new.transform(@asts, ann_lists, model_names, model_files, @pass_user, $*[1..-1])
    # Rebuild the source code
    build_src(dir)
  end

  # Parse all of the relevant files
  def build_asts(dir)
    # Build all models
    Find.find("#{dir}/app/models") do |path|
      next unless legal_file(path)
      filename = File.basename(path)
      puts path
      @asts[:model][filename] = @parser.parse(File.read path)
      @file_dirs[filename] = path
    end

    # Build all controllers
    Find.find("#{dir}/app/controllers") do |path|
      next unless legal_file(path)

      filename = File.basename(path)
      puts path
      @asts[:controller][filename] = @parser.parse(File.read path)
      @file_dirs[filename] = path
    end

    # Build all libraries
    Find.find("#{dir}/lib") do |path|
      next unless legal_file(path)

      filename = File.basename(path)
      puts path
      begin
        @asts[:library][filename] = @parser.parse(File.read path)
      rescue Exception
        puts "Path #{path} did not translate"
        @parser=RubyParser.new
      end
      @file_dirs[filename] = path
    end

    # Build all views
    Find.find("#{dir}/app/views") do |path|
      next unless legal_file(path)

      filename = File.basename(path)
      puts path
      begin
        @asts[:view][path] = RubyParser.new.parse(@gparser.convert_to_ruby(File.read path))
      rescue
        puts @gparser.convert_to_ruby(File.read path)
        puts $!.message
        @parser=RubyParser.new
        puts $!.backtrace
        #exit
      end
      @file_dirs[filename] = path
    end
    puts "done with views"

    # Some single files are needed as well
    begin
      @asts[:migration] = @parser.parse(File.read "#{dir}/db/schema.rb")
    rescue
      puts "No schema file"
      #@asts[:migration]=@parser.parse("ActiveRecord::Schema.define(:version => 20100531202218) do\n\nend")
    end
    begin
      @asts[:helper] 	= @parser.parse(File.read "#{dir}/app/helpers/application_helper.rb")
    rescue
      puts "No application helper file"
    end
  end

  # Get a list of all the models that have ActiveRecord::Base as a parent
  def get_models(model_names, model_files)
    new_models = false
    arb = @parser.parse("ActiveRecord::Base")
    good_models = model_names.collect{ |x| @parser.parse(x.to_s)}

    for filename in @asts[:model].keys
      next if model_files.include? filename
      ast = @asts[:model][filename]

      # Find the sexp where the class is defined
      class_node = ast.deep_find(lambda{ |node| node.is_a? Sexp and node[0] == :class })
      extend_node = class_node[2]

      class_name = class_node[1]
      next if class_name.is_a? Sexp

      # Does the class extend ActiveRecord::Base?
      if extend_node == arb
        model_files.push filename
        model_names.push class_node[1]
        new_models = true
      end

      # Does the class extend anything from model_names?
      if good_models.include? extend_node
        model_files.push filename
        model_names.push class_node[1]
        new_models = true
      end
    end

    get_models(model_names, model_files) if new_models
  end

  # Rebuild all the files from their parsed forms
  def build_src(dir)

    # Models
    for filename in @asts[:model].keys
      path = get_path(filename)
      File.new("#{dir}/#{path}", 'w').puts(@ruby2ruby.process(@asts[:model][filename]))
    end

    # Controllers
    for filename in @asts[:controller].keys
      path = get_path(filename)
      begin
        File.new("#{dir}/#{path}", 'w').puts(@ruby2ruby.process(@asts[:controller][filename]))
      rescue
      end
    end

    # Views
    for filename in @asts[:view].keys
#      path = get_path(filename)
      begin
        File.new("#{filename}", 'w').puts("<% protect do %> "+@gparser.convert_to_erb(@asts[:view][filename],@ruby2ruby)+"<% end %>")
      rescue
        puts "#{path} is bad voodoo"
        txt = File.read "#{dir}/"+path
        File.new("#{dir}/"+path, 'w').puts "<% protect do %> #{txt} <% end %>"
      end
    end

    # Libraries
    for filename in @asts[:library].keys
      File.new("#{dir}/lib/#{filename}", 'w').puts(@ruby2ruby.process(@asts[:library][filename]))
    end

    # Singleton files
    begin
      File.new("#{dir}/db/schema.rb", "w").puts(@ruby2ruby.process(@asts[:migration]))
    rescue
    end
    File.new("#{dir}/app/helpers/application_helper.rb", "w").puts(@ruby2ruby.process(@asts[:helper]))
  end

  # Return true if the file is not a directory or some other weird thing
  def legal_file(path)
    return false if FileTest.directory?(path)
    return false if (File.basename(path) =~ /rb$/) == nil
    return false if (File.basename(path) =~ /^\w/) == nil
    return true
  end

  #########################################################################################
  def config(dir)
    @error_cases = {}
    @pass_user = ""
    line_index = 0
    arr = [:single_model_read, :many_model_read, :model_create, :model_destroy,
      :att_read, :att_write, :singular_assoc_read, :singular_assoc_write,
      :plural_assoc_read, :plural_assoc_write]

    IO.foreach("#{dir}config/config.gr") do |line|
      if line_index < 0
        @error_cases[arr[line_index]] = line.split("#")[0].strip
      else
        @pass_user << line << "\n"
      end
      line_index += 1
    end
    @pass_user += "def pass_user\n Thread.current['user'] = return_user\n Thread.current['response'] = response\n end"
  end

  def get_error_cases(filename)
    flag = false
    count = 0

    arr = [:single_model_read, :many_model_read, :model_create, :model_destroy,
      :att_read, :att_write, :singular_assoc_read, :singular_assoc_write,
      :plural_assoc_read, :plural_assoc_write]
    error_cases = {}

    IO.foreach(filename) do |line|
      if (not flag) and line.include? "#"
        flag = true
        next
      end

      if flag and count < arr.length
        error_cases[ arr[count] ] = line.chop
        count += 1
      end
    end
    return error_cases
  end

  def build_astaas(dir)
    # We need to parse all the files in the controllers, views, models and migrations
    # folders because any one of these files could need changes.

    @all_models = {}
    Find.find("#{dir}/app/models") do |path|
      if legal_file(path)
        filename = File.basename(path)
        #model_ast = @parser.parse(File.read path)
        #class_node = model_ast.deep_find(lambda{ |node| node.is_a? Sexp and node[0] == :class })
        #@all_models[class_node[1]] = [filename, model_ast]
        @asts[:model][filename] = @parser.parse(File.read path)
        @file_dirs[filename] = path
      end
    end

    # However, some models do not inherit from active record and do not persist in the
    # database.  We leave these files to fend for themselves.  Unfortunately, this means
    # we need to first discern the full inheritance structure of the models in order to
    # determine whether or not the model is a subclass of active record.

    #@arb_models = {}
    #@fail_models = {}

    #@all_models.each_pair do |class_name, info|
    #	model_sort(class_name, info[0], info[1]) unless @arb_models.keys.include? class_name or
    #		@fail_models.keys.include? class_name
    #end

    Find.find("#{dir}/app/controllers") do |path|
      if legal_file(path)
        filename = File.basename(path)
        @asts[:controller][filename] = @parser.parse(File.read path)
        @file_dirs[filename] = path
      end
    end

    @asts[:migration] = @parser.parse(File.read "#{dir}/db/schema.rb")
    @asts[:helper] 	= @parser.parse(File.read "#{dir}/app/helpers/application_helper.rb")
  end

  # Only adds models to the asts hash if they extend ActiveRecord.  We need
  # this because we can't do gaurdrailsy stuff on non ActiveRecord extending
  # models.
  def model_sort(class_name, filename, model_ast)
    arb = Sexp.new << :const << :ActiveRecord
    class_node = model_ast.deep_find(lambda{ |node| node.is_a? Sexp and node[0] == :class })
    parent     = class_node[2]
    parent = parent[1] unless parent.nil?

    if parent == arb
      @arb_models[class_name] = [filename, model_ast]
      @asts[:model][filename] = model_ast
      return
    end
    if parent.nil? or not @all_models.keys.include? parent
      @fail_models[class_name] = [filename, model_ast]
      return
    end
    unless @fail_models.keys.include? parent or @arb_models.keys.include? parent
      model_sort(parent, @all_models[parent][0], @all_models[parent][1])
    end
    if @arb_models.keys.include? parent
      @arb_models[class_name] = [filename, model_ast]
      @asts[:model][filename] = model_ast
      return
    end
    if @fail_models.keys.include? parent
      @fail_models[class_name] = [filename, model_ast]
      return
    end
  end

  def build_aasrc(dir)

    @asts[:model].each_pair do |filename, ast|
      path = @file_dirs[filename]
      subpath = path[path.index("models")..-1]
      File.new("#{dir}/app/#{subpath}", 'w').puts(@ruby2ruby.process(ast))
    end

    @asts[:controller].each_pair do |filename, ast|
      path = @file_dirs[filename]
      subpath = path[path.index("controllers")..-1]
      File.new("#{dir}/app/#{subpath}", 'w').puts(@ruby2ruby.process(ast))
    end

    File.new("#{dir}/db/schema.rb", "w").puts(@ruby2ruby.process(@asts[:migration]))
    File.new("#{dir}/app/helpers/application_helper.rb", "w").puts(@ruby2ruby.process(@asts[:helper]))

    # We need to add these lines for string taint to work.
    Find.find("#{dir}/app/views") do |path|
      if legal_file(path)
        txt = File.read path
        File.new(path, 'w').puts "<% protect do %> #{txt} <% end %>"
      end
    end
  end

end

x = GCompiler.new.process(ARGV[0])
puts "Finished transforming"

