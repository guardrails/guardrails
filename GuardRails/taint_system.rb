
###    The main code library used to manage taint tracking.   ###
###    Contains all of the overridden string functions as     ###
###    well as basic functions for handling string taint      ###
###    information.                                           ###

# A non-module used to force Rails to load this file
module TaintSystem
  
  # Look for chunks that are HTML-tainted, then assign them the given taint rules
  def self.taint_field(string, top_level, taint_hash)
    new_string = ""
    string.each_chunk do |str,tnt|
#      puts "Str: #{str}, Tnt: #{tnt}"
      if ComposedTransformer === tnt 
        newTransformer = tnt.clone
        newTransformer.copy_clone!
        newTransformer.transformers.each do |t|
          t.state[top_level] = taint_hash         
        end
        new_val = str.set_taint(new_taint)
        new_string += new_val
      else
#        puts "uncomposed"
      # Ignore if nil, it's untainted      
        if tnt == nil || !tnt.state.has_key?(top_level) || tnt.state[top_level].nil?
#          puts "nilly"
        new_string += str.set_taint(tnt)
        else
#          puts "unnilly"
          new_taint = tnt.clone
          new_taint.state[top_level] = taint_hash
          new_val = str.set_taint(new_taint)
          new_string += new_val
        end
      end
    end
    new_string
  end
  class TaintTransformer
    def transform(string, top_level_context=nil, additional_context=nil)
      return TaintTypes::Identity.sanitize(string)
    end
  end
  class RollbackTransformer < TaintTransformer
    attr_accessor :backup
    def transform(*args)
      return @backup
    end
  end
  class IdentityTransformer < TaintTransformer
    def transform(*args)
      return args[0]
    end
  end
  class ComposedTransformer < TaintTransformer
    attr_accessor :transformers
    def initialize
      @transformers = []
    end
    def transform(string, top_level_context = nil, additional_context=nil)
      activeString = string
      @transformers.each do |t|
        activeString = t.transform(activeString, top_level_context, additional_context)
      end
      return activeString
    end
    def copy_clone!
      for n in (0..@transformers.length-1)
        @transformers[n] = @transformers[n].clone
      end
    end
  end
  class BaseTransformer < TaintTransformer 
    include TaintTypes
    # Defines the DEFAULT value for BaseTransformers
    def initialize
      default = NoHTML.new
      @state = {:HTML => {:DEFAULT => default, "//script" => TaintTypes::Invisible.new}, :SQL => SQLDefault.new}
    end
    def state
      @state
    end
    def state=(new_val)
      @state = new_val
    end
    def self.safe
      return nil
    end
    def transform(string, top_level_context=nil, additional_context=nil) 
      if top_level_context.nil?; return Identity.sanitize(string); end
      if state[top_level_context].nil?; return Identity.sanitize(string); end
      sub_state = state[top_level_context]
      if Hash === sub_state
       
      elsif TType === sub_state.new
        return sub_state.sanitize(string)
      end
      return "undefined"
    end
    # BaseTransformer equality requires the same value and html_state
    def ==(other)
      return false
      # This needs to be fixed
      if BaseTransformer === other 
        ret = true
        if !ret
          return false
        else
          ret = self.state.keys.sort == other.state.keys.sort
          if !ret
            return false
          end
          state.each_pair do |key,val|
            if other.state[key].class != val.class
              return false
            end
          end
          return true
        end
      else
        return false
      end
    end
    def inspect
      "#<BaseTransformer::#{@state.to_s}>"
    end
  end

  # A proxy for a MatchData object, typcially for the one in $~.  Returns only strings
  # that have the proper taint status.
  class MatchDataProxy
    def initialize(target, string)
      @target = target
      @string = string.clone
    end
    def target
      @target
    end
    def [](*args)
      if args.length == 1
        case args[0]
        when Fixnum
          if args[0] < 0
            args[0] += @target.length
          end
          return @string[@target.offset(args[0])[0]..@target.offset(args[0])[1]-1]
        when Range
          ret_array = Array.new
          for n in args[0]
            ret_array << @string[@target.offset(n)[0]..@target.offset(n)[1]-1]
          end
          return ret_array    
        when String
          names = @target.regexp.named_captures
          index = names[args[0]].last
          return @string[@target.offset(index)[0]..@target.offset(index)[1]-1]
        when Symbol      
          names = @target.regexp.named_captures
          index = names[args[0].to_s].last
          return @string[@target.offset(index)[0]..@target.offset(index)[1]-1]
        end
      else
        start = args[0]
        if start < 0
          start += @target.length
        end
        return self[start..start+args[1]-1]
      end
    end
    
    def to_a
      ret_array = Array.new
      for n in (0..@target.length-1)
        ret_array << @string[@target.offset(n)[0]..@target.offset(n)[1]-1]
      end
      return ret_array
    end
    
    def captures
      ret_array = Array.new
      for n in (1..@target.length-1)
        ret_array << @string[@target.offset(n)[0]..@target.offset(n)[1]-1]
      end
      return ret_array
    end

    def pre_match
      bounds = 0..@target.offset(0)[0]-1
      return @string[bounds]
    end
    
    def post_match
      bounds = @target.offset(0)[1]..@string.length
      return @string[bounds]
    end
    
    def string
      @string.clone.freeze
    end
    
    def to_s
      self[0]
    end
    
    def values_at(*indices)
      ret_array = Array.new
      indices.each do |index|
        i = index
        if i < 0
          i += @target.length
        end
        ret_array << @string[@target.offset(i)[0]..@target.offset(i)[1]-1]
      end
      return ret_array
    end
    
    def inspect
      @target.inspect
    end
    
    def method_missing(method, *args, &body)
      @target.send(method,*args,&body)
    end
  end
  
end


# Object modified to include <tt>true_class</tt>, which indicates what class an
# object is, even if it behaves as a wrapper

class Object
  # Returns an object's class, which may be different than that returned by +class+,
  # if the object is behaving as a wrapper.
  def true_class
    return self.class
  end
  def safe_class
    if Class === self
      return self
    else
      return self.class
    end
  end
end

=begin
class Hash
  # NOTE!!!: These are incomplete.  
  # Should add delete, clear, merge, select, etc. for completeness
  if !{}.respond_to?("old_index_set")
    alias old_index_set []=
  end
  if !{}.respond_to?("old_keys")
    alias old_keys keys
    alias old_each each
    alias old_init initialize
  end
  def initialize(*args)
    old_init(*args)
#    puts "intercepting #{self}"
  end
  def []=(*args)
    args.each do |a|
      if String === a        
        if !a.safe?
          @tainted_keys ||= {}
          @tainted_keys.old_index_set(a,a.taint)
        end
      end
    end
    old_index_set(*args)
  end
 =begin
  def each(&block)
    old_each do |key, val|
      if @tainted_keys && @tainted_keys[key] 
        k2 = eval(key.inspect) #Clone Unfreeze Trick
        k2.taint = @tainted_keys[key]
        key = k2
      end
      yield key,val
    end
  end
 =end
  def keys
    res = old_keys
#    puts res.inspect
    if @tainted_keys
      res.map! do |k|
        if @tainted_keys[k] 
          k2 = eval(k.inspect) #Clone Unfreeze Trick
          k2.taint = @tainted_keys[k]
          k2
        else
          k
        end        
      end
    end
   return res
  end
end
=end

# Kernel modified to add support for String to Number casting via +Integer+ and +Float+.
module Kernel

  # Overrides default integer casting via +Integer+, by using <tt>to_i</tt>.  
  #  Note: +Integer+ is supposed to behave slightly differently than <tt>to_i</tt>
  #  with regards to things like strings marked as hexadecimal. For some reason
  #  aliasing wasn't working here, so <tt>to_i</tt> is invoked instead.  This
  #  should be fixed eventually

  def Integer(obj)
    begin
      return obj.to_i
    rescue
      raise TypeError
    end
  end

  # Overrides default integer casting via +Float+, by using <tt>to_f</tt>.  
  #  Note: +Float+ is probably supposed to behave slightly differently than <tt>to_f</tt>
  #  as with +Integer+.  This should be investigated

  def Float(obj)
    begin
      return obj.to_f
    rescue
      raise TypeError
    end
  end

end

#--
### ----------------------------------------------------------------
### -------------------------- STRING ------------------------------
### ----------------------------------------------------------------

