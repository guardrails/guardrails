class GuardRailsError < SecurityError
end

module Wrapper
  #load "GActiveRecord.rb"
  load "GObject.rb"
  module WrapperMethods
    def guard_rails_error(message)
      raise GuardRailsError, message
    end

    # Helpers to process visibility
    def check_visible(obj)
      return obj.gr_is_visible?
    end

    def visible_array(ary)
      new_array = Array.new
      ary.each do |t|
        if check_visible(t)
          new_array << t
        end
      end
      return new_array
    end

    def proxied_visible_array(proxy)
      new_array = visible_array(proxy)
      proxy.target = new_array
      return proxy
    end

    def association_visible(obj)
      if obj.class == Array
        return proxied_visible_array(obj)
      else
        return obj
      end
    end

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
        arg = arg.pull_sql_safe
      end
      return arg
    end

    # Wrapper Helper to determine the actual class of an object that may be a wrapper
    def get_true_class(obj)
      return obj.true_class
    end

    #Other
    def in_set?(set, element)
      set.each do |t|
        if t == element
          return true
        end
      end
      return false
    end

    def call_if_exists(obj, method, default_value = true)
      if obj.respond_to?(method)
        return obj.send(method)
      else
        return default_value
      end
    end

  end

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
  class AssociationProxyWrapper < WrapperCore
    include WrapperMethods
    def true_class
      return AssociationProxyWrapper
    end

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

    def assign_policy(*args)
      target.target.send("assign_policy",*args)
    end

    def policy_object
      target.target.send("policy_object")
    end

    def method_missing(method, *args, &body)
      if in_set?(["<<","clear","delete"],method.to_s)
        if !call_if_exists(@parent, "gr_#{@target.proxy_reflection.name.to_s}_w?")
          guard_rails_error("Not authorized to use #{method.to_s} on read-only object")
          # Plural assoc write
        end
        failed = false
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
        if @target.respond_to?("target")
          if !@target.target.gr_can_edit?
            failed = true
          end
        end
        guard_rails_error("Not authorized to use #{method.to_s} on read-only object") if failed
      end
      special_function = "gr_#{@target.proxy_reflection.name.to_s}_#{method.to_s}"
      if @parent.respond_to?(special_function)
        if !@parent.send(special_function)
          guard_rails_error("Not authorized to use #{method.to_s} on this object")
        end
      end
      if method.to_s == "find"
        sidelog = Logger.new('sidelog.txt')
        sidelog.debug(method.to_s + " " + args.to_s)
        #  args = clean_args(args)
        sidelog.debug(method.to_s + " " + args.to_s)
      end
      target.each do |obj|
        obj.populate_policies
      end
      if block_given?
        @target.target.send(method,*args,&body)
      else
        @target.send(method,*args,&body)
      end
    end

    def true_class
      AssociationProxyWrapper
    end
  end

  # ------------------------------------------------------------
  # ----------------------- ModelProxy -------------------------
  # ------------------------------------------------------------
  class ModelProxy < WrapperCore
    include WrapperMethods
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

    # This function does all the heavy lifting for ModelProxy objects. Virtually all the functions come
    # in through here and are processed to see if they are legal or not.
    def method_missing(method, *args, &block)

      # CREATION PERMISSION CHECK - User.create
      if method.to_s == "new" || method.to_s == "create"
        if @target.gr_can_create?
          new_obj = @target.send(method, *args, &block)
          return new_obj if new_obj.gr_can_create?
        else
          raise GuardRailsError, "Not Authorized to Create New Object"
          return nil
        end
      end

      # DELETION PERMISSION CHECK - User.delete
      if ["delete","destroy"].include? method.to_s
        puts "CHECKING!!!!!!!!!!!!"
        if @target.gr_can_destroy?
          return @target.send(method, *args, &block)
        else
          raise GuardRailsError, "Not Authorized to Destroy New Object"
          return nil
        end
      end

      # READ PERMISSION CHECK - User.find
      return_val = @target.send(method, *args, &block)

      return nil if return_val.nil?

      # Make sure the object is visible
      return_val.populate_policies
      return nil unless return_val.gr_is_visible?

      # Check each of the array elements
      if return_val.is_a? Array
        new_results = []

        for element in return_val
          if element.is_a? ActiveRecord::Base
            element.populate_policies
            if element.gr_is_visible?
              new_results << element
              element.gr_policy_setup
            end
          else
            new_results << element
          end
        end
        return new_results

        # If the result is a single object, set up the gr policies on it
      else
        return_val.populate_policies
        return_val.gr_policy_setup
      end

      return return_val
    end
  end
end

