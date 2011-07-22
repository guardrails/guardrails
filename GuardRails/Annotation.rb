class Annotation
  attr_accessor :type
  attr_accessor :policy
  attr_accessor :lambda
  attr_accessor :target
  attr_accessor :violation

  @@lambda_hash={:always => 'lambda{true}', :never => 'lambda{false}', :random => 'lambda{rand(2)==1}'};
  @@violation_hash={:NOTHING => 'lambda{nil}', :TEST => 'lambda{puts "Test is working !!!";nil}', 
    :ERROR => {:read_access=> 'lambda{raise GuardRailsError, "Not authorized to read object"}',
      :write_access=> 'lambda{raise GuardRailsError, "Not authorized to write to object"}',
      :append_access=> 'lambda{raise GuardRailsError, "Not authorized to append object"}',
      :create_access=> 'lambda{raise GuardRailsError, "Not authorized to create object"}',
      :destroy_access=> 'lambda{raise GuardRailsError, "Not authorized to destroy object"}'}};
  @@default_violation={:read_access=> 'lambda{nil}',:write_access=> 'lambda{nil}',:append_access=> 'lambda{nil}',
    :create_access=> 'lambda{raise GuardRailsError, "Not authorized to create object"}',
    :destroy_access=> 'lambda{raise GuardRailsError, "Not authorized to destroy object"}'}
  @@types 		= [:class, :attr, :assoc, :func]
  @@policies 	= [:read_access, :write_access, :privilege, :create_access, :destroy_access, :append_access, :taint, :read_worlds, :write_worlds, :read_worlds_r, :write_worlds_r]

  def self.policies
    @@policies
  end

  def lambda= obj
    find_lambda obj
  end

  def build str
    ast=RubyParser.new.parse "build("+str+")"
    ast=ast[3]
    @violation=nil
    @policy=ast[1][1]
    if ast[-1][0]==:lit and ast[-1][1].is_a? Symbol
      if @@lambda_hash.has_key? ast[-1][1]
        @lambda=@@lambda_hash[ast[-1][1]]
      else
        puts "ERROR: #{ast[-1][1]} is not a predefined policy!"
      end
    else
      @lambda=GRuby2Ruby.new.process ast[-1]
    end
    if ast.size==5
      @target=ast[2][1]
      if ast[3][0]==:lit and ast[3][1].is_a? Symbol
        if @@violation_hash.has_key? ast[3][1]
          @violation=@@violation_hash[ast[3][1]]
        else
          puts "ERROR: #{ast[3][1]} is not a predefined violation!"
        end
      else
        @violation=GRuby2Ruby.new.process ast[3]
      end
    elsif ast.size==4
      if ast[2][0]==:lit and ast[2][1].is_a? Symbol
        if @@violation_hash.has_key? ast[2][1]
          @violation=@@violation_hash[ast[2][1]]
        else
          @target=ast[2][1]
        end
      else
        @violation=GRuby2Ruby.new.process ast[2]
      end
    end
    @violation=@@default_violation[@policy] if @violation.nil?
    @violation=@violation[@policy] if @violation.is_a? Hash
  end

  def inspect
    return (	  "Ann.target: " + @target.to_s +
    ", Ann.policy: " + @policy.to_s +
    ", Ann.lambda: " + @lambda.to_s +
    ", Ann.violation: " + @violation.to_s)
  end

  # Ruby only implements shallow copying, but we need deep copies
  # of annotations when one annotation is applied to multiple
  # targets.
  def deep_clone
    Marshal::load(Marshal.dump(self))
  end
end