# A special version of the String Class that allows for taint tracking throughout the string's use
class String  
  include TaintSystem
  include ContextSanitization
  # An ordered hash representing a set of mappings between the last character index of each chunk, 
  # and the 2-digit hexidecimal string representing that chunk's taint
  attr_accessor :taint

  alias raw_set_taint taint=
  alias get_taint taint
  # The taint setter.  Makes sure that the taint for each chunk is in character order to prevent
  # problems, and also trims any taint that refers to characters beyond the length of the string.
  def taint=(new_val)
    if new_val == nil
      raw_set_taint(nil)
      return
    end
    if self.length < 1
      raw_set_taint({})
      return 
    end
    new_pairs = Array.new
    last_key = -1
    stopped = false
    new_val.each do |p|      
      if !(p[1].nil? || p[1].is_a?(TaintTransformer)) 
        raise StandardError, "Error: Taint Expected to be a Transformer or nil, is #{p[1].class}"
      end
      if !stopped
        if p[0] >= length
          if last_key != length-1
            new_pairs << [length-1,p[1]]
          end
          stopped = true
        else
          new_pairs << [p[0],p[1]]        
          last_key = p[0]
        end
      end
    end
    new_pairs = new_pairs.sort {|a,b| (a[0].to_i <=> b[0].to_i)}
    raw_set_taint(new_pairs)
  end

  def transform(base_context = nil, additional_context = nil)
    if base_context == :HTML
      return transform_HTML(additional_context)
    end
    if self.taint.nil?; return self; end
    new_string = ""
    self.each_chunk do |str,tnt|
      if !tnt.nil?
        new_string += tnt.transform(str,base_context, additional_context)
      else
        new_string += str
      end
    end
    return new_string
  end

  def transform_HTML(additional_context = nil)
    old_version = self.clone
    new_self = self.clone
    new_self = run_rollback(new_self)  
    res = context_sanitize(new_self)
    new_trans = RollbackTransformer.new
    new_trans.backup = old_version       
    res = res.set_taint(new_trans)
    res
  end

  def run_rollback(str)
    new_str = ""
    str.each_chunk do |val, tnt|
      if tnt.is_a?(RollbackTransformer)
        new_str += tnt.backup
      else      
        val = val.set_taint(tnt)
        new_str += val
      end
    end
    new_str
  end

  def encode_taint
    new_taint = []
    @taint.each do |pair|
      new_taint << [pair[0],pair[1].encode]
    end
    return new_taint.inspect
  end
  def decode_taint(val)   
    new_taint = []
    val.each do |pair|
      new_taint << [pair[0],BaseTransformer.decode(pair[1])]
    end
    raw_set_taint(new_taint)
  end

  def self.version  # :nodoc:
    depths = RUBY_VERSION.split(".")
    new_v = Array.new
    depths.each do |d|
      new_v << d.to_i
    end
    return new_v
  end

  #--
  ### --- Alias Original Methods ---

  def self.safe_alias(method) # :nodoc:
    if !"string".respond_to?("old_" + method)
      old_func = "old_#{method}".intern
      o_func = method.intern
      begin
        String.class_eval("alias #{old_func} #{o_func}")
      rescue
        String.class_eval("def #{'old_' + method}(*args,&body); self.send('#{method}',*args,&body); end;")
      end
    end
  end
  def self.safe_aliases(*methods) # :nodoc:
    methods.each do |m|
      self.safe_alias(m)
    end
  end
  String.safe_alias("replace")
  String.safe_aliases("lstrip","rstrip","strip")
  String.safe_aliases("succ","succ!","next","next!", "upto")
  String.safe_aliases("upcase", "upcase!","downcase", "downcase!")
  String.safe_aliases("swapcase", "swapcase!","capitalize", "capitalize!")
  String.safe_aliases("gsub","gsub!","sub","sub!")
  String.safe_aliases("insert","delete","delete!")
  String.safe_aliases("chop","chop!", "chomp", "chomp!")
  String.safe_aliases("reverse","reverse!")
  String.safe_aliases("ljust","rjust","center")
  String.safe_aliases("tr","tr!", "tr_s","tr_s!")
  String.safe_aliases("chars", "each_char", "chr")
  String.safe_alias("dump")
  String.safe_aliases("squeeze","squeeze!")
  String.safe_aliases("slice", "slice!")
  String.safe_alias("split")
  String.safe_aliases("partition","rpartition")
  String.safe_alias("scan")
  String.safe_alias("inspect")
  String.safe_aliases("each_line","lines")

  # Replaces the current string with the given string.  Works the same as the standard replace method,
  # but replaces the taint, as well as the value of the raw string
  #  Secure
  def replace(val)
    self.old_replace(val)
    self.taint = val.taint
  end

  def to_qstring # :nodoc: 
    if !self.frozen?
      new_self = self.clone
      if new_self.taint == nil
        if new_self.length > 0
          new_self.taint = [[new_self.length-1,BaseTransformer.safe]]
        else
          new_self.taint = []
        end
      end
      return new_self
    else
      if self.taint.nil?
        return eval(self.inspect).to_qstring
      else
        return self
      end
    end
  end

  # Returns a copy of the string with all taint-tracking information removed
  def plain_string # :nodoc:
    new_string = self.clone

    new_string.taint = nil
    return new_string
  end

  # Prints out the string by chunk, while noting the taint of each chunk
  def put # :nodoc:
    each_chunk do |val,tnt|
      puts "#{val} (#{tnt.encode})"
    end
  end

  # Returns a boolean representing whether or not the entire string is untainted or not.
  # Will return true if the all of the string's chunks have either nil taint or "00" taint
  def safe?
    if taint == nil
      return true
    end
    taint.each do |v|
      if v[1] != nil
        return false
      end
    end
    return true
  end

  #Returns a boolean representing whether or not taint needs to be taken account of.  Usually
  #used to check that the string, and any relevant strings in a given method, are not tainted
  #or else the overwritten version of the method should be used, rather than the default ruby one
  def taint_relevant?(*args)
    relevant = !(safe?)
    args.each do |a|
      if String === a
        relevant = relevant || !a.safe?
      end
    end
    return relevant
  end

  def self.taint_union(*args)
    composition = ComposedTransformer.new
    args.each {|a| composition.transformers << a unless a.nil?}
    return composition
  end

  #Returns the <b>effective taint</b> of the string by taking the taint union of all of the
  #strings different chunks
  def effective_taint
    if taint == nil
      return BaseTransformer.safe
    end    
    taints = []
    taint.each do |pair|
      taints << pair[1]
    end
    String.taint_union(*taints)
  end


  def self.proxy_matchdata(md,string)
    if md != nil
      # $~ 
      $gr_md = MatchDataProxy.new(md,string)
      # $&
      $gr_and = $gr_md[0]
      # $`
      $gr_left = $gr_md.pre_match
      # $'
      $gr_right = $gr_md.post_match
      # $+
      begin
        $gr_plus = $gr_md[-1]
      rescue
      end
      # $1,$2,$3,...
      for n in (1..md.length-1)
        begin
          sec_string = string[md.offset(n)[0]..md.offset(n)[1]-1]
          eval("$gr_#{n} = sec_string")
        rescue
        end
      end
    end
  end

  #--
  # --------------- QSTRING METHODS -----------------
  
  #Returns the character (including taint) at the given index 
  def get_char(index) #:nodoc:
    new_char = self.old_slice(index..index)
    new_char = new_char.set_taint(taint_at(index))
    return new_char
  end
  
  #Returns the taint value for a character at the given index
  def taint_at(index) #:nodoc:
    pairs = self.to_qstring.taint
    pairs.each do |p|
      if p[0].to_i >= index
        return p[1]
      end
    end
  end

  # Returns only chunks of the string without any taint
  def pull_clean # :nodoc:
    new_string = ""
    self.each_chunk do |val, state|
      if state != nil
        new_string += val
      end
    end
    return new_string
  end  

  # Combine adjacent chunks of the exact same taint into one chunk   
  def compress_taint #:nodoc:
    new_taint = []
    last_val = "begin"
    last_key = 0
    to_qstring.taint.each do |pair|
      if pair[1] != last_val && last_val != "begin"
        new_taint += [[last_key,last_val]]
      end
      last_key = pair[0]
      last_val = pair[1]
    end
    new_taint += [[last_key, last_val]]
    new_str = self.clone
    new_str.taint = new_taint
    return new_str
  end

  # Combine adjacent chunks of same taint VALUE, but not necessarily the same html_state
  # result will use taint union of the combined chunks
  def special_compress_taint(taint_index) #:nodoc:
    new_taint = []
    last_val = "begin"
    last_key = 0
    to_qstring.taint.each do |pair|
      if last_val != "begin" && pair[1].value.binary_at(taint_index) != last_val.value.binary_at(taint_index)
        new_taint += [[last_key,last_val]]        
        last_key = pair[0]
        last_val = pair[1]
      elsif last_val != "begin"
        last_key = pair[0]
        last_val = String.taint_union(pair[1],last_val)
      else
        last_key = pair[0]
        last_val = pair[1]
      end
    end
    new_taint += [[last_key, last_val]]
    new_str = self.clone
    new_str.taint = new_taint
    return new_str
  end

  # Iterates across each of the chunks, yielding with two parameters: the raw value of the 
  # chunk, and the taint of that chunk
  def each_chunk
    last_index = -1    
    self.to_qstring.taint.each do |pair|            
      yield self[last_index+1..pair[0]], pair[1]
      last_index = pair[0]
    end
  end

  # Create a new qstring based on a pure string and a taint hash
  def self.build(str, taint) # :nodoc:
    self.generate(self.match_taints(str,taint))
  end
  
  # Matches taint hash with pure string to generate an array of chunk pairs
  # [[string,taint],...]
  def self.match_taints(str,taint) # :nodoc:
    string_hash = Array.new
    if taint == nil
      string_hash << [str,BaseTransformer.safe]
    else
      last_index = -1
      taint.each do |pair|              
        temp = str[last_index+1..pair[0]]      
        string_hash << [str[last_index+1..pair[0]], pair[1]]
        last_index = pair[0]
      end
    end
    return string_hash
  end

  # Make a new qstring based on an array of chunk pairs
  def self.generate(str_hash) # :nodoc:
    offset = 0
    new_string = ""
    str_hash.each do |value|
      if value[0] != ""
        temp = value[0]
        temp = temp.set_taint(value[1])
        new_string += temp
      end
    end
    return new_string
  end

  # Return an sql-safe version of the qstring
  def pull_sql_safe        
    new_string = ""
    each_chunk do |str, tnt|
      if tnt.nil? || tnt.state[:SQL] == nil
        new_string += str
      else
        new_string += tnt.state[:SQL].sanitize(str)
      end
    end
    return new_string
  end

  #--
  ### ------------------------------------------------------------
  ###
  ### ---------------------TAINT BIT OPERATIONS ------------------

  def mark_default_tainted
    new_string = self.to_qstring.clone
    new_string.taint = [[new_string.length-1,BaseTransformer.new]]
    return new_string
  end

  def set_taint(taint)
    new_string = self.to_qstring.clone
    new_string.taint = [[new_string.length-1,taint]]
    return new_string
  end

  def set_taint_state(hash) 
    new_string = self.to_qstring.clone
    newtrans = BaseTransformer.new
    newtrans.state = hash
    new_string.taint = [[new_string.length-1, newtrans]]
    return new_string
  end

  ### ---------------------------------------------------------

  #--
  ### -------------------- CONCATENATION ----------------------

  if !"string".respond_to?("concator")
    alias concator +   # :nodoc:
  end
  
  # Overrides normal concatenation with <tt>+</tt> to support taint tracking.
  # When added together, parts of the string with different taint are marked as 
  # seperate _chunks_ in the taint information, and strings that have no taint
  # are marked as having taint of "00"
  #   Assumed to be Secure



  def +(*args)
    args.map! {|s| s.to_s }
    new_string = self.clone.send("concator",*args)
    if taint_relevant?(*args)
      new_string.taint = self.to_qstring.taint.clone
      offset = self.length
      args.each do |a|
        if a.size > 0
          a.to_qstring.taint.each do |pair|
            new_string.taint += [[pair[0].to_i+offset, pair[1]]]
          end
          offset += a.length
        end
      end
    end
    return new_string.clone
  end

  if !"string".respond_to?("concatorlt")
    alias concatorlt <<
  end

  # Overrides normal concatenation with <tt><<</tt> to support taint tracking.
  # When added together, parts of the string with different taint are marked as 
  # seperate _chunks_ in the taint information, and strings that have no taint
  # are marked as having taint of "00"
  #   Assumed to be Secure

  def <<(*args)
    pre_length = self.length
    args.map! {|s| s.to_s}
    new_string = self.send("concatorlt",*args)
    if taint_relevant?(*args)
      new_string.taint = self.to_qstring.taint.clone
      offset = pre_length
      args.each do |a|
        if a.size > 0
          a.to_qstring.taint.each do |pair|
            new_string.taint += [[pair[0]+offset, pair[1]]]
          end
          offset += a.length
        end
      end
    end
    return new_string
  end

  if !"string".respond_to?("concatorconcat")
    alias concatorconcat concat
  end

  # Overrides normal concatenation with <tt>concat</tt> to support taint tracking.
  # When added together, parts of the string with different taint are marked as 
  # seperate _chunks_ in the taint information, and strings that have no taint
  # are marked as having taint of "00"
  #   Assumed to be Secure

  def concat(*args)
    pre_length = self.length
    pre_taint = self.to_qstring.taint.clone
    # TStrings are Depricated
   # args.map! {|s| if TString === s; s.to_s; else; s; end} 
    new_string = self.send("concatorconcat",*args)
    if taint_relevant?(*args)
      new_string.taint = pre_taint
      offset = pre_length
      args.each do |a|
        if a.size > 0
          a.to_qstring.taint.each do |pair|
            new_string.taint += [[pair[0].to_i+offset, pair[1]]]
          end
          offset += a.length
        end
      end
    end
    return new_string
  end

  # ---------------------------------------------------

  # ------------------ OTHER METHODS ------------------


  #--
  #--------------------------------------
  #              % (format)
  #--------------------------------------

  if !"string".respond_to?("format")
    alias format % 
  end

  # Performs the format replacements as on the raw string.  
  # The taint of the given replacements is used when the replacements are put into the string.  
  #
  #  Do we even want format characters of tainted strings to be used?  
  #  If a developer assumes that a user input doesn't contain these sequences, 
  #  unintended behavior could occur with a malicious user.
  def %(arg)   
    if taint_relevant?(*arg)
      continue = true
      count = 0
      last_index = 0
      new_string = ""
      while continue && last_index < length
        if index("%",last_index) == nil
          new_string += rebuild_across_range(self,taint,last_index..length-1)
          continue = false
        else
          next_index = index("%",last_index)
          len = 0
          self[last_index..length-1].old_sub(/%.*?[a-zA-z]/) {|m| len = m.length}
          if next_index != 0
            new_string += rebuild_across_range(self,taint,last_index..next_index-1)         
          end
          if arg.class == Array
            new_string += rebuild_across_range(self,taint,next_index..next_index+len-1).format(arg[count])
            count += 1
          else
            new_string += rebuild_across_range(self,taint,next_index..next_index+len-1).format(arg)
          end 
          last_index = next_index + len
        end
      end
      new_string
    else
      format(arg)
    end
  end
  #--
  #--------------------------------------
  #         * (Copy Multiplication)
  #-------------------------------------- 

  if !"string".respond_to?("mult")
    alias mult *
  end
  
  # Returns a string with _count_ copies of the string back-to-back, each copying the
  # taint of the original.
  #  Should be secure, as it is equivalent to repeated concatentations

  def *(count)
    if taint_relevant?
      new_string = self.send("mult",count)
      new_taint = []
      taint.each do |pair|
        for n in (0..count-1) do
          new_taint += [[pair[0].to_i + length*n,pair[1]]]
        end
      end
      new_string.taint = new_taint
      return new_string
    else
      self.send("mult",count)
    end
  end
  
  #--
  #--------------------------------------
  #       each_char, chr, chars
  #--------------------------------------
  
  # Iterates across each character in the string, including the character's taint.
  # If no block is provided, returns the +chars+ Enumerator.
  #  Secure
  def each_char(&body)
    if taint_relevant?
      if body
        for n in (0..length-1) do
          yield get_char(n)
        end
        return self
      else
        chars
      end
    else
      old_each_char(&body)
    end
  end

  # Returns the first character of the string with its taint.  Only in Ruby 1.9+
  #  Secure
  def chr
    if String.version[1] < 9
      puts "chr not supported in Ruby #{RUBY_VERSION}"
      return 0
    else
      get_char(0)
    end
  end

  # Returns the Enumerator for <tt>each_char</tt>
  #  Secure
  def chars
    Enumerator.new(self,:each_char)
  end

  #--
  #--------------------------------------
  #   lstrip, rstrip, strip, lstrip!, rstrip!, strip!
  #--------------------------------------
  
  # Removes leading spaces across chunks, deleting those with only spaces, until
  # a non-space character is reached
  #  Secure
  def lstrip
    if taint_relevant?
      match_array = String.match_taints(self,taint)
      n = 0
      continue = true
      while n<match_array.length && continue
        match_array[n][0] = match_array[n][0].old_lstrip
        if match_array[n][0].length > 0
          continue = false
        end
        n += 1
      end
      String.generate(match_array)
    else
      old_lstrip
    end
  end

  # See lstrip
  def lstrip!
    res = lstrip
    self.replace(res)
    return self
  end

  # Removes trailing spaces across chunks, deleting those with only spaces, until
  # a non-space character is reached from the right
  #  Secure
  def rstrip
    if taint_relevant?
      match_array = String.match_taints(self,taint)
      n = match_array.length - 1
      continue = true
      while n >= 0 && continue 
        match_array[n][0] = match_array[n][0].old_rstrip
        if match_array[n][0].length > 0
          continue = false
        end
        n -= 1
      end
      String.generate(match_array)
    else
      old_rstrip
    end
  end
  # See rstrip
  def rstrip!
    res = rstrip
    self.replace(res)
    return self
  end

  # A hybrid of _lstrip_ and _rstrip_, removes leading and trailing spaces, removing beginning
  # and ending chunks of only spaces
  #  Secure

  def strip
    if taint_relevant?
      new_string = self.lstrip.rstrip
      return new_string
    else
      old_strip
    end
  end

  # See +strip+
  def strip!
    res = strip
    self.replace(res)
    return self
  end

  #--
  #-------------------------------------
  #    succ, succ!, next, next!, upto
  #-------------------------------------

  def succ_taint_blend(other_str) # :nodoc:
    diff_index = first_diff_index(other_str)
    if diff_index > 0
      new_string = rebuild_across_range(self,other_str.taint,0..diff_index-1)
      new_string += self[diff_index..other_str.length-1].set_taint(other_str.effective_taint)
    else
      new_string = self.set_taint(other_str.effective_taint)
    end
    return new_string
  end
  # Taint is the same as the input, except for all characters affected by the transformation, 
  # all of which gain the effective taint of the affected characters.<br>
  # <tt>"X<b>a</b><i>z9</i>".succ => X<b><i>ba0</i></b></tt><br><br>
  #  Secure?
  def succ
    if taint_relevant?
      new_string = plain_string.old_succ      
      new_string = new_string.succ_taint_blend(self)
      return new_string
    else
      old_succ
    end
  end

  # See +succ+
  def succ!
    if taint_relevant?
      self.replace(succ)
      return self
    else
      old_succ!
    end
  end

  # Taint is the same as the input, except for all characters affected by the transformation, 
  # all of which gain the effective taint of the affected characters.<br>
  # <tt>"X<b>a</b><i>z9</i>".next => X<b><i>ba0</i></b></tt><br><br>
  #  Secure?
  def next
    if taint_relevant?
      new_string = plain_string.old_next      
      new_string = new_string.succ_taint_blend(self)
      return new_string
    else
      old_succ
    end
  end

  # See +next+
  def next!
    if taint_relevant?
      self.replace(self.send("next"))
      return self
    else
      old_next!
    end
  end

  # Behaves normally, except that all values returned have the effective taint of 
  # the entire string. In this way, it does not have the per-character complexity 
  # of the +succ+ method (although it may be possible to add this later).<br><br>

  # *Note*: it might also be wise to include the input parameter's taint, as it 
  # affects what strings are produced 
  #  Should be secure
  def upto(other_str, &block)
    if taint_relevant?
      if block
        old_upto(other_str) { |p|
          new_param = p.set_taint(effective_taint)
          yield new_param
        }
      else
        return Enumerator.new(self,:upto,other_str)
      end
    else
      self.send("old_upto",other_str,&block)
    end
  end

  #--
  #--------------------------------------
  #  upcase, upcase!, downcase, downcase!, swapcase, swapcase!, capitalize, capitalize!
  #--------------------------------------

  # This and all straight case-change functions do not alter the taint at all.  
  #  This is completely safe provided there are no scenarios where a safe string 
  #  could become dangerous when cases are changed.
  def upcase
    same_size_transform("upcase")
  end
  # See +upcase+
  def upcase!
    same_size_transform!("upcase!")
  end

  # This and all straight case-change functions do not alter the taint at all.  
  #  This is completely safe provided there are no scenarios where a safe string 
  #  could become dangerous when cases are changed.
  def downcase
    same_size_transform("downcase")
  end
  # See +downcase+
  def downcase!
    same_size_transform!("downcase!")
  end

  # This and all straight case-change functions do not alter the taint at all.  
  #  This is completely secure provided there are no scenarios where a safe string 
  #  could become dangerous when cases are changed.  
  def capitalize
    same_size_transform("capitalize")
  end
  # See +capitalize+
  def capitalize!
    same_size_transform!("capitalize!")
  end

  # This and all straight case-change functions do not alter the taint at all.  
  #  This is completely safe provided there are no scenarios where a safe string 
  #  could become dangerous when cases are changed.
  def swapcase
    same_size_transform("swapcase")
  end
  # See +swapcase+
  def swapcase!
    same_size_transform!("swapcase!")
  end 

  #--
  #--------------------------------------
  #       sub, sub!, gsub, gsub!
  #--------------------------------------
  def gsub(*args, &block)
    if taint_relevant?(*args)
      if block
        return self.sp_gsub(false,false,*args, &block)
      else
        return self.sp_gsub(false,false,*args)
      end
    end
    if block
      old_gsub(*args) {
        $match = $~
        eval("proc{|m|$~ = m}",block.binding).call($~)
        res = block.call($&)
        if !(String === res) || res.safe?
          String.proxy_matchdata($~,self.clone)
          res          
        else
          return self.sp_gsub(false,false,*args, &block)
        end
      }
    else
      res = old_gsub(*args,&block)
      String.proxy_matchdata($~,self.clone)
      res
    end
  end

  # See +gsub+
  def gsub!(*args, &block)   
    if taint_relevant?(*args)
      res = self.sp_gsub(false,true,*args,&block)
      if res != nil
        self.replace(res)
      end
      return res
    end
    if block
      gsubbed = 
      self.clone.old_gsub(*args) {
        $match = $~
        eval("proc{|m|$~ = m}",block.binding).call($~)
        res = block.call($&)
        if res.safe?
          res
        else
          res = self.sp_gsub(false,true,*args,&block)
          if res != nil
            self.replace(res)
          end
          return res  
        end
      }
      String.proxy_matchdata($~,self.clone)
      if gsubbed == self
        return nil
      else        
        self.replace(gsubbed)
        return self
      end
    else
      res = old_gsub!(*args,&block)
      String.proxy_matchdata($~,self.clone)
      res
    end
  end  

  def subs(*args, &block)
	return old_sub(*args,&block) 
		puts "hello world #{self} #{args}"
    if taint_relevant?(*args)
		puts "first"
      return self.sp_gsub(true,false,*args,&block)
    end
    if block
		puts "second"
      old_gsub(*args) {
        $match = $~
        eval("proc{|m|$~ = m}",block.binding).call($~)
        res = block.call($&)
        if res.safe?
          String.proxy_matchdata($~,self.clone)
          res
        else
          return self.sp_gsub(true,false,*args,&block)
        end
      }
    else
		puts "third"
		return "bob" 
      return send("old_sub",*args)
    end
  end

  # See +sub+
  def sub!(*args, &block)
    if taint_relevant?(*args)
      res = self.sp_gsub(true,true,*args,&block)
      if res
        self.replace(res)
      end
      return res
    end
    if block
      subbed = 
      self.clone.old_sub(*args) {
        $match = $~
        eval("proc{|m|$~ = m}",block.binding).call($~)
        res = block.call($&)
        if res.safe?
          res
        else
          res = self.sp_gsub(true,true,*args,&block)
          if res != nil
            self.replace(res)
          end
          return res
        end
      }
      String.proxy_matchdata($~,self.clone)
      if subbed == self
        return nil
      else
        self.replace(subbed)
        return self
      end
    else
      res = old_sub!(*args,&block)
      String.proxy_matchdata($~,self.clone)
      res
    end
  end  

  def sp_gsub(single_sub, bang, query, replacement = "", &block) # :nodoc:
    ostr = self
    pre_taint = self.to_qstring.taint 
    matches = Array.new
    replacement = replacement.to_qstring
    new_string = "".to_qstring
    index_cur = 0  # The start of the current searching range
    continue = true   # Boolean used to continue or terminate continued searching
    subbed_once = false   # Used by 'sub' (vs. 'gsub') to only do one substition
    count = 0 
    
    # 'match_data' stores the MatchData object for each instance of the query (used later for $~,$1,etc...)
    match_data = Array.new
    old_gsub(query) { match_data << $~ }
    if match_data.length == 0 && bang
      return nil
    end
    # Loop through all of the matches to the query
    while index_cur < ostr.length && continue
      new_replacement = replacement.clone      
      next_index = ostr.index(query,index_cur)
      len = 0

      # If there are no more matches, construct the rest of the string and terminate the loop
      if next_index == nil || (subbed_once && single_sub)
        continue = false
        new_string += rebuild_across_range(ostr, pre_taint, (index_cur..ostr.length-1))

      else
        # Handle the next match
        String.proxy_matchdata(match_data[count],self)
        # If there is a block
        if block
          special_params = nil
          # Simulate the replacement to judge the length of the match 
            # (why does this work better than 'match_data'?)

          ##ostr[index_cur..ostr.length-1].old_sub(query) {|m| puts "here: #{m}";  len = m.length}          

          special_params = match_data[count]  # Pull the right MatchData/$~
          len = special_params[0].length
          var = rebuild_across_range(ostr,pre_taint,next_index..next_index+len-1)

          # The normal block with no support for $1,$2,...,etc., (assumed to handle taint correctly)
          first_block = lambda { |m|
            $~ = special_params
            $match = $~
            eval("proc{|m|$~ = nil}",block.binding).call($~)
            yield m
          }
          
          # Alternate block with $1,$2,... support (because $1 cannot be corrected to contain the right
          # taint, the effective_taint of the match string is used for the entire return
          new_block = lambda { |m|
            $~ = special_params
            $match = $~
            eval("proc{|m|$~ = m;}",block.binding).call($~)
            yield m
          }
          
          # Call normal block, but if there's an error, as there probably would be if one used $1,...
          # try the special block, but ensure taint safety by enforcing the 'effective taint'
          begin
            new_replacement = first_block.call(var)
            if new_replacement.nil?
              new_replacement = new_block.call(var)            
              new_replacement = new_replacement.set_taint(String.taint_union(var.effective_taint,new_replacement.effective_taint))
            end
          rescue
            new_replacement = new_block.call(var)            
            new_replacement = new_replacement.set_taint(String.taint_union(var.effective_taint,new_replacement.effective_taint))
          end
        else
          # No block, use 'replacement'
