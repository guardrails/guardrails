require 'ruby_parser'
require 'pp'
require 'ruby2ruby'

class Sexp
  def insert_at_front(expr)
    return Sexp.from_array [:block, expr, self]
  end

  def insert_at_back(expr)
    return Sexp.from_array [:block, self, expr]
  end

  # Inserts the expression into the first class or module block
  # Inserted at the bottom of the block by default
  def insert_into_class!(expr, front=false)

    # Find the block defining class or module
    block = self.deep_find_first(lambda{ |ast| ast[0] == :class or ast[0] == :module})
    return if block.nil?

    block[3].insert_into_scope!(expr, front) if block[0] == :class
    block[2].insert_into_scope!(expr, front) if block[0] == :module
  end

  def insert_into_scope!(expr, front=false)

    if self.length == 1
      self.push expr
    else
      self[-1] = self[-1].insert_at_back(expr) unless front
      self[-1] = self[-1].insert_at_front(expr) if front
    end
  end

  # Returns the first subtree in ast that matches test. DFS order
  def deep_find_first(test)
    return self if test.call(self)

    for subtree in self do
      next unless subtree.is_a? Sexp
      sub_result = subtree.deep_find_first(test)
      return sub_result unless sub_result.nil?
    end

    return nil
  end

  # Returns all subtrees in ast that match test. Undefined order
  def deep_find_all(test)
    results = []
    results.push self if test.call(self)

    for subtree in self do
      next unless subtree.is_a? Sexp
      results.concat subtree.deep_find_first(test)
    end

    return results
  end

  #DON'T USE THIS ONE USE replace2
  def replace!(match, repl, in_func=false, in_args=false)
    in_func = (in_func or self[0] == :call)
    in_args = (in_args or self[0] == :arglist)

    self.each_index {|i|
      if self[i] == match and in_func and not in_args
        self[i] = repl
      else
        self[i].replace!(match, repl, in_func, in_args) if self[i].is_a? Sexp
      end
    }
  end

  def replace2!(match, repl, okay=true)
    in_func = (self[0] == :call)
    in_args = (self[0] == :arglist)
    in_class = (self[0] == :class)

    ans=false
    self.each_index {|i|
      if self[i] == match and okay and not in_class
        self[i] = repl
        ans=true
      elsif in_func
        ans|=self[i].replace2!(match, repl, true) if self[i].is_a? Sexp
      elsif in_args
        ans|=self[i].replace2!(match, repl, false) if self[i].is_a? Sexp
      else
        ans|=self[i].replace2!(match, repl, okay) if self[i].is_a? Sexp
      end
    }
    ans
  end

  #######################################

  def deep_copy
    Marshal::load(Marshal.dump(self))
  end

  # Replaces all instances of match with repl in the tree.
  # White list style
  def replace(match, repl, in_a_fun = false)
    in_a_fun = (in_a_fun or self[0] == :call)
    self.each do |child|
      if in_a_fun and child.to_s == match
        child = repl
      end
      if child.is_a? Sexp
        child.replace(match, repl, in_a_fun)
      end
    end
  end

  def old_replace(match, repl)
    for i in (1..self.length)

      # Avoid the "with_options" rails flags, everything
      # dies if we touch them
      break if self[i] == :with_options
      next if self[0] == :colon2 and (i == 1 or i == 2)

      # Dont allow changes to class definitions
      if self[i].to_s == match and self[0] != :class
        self[i] = repl
      end

      next unless self[i].is_a? Sexp
      self[i].replace(match, repl) unless (self[0] == :class and i != 3)
    end
  end

  # Returns the first sub-sexp (DFS order) that satisfies cond
  def deep_find (cond)
    if cond.call(self) then return self end

    for child in self
      next unless child.is_a? Sexp
      result = child.deep_find(cond)
      if result != nil then return result end
    end
    return nil
  end

  # Returns all sub-sexps (DFS order) that satisfy cond
  def deep_find_all (cond)
    results = []
    for child in self
      next unless child.is_a? Sexp
      t = child.deep_find_all(cond)
      next if t == nil or t == []
      results.concat t
    end
    results.concat [self] if cond.call(self)
    results
  end

  def insert_lambda_into_func(func_name, lambda)
    func = deep_find( lambda { |sexp| sexp[0] == :defn and sexp[1] == func_name.to_sym })

    tr = Sexp.new
    tr[0] = :true

    call = RubyParser.new.parse("#{lambda}.call(Thread.current['user'])")
    func[3].replace(tr, call)
  end

  # Note that the caller MUST be a scope node [:scope, body]
  # Inserts behind old block by convention.
  def insert_into_scope(stmt, front=false)

    # If there is already a block at the top of the body then we can simply
    # insert the stmt into the block. This just makes the tree easier to work with.
    if self[1].is_a? Sexp and self[1][0] == :block
      if front
        self[1].insert(1,stmt)
      else
        self[1].push(stmt)
      end

      # Otherwise we need to wrap the old body and stmt in a block
    else
      old_block = self[1]
      self[1] = Sexp.new
      self[1][0] = :block

      if front
        self[1][2] = old_block
        self[1][1] = stmt
      else
        self[1][1] = old_block
        self[1][2] = stmt
      end
      # If the body of the scope node is empty, this will still work but put a nil value
      # in the tree that gets converted into a comment. Doesn't happen often and can't hurt.
    end
  end

  # Appends stmt to the end of the class_stmts (front of class statements if front=true)
  def insert_class_stmt(stmt, front=false)
    class_node = self.deep_find( lambda { |sexp| sexp[0] == :class or sexp[0] == :module} )
    scope_node = class_node[3] # class nodes of form [:class, classname, superclass, scope]
    scope_node.insert_into_scope(stmt, front)
  end

end

