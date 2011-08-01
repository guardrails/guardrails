include ActionView::Helpers

module TaintTypes
  include Wrapper
  include Wrapper::WrapperMethods
  include ActionView::Helpers
 
  class TType
    def inspect
      "#{self.class}"
    end

   # tag_protect, combined with parse_quote and parse_tags, attempts to parse
   # any HTML found in the string in question and ensure that it is well-formed.
   # In particular, it needs to be the case that any string checked do not 
   # close tags they did not open and do not open any tags they do not close.
   # In addition, things like quotes that are started but not finished are 
   # also checked.

   # TODO: Currently we are very strict about what counts as well-formed
   # HTML.  <img src=".."> counts as invalid because it does not end with
   # a "/" or a "</img>".  It is common to do this, however, so we probably
   # need this to be more flexible

   def self.tag_protect(string, racl=nil, wacl=nil)
      old_taint = string.taint
      idx = 0

      # Attempt to parse the HTML in the input string. If there
      # are any issues, an error will be thrown and the rescue
      # clause will replace any "<" and ">" characters with their
      # HTML-escaped equivalents
      begin
        while idx<string.length
          idx,string = self.parse_tags(string,0,nil,racl,wacl)
        end
      rescue
        string.gsub!("<","&lt;")
        string.gsub!(">","&gt;")
      end

      # Return either the original string that has well-formed HTML
      # (assuming racl and wacl are nil), the HTML with RACL and WACL
      # values placed on all tags, or the malformed HTML stripped of
      # its tags
      str = string.clone
      str.taint = old_taint
      return str
    end

    # parse_quote analyzes the use of quotes to make sure that they
    # are not left unterminated, and that HTML irregularities contained
    # in quotes (like using < to mean less than) don't cause the 
    # string to be deemed malformed

    # TODO: Check to see if contractions like "I'm happy" are allowed
    # or whether they count as malformed
    def self.parse_quote(string, idx)      
      
      # The leading quote is the first character and needs to be matched
      # to close the quote, but nested quotes must not throw off the 
      # matching
      close = string[idx,1] 
      addstring = string[idx,1]
      idx += 1

      while true

        # Keep moving through the string until something that
        # looks like a string is hit
        while !["\"","\'"].include?(string[idx,1])
          addstring += string[idx,1]
          idx += 1

          # If the string ends, but there is no end quote, 
          # there is a problem
          if idx >= string.length
            raise StandardError, "unterminated quote"
          end
        end
        
        # If the quote that is hit matches the start, then
        # the quote is being terminated and we can quit
        if string[idx,1] == close
          addstring += string[idx,1]
          idx += 1
          return string, idx, addstring
        end

        # If this line is reached, it means a quote that was
        # not the starting quote was reached, meaning we must
        # recursively call parse_quote to see check that this 
        # quote also has proper syntax

        string, idx, addstring2 = self.parse_quote(string, idx)
        addstring += addstring2  
      end
    end

    def self.parse_tags(string, idx, close, racl=nil, wacl=nil)
      while true

        # Plow through the string until we hit a "<" or ">" or the
        # end of the string.  We don't care about characters that 
        # have nothing to do with tags

        # TODO: Check that quotes that have tags in them don't cause trouble
        # We know the case of tags with quotes in them is handled
        while idx < string.length && !["<",">"].include?(string[idx,1])
          idx += 1
        end

        # If we're past the end of the string and we were expecting
        # to find a terminating tag (if "close" is not nil), then
        # we have a problem of an unterminated tag
        if idx >= string.length && close != nil
          raise StandardError, "unclosed tag"
        end

        # If we hit the end of the string and there close was nil,
        # (we weren't expecting any close tags), then we're done
        if idx >= string.length
          return idx, string
        end

        # If there is a > just sitting in the text for some reason,
        # that's a problem
        if string[idx,1] == ">"
          raise StandardError, "stray close tag"
        end

        # Checking for the start of new open tag
        if string[idx,1] == "<"
          activetag = "" # will store the name of the current tag
          idx += 1
          if idx >= string.length
            raise StandardError, "unterminated tag"
          end

          # Skip through space between < and tag name
          while string[idx,1] == " "
            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end
          
          # If the first non-whitespace character is a "/", then this
          # tag must be a close tag
          if string[idx,1] == "/"     
            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end

            # Remove more whitespace between the "/" and the actual tag name
            while string[idx,1] == " "
              idx += 1
              if idx >= string.length
                raise StandardError, "unterminated tag"
              end
            end    

            # Parse the name of close tag and store it
            # in "activetag"
            while ![">"," ", "<"].include?(string[idx,1])            
              activetag += string[idx,1]
              idx += 1
              if idx >= string.length
                raise StandardError, "unterminated tag"
              end
            end    
            
            # Skip through anything else in the close tag,
            # not that there should be anything else.  For
            # that reason, we don't check for quote here

            while string[idx,1] != ">"
              if string[idx,1] == "<"
                raise StandardError, "stray open tag"
              end
              idx += 1
              if idx >= string.length
                raise StandardError, "unterminated tag"
              end
            end      
            
            # The name of the close tag must match the one we
            # are looking for, otherwise we have a case of overlapping
            # tags (i.e. <b><i></b></i>), which is forbidden in rigid 
            # HTML syntax, although some browsers still accept it

            if activetag != close
              raise StandardError, "mismatched tags"            
            end
            idx += 1
            return idx, string
          end
          
          # If we haven't returned yet, then we must be looking at 
          # an open tag

          closed_tag = false # This refers to whether or not the tag
                             # is closed by itself, as in <tag />
                             # vs. whether or not we should be looking
                             # for a matching close tag
          
          # Read in the tag name
          while ![">"," ", "<","/"].include?(string[idx,1])
            activetag += string[idx,1]
            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end  
          
          # Terminator can be directly after the tag type (no space)
          closed_tag = true if string[idx,1] == "/"
          
          # Skim through the rest of the tag.  Nothing of importance here
          # until we hit a ">" or "/", with the exception of quotes, which
          # might contain these characters without affecting the HTML

          while string[idx,1] != ">" and string[idx,1] != "/" and !closed_tag
            if string[idx,1] == "<"
              raise StandardError, "stray open tag"
            end
            idx += 1
            
            # Handle quotes appearing in the tag
            if (["\"", "\'"].include?(string[idx,1]))
              string, idx, addition = self.parse_quote(string,idx)
            end

            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end        
          
          # If RACL or WACL tags (part of collaboration with Yuchen
          # Zhou's work) are to be added, stick them in at the end
          # of the tag, but before the "/" (if there is one) and the ">"

          if !racl.nil? && racl.count > 0
            addString = " RACL='#{racl*','}'"
            string.insert(idx,addString)
            idx += addString.length
          end
          if !wacl.nil? && wacl.count > 0
            addString = " WACL='#{wacl*','}'"
            string.insert(idx,addString)
            idx += addString.length
          end
          
          # If there's a "/" at the end of the tag, then we don't
          # need to worry about finding a matching close tag
          if string[idx,1] == "/"
            closed_tag = true 
            idx += 1
          end

          # Move through the string until we hit the end ">"
          
          while string[idx,1] != ">"
            if string[idx,1] == "<"
              raise StandardError, "stray open tag"
            end

            # Nothing should be between the "/" of a self-closing tag
            # and the closing ">" (i.e. <img /x> is not allowed)
            if closed_tag and string[idx,1] != " "
              raise StandardError, "unexpected character #{string[idx,1]}"
            end

            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end

          idx += 1 #go past the >
          idx, string = self.parse_tags(string, idx, activetag, racl, wacl) unless closed_tag
        end
      end
    end    
  end

  # These two transformations are rather gimmicky and used by 
  # us throughout our tests as an example of a "sanitization routine"
  # that is easily visible.  Also, this demonstrates that sometimes
  # "sanitization" can actually ADD features (like styles and the like).
  # Just be sure that if you do use transformations this way, that you
  # still include sanitization routines, otherwise this will leave you
  # open to XSS as each chunk can only be associated with one transformation
  # in a given context (with the exception of ComposedTransformations, but
  # this behavior cannot be coerced (well, at least not easily))

  class SwitchGs < TType
    def self.sanitize(string)
      string.gsub(/(g|G)/) { "<u>" + $1.swapcase + "</u>"}
    end
  end
  class SwitchDs < TType
    def self.sanitize(string)
      string.gsub(/(d|D)/) { "<b>" + $1.swapcase + "</b>"}
    end
  end

  ### -------------------------------------------------------------- ###
  ###   Here is the list of Transformations that may be used in      ###
  ###   BaseTransformers.  Simply adding a class that descends from  ###
  ###   TType is sufficient to make it so you can use that           ###
  ###   transformation in a taint annotation. Note that every        ###
  ###   descendent of TType is expected to define the function       ###
  ###   self.sanitize(string), which should return some transformed  ###
  ###   version of the string.  Also note that it does not matter    ###
  ###   which class a transformation descends from, as long as it    ###
  ###   ultimately descends from TType.  The inheritance scheme is   ###
  ###   left over from an older implementation of GuardRails.        ###
  ### -------------------------------------------------------------- ###

  # The Identity Transformation - Does nothing to the string
  class Identity < TType
    def self.sanitize(string)
      return string
    end
  end

  # Parent class for all SQL Sanitization Routines
  # Of course, SQL related transformations need not
  # descend from this class
  class SQLBase < TType
    def self.sanitize(string)      
      return ""
    end
  end

  # SQLDefault removes many of the characters that can cause
  # trouble when used in SQL query
  class SQLDefault < SQLBase
    def self.sanitize(string)
      string = string.gsub("'", "")
      string = string.gsub("\\", "")
      string = string.gsub("\"", "")
      return string
    end
  end

  # Parent class for all HTML Sanitization Routines
  # Of course, HTML related transformations need not
  # descend from this class
  class HTMLBase < TType
    def self.sanitize(string)
      return ""
    end
  end

  # Invisible removes the tainted content altogether, 
  # useful if one wants to be sure abolutely sure that 
  # a given string (or chunk) will not cause any trouble
  class Invisible < HTMLBase
    def self.sanitize(string)
      return ""
    end
  end

  # Numbers only removes all characters that are not
  # numbers, useful if you have some user input that 
  # should only be allowed to contain numbers
  class NumbersOnly < Invisible
    def self.sanitize(string)
      string.gsub(/[^0-9]/,"")
    end
  end

  # Similar to NumbersOnly, LettersOnly removes all 
  # characters from the string (or chunk) that are not 
  # letters, useful if a certain piece of user input
  # is only supposed to contain letters (like a name)
  class LettersOnly < Invisible
    def self.sanitize(string)
      string.gsub(/[^a-zA-Z]/,"")
    end
  end

  # As expected, AlphaNumericOnly removes all characters
  # except numbers and letters (special characters, including
  # spaces, will be removed).  A username might have this
  # transformation associated with it in the HTML context
  class AlphaNumericOnly < LettersOnly
    def self.sanitize(string)
      string.gsub(/[^a-zA-Z0-9]/,"")
    end
  end

  # AlphaNumericHTMLRemoved takes out tags BEFORE removing all
  # non-letter or number characters.  Whereas with AlphaNumericOnly
  # "<b>Hello</b>" would become "bHellob", with AlphaNumericHTMLRemoved,
  # it would become "Hello"
  class AlphaNumericHTMLRemoved < LettersOnly
    def self.sanitize(string)
      string = ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => []).gsub(/[^a-zA-Z0-9]/,"")
    end
  end

  # No HTML does not explicitly prohibit a set of characters, 
  # but it does remove any HTML that might be present in the
  # string/chunk. 
  class NoHTML < AlphaNumericOnly
    def self.sanitize(string)
      ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => [])
    end
  end

  # As its name states, BoldItalicOnly removes all HTML,
  # except for bold and italic tags; useful if you want to 
  # allow a user to have bold or italic tags in their content,
  # but block any tags (like javascript) that might cause trouble
  class BoldItalicOnly < NoHTML
    def self.sanitize(string)
      ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => ["b","i"])
    end
  end

  # Identical to BoldItalicOnly, except Underline is also allowed. 
  # These functions are really easy to make if you want something 
  # even more specific: just alter the "tags" list in the
  # sanitize function
  class BoldItalicUnderlineOnly < BoldItalicOnly
    def self.sanitize(string)
      ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => ["b","u","i"])
    end
  end

  # HTMLAllowed simply does no sanitization and allows any 
  # characters, including those that form HTML tags
  class HTMLAllowed < BoldItalicUnderlineOnly
    def self.sanitize(string)
      string
    end
  end
end

# TaintContexts is meant to be a set of shortcuts for
# commonly used XPath contexts.  This should allow developers
# to use these nicknames, or their corresponding strings 
# when constructing annotations

# TODO: These nicknames are currently unsupported in annotations.
# Annotation currently allow only XPath strings for HTML contexts.
# Support for these nicknames should be added.

class TaintContexts
  TagAttribute = "//@*"
  TitleTag = "//title"
  LinkTag = "//a"
  Javascript = "//script[@language='javascript'] | //script[@language='text/javascript']"
  ScriptTag = "//script"
end
