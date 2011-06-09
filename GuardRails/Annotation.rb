#require 'taint_types'

class Annotation
  attr_accessor :type
  attr_accessor :policy
  attr_accessor :lambda
  attr_accessor :target

  @@lambda_hash={:always => 'lambda{|obj| true}', :never => 'lambda{|obj| false}', :random => 'lambda{|obj| rand(2)==1}'};

  def initialize
    @types 		= [:class, :attr, :assoc, :func]
    @policies 	= [:read_access, :write_access, :privilege, :create_access, :destroy_access, :append_access, :taint]
  end

  def lambda= obj
    find_lambda obj
  end

  def find_lambda obj
    s=obj.to_s.intern
    if @@lambda_hash.has_key? s
      @lambda=@@lambda_hash[s]
    else
      @lambda=obj
    end
    #p @lambda
  end

  #  def build ty, la
  #    @policy=ty
  #    @lambda=la
  #  end
  #
  #  def build ty, ta, la
  #    @policy=ty
  #    @lambda=la
  #    @target=ta
  #  end

  def build str, *args
    tarr=str.split(",");
    tarr=tarr[(args.length-1)..-1]
    str=tarr*","
    str.strip!
    @policy=args[0]
    if args[-1].is_a? Symbol
      find_lambda args[-1]
    elsif args[-1].is_a? Hash
      find_lambda args[-1].to_s
    else
      find_lambda str
    end
    if args.length>2
      @target=args[1]
    end
    p @lambda.class
  end

  def inspect
    return (	  "Ann.target: " + @target.to_s +
    ", Ann.type: " + @type.to_s +
    ", Ann.policy: " + @policy.to_s +
    ", Ann.lambda: " + @lambda.to_s)
  end

  def <=>(obj2)
    a = @types.index(self.type)
    b = @types.index(obj2.type)
    if a != b then return a - b end

    a = @policies.index(self.policy)
    b = @policies.index(obj2.policy)
    if a != b then return a - b end

    #pp self.target
    #pp obj2.target

    return 1
  end

  # Ruby only implements shallow copying, but we need deep copies
  # of annotations when one annotation is applied to multiple
  # targets.
  def deep_clone
    #Marshal::load(Marshal.dump(self))
    ans=Annotation.new
    ans.type=type
    ans.target=target
    ans.policy=policy
    ans.lambda=lambda
    return ans
  end
end
