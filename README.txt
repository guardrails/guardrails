GEM REQUIREMENTS:
-----------------
	- Ruby on Rails [version 2.x.x] (Rails 3 not yet supported)
	- ruby_parser [2.0.5+]
	- ruby2ruby [1.2.5+]
	- nokogiri [1.4.4+] and mechanize

WHAT VERSIONS OF RUBY ARE SUPPORTED?
------------------------------------
	Ruby 1.8 is necessary to run the ruby_parser and ruby2ruby gems and must be the version
	of Ruby that is used when performing transformations.  That being said, GuardRails 
	supports both Ruby 1.8 and Ruby 1.9, so once the GuardRails transformation has been
	performed, either Ruby 1.8.x or Ruby 1.9.x may be used to run the application.

GUARDRAILS SETUP:
-----------------
	To initially set up GuardRails, follow these steps:
	1.  Install the required gems
	2.  Download a copy of GuardRails
	3.  Navigate the GuardRails package to the RawApps folder and place a working 
	    copy of your Rails application in the folder.
	4.  Go to RawApps/yourApp/config.  Copy the template "config.gr" from the root 
	    of the GuardRails package and place them here.  You will want to edit these 
	    for each application individually.
	5.  To test your setup, in the root of the GuardRails package, execute the 
	    "run.sh" shell script, passing in the name of the folder containing your 
	    application in the RawApps directory:
 
    	    ~$ ./run.sh yourApp

   *** Refer to the USING_GAURDRAILS.txt file for more details on using features of GuardRails

GEM MODIFICATIONS:
------------------
	Because string interpolation is only controlled by native Ruby code, it can potentially 
	drop taint information.  For this reason, any cases of interpolation must be removed 
	from ruby libraries that are used in your application that may handle sensitive string
	information.  Note that this is done for your application by default.  Rails, however, must
	be modified to remove interpolation.  Currently, this can be done with the following steps:

	1.  Replace the ruby2ruby.rb file in your gem library with the ruby2ruby.rb file given
	    in the repository
	2.  Back up a copy of the rails gem you are using
	3.  Run the 'converter.rb' file Ruby 1.8 giving the directory of the actionpack gem for
	    the version of rails you are using

	Note that this only removes interpolation from actionpack rails files, but this is
	often sufficient to secure the application.  This transformation will soon be able to
	be applied to all of rails and arbitrary code libraries.  In addition, we will soon
	provide pre-transformed versions of rails that can be installed simply as another
	version of rails and thus no rails gems will need to be modified.
