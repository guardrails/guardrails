###  This file contains extra taint tracking support       ###
###  particularly for string related functions in classes  ###
###  other than String that are written in C               ###

###  **This file needs a bit more work to ensure that all  ###
###    string-related functions to not drop taint info     ###

include TaintSystem

module ExtraString
end

class File
  if !File.respond_to?("old_extname")    
    class << self      
      alias old_extname extname
      alias old_join join      
    end
  end
  def self.extname(string)
    tstring = false
    use_string = string
    ret = self.old_extname(use_string)
    ret = ret.set_taint string.effective_taint
    if tstring
      ret = TString.new(ret, string.cdiv, string.tdiv, string.char_hash)
    end
    return ret
  end
  def self.join(*strings)
    tstring = Array.new
    use_strings = strings
    for n in (0..strings.length-1)
      begin
        if strings[n].respond_to?("target") # is it a TString?
          tstring[n] = true       
          use_strings[n] = strings[n].target
        else
          tstring[n] = false
        end
      rescue
        tstring[n] = false
      end
    end
    # end
    ret = self.old_join(*use_strings)
    return ret
    if !(String === ret)  
      return ret
    end
    ret = ret.to_qstring
    strings.each do |s|
      if String === s
        ret = ret.set_taint String.taint_union(s.to_qstring.effective_taint,ret.taint)
      end
    end
    return ret    
  end
end

# Array class 'pack' overwritten to correctly generate strings that are tainted
class Array
  if ![].respond_to?("old_pack")
    alias old_pack pack
  end
  def pack(format)
    safe = true
    taint = " ".to_qstring.effective_taint
    self.each do |t|
      if String === t
        if !t.safe?
          safe = false
          taint = String.taint_union(taint,t.effective_taint)
        end
      end
    end
    taint = String.taint_union(taint,format.effective_taint)
    safe = safe && format.safe?
    if safe
      old_pack(format)
    else
      res = old_pack(format)
      res = res.set_taint(taint)
      return res
    end
  end
  if ![].respond_to?("old_join")
    alias old_join join
  end
  if ![].respond_to?("old_mult")
    alias old_mult *
  end
  def join(str = "")
    res = ""
    if self.size > 0 && String === self[0] 
      self.each do |indx|
        if indx
          if Array === indx
            indx = indx.join
          end      
          begin
            res += indx.to_s + str.to_s
          rescue
            raise StandardError, "Failure in Array Join with parameter: #{self}"
          end
        end
      end
      return res[0..res.length-str.length-1]
    else
      return old_join(str)
    end
  end
  def *(str)
    if self.size > 0 && String === self[0] 
      res = ""
      self.each do |indx|
        res += indx + str
      end
      return res[0..res.length-str.length-1]
    else
      return old_mult(str)
    end
  end
end

class Regexp
  if !//.respond_to?("old_match")
    alias old_match match
  end
  def match(*args)
    if !args[0].safe?
      String.proxy_matchdata(old_match(*args),args[0])
      return $gr_md
    else
      self.old_match(*args)
    end
  end
  def self.last_match(*args)
    raise StandardError "This Action Currently Forbidden!"
  end

  if !//.respond_to?("old_matcher")
    alias old_matcher =~
  end
=begin
  This needs to be fixed at some point
  def =~(str)    
    res = old_matcher(str)
  #  String.proxy_matchdata($~,str)   
    # No Support for local variable definition for names, is is
    # possible ?
    return res
  end
=end
end
