class GRuby2Ruby < Ruby2Ruby
  def initialize
    super
  end

  def process_dstr(exp)
    "\"#{util_dthing2(:dstr, exp)}\""
  end

  def util_dthing2(type, exp)
    s = []

    # first item in sexp is a string literal
    s << dthing_escape(type, exp.shift)

    until exp.empty?
      pt = exp.shift
      case pt
      when Sexp then
        case pt.first
        when :str then
          s << dthing_escape(type, pt.last)
        when :evstr then
          s << '"+(' << process(pt) << ').to_s()+"' # do not use interpolation here
        else
          raise "unknown type: #{pt.inspect}"
        end
      else
        # HACK: raise "huh?: #{pt.inspect}" -- hitting # constants in regexps
        # do nothing for now
      end
    end

    s.join
  end

  def process_nth_ref(exp)

    "$gr_#{exp.shift}"
  end

  def process_grhtml(exp)
    #p exp
    ans="%>"+exp[2][1][1]+"<%"
    exp.shift until exp.empty?
    return ans
  end

  def process_grhtmlputs(exp)
    ans="%><%="+process(exp[1])+"%><%"
    exp.shift until exp.empty?
    return ans
  end
  
def process_block(exp)
  result = []

  exp << nil if exp.empty?
  until exp.empty? do
   code = exp.shift
   if code.nil? or code.first == :nil then
    result << "nil # do nothing"
   else
    result << process(code)
   end
  end
  result = result.join "\n"

  result = case self.context[1]
       when nil, :scope, :if, :iter, :resbody, :when, :while then
        result + "\n"
       else
        "(#{result})"
       end

  return result
 end

def process_ensure(exp)
  body = process exp.shift
  ens = exp.shift
  ens = nil if ens == s(:nil)
  ens = process(ens) || "# do nothing"
#  body.sub!(/\n\s*end\z/, '') # I removed this line. What was its point??? -JB
  return "#{body}\nensure\n#{indent ens}"
end

  def process_hash(exp)
    result = []
    until exp.empty?
      lhs = process(exp.shift)
      rhs = exp.shift
      t = rhs.first
      rhs = process rhs
      rhs = "(#{rhs})" unless [:lit, :str].include? t # TODO: verify better!
      result << "#{lhs} => #{rhs}"
    end
    case self.context[1]
    when :arglist, :argscat then
      unless result.empty? then
    return "{ #{result.join(', ')} }"
      else
        return "{}"
      end
    else
      return "{ #{result.join(', ')} }"
    end
  end
  
def process_if(exp)
  expand = Ruby2Ruby::ASSIGN_NODES.include? exp.first.first
  c = process exp.shift
  t = process exp.shift
  f = process exp.shift

  c = "(#{c.chomp})" if c =~ /\n/

  if t then
    unless expand then
      if f then
        r = "((#{c}) ? (#{t}) : (#{f}))"
        r = nil if r =~ /return/ # HACK - need contextual awareness or something
      else
        r = "(#{t} if #{c})"
      end
      return r if r and (@indent+r).size < LINE_LENGTH and r !~ /\n/
    end

    r = "(if #{c} then\n#{indent(t)}\n"
    r << "else\n#{indent(f)}\n" if f
    r << "end)"

    r
  else
    unless expand then
      r = "#{f} unless #{c}"
      return r if (@indent+r).size < LINE_LENGTH and r !~ /\n/
    end
    "unless #{c} then\n#{indent(f)}\nend"
  end
end
  def process_resbody exp
    args = exp.shift
    body = process(exp.shift) || "nil # do nothing"

    name =   args.lasgn true
    name ||= args.iasgn true
    args = process(args)[1..-2]
    args = " #{args}" unless args.empty?
    args += " => #{name[1]}" if name

    "rescue#{args}\n#{indent body}"
  end

  def process_rescue exp
    body = process(exp.shift) unless exp.first.first == :resbody
    els  = process(exp.pop)   unless exp.last.first  == :resbody

    body ||= "nil # do nothing"
    simple = exp.size == 1

    resbodies = []
    until exp.empty? do
      resbody = exp.shift
      simple &&= resbody[1] == s(:array) && resbody[2] != nil
      resbodies << process(resbody)
    end
    if els then
      "#{indent body}\n#{resbodies.join("\n")}\nelse\n#{indent els}"
    elsif simple then
      resbody = resbodies.first.sub(/\n\s*/, ' ')
      "(#{body} #{resbody})"
    else
      "#{indent body}\n#{resbodies.join("\n")}"
    end
  end
end
