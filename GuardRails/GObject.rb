
# We need to add some methods to the ActiveRecord::Base class
# to enforce all of the access control policies correctly.  In 
# particular, we occasionally add copies of policy and violation 
# objects that would be stored on the fields of the ActiveRecord
# object, were it not for some limitation, usually because that 
# field contains a frozen object (like nil).  See the individual
# methods for more details on what is added/changed.

class ActiveRecord::Base
  attr_accessor :frozen_policy_store, :plural_policy_store
  
  # The frozen_policy_store on ActiveRecord objects is used
  # as a backup storage method when the appropriate policy
  # object cannot be attached to the desired field directly,
  # because that object is frozen (usually this occurs when
  # the value is "nil", as nil counts as being frozen).

  # All of these "store" fields map strings with the name
  # of the field in question with an additional hash, which
  # maps the a symbol representing the policy type (:read,
  # :create, etc.) to the function representing the policy 
  # (or violation) that would have normally been assigned 
  # to the object directly

  def frozen_policy_store
    @frozen_policy_store = {} if @frozen_policy_store.nil?
    return @frozen_policy_store
  end

  # As with frozen fields, we also store policies that would 
  # be assigned to plural associations. This is mainly necessary
  # because our proxy + the Rails proxy adds quite a bit of
  # of complexity to determining what object we are assigning
  # the given policy to (particularly since we make assign_policy
  # a function supported by ALL objects)

  def plural_policy_store
    @plural_policy_store = {} if @plural_policy_store.nil?
    return @plural_policy_store
  end

  # A small utility function used to initialize the hash if
  # nil and give it a blank hash for the given key if none exists
  def pps_init(key)
    @plural_policy_store = {} if @plural_policy_store.nil?
    @plural_policy_store[key] = {} if @plural_policy_store[key].nil?
  end

  # Each of the policy object functions has a mirror function
  # for violation objects, i.e. rules for what to do if one of 
  # the policies is violated.  Since these two sets are essentially
  # identical, it may have been more prudent to store the two 
  # together, but we will leave it like this for now

  attr_accessor :frozen_violation_store, :plural_violation_store
  def frozen_violation_store
    @frozen_violation_store = {} if @frozen_violation_store.nil?
    return @frozen_violation_store
  end
  def plural_violation_store
    @plural_violation_store = {} if @plural_violation_store.nil?
    return @plural_violation_store
  end
  def pvs_init(key)
    @plural_violation_store = {} if @plural_violation_store.nil?
    @plural_violation_store[key] = {} if @plural_violation_store[key].nil?
  end

  # Most of the time, functions that modify the database go through the
  # Model objects like User, Group, Product, etc., but occasionally the
  # database is modified through other means, like plural association
  # objects with special Rails proxies on them.  In this case, instances
  # of the Model objects (instances of a class that inherits from
  # ActiveRecord::Base) can modify the database if delete or destroy is
  # called on them.  These methods preserve the same functionality as 
  # the original methods, but add the appropriate access control checks

  # For some reason, the destroy method could not be aliased without 
  # causing the infinite aliasing loop problem.  Some basic tricks to 
  # prevent this did not work, so we copied the destroy method
  # straight out of the Rails code.  This means that this implementation
  # is Rails dependent (to the extent to which the 'destroy' method varies
  # between Rails versions).

  # TODO: Implement a destroy method that still preserves the access
  # control rules, but is not tied to a certain Rails implementation

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
      eval_violation(:destroy_access)
    end
  end

  # The 'delete' method can be overridden to support access control
  # policies in the usual aliasing way without any problems

  begin
    alias :old_delete :delete
  rescue
  end
  def delete
    if self.gr_can_destroy?
      self.send("old_delete")
    else      
      eval_violation(:destroy_access)
    end
  end
end

# We add a whole bunch of methods to the Object class so that
# we can assign access control policies to different objects
# that need protection.  All of the main code for assigning
# and evaluating access control policies is written here.

