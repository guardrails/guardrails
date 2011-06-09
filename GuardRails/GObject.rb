# We need to give all objects some built in fields and methods so we
# modify the object class here.
class ActiveRecord::Base
  attr_accessor :frozen_policy_store, :plural_policy_store
  def frozen_policy_store
    @frozen_policy_store = {} if @frozen_policy_store.nil?
    return @frozen_policy_store
  end

  def plural_policy_store
    @plural_policy_store = {} if @plural_policy_store.nil?
    return @plural_policy_store
  end

  def pps_init(key)
    @plural_policy_store = {} if @plural_policy_store.nil?
    @plural_policy_store[key] = {} if @plural_policy_store[key].nil?
  end

  def destroy(*args)
    if self.gr_can_destroy?
      unless new_record?
        connection.delete(
        "DELETE FROM #{self.class.quoted_table_name} " +
        "WHERE #{connection.quote_column_name(self.class.primary_key)} = #{quoted_id}",
        "#{self.class.name} Destroy"
        )
      end
      @destroyed = true
      freeze
    else
      raise GuardRailsError, "Not Authorized to Destroy Object"
    end
  end

  alias :old_delete :delete

  def delete
    if self.gr_can_destroy?
      self.send("old_delete")
    else
      raise GuardRailsError, "Not Authorized to Destroy Object"
    end
  end

end

class Object

  attr_accessor :policy_object, :violation_object
  def populate_policies
  end

  def policy_object
    return @policy_object if !@policy_object.nil?
    cls = self.class
    if cls.respond_to?("superclass")
      if cls.superclass == ActiveRecord::Base
        return cls.policy_object
      end
    end
    return nil
  end

  def assign_policy(policy_type, function, target=:self, owner=self, field="")
    if policy_type
    if !self.frozen?
      @policy_object = {} if policy_object.nil?
      @policy_object[policy_type] = function
      if owner.is_a?(ActiveRecord::Base)
        owner.pps_init(field.intern)
        owner.plural_policy_store[field.intern][policy_type] = function
      end
    else
      if owner.is_a?(ActiveRecord::Base)
        puts "I'm Frozen! Owner: #{owner}, Field: #{field}"
        owner.frozen_policy_store[field.intern] = {} if (owner.frozen_policy_store[field.intern].nil?)
        owner.frozen_policy_store[field.intern][policy_type] = function
      else
        puts "Policy can't be propagated to non ActiveRecord Objects! #{owner}, #{field}"
      end
    end
  end

  def assign_violation(policy_type, violation, target=:self)
    @violation_object = {} if violation_object.nil?
    @violation_object[policy_type] = function
  end

  def eval_policy(policy_type)
    return true if policy_object.nil?
    function = policy_object[policy_type]
    return true if function.nil?
    return true if Thread.current['loopbreak'] == true
    Thread.current['loopbreak'] = true
    ret = function.call(Thread.current['user'])
    Thread.current['loopbreak'] = false
    ret
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

  def gr_can_append?(transparent=false)
    return true if eval_policy(:append_access)
    eval_violation(:append_access) unless transparent
  end

  # Alias all the object's getters and setters to check write policies
  def gr_policy_setup
    begin
      define_attribute_methods
    rescue
    end
    if self.respond_to?("reflections")
      dummy = eval("#{self}.new")
      attrs = dummy.attribute_names
      #    cast_attrs = []
      #            attrs.each {|a| cast_attrs << a + "_before_type_cast"}
      #            cast_attrs.delete_if {|label| !dummy.respond_to?(label)}
      #            puts cast_attrs.inspect
      for var in reflections.keys + attrs do
        #var = var[1..-1]

        #              next if var == :policy_object or var == :violation_object
        self.class_eval("alias :old_#{var}= :#{var}=")
        self.class_eval("
            define_method(:#{var}=) do |val|
						  target = old_#{var}
						  if target.nil?
                target = Object.new
						    if !self.frozen_policy_store[:#{var}].nil?
   						    target.assign_policy(:write_access, self.frozen_policy_store[:#{var}][:write_access])
						      puts 'Attempting to Restore Policy'
						      puts self.frozen_policy_store[:#{var}][:write_access]
                  puts target.policy_object.inspect
						    end
						  end
              self.send('old_#{var}=',val) if gr_can_edit? and target.gr_can_edit?
						end")

        self.class_eval("alias :old_#{var} :#{var}")
        self.class_eval("
            define_method(:#{var}) do
		 				  target = old_#{var}
						  return if target.nil?
              isproxy = target.respond_to?('target')
              if target.is_a?(Array)
                new_array = visible_array(target)
                if isproxy
                  target.target = new_array
                  target = AssociationProxyWrapper.new(target,self)
                  hsh = self.plural_policy_store[:#{var}]
                  if !hsh.nil?
                    hsh.each do |policy, func|
                    target.assign_policy(policy, func)
                  end
                end
                else
                  target = new_array
                end
              end
						  return target if target.gr_is_visible?
              return nil
					  end")
        self.class_eval("alias :#{var}_before_type_cast #{var}")

      end
    end
  end
end

