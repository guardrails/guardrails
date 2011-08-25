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
  TODO: This needs to be fixed at some point
  def =~(str)    
    res = old_matcher(str)
  #  String.proxy_matchdata($~,str)   
    # No Support for local variable definition for names, is is
    # possible ?
    return res
  end
=end
end

class Hash
  attr_accessor :tainted_keys
  if !{}.respond_to?("old_index_set")
    alias old_index_set []=
  end
  if !{}.respond_to?("old_keys")
    alias old_keys keys
    alias old_each each
    alias old_clear clear
    alias old_init initialize
    alias old_store store
    alias old_assoc assoc
    alias old_rassoc rassoc
    alias old_flatten flatten
    alias old_replace replace
    alias old_invert invert
    alias old_each_pair each_pair
    alias old_each_key each_key
    alias old_merge merge
  end
  def initialize(*args)
    old_init(*args)
  end
  def unfreeze(str)
    eval(str.inspect)
  end
  def []=(*args)
    self.send("store",*args)
  end
  def store(*args)
    key = args[0]
    if key.is_a?(String)        
      if !key.taint.nil?
        @tainted_keys ||= {}
        @tainted_keys.old_index_set(key,key.taint)
      end
    end 
    old_index_set(*args)
  end
  def assoc(*args)
    res = old_assoc(*args)
    if @tainted_keys
      if !res.nil?
        new_val = unfreeze(res[0])
        new_val.taint = @tainted_keys[res[0]]
        res[0] = new_val
        return res
      else
        return res
      end
    else
      return res
    end
  end
  def rassoc(*args)
    res = old_rassoc(*args)
    if @tainted_keys
      if !res.nil?
        new_val = unfreeze(res[0])
        new_val.taint = @tainted_keys[res[0]]
        res[0] = new_val
        return res
      else
        return res
      end
    else
      return res
    end
  end
  def clear(*args)
    @tainted_keys = {}
    old_clear(*args)
  end
  def flatten(*args)
    full_res = old_flatten(*args)
    short_res = old_flatten
    if @tainted_keys
      f_index = 0    
      s_index = 0
      while s_index < short_res.length
        new_val = unfreeze(full_res[f_index])
        new_val.taint = @tainted_keys[new_val]
        full_res[f_index] = new_val
        if short_res[s_index+1].is_a?(Array)
          if args.length == 0 || args[0] <= 1
            f_index += 2
          else
            f_index += short_res[s_index+1].flatten(args[0]-2).size+1
          end
        else
          f_index += 2
        end
        s_index += 2
      end
      return full_res
    else
      return full_res
    end
  end
  def self.example
    a = "abc".mark_default_tainted
    b = "def".mark_default_tainted
    c = "ghi".mark_default_tainted
    d = "jkl".mark_default_tainted
    z = {}
    z[a] = "zzz".mark_default_tainted
    z[b] = [1,2,3]
    z[c] = [1, [2, 3, [4, 5], 6], 7]
    z[d] = 5
    z
  end
  def each(&block)
    if block_given?
      old_each do |key, val|
        if @tainted_keys && @tainted_keys[key] 
          k2 = unfreeze(key)
          k2.taint = @tainted_keys[key]
          key = k2
        end
        yield key,val
      end
    else
      enum_gen = old_each.to_a
      if @tainted_keys
        for i in (0...enum_gen.length)
          if enum_gen[i][0].is_a?(String)
            enum_gen[i][0].taint = @tainted_keys[enum_gen[i][0]]
          end
        end
      end
      return enum_gen.each
    end
  end
  def each_pair(&block)
    send("each",&block)
  end
  def each_key(&block)
    keys.to_a.each(&block)
  end
  def invert
    new_tainted_keys = {}
    old_values = values
    old_values.each do |val|
      if val.is_a?(String)
        if !val.taint.nil?
          new_tainted_keys[val] = val.taint
        end
      end
    end
    res = old_invert
    res.tainted_keys = new_tainted_keys
    if @tainted_keys
      res.values.each do |val|     
        if val.is_a?(String)
          new_val = unfreeze(val)
          new_val.taint = @tainted_keys[val]
          new_val.freeze
          res[self[val]] = new_val
        end
      end
    end
    res
  end
  def keys
    res = old_keys
    if @tainted_keys
      res.map! do |k|
        if @tainted_keys[k] 
          k2 = unfreeze(k)
          k2.taint = @tainted_keys[k]
          k2
        else
          k
        end        
      end
    end
   return res
  end
  def replace(other_hash)
    @tainted_keys = other_hash.tainted_keys
    old_replace(other_hash)
  end
  def merge(other_hash, &block)
    if block_given? 
      res = old_merge(other_hash) do |key, oldval, newval| 
        new_key = unfreeze(key)
        if @tainted_keys
          old_taint = @tainted_keys[key]
        else 
          old_taint = nil
        end
        if other_hash.tainted_keys
          new_taint = other_hash.tainted_keys[key]
        else
          new_taint = nil
        end
        if old_taint.nil? && new_taint.nil?
          real_new_taint = nil
        elsif (old_taint.nil? && !new_taint.nil?)
          real_new_taint = new_taint
        elsif (!old_taint.nil? && new_taint.nil?)
          real_new_taint = old_taint
        else
          #TODO: In this case, one taint is picked as preferred.
          # They should really be blended
          real_new_taint = new_taint
        end        
        new_key.taint = real_new_taint
        yield new_key, oldval, newval
      end
      return res
    else
      res = old_merge(other_hash)
      if @tainted_keys
        cross_taint = @tainted_keys.old_merge(other_hash.tainted_keys)
        res.tainted_keys = cross_taint
      end
      return res
    end
  end
end
