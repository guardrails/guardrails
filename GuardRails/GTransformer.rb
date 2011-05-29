require 'ruby_parser'
require 'GSexp'
require 'GStringTransformer'
require 'pp'

class GTransformer

	# Transformations that happen to all model files
	def universal_transformations(ast)
		ast = ast.insert_at_front(@parser.parse("require 'GObject'; require 'wrapper'"))

		ast.insert_into_class! @parser.parse("unloadable"), true
		ast.insert_into_class!(@parser.parse(
				"include Wrapper; include Wrapper::WrapperMethods"), true)
		ast.insert_into_class!(@parser.parse("public"))
		ast.insert_into_class!(@parser.parse("define_attribute_methods"))

		return ast
	end

	# Transformations to build the policy and violation hashes
	def build_policy_objects(ast, ann_list)	
		return ast if ann_list.nil?

		function = "def populate_policies\n"
		for ann in ann_list do
			function += "#{ann.target}.assign_policy (:#{ann.policy}, '#{ann.lambda.to_s}')\n"
		end
		function += "end"

		ast.insert_into_class!(@parser.parse(function))
		return ast
	end

	# Transformations to enforce policies
	#def access_policy_transformations(ast)
	#	ast.insert_into_class! @parser.parse("gr_policy_setup")
	#	return ast
	#end

	# Replaces all references to Models in target ast with a ModelProxyObject.
	# We do this so we can intercept calls like [Model].find and [Model].delete
	def insert_model_proxies(ast, model_list)

		for model_name in model_list

			ast.replace!(model_name.to_sym, "gr_#{model_name}".to_sym)
			ast.insert_into_class! @parser.parse(
				"def gr_#{model_name}; ModelProxy.new(#{model_name}); end")
			ast.insert_into_class! @parser.parse(
				"def self.gr_#{model_name}; ModelProxy.new(#{model_name}); end")
		end
		return ast
	end

	def transform(asts, ann_lists, model_names, model_filenames)
		@parser = RubyParser.new	  
	
		# Transform the models to have policy mappings and such
		for filename in asts[:model].keys do

			# Only transform models that extend ActiveRecord::Base
			next unless model_filenames.include? filename

			ast = asts[:model][filename] 
			ann_list = ann_lists[filename]

			ast = universal_transformations(ast)
			ast = build_policy_objects(ast, ann_list)
			#ast = access_policy_transformations(ast)

			asts[:model][filename] = ast
		end

		# Transform the controllers to include the proper files and have model proxies
		for filename in asts[:controller].keys do
			ast = asts[:controller][filename] 
			ast = ast.insert_at_front(@parser.parse("require 'wrapper'"))
			ast.insert_into_class!(@parser.parse(
				"include Wrapper; include Wrapper::WrapperMethods"), true)

			ast.insert_into_class! @parser.parse("unloadable"), true

			ast = insert_model_proxies(ast, model_names)

			asts[:controller][filename] = ast
		end

		# Application helper needs a new function
		asts[:helper].insert_into_class! @parser.parse(
			'def protect
    		 	yield
    			@output_buffer = @output_buffer.transform(:HTML)
			 end')

		# Handle taint tracking transformations
		taint_tracking_transformations(asts)

		# We need the models to have access to the authentication information so they can decide
		# about authorization. 
	#	app_control = @asts[:controller]['application_controller.rb']
	#	app_control = @asts[:controller]['application.rb'] if app_control.nil?
	#	app_control.insert_class_stmt @parser.parse("before_filter :pass_user"), true
	#	app_control.insert_class_stmt @parser.parse(pass_user)

	end
end
