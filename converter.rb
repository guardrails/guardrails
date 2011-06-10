require 'rubygems'
require 'ruby_parser'
require 'ruby2ruby'
require 'find'

def interp_to_concat(ast)
	initial_string = Sexp.from_array [:str, ast[1]]
	arglist = Sexp.from_array [:arglist, interp_to_concat_helper(ast[2..-1])]
	return Sexp.from_array [:call, initial_string, :+, arglist]
end

def interp_to_concat_helper(ast)
	init_exp = nil	
	
	if ast[0][0] == :str
		init_exp = ast[0]
	end
	if ast[0][0] == :evstr
		empty_args = Sexp.from_array [:arglist]
		init_exp = Sexp.from_array [:call, ast[0][1], :to_s, empty_args]
	end	


	if ast.length < 2
		return init_exp			
	end

	arglist = Sexp.from_array [:arglist, interp_to_concat_helper(ast[1..-1])]
	return Sexp.from_array [:call, init_exp, :+, arglist]

end
	

def convert(file)
	code = File.read file

	code.gsub!(/".* \#\{.*\} .*"/x) { |match|
		ast = RubyParser.new.parse(match)
		new_ast = interp_to_concat(ast)
		x = Ruby2Ruby.new.process(new_ast)
	}	

	File.new(file, 'w').puts code 

end


def process(dir)
	Find.find("#{dir}") do |path|
		if File.file?(path) then convert(path) end
	end
end

process(ARGV[0])

