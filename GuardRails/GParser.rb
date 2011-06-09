require 'ruby_parser'
require 'Annotation'

Annotation_regex = /^\s*#\s*@.*/
Annotation_start_regex = /^\s*#\s*@/
Comment = /#[^$]*/
Embedded_ruby_flag = /<%?%|%?%>/
Embedded_ruby_line = /^\s*%[^>]*\n/
Erb_file_regex = /^.*\.erb/
String_regex = /(^|[^\\])"([^\\"]|\\.)*"/

#class Annotation
#	attr_accessor :type
#	attr_accessor :id
#	attr_accessor :attrs
#	attr_accessor :policy
#	attr_accessor :lambda
#	attr_accessor :target

#	def inspect
#		return (	  "Ann.type  : " + @type.to_s +
#					", Ann.id    : " + @id.to_s +
#					", Ann.attrs : " + @attrs.to_s +
#					", Ann.policy: " + @policy.to_s +
#					", Ann.lambda: " + @lambda.to_s +
#					", Ann.target: " + @target.to_s)
#	end
#end

class GParser
  attr_accessor :is_erb
  attr_accessor :ann_list
  def parse(filename)
    begin
      return unless File.exist?(filename)

      @src = File.read(filename)
      @parser = RubyParser.new
      @lexer = @parser.lexer
      @src_by_lines = @src.split(/\n|;/)
      @is_erb = false
      @ann_list = []

      # If the file is an html file with embedded ruby, we need to treat it
      # differently.  Instead, go inside and extract the ruby code from
      # the flags inside the file.
      if filename =~ Erb_file_regex
        @is_erb = true
        @src = convert_to_ruby(@src)
      end

      begin
        @ast = @parser.parse(@src)
      rescue StandardError => msg
        puts "RubyParser parsing error..."
        puts msg
      end

      traverse(@ast)
    rescue StandardError => msg
      puts "Did not transform #{filename}"
      puts msg
    end
    return @ast
  end

  def traverse(node)
    if node.class != Sexp
      return
    end
    if (id = get_identifier(node)) != nil
      # gr_html is our reserved keyword
      match(id, node) unless id == "gr_html"
    end
    node.each { |child|
      traverse(child)
    }
  end

  def get_identifier(node)
    # declarations
    if node[0] == :class or node[0] == :defn
      return node[1].to_s
    end
    # accessors
    if node[2] == :attr_reader or
    node[2] == :attr_writer or
    node[2] == :attr_accessor or
    node[2] == :attr or
    #associations
    node[2] == :belongs_to or
    node[2] == :has_one or
    node[2] == :has_many or
    node[2] == :has_and_belongs_to_many
      return node[3][1][1].to_s
    end
    return nil
  end

  def build_annotations(ann_src, node)
    ann = Annotation.new

    ann_src.slice!(Annotation_start_regex)
    arr = ann_src.split(",") #TODO - split by something else
    #ann.policy = arr[0].strip.to_sym
    #ann.lambda = arr[-1].strip
    begin
      eval("ann.build("+ann_src+")");
    rescue StandardError => msg
      puts "Invalid annotation..."
      puts msg
    end

    if node[0] == :defn
      # We can now annotate function definitions to be privalidged functions.
      ann.type = :func
      ann.target = node[1]
      return [ann]
    end

    if node[0] == :class
      # We can annotate classes, but class annotations
      # can actually be attr annotations because of rails hack.

      #if arr.length > 2
      if !ann.target.nil?
        # If the optional field is included, its an attr annotation
        #        anns = []
        #        ann.type = :attr
        #        targets = arr[1..-2]
        #        targets.each { |tar|
        #          next_ann = ann.deep_clone
        #          next_ann.target = tar.strip
        #          anns.push next_ann
        #        }
        #        return anns
      else
        ann.type = :class
        ann.target = node[1]
      end
    elsif node[0] == :call
      anns = []
      node[3].each { |assoc|
        next if assoc == :arglist
        next_ann = ann.deep_clone
        next_ann.target = assoc[1]
        anns.push next_ann
      }
      return anns
    else
      ann.type = :attr
      ann.target = node[1]
    end

    return [ann]
  end

  def match(id, node)

    # Use an array of annotation objects so we can recognize multiple
    # annotations for a single line of code
    anns = []

    while (line = @src_by_lines.shift) != nil
      if(line =~ Annotation_regex) != nil
        anns.concat(build_annotations($~.to_s.lstrip, node))
      end
      if line_has_identifier?(line, id)
        apply_annotation(node, anns, id)
        return
      end
    end
    pp "ERROR: Never found token (" + id + ") in the source code..."
  end

  def apply_annotation(node, anns, id)
    if node.class == Sexp
      if (node[2] == :attr_reader or node[2] == :attr or node[2] == :attr_writer or
      node[2] == :attr_accessor)
        anns.each_index{ |i|
          anns[i].type = :attr
        }
        node[3].each{ |arg|
          apply_annotation(arg, anns, arg[1].to_s) unless arg == node[3][0]
        }
        return true
      elsif (node[2] == :belongs_to or node[2] == :has_one or
      node[2] == :has_many or node[2] == :has_and_belongs_to_many)
        anns.each_index{ |i|
          anns[i].type = :assoc
        }
        node[3].each{ |arg|
          return false unless arg.class == Sexp
          apply_annotation(arg, anns, id) unless arg[0] == :hash
        }
        return true
      end

      # Annotations are inserted to the end of the sexp so that we don't
      # change the current ast, only add to it
      anns.each { |ann|
        my_ann = ann.deep_clone
        ann_list.push(my_ann)
      }
      true
    end
    false
  end

  def get_annotations(filename)
    parse(filename)
    return @ann_list
  end

  # We need this to differentiate between actual instances of the id and just
  # text by the same name within a line (perhaps in quotes as a string or in a
  # comment, which would make it otherwise inadmissable).
  def line_has_identifier?(line, id)
    while (index = line.index(String_regex)) != nil
      line.insert(index, line.slice!(String_regex)[0..0])
      line.slice!(/^"/)
    end
    line.slice!(Comment)
    return line.include?(id)
  end

  # These are the accepted ERB formats
  # <% Ruby code -- inline with output %>
  # <%= Ruby expression -- replace with result %>
  # <%# comment -- ignored -- useful in testing %>
  # % a line of Ruby code -- treated as <% line %> (optional -- see ERB.new)
  # %% replaced with % if first thing on a line and % processing is used
  # <%% or %%> -- replace with <% or %> respectively

  def convert_to_ruby (src)
    rb = ""
    # dunno how to deal with only leading declarations of ruby code,
    # so replace it with the other markings
    while	src.index(Embedded_ruby_line) != nil
      src.sub!(Embedded_ruby_line) { |match|
        match[match.index '%'] = " "
        "<% " + match + " %>"
      }
    end
    lines = src.split(Embedded_ruby_flag)

    is_ruby_line = false
    lines.each { |line|
      if (line.strip != "" and line.strip != nil)
        if is_ruby_line
          if line[0] == '='
            line[0] = " "
            rb += "puts " + line.strip
          else
            rb += line.strip
          end
        else
          rb += "gr_html(\"" + line + " gr_html\")"
        end
        rb += "\n"
      end
      is_ruby_line = (not is_ruby_line)
    }
    puts rb
    return rb
  end

  def convert_to_erb(code)
    code_by_words = code.split
    code_by_words.insert(0, "<%")
    inside_ruby_code = true
    code_by_words.each_index{ |index|
      if code_by_words[index].index('gr_html')
        if inside_ruby_code
          code_by_words[index] = "%>"
        else
          code_by_words[index] = "<%"
        end
        inside_ruby_code = (not inside_ruby_code)
      end
    }
    code_by_words.push("%>")
    code = code_by_words.join(" ")
    return code
  end

end

#pp GParser.new.get_annotations(ARGV[0])
