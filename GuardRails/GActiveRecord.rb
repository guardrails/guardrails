# This is an extension to the usual ActiveRecord class to include functions that need 
# to be in every model when using GuardRails. These functions handle a lot of the write
# control as well as include default authorization checks. 
class ActiveRecord::Base

	# Function used to testing if we are in privileged execution mode.
	# Helps clean up some of the authorization check functions.
	#def priv_test(filename)
	#	return (Thread.current['priv'] != nil and Thread.current['priv'][filename])
	#end

	# COMMENT THIS
	#def setup
	#	self.class.define_attribute_methods
	#	for att in self.attributes.keys do
	#		begin
	#			if not self.respond_to?("gr_#{att}_w?")
	#				self.class.class_eval("
	#					alias raw_#{att}= #{att}=
	#					def #{att}=(new_val)
	#						if gr_#{att.to_sym}_w?
	#							self.send(\'raw_#{att}=\', new_val)
	#						else
	#							error_case_result(:att_write)	
	#						end
	#					end
	#					def gr_#{att}_w?		
	#						gr_can_edit?
	#					end"	)		
	#			end
	#		rescue
	#		end
	#	end
	#	self
	#end

	
	# Destruction functions need to call gr_can_destroy
	if not self.public_instance_methods.include? "raw_destroy"
		alias raw_destroy destroy
		alias raw_delete delete
	end

	def destroy
		if gr_can_destroy? then raw_destroy 
		else error_case_result(:model_destroy)	
		end
	end

	def delete
		if gr_can_destroy? then raw_delete 
		else error_case_result(:model_destroy)	
		end
	end

	# This function will execute the proper functions depending on the error specification
	# provided by the user and the type of function that failed an authorization check. 
	#def error_case_result(key, target=nil)
	#	error_case = error_cases(key)
#
#		if error_case == "error"
#			raise GuardRailsError
#		elsif error_case == "nothing" or error_case == "transparent"
#			return nil
#		else
#			return eval error_case
#		end
#	end

end
