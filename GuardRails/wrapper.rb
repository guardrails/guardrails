
###  This file contains many of the utility code for some     ###
###  key parts of the access control system, particularly     ###
###  those that pertain to wrapper (or proxy) objects, which  ###
###  are needed to enforce policies on Model objects          ###


# A simple error type used throughout GuardRails to distinguish errors
# we raise from those that are caused by other problems.
class GuardRailsError < SecurityError
end

module Wrapper
  load "GObject.rb"

  # WrapperMethods contains a whole bunch of utility functions used
  # throughout GuardRails
  module WrapperMethods

    def guard_rails_error(message)
      raise GuardRailsError, message
    end

    # DEPRICATED: Now that gr_is_visible? is defined on ALL objects
    # (see "GObject.rb") this function is not really neccesary.  Just
    # call .gr_is_visible?
    def check_visible(obj)
      return obj.gr_is_visible?
    end

    # visible_array takes an array and removes all of the elements that
    # are not visible as defined by the gr_is_visible? function on those
    # objects
    def visible_array(ary)
      new_array = Array.new
      ary.each do |t|
        if check_visible(t)
          new_array << t
        end
      end
      return new_array
    end
    
    # If an array is covered with a proxy (like the plural association
    # proxies employed by Rails or the ones we use in GuardRails), this
    # is the appropriate version of visible_array to call
    def proxied_visible_array(proxy)
      new_array = visible_array(proxy)
      proxy.target = new_array
      return proxy
    end

    # Since plural associations have proxies but singular associations
    # do not, this function discriminates between the two, removing invisible
    # objects from the association array if it's plural, otherwise, it will
    # just be returned
    def association_visible(obj)
      if obj.class == Array
        return proxied_visible_array(obj)
      else
        return obj
      end
    end

    # These two functions together SQL sanitize a set of arguments
    # to a function.  Note that only Strings will be modified, however,
    # ALL strings will be modified, including ones nested in Hashes
    # or Arrays

    def clean_args(args)
      (0..args.size-1).each do |n|
        args[n] = clean_arg(args[n])
      end
      return args
    end

    def clean_arg(arg)
      if arg.class == Hash
        arg.each_pair do |key, val|
          arg[key] = clean_arg(val)
        end
      elsif arg.class == Array
        (0..arg.size-1).each do |m|
          arg[m] = clean_arg(arg[m])
        end
      elsif arg.class == String
        arg = arg.transform(:SQL)
      end
      return arg
    end

    # Wrapper Helper to determine the actual class of an object 
    # that may be a wrapper

    def get_true_class(obj)
      return obj.true_class
    end

    # For some reason, I did not realize that the "include?" method 
    # existed in the Array class, so I created this function.  Some 
    # functions may still call it, so it should not be removed yet.

    def in_set?(set, element)
      set.each do |t|
        if t == element
          return true
        end
      end
      return false
    end

    # Given a method name (String), it will be called on the given
    # object, but only if that method exists on that object.  If the
    # method is not defined, default_value will be returned

    def call_if_exists(obj, method, default_value = true)
      if obj.respond_to?(method)
        return obj.send(method)
      else
        return default_value
      end
    end
  end

  # WrapperCore serves as the superclass for most of the wrappers we
  # use in GuardRails.  It overrides most of the standard object methods
  # like class, is_a?, etc. to return the values defined by the target
  # object that is being wrapped.  Note that calling "true_class" will
  # generally give the Wrapper class since the "class" variable will return
  # the class of the target.

  class WrapperCore
    def target
      @target
    end

    def id
      @target.id
    end

    def inspect
      @target.inspect
    end

    def to_param
      @target.to_param
    end

    def is_a?(thing)
      @target.is_a?(thing)
    end

    def kind_of?(thing)
      @target.kind_of?(thing)
    end

    def class
      return @target.class
    end

    def type
      return @target.type
    end

    def to_s
      return @target.to_s
    end
  end

  # ------------------------------------------------------------
  # ---------------- AssociationProxyWrapper -------------------
  # ------------------------------------------------------------
  
  # In Ruby on Rails, one normally has to reference a model object like User
  # or Message in order to read and write to the database.  Plural associations
  # are one key exception, as when these arrays are modified or read, they can 
  # actually read and write to the database.  Rails accomplishes this by putting
  # a proxy object around the array representing the plural association.  In order
  # to make sure that none of the data access done through this proxy violates an
  # access control policy, we wrap the Rails proxy with an ADDITIONAL proxy, we 
  # call the AssociationProxyWrapper.

  class AssociationProxyWrapper < WrapperCore
    include WrapperMethods

    # Calling true_class on an object can be used to determine whether it has
    # an AssociationProxyWrapper or not

    def true_class
      return AssociationProxyWrapper
    end

    # The 'target' field refers to the object being proxied, in this case, the proxy
    # on the association array.  Thus target.target is the actual array in question.
    # The 'parent' field refers to the object that owns this association and is needed
    # in case that object has some access control property relevant to its fields and
    # associations.  

    def initialize(targ, prnt)
      @target = targ
      @parent = prnt
    end

    def parent
      @parent
    end

    alias_method :old_respond_to?, :respond_to?

    def respond_to?(param)
      old_respond_to?(param) || @target.respond_to?(param)
    end

    # The policy object accessor must be changed to reference the actual
    # array, rather than the array proxy.  This is accomplished by referring
    # to target.target (the target of the rails proxy).

    def assign_policy(*args)
      target.target.send("assign_policy",*args)
    end
    def policy_object
      target.target.send("policy_object")
    end

    # As with most ruby proxies, "method_missing" is the main function that serves
    # to regulate what functions are allowed to reach the proxied object.  In this
    # case, we check to make sure that the methods that, when called, change the 
    # database (like <<, clear, and delete) are only allowed through if the object
    # has the appropriate access credentials

    def method_missing(method, *args, &body)

      if in_set?(["<<","clear","delete"],method.to_s)

        # DEPRICATED CODE:
        if !call_if_exists(@parent, "gr_#{@target.proxy_reflection.name.to_s}_w?")
          guard_rails_error("Not authorized to use #{method.to_s} on read-only object")
        end
        # END OF DEPRICATED CODE

        failed = false
        
        # If the parent, the proxy, the Rails proxy, or the array itself
        # fail to allow edits, then the edit methods will be prohibited

        if @parent.respond_to?("gr_can_edit?")
          if !@parent.gr_can_edit?
            failed = true
          end
        end
        if @target.respond_to?("gr_can_edit?")
          if !@target.gr_can_edit?
            failed = true
          end
        end
        if self.respond_to?("gr_can_edit?")
          if !self.gr_can_edit?
            failed = true
          end
        end
        if @target.respond_to?("proxy_reflection")
          if !@target.target.gr_can_edit?
            failed = true
          end
        end

        # << counts as an append method, so it can be performed, even without
        # write access, as long as one of the objects in quesiton actively 
        # allows append access (note that not specifying append access at all)
        # does not count the same as directly saying append access is allowed,
        # as it would with any other type of access control policy

        if failed and method.to_s=="<<" 
          if @parent.respond_to?("gr_can_append?")
            if @parent.gr_can_append?
              failed = false
            end
          end
          if @target.respond_to?("gr_can_append?")
            if @target.gr_can_append?
              failed = false
            end
          end
          if self.respond_to?("gr_can_append?")
            if self.gr_can_append?
              failed = false
            end
          end
          if @target.respond_to?("proxy_reflection")
            if @target.target.gr_can_append?
              failed = false
            end
          end
          # If the method in question is << and there is no
          # append access, the violation policy for append access
          # will be run.

          # TODO: check to make sure that this line cannot be 
          # reached if << was called but no append access annotation
          # was defined
          return eval_violation(:append_access) if failed
        end
        
        # If the method is blocked for write access reasons, call
        # the appropriate violation method
        eval_violation(:write_access) if failed
      end

      # DEPRICATED CODE: Allows specific methods to be singled out as allowed
      # or not based on gr_ methods in the object that "owns" this reflection.
      # This feature is currently unused, but might be useful
      special_function = "gr_#{@target.proxy_reflection.name.to_s}_#{method.to_s}"
      if @parent.respond_to?(special_function)
        if !@parent.send(special_function)
          guard_rails_error("Not authorized to use #{method.to_s} on this object")
        end
      end
      # END OF DEPRICATED CODE

      # If 'find' is used on the plural association, make sure that none of its
      # parameters contain unsafe SQL (aka call the appropriate 'transform' method
      # on that string).
      if method.to_s == "find"
        args = clean_args(args)
      end

      # As with all objects potentially pulled from the database, policies need
      # to be set up immediatly
      target.each do |obj|
        obj.populate_policies
      end
      
      # If no errors have been raised up to this point, pass the method on to the
      # target, along with any arguments or block that may have been provided
      if block_given?
        @target.target.send(method,*args,&body)
      else
        @target.send(method,*args,&body)
      end
    end
  end

  # ------------------------------------------------------------
  # ----------------------- ModelProxy -------------------------
  # ------------------------------------------------------------
  
  # Like the AssociationProxyWrapper, the ModelProxy wrapper protects mitigates access
  # control calls to the database.  ModelProxy objects serve as proxies for the Model
  # objects like User, Message, Group, etc. ensuring that they do not disclose hidden
  # information and prevent unauthorized writes to the database. Unlike the
  # AssociationProxyWrapper, there is no Rails proxy, so @target refers directly to the
  # model object in question.

  class ModelProxy < WrapperCore
    include WrapperMethods

    # Calling "true_class" can be used distinguish between ModelProxy objects and 
    # Model objects as calling the "class" method will return the same class for
    # both.
    def true_class
      return ModelProxy
    end

    def initialize(targ)
      @target = targ
    end

    alias_method :old_respond_to?, :respond_to?

    def respond_to?(param)
      old_respond_to?(param) || @target.respond_to?(param)
    end

    # This function does all the heavy lifting for ModelProxy objects. Virtually 
    # all the functions come in through here and are processed to see if they 
    # are allowed or not

    def method_missing(method, *args, &block)

      # Check to see if the method attempts to create a new object (i.e. 
      # User.new or User.create).  If so, then check the creation access control
      # policy
      if ["new","create"].include? method.to_s
        if @target.gr_can_create?
          new_obj = @target.send(method, *args, &block)
          return new_obj if new_obj.gr_can_create?
        else
          return eval_violation(:create_access)
        end
      end

      # Check to see if the method attempts to destroy an object (i.e 
      # User.delete or User.destroy).  If so, check the destroy access control
      # policy
      if ["delete","destroy"].include? method.to_s
        if @target.gr_can_destroy?
          return @target.send(method, *args, &block)
        else
          return eval_violation(:destroy_access)
        end
      end

      # Make sure that the parameters passed into SQL queries (which are
      # constructed out of 'find' and 'count' function calls) are 
      # appropriately sanitized before they are executed
      if method.to_s == "find" || method.to_s == "count"
        args = clean_args(args)
      end

      # The "count" method should return the number of VISIBLE objects
      # and should not leak information about how many objects meet 
      # a certain criteria.  Since 'count' and 'find(:all)' have similar
      # syntax, the count parameters are passed to the find method
      # and the query results are then counted

      if method.to_s == "count"
        group_handling = false
        begin
          return_val = self.send("all",*args)
        rescue
          group_handling = true
          if args[0][:group] != nil
            group = args[0][:group]
            args[0].delete(:group)
          end
          return_val = self.send("all",*args)
        end
        if group_handling
          hash_store = Hash.new
          return_val.each do |t|
            key = t.send(group)
            if (hash_store.has_key?(key))
              hash_store[key] << t
            else
              hash_store[key] = Array.new
              hash_store[key] << t
            end
          end
          hash_store.each_pair do |key, val|
            hash_store[key] = visible_array(val).size
          end
          return hash_store
        else
          return return_val.size
        end
      end

      # Perform the desired method call, now that it is known
      # that it is not an illegal delete or create:

      return_val = @target.send(method, *args, &block)
      return nil if return_val.nil?

      if return_val.class == ActiveRecord::NamedScope::Scope
        return ModelProxy.new(return_val)
      end

      # Objects just pulled from the database must have their
      # access control policies established
      return_val.populate_policies

      # If the object is not an array, check that it is visible to the
      # current user, run the violation policy if it is not
      return return_val.eval_violation(:read_access) unless return_val.gr_is_visible?
     
      # If the return value is an array, check that none of its elements
      # should be hidden from the user.  If there are hidden elements,
      # they must be removed from the array.

      if return_val.is_a? Array
        new_results = []

        for element in return_val
          if element.is_a? ActiveRecord::Base # We only care about ActiveRecord Objects
            element.populate_policies
            if element.gr_is_visible?
              new_results << element
              element.gr_policy_setup
            else
              # Trigger violation if items are removed.
              # Note that in most read_access cases, the
              # would-be element is replaced by the return
              # value from the violation function, but in this
              # case, removing the object completely makes
              # a bit more sense
              element.eval_violation(:read_access)
            end
          else
            new_results << element
          end
        end
        return new_results
      else
        # TODO: Are these two lines necessary?
        return_val.populate_policies
        return_val.gr_policy_setup
      end

      return return_val
    end
  end
end