#          puts "Pre: #{new_replacement} ~~~ #{match_data[count]}"
          if new_replacement.index(/\\k<.*>/)   
            new_replacement.gsub!(/\\k<([^>]*)>/) { $1+""; if match_data[count][$1.intern]; off = match_data[count].offset($1.intern); rebuild_across_range(self,taint,off[0]..off[1]-1); else ""; end }          
          elsif new_replacement.index(/\\(.)/)           
            new_replacement.gsub!(/\\(.)/) { $1+""; if match_data[count][$1.to_i]; off = match_data[count].offset($1.to_i); rebuild_across_range(self,taint,off[0]..off[1]-1); else ""; end }
          end
#          puts "Post: #{new_replacement}"
          ostr[index_cur..ostr.length-1].old_sub(query) {|m| len = m.length}
        end      

        matches << next_index       
        if next_index != 0
          new_string += rebuild_across_range(ostr,pre_taint,(index_cur..next_index-1))
        end
        count += 1
        new_string += new_replacement
        if len == 0
          len = 1
        end
        index_cur = next_index + len
        subbed_once = true
      end
    end
    return new_string.compress_taint
  end

  #--
  #--------------------------------------
  #       insert, delete, delete!
  #--------------------------------------

  # Adds the given string at the specified index, either splitting taint around the 
  # string if it is added in the middle of a chunk, or adding it a the boundary between
  # two existing chunks.  The inserted string has its taint preserved in the new string.
  #  Secure
  def insert(index,other_str)
    if taint_relevant?(other_str)
      if index == 0
        pre_string = ""
      else
        pre_string = rebuild_across_range(self,taint,0..index-1)
      end
      post_string = rebuild_across_range(self,taint,index..length-1)
      result = pre_string + other_str + post_string
      self.replace(result)
      return self
    else
      old_insert(index,other_str)
    end
  end

  # Since +delete+ works only with single characters, the string is split into chunks,
  # the old +delete+ is applied to those chunks and then the string is reassembled.
  #  Secure
  def delete(*args)
    if taint_relevant?
      match_array = String.match_taints(self,taint)
      new_matched_array = Array.new(match_array.size)
      n = 0
      while n < match_array.size
        new_pair = match_array[n]       
        new_pair[0] = new_pair[0].plain_string.old_delete(*args)
        new_matched_array[n] = new_pair
        n += 1
      end
      String.generate(new_matched_array)
    else
      old_delete(*args)
    end
  end
  # See +delete+
  def delete!(*args)
    if taint_relevant?
      res = delete(*args)
      self.replace(res)
      return self
    else
      old_delete!(*args)
    end
  end

  #--
  #--------------------------------------
  #         reverse, reverse!
  #--------------------------------------

  # Reverses the string by reversing each individual chunk (while preserving its taint),
  # then reversing the order of the chunks
  #  Secure
  def reverse
    if taint_relevant?   
      match_array = String.match_taints(self,taint)
      new_matched_array = Array.new(match_array.size)
      n = 0
      while n < match_array.size
        new_pair = match_array[n]
        new_pair[0] = new_pair[0].old_reverse
        new_matched_array[match_array.size-n-1] = new_pair
        n += 1
      end
      String.generate(new_matched_array)
    else
      old_reverse
    end
  end
  # See +reverse+
  def reverse!
    res = reverse
    self.replace(res)
    return self
  end

  #--
  #--------------------------------------
  #       ljust, rjust, center
  #--------------------------------------
  
  # Adds whitespace or the <em>pad_str</em> to the end of the string so that it is 
  # the specified length.  If whitespace is added, that section is marked as untainted.
  # Sections added for <em>pad_str</em> are marked with the <em>effective taint</em> of
  # <em>pad_str</em>
  #  Secure

  def ljust(integer, pad_str='')
    if taint_relevant?(pad_str)   
      if pad_str != ''
        str = old_ljust(integer,pad_str)
      else
        str = old_ljust(integer)
      end
      new_taint = taint
      if length != str.length
        if pad_str == ''
          new_taint += [[str.length-1, BaseTransformer.safe]]
        else
          new_taint += [[str.length-1, pad_str.effective_taint]]
        end
      end
      return String.build(str,new_taint)
    else 
      if pad_str != ''
        old_ljust(integer,pad_str)
      else
        old_ljust(integer)
      end
    end
  end

  # Adds whitespace or the <em>pad_str</em> to the front of the string so that it is 
  # the specified length.  If whitespace is added, that section is marked as untainted.
  # Sections added for <em>pad_str</em> are marked with the <em>effective taint</em> of
  # <em>pad_str</em>
  #  Secure

  def rjust(integer, pad_str='')
    if taint_relevant?(pad_str)
      if pad_str != ''
        str = old_rjust(integer,pad_str)
      else
        str = old_rjust(integer)
      end
      if length != str.length
        diff = str.length - length
        new_taint = []
        if pad_str == ''
          new_taint = [[diff-1, BaseTransformer.safe]]
        else
          new_taint = [[diff-1, pad_str.effective_taint]]
        end
        taint.each do |pair|
          new_taint += [[pair[0]+diff,pair[1]]]
        end        
      end
      return String.build(str,new_taint)
    else 
      if pad_str != ''
        old_rjust(integer,pad_str)
      else
        old_rjust(integer)
      end
    end
  end

  # A hybrid of ljust and rjust, adds whitespace or the <em>pad_str</em> to the 
  # beginning and end of the string so that it is the specified length.  If 
  # whitespace is added, that section is marked as untainted.
  # Sections added for <em>pad_str</em> are marked with the <em>effective taint</em> of
  # <em>pad_str</em>
  #  Secure
  # *Note:* Ruby's _center_ has some strange behavior if there is a pad_str and the length
  # given makes it so that the exact length of the string will be added on either side, the
  # pad_str is not added.  This might be worth investigating

  def center(*args)
    if taint_relevant?
      if args.size == 1
        integer = args[0]
        pad_string = ''
      else
        integer = args[0]
        pad_string = args[1]
      end
      to_add = args[0] - length
      if to_add <= 0
        return self
      end
      if to_add.even?
        left_pad = to_add/2
        right_pad = to_add/2
      else
        left_pad = to_add/2
        right_pad = to_add/2 + 1
      end
      res = rjust(left_pad+length,pad_string)
      res = res.ljust(right_pad+res.length,pad_string)
      return res
    else
      old_center(*args)
    end
  end

  #--
  #--------------------------------------
  #              dump
  #--------------------------------------

  # Escapes special charactes and gets makes non-printable characters readable. 
  # This function works provided that no escaped segments actually are more than
  # one character, in which case they could occur across chunks
  #  Should be secure, but deals with special characters so keep an eye on
  def dump
    if taint_relevant?
      match_array = String.match_taints(self,taint)
      new_matched_array = Array.new(match_array.size)
      n = 0
      while n < match_array.size
        new_pair = match_array[n]
        new_pair[0] = new_pair[0].old_dump
        new_matched_array[n] = new_pair
        n += 1
      end
      return String.generate(new_matched_array)            
    else
      old_dump
    end
  end

  #--
  #--------------------------------------
  #      chomp, chomp!, chop, chop!
  #--------------------------------------

  # Performs the standard chomp without regard to taint, then reapplies the
  # taint accomadating for the shorter string and ignoring any chunks that have
  # been removed entirely
  #  Secure
  def chomp(*args)
    if taint_relevant?
      res = old_chomp(*args)
      res.taint = self.taint.clone
      return res
    else
      old_chomp(*args)
    end
  end

  # See +chomp+
  def schomp!(*args)
    res = chomp(*args)
    self.replace(res)
    return self
  end

  # Performs the standard chop without regard to taint, then reapplies the
  # taint accomadating for the shorter string and ignoring any chunks that have
  # been chopped of entirely
  #  Secure
  def chop(*args)
    if taint_relevant?
      res = plain_string.old_chop(*args)
      res.taint = self.taint.clone
      return res
    else
      old_chop(*args)
    end
  end

  # See +chop+
  def chop!
    if taint_relevant?
      res = chop
      self.replace(res)
      return self
    else
      old_chop!
    end
  end

  # Replaces _inspect_ so that it returns a string with taint information
  #  Should be secure, but there may be sequences that _inspect_ escapes that
  #  are longer than one character, in which case it would not currently be 
  #  escaped correctly
  def inspect
    if taint_relevant?
      match_array = String.match_taints(self,taint)
      new_matched_array = Array.new
      match_array.each do |pair|
        new_pair = pair.clone
        new_pair[0] = new_pair[0].old_inspect
        new_pair[0] = new_pair[0][1..new_pair[0].length-2] #get rid of inter-chunk quotes
        new_matched_array << new_pair
      end
      return ('"' + String.generate(new_matched_array) + '"')
    else
      old_inspect
    end
  end

  #--
  #--------------------------------------
  #         squeeze, squeeze!
  #--------------------------------------

  # _squeeze_ is usually a simple question of applying squeeze normally to separate taint chunks.
  # When duplicate characters appear across taint boundaries, however, the effective taint of 
  # the two chunks. <br><br>
  # Should check to make sure this works if a duplicate character is on the boundaries 
  # of two chunks with entire chunks of that character between them.  Will they be removed 
  # successfully with their taint included in the effective taint?

  def squeeze(*args)
    if taint_relevant?     
      match_array = String.match_taints(self,taint)
      new_matched_array = Array.new
      trailing_char = ""
      offset = 0
      n = 0
      while n < match_array.size
        new_pair = match_array[n]
        if trailing_char != "" 
          valid = args[0] == nil
          valid = valid || args[0] == trailing_char
          if valid
            rexp = Regexp.new(trailing_char + "+")
            if new_pair[0].index(rexp) == 0
              new_pair[0] = new_pair[0].sub(rexp,"")
              new_matched_array[n-1+offset][0] = new_matched_array[n-1+offset][0].old_chop             
              new_matched_array[n+offset] = [trailing_char,String.taint_union(new_pair[1],new_matched_array[n-1+offset][1])]
              offset += 1              
            end
          end
        end
        new_pair[0] = new_pair[0].plain_string.old_squeeze(*args)
        trailing_char = new_pair[0][new_pair[0].length-1]
        new_matched_array << new_pair        
        n += 1
      end
      return String.generate(new_matched_array)            
    else
      old_squeeze
    end
  end
  # See +squeeze+
  def squeeze!(*args)
    if taint_relevant?
      pre_res = self.clone
      res = squeeze(*args)
      self.replace(res)
      if res == pre_res
        return nil
      else
        return self
      end
    else
      old_squeeze!(*args)
    end
  end
  
  #--
  #--------------------------------------
  #       [], []=, slice, slice!
  #--------------------------------------

  if !"string".respond_to?("short_slice")
    alias short_slice []
  end

  # Now succesfully pulls out the segment of the string for all the types of parameters,
  # including funky Regex, with the correct tainting.  A single Fixnum parameter will return
  # the first char in 1.9+ and the byte value in <1.9
  #  Secure, but keep an eye on use of $~
  def [](*args)
    if taint_relevant?
      if String.version[1] < 9
        if Fixnum === args[0]
          return self.send("short_slice",*args)
        end
      end
      slice_range(*args) do |lower_bound, upper_bound|
        if lower_bound == nil || upper_bound == nil || lower_bound > length
          return nil
        else
          return rebuild_across_range(self,taint,lower_bound..upper_bound)
        end
      end
    else
      self.send("short_slice",*args)
    end
  end

  # See <tt>[]</tt>.  Literally exactly the same
  def slice(*args)
    send("[]",*args)
  end

  def slice!(*args)
    if taint_relevant?
      slice_range(*args) do |lower_bound, upper_bound|
        if lower_bound > 0
          bottom_string = rebuild_across_range(self, taint, 0..lower_bound-1)
        else
          bottom_string = ""
        end
        top_string = rebuild_across_range(self, taint, upper_bound+1..length-1)       
        out_string = rebuild_across_range(self, taint, lower_bound..upper_bound) 
        new_string = bottom_string + top_string
        self.replace(new_string)
        return out_string
      end
    else
      old_slice!(*args)
    end
  end
  if !"string".respond_to?("slice_set")
    alias slice_set []=
  end
  def []=(*args)
    if taint_relevant?
      # Take out the new_value from the args so it works right in the 'slice_range' function
      simple_args = Array.new
      for n in (0..args.length-2)
        simple_args << args[n]
      end
      slice_range(*simple_args) do |lower_bound, upper_bound|
        if lower_bound > 0
          bottom_string = rebuild_across_range(self, taint, 0..lower_bound-1)
        else
          bottom_string = ""
        end
        top_string = rebuild_across_range(self, taint, upper_bound+1..length-1)             
        new_string = bottom_string + args[args.length-1] + top_string
        self.replace(new_string)       
      end
    else
     slice_set(*args)
    end
  end

  #--
  #--------------------------------------
  #              split
  #-------------------------------------- 
 
  # _split_ works fine now with support for all parameter types.
  #  Secure

  def split(*args)
    if taint_relevant?
      if args == nil || args.size == 0
        pattern = $;
        if pattern == nil
          pattern = " "         
        end
      else
        pattern = args[0]
        if args.size == 2
          limit = args[1]
          if limit == 0
            limit = nil
          end
        end
      end 
      if pattern == " "
        trim_front = true
        pattern = /\s+/        
      end
      match_data = Array.new
      old_gsub(pattern) { match_data << $~; ""}
      new_array = Array.new
      last_char = 0
      match_data.each do |m|
        if limit == nil || new_array.length < limit - 1 || limit < 0
          off = m.offset(0)
          #puts "#{m[0]}|#{m.offset(0)}|#{self[last_char..off[0]-1]}"
          if off[1] != 0 && (last_char != off[0] || off[0] != off[1])
            if off[0] == 0
              new_array << ""
            else              
              new_array << self[last_char..off[0]-1]
            end
          end
          last_char = off[1]     
        end
      end      
      if last_char < length || (limit != nil && (limit < 0 || limit>new_array.length))
        new_array << self[last_char..length-1]
      end   
      while new_array[new_array.length-1] == "" && (limit == nil || (limit > 0 && limit<new_array.length))
        new_array.delete_at(new_array.length-1)
      end
      if trim_front
        new_array.delete_at(0)
      end
      new_array
    else
      old_split(*args)
    end
  end
  
  #--
  #--------------------------------------
  #        partition, rpartition
  #--------------------------------------

  def partitioner(sep,method) # :nodoc:
    match_index = method.call(sep)
    match_length = 0
    old_sub(sep) {|m| match_length = m.length}
    ret_array = Array.new(3)
    if match_index != nil
      if match_index != 0
        ret_array[0] = rebuild_across_range(self,taint,0..match_index-1)
      else
        ret_array[0] = ""
      end
      ret_array[1] = rebuild_across_range(self,taint,match_index..match_index+match_length-1)
      ret_array[2] = rebuild_across_range(self,taint,match_index+match_length..length-1)
    else
      ret_array[0] = self.clone
      ret_array[1] = ""
      ret_array[2] = ""
    end
    return ret_array
  end

  # Works fine.  Splits up the string in terms of pre-match, match, and post-match with the
  # first result from the left side.
  #  Should be Secure, but watch use of $~
  def partition(sep)
    if taint_relevant?
      partitioner(sep,lambda {|m| index(m)})
    else
      old_partition(sep)
    end
  end

  # Works fine.  Splits up the string in terms of pre-match, match, and post-match with the
  # first result from the right side.
  #  Should be Secure, but watch use of $~
  def rpartition(sep)
    if taint_relevant?
      partitioner(sep,lambda {|m| rindex(m)})
    else
      old_rpartition(sep)
    end
  end
  
  #--
  #--------------------------------------
  #               scan
  #--------------------------------------

  def scan(pattern, &body)
    if taint_relevant?
      continue = true
      start_index = 0
      ret_array = Array.new
      while continue && start_index < length       
        next_index = index(pattern, start_index)     
        if next_index == nil
          continue = false
        else
          len = 0
          self[start_index..length-1].old_sub(pattern) {|m| len = m.length}
          if $~.to_a.length > 1
            new_array = Array.new
            for n in (1..$~.to_a.length-1) do
              new_array << rebuild_across_range(self,taint,$~.offset(n)[0]+start_index..$~.offset(n)[1]-1+start_index)
            end
          end
          if block_given?
            if $~.to_a.length > 1
              body.call(*new_array)
            else
              body.call(rebuild_across_range(self,taint,next_index..next_index+len-1))           
            end
          else
            if $~.to_a.length > 1
              ret_array << new_array
            else
              ret_array << rebuild_across_range(self,taint,next_index..next_index+len-1)
            end
          end
          start_index = next_index + len
        end
      end
      if block_given?
        return self
      else
        return ret_array
      end
    else
      self.send("old_scan",pattern,&body)
    end
  end

  #--
  #--------------------------------------
  #         tr, tr!, tr_s, tr_s!
  #--------------------------------------  
  def tr_helper(from_str,to_str, tr_s = false) # :nodoc:
    from_str = parse_char_range(from_str)
    to_str = parse_char_range(to_str)
    new_strings = Array.new
    if !from_str.starts_with?("^")
      for n in (0..from_str.length-1) do
        if n >= to_str.length
          replacement = to_str[-1..-1]
        else
          replacement = to_str[n..n]
        end        
        new_strings << gsub(from_str[n..n],replacement)
      end
      new_string = ""
      last_char_special = false
      last_char = ""
      for n in (0..length-1) do
        add_char = get_char(n)
        o_char = add_char
        new_strings.each do |s|
          if o_char != s.get_char(n)
            add_char = s.get_char(n)
          end
        end
        if add_char == o_char || !tr_s
          new_string += add_char
          last_char_special = false
        else
          if !last_char_special || add_char != last_char
            new_string += add_char
          end
          last_char = add_char
          last_char_special = true
        end  
      end
      return new_string.compress_taint
    else
      not_exp = Regexp.new("[^#{from_str[1,from_str.length-1]}]")
      new_string = self.gsub(not_exp,to_str[-1..-1].to_qstring)
      return new_string
    end
  end
  def tr(from_str, to_str)   
    if taint_relevant?(to_str)
      tr_helper(from_str,to_str)
   else
      old_tr(from_str,to_str)
    end
  end
  def tr!(*args)
    if taint_relevant?
      res = tr(*args)
      self.replace(res)
      return self
    else
      old_tr!(*args)
    end
  end
  def tr_s(from_str, to_str)   
    if taint_relevant?(to_str)
      tr_helper(from_str,to_str,true)
    else
      old_tr(from_str,to_str)
    end
  end
  def tr_s!(*args)
    if taint_relevant?
      res = tr_s(*args)
      self.replace(res)
      return self
    else
      old_tr_s!(*args)
    end
  end 

  # Iterates across all of the lines in the string as determined by $/ (usually \n) or 
  # whatever the separator is.  Taint is preserved in each of these lines.  If no block
  # is provided, an enumerator is returned
  #  Secure
  def each_line(seperator=$/, &block)
    if taint_relevant?
      if block
        if seperator == ""
          seperator = $/
        end
        continue = true
        start_index = 0
        while continue == true && start_index < length
          if index(seperator,start_index) == nil
            block.call(rebuild_across_range(self,taint,start_index..length-1))
            continue = false
          else
            next_index = index(seperator,start_index)
            len = seperator.length
            while index(seperator,next_index+len) == next_index+len
              len += seperator.length
            end
            block.call(rebuild_across_range(self,taint,start_index..next_index+len-1))
            start_index = next_index + len
          end
        end
        return self
      else
        return Enumerator.new(self,:each_line,seperator)
      end
    else
      self.send("old_each_line", seperator, &block)
    end
  end
  
  # Returns the Enumerator for <tt>each_line</tt> based on the given seperator
  #  Secure
  def lines(seperator=$/)
    if taint_relevant?
      return Enumerator.new(self,:each_line,seperator)
    else
      old_lines(seperator)
    end
  end

  String.safe_alias("match")
  def match(pattern)
    if taint_relevant?
      ret = old_match(pattern)
      if ret == nil
        return nil
      end
      String.proxy_matchdata(ret,self)
      return $gr_md
    else
      old_match(pattern)
    end
  end

  String.safe_alias("unpack")
  def unpack(format)
    if taint_relevant?(format)
      res = old_unpack(format).clone
      new_res = Array.new
      res.each do |e|
        if String === e
          new_res << e.set_taint(String.taint_union(effective_taint,format.effective_taint))
        else
          new_res << e
        end
      end
      return new_res
    else
      old_unpack(format)
    end
  end

  #--
  #--------------------------------------
  #                SAMPLES
  #--------------------------------------
  def self.sampleX
    q1 = "GOD likes dogs".to_qstring.set_taint_state({:X => TaintTypes::SwitchGs})    
    q1
  end

  def self.sampleY
    q1 = "It is GOOD to dodge".to_qstring.set_taint_state({:X => TaintTypes::SwitchDs})
    q1    
  end

  def self.sample # :nodoc:
    q1 = "abc".to_qstring.set_taint_byte(125)
    q2 = "zyx".to_qstring.set_taint_byte(55)
    q3 = "dog".to_qstring.set_taint_byte(100)
    q1 + q2 + q3
  end
  
  def self.sample2 # :nodoc:
    q1 = "abbc ".to_qstring.set_taint_byte(125)
    q2 = " zyx".to_qstring.set_taint_byte(55)
    q3 = "xxdog".to_qstring.set_taint_byte(100)
    q3.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, "boo" => TaintTypes::Invisible.new}
    q1 + q2 + q3
  end
  
  def self.sample3 # :nodoc:
    q1 = "dat|um".to_qstring.set_taint_byte(125)
    q2 = "| sx".to_qstring.set_taint_byte(55)
    q3 = "ab|dog|".to_qstring.set_taint_byte(100)
    q1 + q2 + q3
  end

  def self.sample4 # :nodoc:
    q = "<html><body><script language='javascript'>alert('your name is:"
    q += "jimmy".t
    q += ".');</script></body></html>"
    q
  end

  def self.sample5 # :nodoc:
    q1 = "<html><head><title>" 
    q2 = "<font color='blue'><b>jimmy!!</b></font>".t
    q3 = "</title></head><body><div name='"
    q4 = "'>"
    q5 = "</div></body></html>"
    q2.taint[0][1].html_state = {"all" => TaintTypes::BoldItalicUnderline.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new, TaintContexts::TitleTag => TaintTypes::NoHTML.new}
    q1 + q2 + q3 + q2 + q4 + q2 + q5
  end

  def self.sample6 # :nodoc:
    q1 = "<html><body><script language='javascript'>alert('Welcome "
    q2 = "Bob');alert('You smell".t
    q3 = "');</script>Welcome "
    q4 = "</body></html>"
    q2.taint[0][1].html_state = {"all" => TaintTypes::BoldItalicUnderline.new, "//script[@language='javascript']" => TaintTypes::LettersOnly.new}
    q1 + q2 + q3 + q2 + q4
  end

  def self.sample7 # :nodoc:
    q1 = "<html><body>Name: "
    q2 = "Bob".t
    q3 = ", Address: "
    q4 = "123 Super Lane".t
    q5 = ", Phone Number: "
    q6 = "201-405-9803".t
    q7 = "</body></html>"
    q2.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new}
    q4.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new}
    q6.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new}
    q1 + q2 + q3 + q4 + q5 + q6 + q7
  end

  def self.sample72 # :nodoc:
    q1 = "<html><body>Name: "
    q2 = "Bob <a href='#' onclick='".t
    q3 = ", Address: "
    q4 = "go'> </a>123 Super Lane".t
    q5 = ", Phone Number: "
    q6 = "201-405-9803".t
    q7 = "</body></html>"
    q2.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new}
    q4.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new}
    q6.taint[0][1].html_state = {"all" => TaintTypes::NumbersOnly.new, TaintContexts::TagAttribute => TaintTypes::AlphaNumericHTMLRemoved.new}
    q1 + q2 + q3 + q4 + q5 + q6 + q7
  end

  def self.sample8 # :nodoc
    q1 = "<html><body>"
    q2 = "<div>".t
    q3 = "Hello123".t
    q4 = "</div>".t
    q5 = "</body></html>"
    q2.taint[0][1].html_state = {"all" => TaintTypes::HTMLAllowed.new}
    q4.taint[0][1].html_state = {"all" => TaintTypes::HTMLAllowed.new}
    q3.taint[0][1].html_state = {"all" => TaintTypes::LettersOnly.new, "//div" => TaintTypes::NumbersOnly.new}
    q1 + q2 + q3 + q4 + q5
  end

  def self.sample9 # :nodoc
    q1 = "<html><body>"
    q2 = "<".t
    q3 = "d".t
    q4 = "i".t
    q5 = "v".t
    q6 = ">".t
    q7 = "</body></html>"
    q2.taint[0][1].html_state = {"all" => TaintTypes::BoldItalicUnderline.new}
    q3.taint[0][1].html_state = {"all" => TaintTypes::BoldItalic.new}
    q4.taint[0][1].html_state = {"all" => TaintTypes::BoldItalicUnderline.new}
    q5.taint[0][1].html_state = {"all" => TaintTypes::BoldItalic.new}
    q6.taint[0][1].html_state = {"all" => TaintTypes::BoldItalicUnderline.new}
    q1 + q2 + q3 + q4 + q5 + q6 + q7
  end

  def t # :nodoc:
    return self.mark_default_tainted
  end
  private

  #--
  #------------------- PRIVATE METHODS --------------------------------
  
  def set_bit(string, bindex, val)  
    # Take a hexidecimal string and alter the bit at position 'bindex' to 'val'
    char = string.to_i(16)
    binary = char.to_s(2)
    while binary.size < 8
      binary = "0" + binary
    end
    binary[bindex] = val.to_s
    new_char = binary.to_i(2).to_s(16)
    return new_char
  end

  # Helper for methods like _upcase_ that do not change the taint of the string
  def same_size_transform(method)
    new_string = self.send("old_#{method}")
    new_string.taint = taint
    return new_string
  end

  # 'same_size_transform' to handle bang (!) methods
  def same_size_transform!(method)
    new_string = self.send("old_#{method}")
    if new_string != nil
      new_string.taint = taint
      self.replace(new_string)
      return self
    else
      return nil
    end
  end

  # Important Helper for taking a raw string, taint, and character range, and reconstructing
  # a taint string representing the part of the original string specified by the range
  def rebuild_across_range(string, taint, range)
    divs = Array.new
    new_string = ""
    last = range.first
    taint.each do |v|
      d = v[0]
      if range === d
        temp = string.short_slice(last..d).set_taint(v[1])
        new_string += temp
        last = d+1
      end
    end
    if next_hash_key(taint,last-1) == nil
      temp = string.short_slice(last..range.end).set_taint(BaseTransformer.safe)
      new_string += temp
    else
      temp = string.short_slice(last..range.end).set_taint(next_hash_key(taint,last-1)[1])
      new_string += temp
    end
    return new_string
  end

  # Takes the set of taint character index keys and checks if the range 
  # is entirely contained by the chunk, if so, returns that key
  # otherwise returns nil (if range is across multiple chunks)
  def range_special_intersection(divisions,range)    
    # Check if range falls between each subsequent division
    for n in (0..divisions.size-2)
      if (divisions[n]..divisions[n+1]) === range
        return divisions[n+1]
      end
    end
    # Check if the range falls in the 0 -> division[0] chunk
    if divisions.size > 0
      if (0..divisions[0]) === range
        return divisions[0]
      end
    end
    return nil
  end

  def range_special_find(divisions,range) # :nodoc:
    divisions.each do |d|
      if range === d
        return d
      end
    end
    return nil
  end

  # Returns the key listed as following the given key in an ordered Hash
  def next_hash_key(hash,key)    
    return_next = key<0
    hash.each do |k|
      if return_next
        return k
      end
      if k[0].to_i > key.to_i
        return k
      end
      if k[0] == key
        return_next = true
      end
    end
    return nil
  end

  # Helper for _slice_ functions to parse the different types of parameters
  # they can recieve
  def slice_range(*args)
    lower_bound = nil
    upper_bound = nil
    if args.size == 1
      case args[0]
      when Range
        lower_bound = args[0].first
        if args[0].exclude_end?
          upper_bound = args[0].last-1
        else
          upper_bound = args[0].last
        end
      when Fixnum
        lower_bound = args[0]
        upper_bound = args[0]
      when Regexp, String
        lower_bound = index(args[0])
        res = short_slice(args[0])
        if res != nil
          upper_bound = res.length + lower_bound - 1
        else
          return nil
        end
      else          
      end
    elsif args.size == 2
      case args[0]
      when Fixnum       
        lower_bound = args[0]
        upper_bound = args[1] + lower_bound - 1
      when Regexp        
        old_sub(args[0]) { $matchdat = $~ }
        if args[1] < $matchdat.to_a.size
          lower_bound = $matchdat.offset(args[1])[0]
          upper_bound = $matchdat.offset(args[1])[1] - 1
        else
          # This is just to make it nil
          lower_bound = nil
          upper_bound = nil
        end
      end      
    end    
    if lower_bound && lower_bound < 0
      lower_bound += length
    end
    if upper_bound && upper_bound < 0
      upper_bound += length
    end
    yield lower_bound, upper_bound
  end  

  # Helper used to handle character ranges for functions like _tr_<br><br>
  # <tt>parse_char_range("a-f") => "abcdef"</tt><br>
  # <tt>parse_char_range("^x-z") => "^xyz"</tt>
  def parse_char_range(str)
    except = false
    if str.include?("-") && str != "-"
      if str.starts_with?("^")
        except = true
        str = str[1,str.length-1]
      end
      charz = str.old_split("-")
      charzarray = Array.new
      charz[0].old_upto(charz[1]) {|c| charzarray << c} 
      range = charzarray * ""
      if except
        return ("^" + range).set_taint(str.effective_taint)
      else
        return range.set_taint(str.effective_taint)
      end
    else
      return str
    end
  end

  # Support for 'next' and 'succ'
  def first_diff_index(other_str)
    old_string = self
    if old_string.length != other_str.length
      return 0
    end
    for n in (0..other_str.length-1)
      if old_string[n] != other_str[n]
        return n
      end
    end
  end

