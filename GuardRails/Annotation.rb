class Annotation
	attr_accessor :type
	attr_accessor :policy
	attr_accessor :lambda
	attr_accessor :target 

	def initialize
		@types 		= [:class, :attr, :assoc, :func]
		@policies 	= [:read_access, :write_access, :privilege]
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
		Marshal::load(Marshal.dump(self))
	end
end