#if return_val.class == Array
#			new_array = Array.new
#			for ele in return_val
#				if ele.gr_is_visible?
#					ele.setup
#					new_array << ele
#				else
#					# If error is not transparent, we prevent the whole find
#					# Otherwise, we continue and ignore the unauthorized object.
#					if ele.error_cases(:many_model_read) != "transparent"
#						return ele.error_case_result(:many_model_read)
#					end
#				end
#			end
#			return new_array

# DELETION PERMISSION CHECK
#if ["delete","destroy"].include? method.to_s
#	if args[0].is_a? Array
#		new_args = Array.new
#		for id in args[0]
#			found_obj = find(id)
#
#					if found_obj.gr_can_destroy?
#						new_args << id
#					else
#						# If error is not transparent, we prevent any deletes from executing
#						# Otherwise, we continue with deletes and ignore the unauthorized delete.
#						if found_obj.error_cases(:model_destroy) != "transparent"
#							return found_obj.error_case_result(:model_destroy)
#						end
#					end

#				end
#				args[0] = new_args
#				return @target.send(method, *args, &block)

#			else
#				new_obj = @target.find(args[0])
#				if new_obj.gr_can_destroy?
#					return @target.send(method, *args, &block)
#				else
#					# Single object destroy is simple because transparent destroy does nothing
#					return new_obj.error_case_result(:model_destroy)
#				end
#			end
#		end

# DELETION PERMISSION CHECK
#		if method.to_s == "delete_all"
#			count = 0
#			objs_to_delete = Array.new
#			@target.find(:all, :conditions => args[0]).each { |object|
#				if object.gr_can_destroy?
#					objs_to_delete << object
#				else
#					# If error is not transparent, we prevent any deletes from executing
#					# Otherwise, we continue with deletes and ignore the unauthorized delete.
#					if object.error_cases(:model_destroy) != "transparent"
#						return object.error_case_result(:model_destroy)
#					end
#				end
#			}
#			objs_to_delete.each { |object|
#				object.delete
#				counter +=1
#			}
#			return counter
#		end

#		# DELETION PERMISSION CHECK
#		if method.to_s == "destroy_all"
#			objs_to_delete = Array.new
#			@target.find(:all, :conditions => args[0]).each { |object|
#				if object.gr_can_destroy?
#					objs_to_delete << object
#				else
#					# If error is not transparent, we prevent any deletes from executing
#					# Otherwise, we continue with deletes and ignore the unauthorized delete.
#					if object.error_cases(:model_destroy) != "transparent"
#						return object.error_case_result(:model_destroy)
#					end
#				end
#			}
#			objs_to_delete.each { |object|
#				object.destroy
#			}
#			return objs_to_delete
#		end
#

#args = clean_args(args)

# Update_all currently prohibited
#     if method.to_s == "update_all"
#      guard_rails_error("update_all is forbidden in GuardRails because of security implications, please manually use update_attributes")
#   end

#Special Handling so 'count' only includes visible objects
#      if method.to_s == "count"
#       group_handling = false
#      begin
#       return_val = @target.send("all",*args)
#       rescue
#          group_handling = true
#          if args[0][:group] != nil
#            group = args[0][:group]
#            args[0].delete(:group)
#          end
#          return_val = @target.send("all",*args)
#        end
#        if group_handling
#          hash_store = Hash.new
#          return_val.each do |t|
#            key = t.send(group)
#            if (hash_store.has_key?(key))
#              hash_store[key] << t
#            else
#              hash_store[key] = Array.new
#              hash_store[key] << t
#            end
#          end
#          hash_store.each_pair do |key, val|
#            hash_store[key] = visible_array(val).size
#          end
#          return hash_store
#        else
#          return return_val.size
#        end
#      end
# --- end 'count' handling

#      return_val = @target.send(method, *args, &block)
#		return nil if return_val.nil?

# Cover NamedScopes that are returned
#      if return_val.class == ActiveRecord::NamedScope::Scope
#        return ModelProxy.new(return_val)
#      end

# Ensures all the results are visible.
#		if return_val.class == Array
#			new_array = Array.new
#			for ele in return_val
#				if ele.gr_is_visible?
#					ele.setup
#					new_array << ele
#				else
#					# If error is not transparent, we prevent the whole find
#					# Otherwise, we continue and ignore the unauthorized object.
#					if ele.error_cases(:many_model_read) != "transparent"
#						return ele.error_case_result(:many_model_read)
#					end
#				end
#			end
#			return new_array
#
#		else
#			if return_val.respond_to?("gr_is_visible") and not return_val.gr_is_visible?
#				return return_val.error_case_result(:single_model_read, return_val.class.to_s)
#			end
#			return return_val.setup if return_val.respond_to? "setup"
#			return return_val
#		end
#   end
#end
#end
