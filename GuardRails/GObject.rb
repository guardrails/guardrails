# We need to give all objects some built in fields and methods so we 
# modify the object class here. 
class Object

	attr_accessor :policy_object, :violation_object
   def populate_policies
	end 	

	def assign_policy(policy_type, function, target=:self)
		@policy_object = {} if policy_object.nil?
		@policy_object[policy_type] = function
	end

	def assign_violation(policy_type, violation, target=:self)
		@violation_object = {} if violation_object.nil?
		@violation_object[policy_type] = function
	end

	def eval_policy(policy_type)
		return true if policy_object.nil?
		function = policy_object[policy_type]
		return true if function.nil?				
		eval(function).call(Thread.current[:user])				
	end

	def eval_violation(policy_type)
		return if violation_object.nil?
		function = violation_object[policy_type]
		return if function.nil?				
		eval(function).call(Thread.current[:user])				
	end

	def gr_is_visible?(transparent=false)
		return true if eval_policy(:read_access)
		eval_violation(:read_access) unless transparent
	end

	def gr_can_edit?(transparent=false)
		return true if eval_policy(:write_access)
		eval_violation(:write_access) unless transparent
	end

	def gr_can_create?(transparent=false)
		return true if eval_policy(:create_access)
		eval_violation(:create_access) unless transparent
	end

	def gr_can_destroy?(transparent=false)
		return true if eval_policy(:delete_access)
		eval_violation(:delete_access) unless transparent
	end

	# Alias all the object's getters and setters to check write policies
	def gr_policy_setup	
		return true
		define_attribute_methods if self.is_a? ActiveRecord
		for var in instance_variables do
			var = var[1..-1]
				
			next if var == :policy_object or var == :violation_object
			eval("alias :old_#{var}= :#{var}= if defined?('#{var}=') == 'method'")
			eval("define_method #{var}=(val)
						target = old_#{var}
						return if target.nil?
		
						return old_#{var}=(val) if gr_can_edit? and target.gr_can_edit?
					end")

			eval("alias :old_#{var} :#{var} if defined?('#{var}') == 'method'")
			eval("define_method #{var}
						target = old_#{var}
						return if target.nil?
						return target if target.gr_is_visible? 
					end")
		end
	end
end