end


# :enddoc:

class StringTests
  @@s1 = "abcde"
  @@s2 = "zyxwv"
  @@q1 = @@s1.to_qstring
  @@q2 = @@s2.to_qstring   
  @@test_count = 0
  @@passes = 0
  @@failures = 0
  @@errors = 0  
  def self.run
    @@test_count = 0
    @@passes = 0
    @@failures = 0
    @@errors = 0        
    self.methods.each do |m|
      if m.to_s.index("test") != nil
        puts "Running #{m.to_s}:"
        self.send(m.to_s)
        puts "-----------------------------"
      end
    end
    puts "Results:"
    puts "Sucesses: #{@@passes}/#{@@test_count}   Failures: #{@@failures}/#{@@test_count}"
    return @@passes == @@test_count
  end
  def self.test_concatenation
    self.assert(@@s1 + @@s2, "abcdezyxwv")
    self.assert(@@s2 + @@s1, "zyxwvabcde")
  end
  def self.test_slice
    a = "hello there".t
    if String.version[1] < 9
      self.assert(a[1],101)
    else
      self.assert(a[1],"e")
    end
    self.assert(a[1,3],"ell")
    self.assert(a[1..3],"ell")
    self.assert(a[-3,2],"er")
    self.assert(a[-4..-2],"her")
    self.assert(a[12..-1],nil)
    self.assert(a[-2..-4],"")
    self.assert(a[/[aeiou](.)\1/],"ell")
    self.assert(a[/[aeiou](.)\1/,0],"ell")
    self.assert(a[/[aeiou](.)\1/,1],"l")
    self.assert(a[/[aeiou](.)\1/,2],nil)
    self.assert(a["lo"],"lo")
    self.assert(a["bye"],nil)
  end
  def self.test_scan
    a = "cruel world".t
    self.assert(a.scan(/\w+/),["cruel","world"])
    self.assert(a.scan(/.../),["cru", "el ", "wor"])
    self.assert(a.scan(/(...)/),[["cru"], ["el "],["wor"]])
    self.assert(a.scan(/(..)(..)/),[["cr","ue"],["l ", "wo"]])
  end
  def self.test_gsub
    a = "hello".t
    self.assert(a.gsub(/[aeiou]/, '*'),"h*ll*")
    self.assert(a.gsub(/([aeiou])/, '<\1>'),"h<e>ll<o>")
    if String.version[1] >= 9
      self.assert(a.gsub(/./) {|s| s[0].ord.to_s + ' '} , "104 101 108 108 111 ")
      self.assert(a.gsub(Regexp.new("(?<foo>[aeiou])"), '{\k<foo>}'),"h{e}ll{o}")
    end
  end
  def self.test_sub
    a = "hello".t
    self.assert(a.sub(/[aeiou]/, '*'),"h*llo")
    self.assert(a.sub(/([aeiou])/, '<\1>'),"h<e>llo")
    if String.version[1] >= 9
      self.assert(a.sub(/./) {|s| s[0].ord.to_s + ' '} , "104 ello")
      self.assert(a.sub(Regexp.new("(?<foo>[aeiou])"), '*\k<foo>*'),"h*e*llo")
    end
  end
  def self.test_split
    self.assert(" now's  the time".t.split,["now's","the","time"])
    self.assert(" now's  the time".t.split(' '),["now's","the","time"])
    self.assert(" now's  the time".t.split(/ /),["", "now's", "", "the","time"])
    self.assert("1, 2.34,56, 7".t.split(%r{,\s*}), ["1","2.34", "56","7"])
    self.assert("hello".t.split(//), ["h", "e", "l", "l", "o"])
    self.assert("hello".t.split(//,3), ["h", "e", "llo"])
    self.assert("hi mom".t.split(%r{\s*}), ["h", "i", "m", "o", "m"])
    self.assert("mellow yellow".t.split("ello"),["m", "w y", "w"])
    self.assert("1,2,,3,4,,".t.split(','),["1","2","","3","4"])
    self.assert("1,2,,3,4,,".t.split(',',4),["1","2","","3,4,,"])
    self.assert("1,2,,3,4,,".t.split(',',-4),["1","2","","3","4","",""])
  end
  def self.test_tr
    self.assert("hello".t.tr('aeiou','*'),"h*ll*")
    self.assert("hello".t.tr('^aeiou','*'),"*e**o")
    self.assert("hello".t.tr('el','ip'),"hippo")
    self.assert("hello".t.tr('a-y','b-z'),"ifmmp")
  end
  def self.test_delete
    self.assert("hello".t.delete("l", "lo"),"heo")
    self.assert("hello".t.delete("lo"),"he")
    self.assert("hello".t.delete("aeiou", "^e"),"hell")
    self.assert("hello".t.delete("ej-m"),"ho")
  end
  def self.test_chop
    self.assert(@@s1.chop, "abcd")
    self.assert(@@s1.chop.chop.chop, "ab")
    self.assert(@@q1.chop, "abcd".to_qstring)
    self.assert(@@q1.chop.chop.chop, "ab".to_qstring)
  end
  def self.test_fuzz
    for n in (0..20)
      self.random_compare
    end
    for n in (0..10)
      self.random_compare2
    end
  end








  def self.big_fuzz
    for n in (0..200)
      self.random_compare
    end
    for n in (0..100)
      self.random_compare2
    end
  end
  def self.run_long
    @@test_count = 0
    @@passes = 0
    @@failures = 0
    @@errors = 0        
    self.big_fuzz
    puts "Results:"
    puts "Sucesses: #{@@passes}/#{@@test_count}   Failures: #{@@failures}/#{@@test_count}"
    return @@passes == @@test_count
  end
  def self.random_compare
    smethods = ["upcase","upcase!","downcase","downcase!","swapcase","swapcase!","capitalize","capitalize!", "chop","chop!","chomp","chomp!","squeeze","squeeze!","succ","succ!","next","next!","lstrip","strip","rstrip", "reverse", "reverse!", "dump", "chr"]
    m = smethods[rand(smethods.length)]
    str = self.random_string
    tstr = str.clone.t
    print m.ljust(20)
    print str.ljust(10)
    self.assert(str.send(m),tstr.send(m))    
  end
  def self.random_compare2
    smethods = [["ljust", lambda {rand(18)}],["center", lambda {rand(18)}],["rjust", lambda {rand(18)}],["slice", lambda {rand(8)}], ["slice", lambda {-1}]]
    m = smethods[rand(smethods.length)]
    str = self.random_string
    tstr = str.clone.t
    print m[0].ljust(20)
    print str.ljust(10)
    param = m[1].call
    self.assert(str.send(m[0],param),tstr.send(m[0],param))    
  end
  def self.random_string(len = 8)
    new_string = ""
    while new_string.length<len
      new_string += (rand(94)+32).chr      
    end
    return new_string
  end
  def self.assert(v1,v2)

    @@test_count += 1
    begin
      result = (v1 == v2)
      puts "#{v1} == #{v2}".ljust(20) + " -> #{v1 == v2}"
      if result
        @@passes += 1
      else
        @@failures += 1
      end
    rescue
        @@errors += 1
    end
  end
end

class StringScanner

  # This class method 'alias_hold' is designed to fix the alias detection problem
  # so there are not aliased infinite loops
  def self.alias_hold
    return nil
  end
  if !StringScanner.respond_to?("aliased_hold")
    alias old_init initialize
    class << self      
      alias aliased_hold alias_hold
    end
  end

  def initialize(string)
    @is_tstring = false #TStrings are depricated
    if @is_tstring
      @tstring = string.clone
      string = string.target
    end
    @taint = string.to_qstring.effective_taint
    old_init(string)
  end
  def self.s_overwrite(name)
    if !StringScanner.new("abc").respond_to?("old_#{name}")
      s = "alias old_#{name} #{name};"
      s += "def #{name}(*args);"
      s += "res = old_#{name}(*args);"
      s += "return nil unless !res.nil?;"
      s += "res = res.set_taint(@taint);"
      s += "if @is_tstring;"
      s += "res = TString.new(res,@tstring.cdiv,@tstring.tdiv,@tstring.char_hash);"
      s += "end;"
      s += "return res;"
      s += "end"
      StringScanner.class_eval(s)      
    end
  end
  self.s_overwrite("scan")
  self.s_overwrite("scan_until")
  self.s_overwrite("check")
  self.s_overwrite("check_until")
  self.s_overwrite("get_byte")
  self.s_overwrite("getch")
  self.s_overwrite("matched")
  self.s_overwrite("peek")
  self.s_overwrite("peep")
  self.s_overwrite("string")
  self.s_overwrite("rest")
  self.s_overwrite("post_match")
  self.s_overwrite("pre_match")
end


### Take out the use of SafeBuffers (is this ok?)**********
class String
  def html_safe?
    true
  end
  def html_safe
    return self
  end
  alias safe_concat concat
end

class NilClass
  def to_qstring
	return nil
  end	
  def taint
	return nil
  end
end
