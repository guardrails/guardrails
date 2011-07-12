module ContextSanitization
  $taint_marker = "**gr**"
  
  # Sanitize any HTML tainted chunks based on the sanitization routine they
  # specify in their taint policy
  def context_sanitize(text)   
    new_string = ""
    index = 0
    orig_index = 0
    text = text.compress_taint #(States::HTML) #This originally used the 'special compress taint'
    text.each_chunk do |str,tnt|   
      if tnt.nil?
        new_string += str
      else 
#        puts "*************************************************"
#        puts "Looking at: #{str}.  Index: #{index}"
#        puts "*************************************************"
        new_text = new_string + after_slice(text,orig_index) 
        taint_layers = Array.new
        case tnt
        when BaseTransformer
          taint_layers << tnt
        when ComposedTransformer
          taint_layers = tnt.transformers
        else
          taint_layers << tnt
        end
        transformed_string = str
        taint_layers.each do |transform|
          transmethod = nil
          if !transform.state.has_key?(:HTML)
            #puts "Transformer is missing an HTML transformation.  Skipping..."
            if transform.state.has_key?(:Worlds)
              puts "World Data 1: #{transform.state[:Worlds]}"
              transformed_string = "<span style='color: blue' RACL='#{transform.state[:Worlds][:read].keys*','}' WACL='#{transform.state[:Worlds][:write].keys*','}'>" + transformed_string + "</span>"  
            end
          else
            transmethod = hash_recurse(transform.state[:HTML], new_text, index, str)
            if transmethod.is_a?(Symbol)
              transmethod = eval("TaintTypes::#{transmethod.to_s}.new")
            end
            transformed_string = transmethod.safe_class.sanitize(transformed_string)
            if transform.state.has_key?(:Worlds)
              puts "World Data 2: #{transform.state[:Worlds]}"
              transformed_string = "<span style='color: blue'>" + transformed_string + "</span>"
            end
#            puts "Result: #{transformed_string} with tnt: #{transformed_string.taint}" 
            if transformed_string.taint.nil?
              index -= 1
            end
          end
        end
        new_string += transformed_string#.set_taint(tnt)
        index += 1
        orig_index +=1
      end 
   end
    return new_string
  end
  def hash_recurse(hash, new_text, index, string)
    themethod = nil
    default = nil
    hash.each_pair do |key, val|
      if themethod.nil?
        if key != :DEFAULT
          if taint_there?(new_text,key,index)          
#            puts "Taint There!"
            if Hash === val then
              themethod = hash_recurse(val, new_text, index, string)
            else
              themethod = val
            end
          else
#            puts "Taint not there!"
          end         
        end
      end
    end
    if themethod.nil?
#      puts "Going with the default"
      if !hash.has_key?(:DEFAULT)
        raise StandardError, "Wanted to use :DEFAULT sanitization routine, but none was specified! String: #{string} - Hash: #{hash}"
      end
      themethod = hash[:DEFAULT]
    end
    return themethod
  end

  # Get the input string so that everything before the given taint index is safe and
  # any tainted chunks after are removed
  def after_slice(str, index)
    count = 0
    for n in (0..str.taint.length-1)
      if !str.taint[n][1].nil?
        if count == index
          if n == 0
            return str
          else            
   #       puts "After Slicing #{str[str.taint[n-1][0]+1..str.length-1]}"
            return str[str.taint[n-1][0]+1..str.length-1]
          end
        end
        count += 1
      end
    end
  end

  #Checks a Nokogiri tree for whether the given taint occurs in the tree at the
  #given xpath
  def taint_there?(str,xpath,index)
    str.gsub($taint_marker,"") # Protect against people trying to match the taint_marker  
#    puts "All Taint: #{index} ---- " + all_taint_before_index(str,index)
    matches = Nokogiri::HTML(all_taint_before_index(str,index)).xpath(xpath)
#    puts "Matches:::: " + matches.inspect
    res = false
    matches.each do |m| 
      res = res || locate_taint(m)
    end
    res
  end
  
  def parse_taint(str)
    locate_taint(Nokogiri::HTML(all_taint_but_index(str,0)))
  end
  
  # Recursively searches a Nokogiri XML tree to see if it can find $taint_marker
  # as an indicater that the taint is a descendent of the root node of the search
  def locate_taint(node)
#    puts "recursing... At #{node.inspect}"
    ret = false
    node.children.each do |c|
      ret = ret || locate_taint(c)
    end
    if ret
      return true
    end
 #   puts "Last Checking #{node.type}"
    if node.attributes
      node.attributes.values.each do |a| # Attributes
        if a.value.include?($taint_marker) 
          return true
        end
      end
    end
    if node.type == 4 || node.type == 3 # Text and CDATA Nodes
  #    puts "Here's the text #{node.text} vs. #{$taint_marker} -- #{node.text.include?($taint_marker)}"
      if node.text.include?($taint_marker)
        return true
      end
    end
    if node.respond_to?("value") # Attribute Nodes
      if node.value.include?($taint_marker)
        return true
      end
    end
    return false
  end
  
  def all_taint_but_index(str,index)
    cur = 0
    new_string = ""
    str.to_qstring.each_chunk do |str,tnt|
      if tnt.value == "00"
        new_string += str.set_taint(tnt)
      else
        if cur != index
          new_string += str.set_taint(tnt)
        else
          new_string += $taint_marker
        end
        cur += 1
      end
    end
    new_string
  end

  def all_taint_before_index(str,index)
    cur = 0
    new_string = ""
    str.to_qstring.each_chunk do |str,tnt|
      if tnt.nil?
        new_string += str.set_taint(tnt)
      else
        if cur < index
          new_string += str.set_taint(tnt)
        elsif cur > index
          new_string += ""
        else
          new_string += $taint_marker
        end
        cur += 1
      end
    end
    new_string
  end
end