class Object
  
  # The policy_object and violation_object fields are hashes
  # that contain the various access control function used to
  # evaluate whether or not the user has sufficient privileges
  # to perform certain actions  (policy_object) or what to 
  # do if the user attempts to perform an action without 
  # those privileges (violation_object)
  attr_accessor :policy_object, :violation_object

  # populate_policies is defined here so that we can call it on
  # all objects without problem.  For most objects, it does 
  # nothing, but for those objects (mainly ActiveRecord objects)
  # that have access control policies on themselves or their
  # fields, this method will be overridden to setup the those
  # policies

  def populate_policies
  end

  # Getter for the policy_object field.  If no policy object
  # is defined and the object's class descends from the 
  # ActiveRecord class, it will look for the policy in the
  # object's class (the corresponding model object)
 
  def policy_object
    return @policy_object if !@policy_object.nil?
    if self.is_a?(ActiveRecord::Base)
      return self.class.policy_object
    end
    return nil
  end

  # Getter for the violation_object field.  Essentially
  # identical to the policy_object accessor.

  def violation_object
    return @violation_object if !@violation_object.nil?
    if self.is_a?(ActiveRecord::Base)
        return self.class.violation_object
    end
    return nil
  end

  def assign_policy(policy_type, function, target=:self, owner=self, field="")

    # If the policy relates to taint tracking, call the taint_field
    # function, which has its own elaborate way of assigning the 
    # new taint status correctly. See taint_system.rb for more on that.
    if policy_type == :taint
      if !self.nil?
        t_hash = eval(function)
        new_str = TaintSystem::taint_field(self,:HTML, t_hash[:HTML])
        self.taint = new_str.taint
      end

    # Handle policies relating to the "Worlds" system, a tie-in with 
    # work by Yuchen Zhou.  These "Worlds" help partition the DOM 
    # so that third-party scripts have access to only very specific 
    # portions of the HTML

    elsif [:read_worlds,:write_worlds,:read_worlds_r, :write_worlds_r].include?(policy_type)
      if !self.nil?
        worlds = eval(function)

        # The "function" portion of the annotation (the place in the
        # annotation where the function would go if this were an 
        # access control annotation) must be an Array containing 
        # the list of the appropriate "Worlds"
        if worlds.class != Array
          raise GuardRailsError, "World annotation does not contain an array"
        end

        # We represent the list of worlds (either read, write, read
        # recursive, or write recursive) as a hash with the string
        # representing the world mapping to true.  This is used to 
        # quickly eliminate double entries, especially when we
        # merge multiple sets of worlds together

        world_hash = {}
        worlds.each do |w|
          world_hash[w] = true
        end

        # Each of the different "world" types are all incorporated
        # into a single hash, which is later stored as the :Worlds
        # top-level context in the taint Transformer
        #
        # Example :Worlds hash:
        # :World => {:read => {"World1" => true, "World2" => true}, 
        #            :readR => {"World2" => true},
        #            :write => {"World2" => true, "World3" => true}}

        if policy_type == :read_worlds
          t_hash = {:read => world_hash}
        elsif policy_type == :read_worlds_r
          t_hash = {:readR => world_hash}
        elsif policy_type == :write_worlds
          t_hash = {:write => world_hash}
        else policy_type == :write_worlds_r
          t_hash = {:writeR => world_hash}
        end

        # "Worlds" information propagates using the taint system,
        # as the information affects how the content is rendered
        # in HTML.  Note that the "true" fourth parameter here means
        # that this assignment will be "forced", ignoring whether or
        # not the string is already tainted or untainted.  See 
        # taint_system.rb for more on how this function works.

        new_str = TaintSystem::taint_field(self,:Worlds, t_hash, true)
        self.taint = new_str.taint
      end

    # If the policy is not a :taint or Worlds one, then it must be about
    # access control policies (well it could be about giving a function
    # special privileges, but that does not involve calling assign_policy).
    else      
      if !self.frozen?

        # If the object onto which we are trying to assign a policy
        # is not frozen, then we can simply assign it to its 
        # policy object (which is just a hash mapping the policy type
        # like :read, :create, etc.) to the function that will return
        # true or false based on whether or not the user has that 
        # permission.

        @policy_object = {} if policy_object.nil?
        @policy_object[policy_type] = function        

        # If we are dealing with an ActiveRecord, we store the policy
        # in the "plural_policy_store" as a backup in case there is 
        # proxy-related confusion
        if owner.is_a?(ActiveRecord::Base)
          owner.pps_init(field.intern)
          owner.plural_policy_store[field.intern][policy_type] = function
        end
      else

        # If the object is frozen, then the policy cannot be attached
        # directly to the object (this is most commonly the case if the
        # the object is nil).  Instead it is stored in the frozen_policy_store
        # of the "owner" (the ActiveRecord Object that has this object as 
        # a field).  See the discussion at the beginning of this file for more        
        if owner.is_a?(ActiveRecord::Base)
          owner.frozen_policy_store[field.intern] = {} if (owner.frozen_policy_store[field.intern].nil?)
          owner.frozen_policy_store[field.intern][policy_type] = function
        else
          puts "Policy can't be propagated to non ActiveRecord Objects! #{owner}, #{field}"
        end

        # Note: We're out of luck if the owner is not an ActiveRecord object
        # but I don't think this will ever happen in practice
      end
    end
  end

  # This function is essentially the same as the assign_policy function,
  # but instead deals with violation objects. Note that we don't have to
  # worry about taint or worlds annotations here, as they do not really
  # have a "violation behavior" per-say

  def assign_violation(violation_type, function, target=:self, owner=self, field="")
    if !self.frozen?
      @violation_object = {} if violation_object.nil?
      @violation_object[violation_type] = function
      if owner.is_a?(ActiveRecord::Base)
        owner.pvs_init(field.intern)
        owner.plural_violation_store[field.intern][violation_type] = function
      end
    else
      if owner.is_a?(ActiveRecord::Base)
        owner.frozen_violation_store[field.intern] = {} if (owner.frozen_violation_store[field.intern].nil?)
        owner.frozen_violation_store[field.intern][violation_type] = function
      else
        puts "Violation can't be propagated to non ActiveRecord Objects! #{owner}, #{field}"
      end
    end
  end

  # Eval_policy is used to lookup policies stored on an object in order
  # to judge whether or not the user has permission to perform a certain
  # action.  Note that it is expected that both Thread.current['user']
  # and Thread.current['response'] are appropriately defined when this
  # function is called

  def eval_policy(policy_type)    

    # Bail out on the policy evaluation if 'override_policy' is defined 
    # in the current Thread.  This indicates that there is some function 
    # privileging that should take the place of the actual policy.

    return Thread.current['override_policy'].call unless Thread.current['override_policy'].nil?

    # If there is no policy object defined, then we assume that 
    # access should be allowed.  This is part of our philopsophy that
    # GuardRails should not interfere with existing functionality
    # unless explicity told to do so.

    if policy_object.nil?
      if policy_type == :append_access
        # Not sure whether defering to :write_access in this case
        # actually does anything since the entire object is nil
        return eval_policy(:write_access)
      else
        return true
      end
    end

    # If there is a policy_object, but it has no rule for the 
    # specific type of access we are concerned with, true is the
    # default response, except in the case of append access, which
    # should defer to write access if undefined.  After all, if
    # you do not have write access, you should not be able to
    # append anything.

    function = policy_object[policy_type]
    if function.nil?
      if policy_type == :append_access
        return eval_policy(:write_access)
      else
        return true
      end
    end

    # Loopbreak is a thread variable that prevents infinite loops
    # from occuring when an access control check occurs within
    # an annotation's function that are mutually dependent.
    # For now, we just run the annotation functions in a universally
    # privileged environment.

    return true if Thread.current['loopbreak'] == true
    Thread.current['loopbreak'] = true

    # The number of parameters passed to the policy's function depends
    # on how many parameters it wants.  It can have no parameters, the
    # current user if it has one parameter, and the current user and 
    # response information if it has two.

    func = eval(function)
    if func.arity == 0
      ret = eval(function).call
    elsif func.arity == 1
      ret = eval(function).call(Thread.current['user'])
    elsif func.arity == 2
      ret = eval(function).call(Thread.current['user'], Thread.current['response'])
    else
      raise GuardRailsError, "Annotation Policy Requires Too Many Parameters"
    end

    # Turn of the extra privileges
    Thread.current['loopbreak'] = false

    # Return true if the access is allowed, false otherwise
    ret
  end


  # The violation equivalent of eval_policy.  See earlier comments
  # for help with this function.
  def eval_violation(policy_type)
    return nil if violation_object.nil?
    function = violation_object[policy_type]
    if function.nil?
      if policy_type == :append_access
        return eval_violation(:write_access)
      else
        return true
      end
    end
    return nil if Thread.current['loopbreak'] == true
    Thread.current['loopbreak'] = true
    func = eval(function)
    if func.arity == 0
      ret = eval(function).call
    elsif func.arity == 1
      ret = eval(function).call(Thread.current['user'])
    elsif func.arity == 2
      ret = eval(function).call(Thread.current['user'], Thread.current['response'])
    else
      raise GuardRailsError, "Annotation Violation Requires Too Many Parameters"
    end
    Thread.current['loopbreak'] = false
    ret
  end

  # A bunch of nice shortcut functions for judging whether or
  # not a user has permission to perform a certain action
  # on the piece of data in question
  def gr_is_visible?
    eval_policy(:read_access)
  end
  def gr_can_edit?
    eval_policy(:write_access)
  end
  def gr_can_create?
    eval_policy(:create_access)
  end
  def gr_can_destroy?
    eval_policy(:delete_access)
  end
  def gr_can_append?
    # If the user has write_access, it trumps whatever
    # the value of append_access is
    eval_policy(:write_access) || eval_policy(:append_access)
  end

  # gr_policy_setup is resonsible for overriding the default accessors
  # for fields of ActiveRecord objects, such that the access does 
  # not violate any of the specified access control rules.  Because
  # it is almost impossible to determine what fields an attribute
  # will have before runtime (also, the accessors for these fields
  # have a rather sneaky habit of being undefined until you ask for
  # them.  Poke around at the "method_missing" method in ActiveRecord
  # objects to see the oddities for yourself), we do the accessor 
  # modifications DYNAMICALLY (at runtime).

  # Note that it is not clear why we have gr_policy_setup in the 
  # Object class when it is clear designed to work only with
  # ActiveRecord Objects.  It may be more logical to move it
  # to that class (TODO).

  def gr_policy_setup
    begin
      # If there are no accessors for the model object's accessors,
      # they need to be defined so we can alias them
      define_attribute_methods
    rescue
    end
    
    if self.respond_to?("reflections")

      # Make a dummy instance of the ActiveRecord class
      # so that we can read off its list of attributes
      dummy = eval("#{self}.new")
      attrs = dummy.attribute_names

      # We need to override the accessors both for attributes
      # and reflections (i.e belongs_to, has_many, etc.)
      for var in reflections.keys + attrs do

        # Setter - 
        self.class_eval("alias :old_#{var}= :#{var}=")
        self.class_eval("
            define_method(:#{var}=) do |val|
                 # We need the old value in order to make judgments 
                 # about whether or not certain accesses are allowed
                 # In particular, the access control policies are attached
                 # to the value being edited (unless its frozen) so 
                 # we need the object itself to decide if it can be changed.
                 # In addition, the old object is used for comparisons
                 # to distinguish complete edits from simple appends.

		 target = old_#{var}

                 # If the current version of the data is frozen, then
                 # we can't judge it by its attached data policy and
                 # instead must turn to its owner and its frozen_policy_store
                 # then put that in target so it looks no different
                 # than if it were not frozen

		 if target.nil? || target.frozen?
                    target = Object.new
		    if !self.frozen_policy_store[:#{var}].nil?
   		       target.assign_policy(:write_access, 
                          self.frozen_policy_store[:#{var}][:write_access])		
		    end
		 end
                  
                 # In order for an edit to be allowed, both the object
                 # to be edited, and the object that owns the field that
                 # is being edited must have edit permissions. The exception
                 # to this is if the change is appending to the content and
                 # appends are explicity allowed

                 if gr_can_edit? and target.gr_can_edit?
                    return self.send('old_#{var}=',val)  #Edits allowed             
                 elsif target.gr_append_check? val
                     if gr_can_append? and target.gr_can_append?
                       return self.send('old_#{var}=',val)
                     else
                       return eval_violation(:append_access) if target.gr_can_append?
                       return target.eval_violation(:append_access)
                     end
                 else
                    # Edits not allowed and appends either not applicable
                    # or also not allowed
                    return eval_violation(:write_access) if target.gr_can_edit?
                    return target.eval_violation(:write_access)
                 end
	     end")

        # Getter
        self.class_eval("alias :old_#{var} :#{var}")
        self.class_eval("
            define_method(:#{var}) do
             
              # Actually get the value in question, but we only
              # return it if read access is allowed.  We also
              # need this value to perform checks against the
              # access control policy

   	      target = old_#{var}

              # We assume that having a value of nil tells no one
              # any particularly useful information, so if the 
              # object is nil, we just skip the rest and return it.

	      return if target.nil?
                           
              # If the data being returned is an array, then we need
              # to do some extra checks.  First, the array cannot 
              # contain any objects which are themselves hidden. 
              # Second, we need to check if the Array is wrapped
              # with a Rails proxy that will allow it to make changes
              # to the database after the leaving this function.  If
              # this is the case, we must wrap the proxy with one of
              # our proxies (AssociationProxyWrapper) so that methods
              # called on the returned proxied array cannot change
              # the database if not allowed by the access control policies

              isproxy = target.respond_to?('proxy_reflection')
              if target.is_a?(Array)
                new_array = visible_array(target)
                if isproxy
                  target.target = new_array
                  target = AssociationProxyWrapper.new(target,self)

                  # Pull the appropriate policy from the owner of the
                  # field's plural policy store (see GObject.rb)

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
              
              # If the object in question is visible, then we can return it 
	      return target if (target.gr_is_visible? && self.gr_is_visible?)

              # If the target is visible, then it must be the owner that
              # is hidden, so evaluate the violation there
              return eval_violation(:read_access) if target.gr_is_visible?

              # If this line is reached, then the visibility issue
              # lies with the target, so the violation should be 
              # evaluated on it
              return target.eval_violation(:read_access)
	    end")
        
        # Our current implementation overrides only the
        # default accessors, however, [var]_before_type_cast
        # offers another route to the raw data that we need 
        # to cover.  For now, the two accessors are made
        # identical.
        
        # TODO: Distinguish the _before_type_cast accessor from
        # the normal getter so that they both preserve the security
        # policies, and their intended content formatting differences
        self.class_eval("alias :#{var}_before_type_cast #{var}")
      end
    end
  end

  # Note that this function is very different from gr_can_append, 
  # which checks whether or not an append is allowed at all. 
  # This function compares the current value of the object to
  # a candidate new value to determine whether the new version
  # is simply an "appended" version of the first one.  If this
  # is the case, then the function will return true.  If the
  # objects are different classes, have different content or
  # changes are not at the "end" of the object, then it will
  # return false.  This currently supports anything with a 
  # "to_enum" method, like Arrays.  Special cases, like Strings
  # and Hashes, where defining the idea of "appending" is fairly
  # simple, are defined below.

  def gr_append_check? obj
    return false if obj.class!=self.class
    return false if !respond_to("each")
    myEnum=to_enum
    objEnum=obj.to_enum
    while true
      begin
        myEle=myEnum.next
      rescue
        return true
      end
      begin
        objEle=objEnum.next
      rescue
        return false
      end
      return false if myEle!=objEle
    end
    return true
  end
end

# Append checks for Strings and Hashes.  See comments
# above for more details for whats going on.  You can
# feel free to write append checks for additional classes, 
# but be sure to always make sure the two objects being
# compared have the same class

class String
  def gr_append_check? obj
    return false if !obj.is_a? String
    return obj[0...length]==self
  end
end

class Hash
  def gr_append_check? obj
    return false if !obj.is_a? Hash
    each_key do |k|
      if !obj.has_key? k or self[k]!=obj[k]
        return false
      end
    end
    return true
  end
end
