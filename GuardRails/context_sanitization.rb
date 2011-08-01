
###       This file contains the majority of code used        ###
###       to transform a string in accordance with the        ###
###       context rules specified by each chunk's             ###
###       transformer. Most of this file deals with HTML      ###
###       sanitization only.                                  ###  

module ContextSanitization

  # Taint marker is used to replace the current chunk being analyzed in a string
  # and then searched for by Nokogiri to see if it appears in the contexts picked
  # out by the transformer.  This string can contain arbitrarily context content,
  # but it is important to choose something that is unlikely to be found in common
  # text.  There is no security risk if a user types the content of this string,
  # but it may mess up their text in some cases.
  $taint_marker = "**gr**"
  
  # Helper method to get an array of the keys of a hash, returning
  # an empty array if the hash is currently nil
  def get_keys(hash)
    return [] if hash.nil?     
    return hash.keys
  end

  # Transform each chunk of the given string in accordance with each chunk's
  # Transformer and its rules for use in the HTML context.  The contents of
  # the entire string plays a role in dictating the more specfic context 
  # for each chunk WITHIN HTML.

  def context_sanitize(text)    
    new_string = ""
    index = 0
    orig_index = 0
    text = text.compress_taint

    # Iterate through each chunk in the string
    text.each_chunk do |str,tnt|   

      # Nothing needs to be done if the chunk is untainted
      if tnt.nil?
        new_string += str
      else 

        # Construct a new version of the string that consists of 
        # all of the parts of the string that have been transformed
        # so far (up to the current string) plus the rest of the
        # un-transformed string with any tainted portions temporarily
        # removed
        new_text = new_string + after_slice(text,orig_index) 

        # In most cases, only one transformation will need to be applied,
        # as the chunk is associated with only a BaseTransformer.  If, however,
        # the chunk is linked with a ComposedTransformer, then each of the
        # transformations associated with each of the Transformers in the 
        # ComposedTransformer need to be applied separately
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

        # Iterate through each of the transformations that need to be 
        # performed (usually only 1)
        taint_layers.each do |transform|
          transmethod = nil #Will stores the transformer that best matches the context

          # Check to make sure that the Transformer has an :HTML top-level 
          # context.  If not, much less work has to be done.
          if !transform.state.has_key?(:HTML)           

            # Even if the Transformer has no HTML rules, it may still dictate
            # which "Worlds" the content of the string should be in (tie in
            # to Yuchen Zhou's work)
            if transform.state.has_key?(:Worlds)
              transformed_string = "<span RACL='#{(get_keys(transform.state[:Worlds][:read])+get_keys(transform.state[:Worlds][:readR]))*','}' WACL='#{(get_keys(transform.state[:Worlds][:write])+get_keys(transform.state[:Worlds][:writeR]))*','}'>" + transformed_string + "</span>"  

              # If the chunk has rules for recursive world assignment (applying
              # the world labels to all tags found in chunk, not just around the
              # outsides), add the extra world attributes.  This will only occur
              # IF THE CHUNK CONTAINS ONLY WELL-FORMED HTML!
              if transformed_string == TaintTypes::TType.tag_protect(transformed_string)
                transformed_string = TaintTypes::TType.tag_protect(transformed_string, get_keys(transform.state[:Worlds][:readR]), get_keys(transform.state[:Worlds][:writeR]))
              end
            end

          # Now on to the case where there is a defined :HTML top-level
          # context rule
          else
            
            # Using the :HTML top-level context rules, determine the correct
            # transformation to apply
            transmethod = hash_recurse(transform.state[:HTML], new_text, index, str)

            # Annotation syntax specifies transformations using symbols, so
            # these need to be converted to instances of the appropriate
            # transformation object (TaintType) from taint_types.rb            
            if transmethod.is_a?(Symbol)
              transmethod = eval("TaintTypes::#{transmethod.to_s}.new")
            end            
            
            # Invoke the transformation method of the transformation (TaintType)
            transformed_string = transmethod.safe_class.sanitize(transformed_string)

            # Check to make sure that the chunk after the transformation still 
            # does not contain any malformed HTML, particularly, check to make
            # sure that the chunk does not open any tags without closing them
            # or vice-versa
            afterString = transmethod.safe_class.tag_protect(transformed_string)            
            if transformed_string == afterString && transform.state.has_key?(:Worlds)

              # Again, apply the recursive read and write worlds to all tags 
              # in the newly transformed chunk, but only if the chunk has
              # well-formed HTML that does close or open too many tags
              transformed_string = TaintTypes::TType.tag_protect(transformed_string, get_keys(transform.state[:Worlds][:readR]), get_keys(transform.state[:Worlds][:writeR]))
            else
              
              # Even if the chunk has been sanitized and does not have a Worlds
              # context, it still needs to contain well-formed HTML as not 
              # requiring this can lead to some issues with chunks closing
              # tags from other chunks.  Note that if the chunk is deemed malformed,
              # it will simply have its < and > characters replaced with &lt; and
              # &gt; respectively.

              #TODO: Our current definition of well-formed HTML includes adding the 
              # "/" to the end of single tags like "img" and "br", which most people
              # don't do.  We should make it more flexible, but not insecure. See
              # taint_types.rb for more

              transformed_string = afterString
            end

            # Already done the recursive worlds additions, but now need to 
            # add the spans around the content if there are ANY Worlds
            # annotations
            if transform.state.has_key?(:Worlds)
              transformed_string = "<span RACL='#{(get_keys(transform.state[:Worlds][:read])+get_keys(transform.state[:Worlds][:readR]))*','}' WACL='#{(get_keys(transform.state[:Worlds][:write])+get_keys(transform.state[:Worlds][:writeR]))*','}'>" + transformed_string + "</span>"
            end

            # If the newly transformed chunk is not tainted, it
            # will throw off our count of which tainted chunk we are
            # on, so we nee to compensate
            if transformed_string.taint.nil?
              index -= 1
            end
          end
        end

        # Add the newly transformed chunk to the current working string
        new_string += transformed_string    #.set_taint(tnt)
        
        index += 1
        orig_index +=1
      end 
   end
    return new_string
  end

  # Hash_recurse is used to match the HTML context of a string with the
  # appropriate transformation found in the set of nested hashes that
  # represent the top-level HTML context in the Transformer.  This function
  # uses recursion to be able to traverse nested hashes of arbirtrary depth.

  def hash_recurse(hash, new_text, index, string)
    themethod = nil
    default = nil
    
    # Go through each of the elements of the hash,
    # note that with the exception of the :DEFAULT marker,
    # which can be placed anywhere, the order in which elements
    # appear in the hash DOES MATTER, as the first match found
    # in a given hash will be the one that is picked, even if 
    # later elements include more nested hashes to check

    hash.each_pair do |key, val|
      if themethod.nil?

        # We only care about the :DEFAULT element if none
        # of the others match, so ignore it for now
        if key != :DEFAULT
          if taint_there?(new_text,key,index)      

            # If it's a hash, then keep going deeper, if not, then 
            # we already have a match!  Note that because nested
            # hashes must always have a :DEFAULT, once we know that
            # a nested hash matches, it will always return a method.
            # If the developer does not want this to be the case 
            # (i.e. if nothing matches in the nested hash, back up 
            # instead of using default) map :DEFAULT in that nested 
            # hash to "nil"
            if Hash === val then
              themethod = hash_recurse(val, new_text, index, string)
            else
              themethod = val
            end
          end         
        end
      end
    end
    
    # If no matches were found in the current hash, go with the one
    # marked as :DEFAULT.  If there isn't one, then throw an error
    if themethod.nil?
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
            return str[str.taint[n-1][0]+1..str.length-1]
          end
        end
        count += 1
      end
    end
  end

  # Checks a Nokogiri tree for whether the given taint occurs in the tree at the
  # given xpath
  def taint_there?(str,xpath,index)
    str.gsub($taint_marker,"") # Protect against people trying to match the taint_marker  

    # Use Nokogiri to find all of the nodes that match the given xpath from 
    # the context we are currently looking for
    matches = Nokogiri::HTML(all_taint_before_index(str,index)).xpath(xpath)

    # Search the results for the taint_marker.  If we find it, then we know 
    # that the tainted chunk in question appears in the context specified
    # by the given xpath
    res = false
    matches.each do |m| 
      res = res || locate_taint(m)
    end
    res
  end
  
  # Recursively searches a Nokogiri XML tree to see if it can find $taint_marker
  # as an indicater that the taint is a descendent of the root node of the search
  def locate_taint(node)
    ret = false
    
    # First, recursively search through the children of the node
    # if found there, we can stop looking
    node.children.each do |c|
      ret = ret || locate_taint(c)
    end
    if ret
      return true
    end

    # Second, search the attributes to see if the taint_marker is found
    # there.  If it is, stop searching
    if node.attributes
      node.attributes.values.each do |a| # Attributes
        if a.value.include?($taint_marker) 
          return true
        end
      end
    end


    # Now check to see if the taint_marker is in the node's text,
    # as in <a href="#">Blah Blah taint_marker Blah</a>.  If so,
    # return
    if node.type == 4 || node.type == 3 # Text and CDATA Nodes
      if node.text.include?($taint_marker)
        return true
      end
    end

    # This final check does something relating to attribute nodes
    # to see if they contain the taint_marker.  Quite frankly,
    # I can't remember why we need this
    if node.respond_to?("value") 
      if node.value.include?($taint_marker)
        return true
      end
    end

    # If we haven't found the taint_marker yet, then its not there
    return false
  end
  
  # Takes the current string and focuses on the substring of
  # text that is before the chunk that is currently being looked
  # at while adding only the untainted text that appears after. 
  # Usually this means taking only the part of the string 
  # that has already been sanitized, and removing the rest that
  # has yet to be sanitized

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

# LEGACY CODE!
=begin
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
=end

end
