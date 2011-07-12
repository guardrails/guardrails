class GForm
  puts "GForming"
  def alterFormFors ast, parser=RubyParser.new
    puts "Alter forms"
    @@parser=parser
    findFormFor ast
  end

  private

  def findFormFor ast
    return nil unless ast.is_a? Sexp
    a=b=c=nil
    for x in ast
      unless b.nil?
        c=x
        break
      end
      unless a.nil?
        b=x[1]
        next
      end
      unless(a=getFormForName x)
        findFormFor x
      end
    end
    return if a.nil?
    replaceFormForBuilderCall a,b,c
  end

  def replaceFormForBuilderCall name,builder,ast
    return unless ast.is_a? Sexp
    for x in ast
      if isAGoodCall name,builder,x
        doTheReplacement name,builder,x
      else
        replaceFormForBuilderCall name,builder,x
      end
    end
  end

  def isAGoodCall name,builder,ast
    return nil unless ast.is_a? Sexp
    return nil unless ast[0]==:call
    return nil if ast[1].nil?
    return nil unless ast[1][0]==:lvar
    return nil unless ast[1][1]==builder
    return nil unless [:text_field,:label,:password_field,:hidden_field,:file_field,:text_area,:check_box,:radio_button].include? ast[2]
    return true;
  end

  def doTheReplacement name,builder,ast
    puts "Doing the Replacement! N:#{name}"
    ast=ast[3]
    field=ast[1][1]
    if ast[2].nil?
      ast<<getSexpFormFor(name, field)
    else
      return unless ast[2][0]==:hash
      return if hasDisabled ast[2]
      temp=getSexpFormFor(name, field)
      ast[2]<<temp[1]
      ast[2]<<temp[2]
    end
  end

  def hasDisabled ast
    i=1
    while i<ast.size
      return true if ast[i][1]=="disabled" or ast[i][1]==:disabled
      i+=2
    end
    return false
  end

  def getSexpFormFor name,field
    return @@parser.parse("{\"disabled\"=>((#{name.to_s}.#{field.to_s}.gr_can_edit?())?(false):(true))}")
  end

  def getFormForName ast
    return nil unless ast.is_a? Sexp
    return nil unless ast[0]==:call
    return nil unless ast[2]==:form_for
    return ast[3][1][1]
  end
end
