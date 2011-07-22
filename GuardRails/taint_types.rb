include ActionView::Helpers

module TaintTypes
  include Wrapper
  include Wrapper::WrapperMethods
  include ActionView::Helpers
 
  # Parent for all taint types, assigns an index to all subclasses
  # so that they can be encoded in a smaller amount of space
  class TType
    @@subclasses = Array.new
    @@encode_vals = Hash.new
    @@decode_vals = Hash.new
    @@next_key = 1
    def self.upper_bound(*args)
      bound = args[0]
      for n in (1..args.length-1)
        while !args[n].new.is_a?(bound)
          bound = bound.superclass
        end
      end
      bound
    end
    def subclasses
      @@subclasses
    end
    def self.encode_vals
      @@encode_vals 
    end
    def self.decode_vals
      @@decode_vals
    end
    def self.inherited(subclass)
      @@subclasses << subclass.to_s
      @@encode_vals[subclass] = @@next_key
      @@decode_vals[@@next_key] = subclass
      @@next_key += 1
    end
    def inspect
      "#{self.class}"
    end

   def self.tag_protect(string, racl=nil, wacl=nil)
      old_taint = string.taint
      idx = 0
      begin
        while idx<string.length
          idx,string = self.parse_tags(string,0,nil,racl,wacl)
        end
      rescue
        string.gsub!("<","&lt;")
        string.gsub!(">","&gt;")
      end
      str = string.clone
      str.taint = old_taint
      return str
    end
    def self.parse_quote(string, idx)
      close = string[idx,1]
      addstring = string[idx,1]
      idx += 1
      while true
      while !["\"","\'"].include?(string[idx,1])
        addstring += string[idx,1]
        idx += 1
        if idx >= string.length
          raise StandardError, "unterminated quote"
        end
      end
      if string[idx,1] == close
        addstring += string[idx,1]
        idx += 1
        return string, idx, addstring
      end
      string, idx, addstring2 = self.parse_quote(string, idx)
      addstring += addstring2  
      end
    end
    def self.parse_tags(string, idx, close, racl=nil, wacl=nil)
      while true
      while idx < string.length && !["<",">"].include?(string[idx,1])
        idx += 1
      end
      if idx >= string.length && close != nil
        raise StandardError, "unclosed tag"
      end
      if idx >= string.length
        return idx, string
      end
      if string[idx,1] == ">"
        raise StandardError, "stray close tag"
      end
      if string[idx,1] == "<"
        activetag = ""
        idx += 1
        if idx >= string.length
          raise StandardError, "unterminated tag"
        end
        while string[idx,1] == " "
          idx += 1
          if idx >= string.length
            raise StandardError, "unterminated tag"
          end
        end

        # close tag
        if string[idx,1] == "/"     
          idx += 1
          if idx >= string.length
            raise StandardError, "unterminated tag"
          end
          while string[idx,1] == " "
            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end    
          while ![">"," ", "<"].include?(string[idx,1])            
            activetag += string[idx,1]
            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end    
          while string[idx,1] != ">"
            if string[idx,1] == "<"
              raise StandardError, "stray open tag"
            end
            idx += 1
            if idx >= string.length
              raise StandardError, "unterminated tag"
            end
          end      
          if activetag != close
            raise StandardError, "mismatched tags"            
          end
          idx += 1
          return idx, string
        end

     # open tag
        closed_tag = false

        # Determine the tag type
        while ![">"," ", "<","/"].include?(string[idx,1])
          activetag += string[idx,1]
          idx += 1
          if idx >= string.length
            raise StandardError, "unterminated tag"
          end
        end  

        # Terminator can be directly after the tag type (no space)
        closed_tag = true if string[idx,1] == "/"

        # Skim through the rest of the tag
        while string[idx,1] != ">" and string[idx,1] != "/" and !closed_tag
          if string[idx,1] == "<"
            raise StandardError, "stray open tag"
          end
          idx += 1
          if (["\"", "\'"].include?(string[idx,1]))
            string, idx, addition = self.parse_quote(string,idx)
          end
          if idx >= string.length
            raise StandardError, "unterminated tag"
          end
        end        

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

        if string[idx,1] == "/"
          closed_tag = true 
          idx += 1
        end
        while string[idx,1] != ">"
          if string[idx,1] == "<"
            raise StandardError, "stray open tag"
          end
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
  class Identity < TType
    def self.sanitize(string)
      return string
    end
  end
  class SQLBase < TType
    def self.sanitize(string)      
      return ""
    end
  end
  class SQLDefault < SQLBase
    def self.sanitize(string)
      string = string.gsub("'", "")
      string = string.gsub("\\", "")
      string = string.gsub("\"", "")
#      string.taint[0][1].state.delete(:SQL)     
      return string
    end
  end
  class HTMLBase < TType
    def self.sanitize(string)
      return ""
    end
  end
  class Invisible < HTMLBase
    def self.sanitize(string)
      return ""
    end
  end
  class NumbersOnly < Invisible
    def self.sanitize(string)
      string.gsub(/[^0-9]/,"")
    end
  end
  class LettersOnly < Invisible
    def self.sanitize(string)
      string.gsub(/[^a-zA-Z]/,"")
    end
  end
  class AlphaNumericOnly < LettersOnly
    def self.sanitize(string)
      string.gsub(/[^a-zA-Z0-9]/,"")
    end
  end
  class AlphaNumericHTMLRemoved < LettersOnly
    def self.sanitize(string)
      string = ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => []).gsub(/[^a-zA-Z0-9]/,"")
    end
  end
  class NoHTML < AlphaNumericOnly
    def self.sanitize(string)
      ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => [])
    end
  end
  class BoldItalicOnly < NoHTML
    def self.sanitize(string)
      ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => ["b","i"])
    end
  end
  class BoldItalicUnderlineOnly < BoldItalicOnly
    def self.sanitize(string)
      ActionView::Helpers::SanitizeHelper.sanitize(string, :tags => ["b","u","i"])
    end
  end
  class HTMLAllowed < BoldItalicUnderlineOnly
    def self.sanitize(string)
      string
    end
  end
end

class TaintContexts
  TagAttribute = "//@*"
  TitleTag = "//title"
  LinkTag = "//a"
  Javascript = "//script[@language='javascript'] | //script[@language='text/javascript']"
  ScriptTag = "//script"
end
