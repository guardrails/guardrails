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
