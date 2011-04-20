module ContextSanitization
  $taint_marker = "**gr**"
  
  # Sanitize any HTML tainted chunks based on the sanitization routine they
  # specify in their taint policy
  def context_sanitize(text)  
    new_string = ""
    index = 0
    text = text.compress_taint #(States::HTML) #This originally used the 'special compress taint'
    text.each_chunk do |str,tnt|     
      if tnt.nil?
        new_string += str
      else          
        new_text = new_string + after_slice(text,index) 
        puts "********* #{tnt}"
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
          puts "^^^^^ #{taint_layers} - #{transform}"
          if !transform.state.has_key?(:HTML)
            puts "Transformer is missing an HTML transformation.  Skipping..."
          else
            transmethod = hash_recurse(transform.state[:HTML], new_text, index, str)
            puts "!!!!!!!!!!!! #{transmethod} -- #{transmethod.nil?}"
            transformed_string = transmethod.safe_class.sanitize(transformed_string)
          end
        end
        new_string += transformed_string.set_taint(tnt)
        index += 1
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
            if Hash === val then
              themethod = hash_recurse(val, new_text, index, string)
            else
              themethod = val
            end
          end
        end
      end
    end
    if themethod.nil?
      if !hash.has_key?(:DEFAULT)
        raise StandardError, "Wanted to use :DEFAULT sanitization routine, but none was specified! String: #{string} - Hash: #{hash}"
      end
      puts "Here's the hash: #{hash}"
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
    matches = Nokogiri::HTML(all_taint_before_index(str,index)).xpath(xpath)
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
    ret = false
    node.children.each do |c|
      ret = locate_taint(c)
    end
    if ret
      return true
    end
    if node.attributes
      node.attributes.values.each do |a| # Attributes
        if a.value.include?($taint_marker) 
          return true
        end
      end
    end
    if node.type == 4 || node.type == 3 # Text and CDATA Nodes
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
