SETUP- GUARDRAILS
	To initially set up GuardRails, follow these steps:
		1.  Install the Ruby On Rails gem in the default gem path.
		2.  In the GuardRails package, execute the "patch" program.  This program will make a new version of Ruby On Rails on your machine which will be compatable with GuardRails.  It will not affect your ability to use the original version of Ruby on Rails, which remains unchanged.
		3.  Navigate the GuardRails package to the RawApps folder and place a working copy of your Rails application in the folder.
		4.  Go to RawApps/yourApp/config.  Copy the template "config.gr" from the root of the GuardRails package and place them here.  You will want to edit these for each application individually.
		5.  To test your setup, in the root of the GuardRails package, execute the "run.sh" shell script, passing in the name of the folder containing your application in the RawApps directory: 

		~$ ./run.sh yourApp

	Your application should launch as though you had deployed the Rails version.
		
SETUP- FIRST APP
	To prepare your first GuardRails application, follow these steps:
		1.  Create a new Rails application as you would any Rails application in the RawApps directory of the GaurdRails package OR move your current Rails project folder into the RawApps directory.
		2.  Go to RawApps/yourApp/config.  Copy the template "config.gr" from the root of the GuardRails package and place them here.  For now, leave the default error cases (these will cause your application to throw an exception when a policy is violated).  Below, you must specify the body of a ruby function which will be able to retrieve the current user's authentication information and store it in Thread.current["user"].  The easiest way to do this is to leave the default code stub and define a function in your application controller called "currentUser" which returns the user's information.
		3.  To test your setup, in the root of the GuardRails package, execute the "run.sh" shell script, passing in the name of the folder containing your application in the RawApps directory: 

		~$ ./run.sh yourApp

	Your application should launch as though you had deployed the Rails version, but will automatically deploy the updated GaurdRails String library modifications, protecting your application from most injection attacks.

ANNOTATIONS- AN INTRODUCTION
	GuardRails requires you to formally present your security policies via annotations in model folders of the data your wish to protect.  We assume here that you already have a basic grasp of how to use the Ruby on Rails framework.
		Go to your project in the RawApps folder and navigate to your User model file.  At the top of this file, specify a basic basic policy by typing this above the first line of code (i.e. class User):

		# @ read_access, lambda { |user| not user.nil? }

		Run your GuardRails application again the same way as before.  This process parses your code, looking for annotations, and applies them.  (If your project is ever unchanged and you wish to run it again, you can do so by running GuardRails/ProdApps/yourApp/script/server.  However, to edit your application, we strongly recommend that you edit the version in your RawApps folder and then rerun the GaurdRails transformation.)  If your application previously allowed unauthenticated users to view any information about any users, your application will now throw a GuardRails Exception when trying to bring up the page.  This means that GuardRails is now protecting data as specified by the policy!
		GuardRails policies have three parts: policy type, policy targets, and the policy itself as a lmbda expression.  In this example, we are restricting the readability of data, the policy targets are omitted here which causes GaurdRails to apply them to the next reasonable target- the entire model, and lambda expression uses the current users authentication information (as supplied by the pass_user function in your project's config.gr file) to test if the user is logged in or not.  Here, we assume that an unauthenticated user results in the current user being tracked as a NIL object, but this check can be manually editted to suit your implementation.
		The three parts of a GuardRails annotation are delimited by commas.  Annotations begin with a "# @", which would comment out these lines if you wanted to convert this application back to a regular Rails application.  The lambda expression should return true if and only if the current user should be granted the specified access to the specified data and false at all other times.  The set of recognized access types are: read_access, write_access, append_access, create_access, delete_access.  Creation and deletion refer to making or destroying instances of the object as a whole.  
		You may also specify target data fields which are stored in your database to be protected by your annotation, though you may alternatively just place the annotation immediately before the variables declaration.  An annotation with targets might look like this:

		# @ append_access, user_list, mailing_lists, lambda { |user| not user.nil? }

		In this case, a logged in user would be able to add new entries to the arrays "user_list" and "mailing_lists", but not edit current entries.

FAILING GRACEFULLY
	
	By modifying the default error case handling code, you can cause your application to fail in specified ways based on the type of policy violation experienced by the program.  By default, all policy violations result in an error page being displayed.  However, you may choose to fail gracefully, log the violation error, or execute arbitrary code, allowing you to redirect the user to another page such as a login screen.
	To fail gracefully, navigate to your project in the RawApps/yourApp/config directory, and open config.gr.  In this file, all error handling is currently set to default behavior by the string "error" following the "#" symbol on each of the first ten lines.  If you replace the string with the word "transparent", your application will not throw an exception when that type of policy violation occurs.  You may also replace this with a section of arbitrary ruby code which will be executed when the violation occurs.

POLICY EXCEPTIONS

	In some circumstances, a policy is generally correct, but needs to allow a few exceptions.  For example, consider a "forgot my password" function which is fairly common.  A reasonable policy concerning user passwords is that only admins or that single user should be allowed to see or modify the password.  However, in this example, an unauthenticated user must be able to (typically) change the password into a temporary, random password and have it emailed to the user.  Our simple policy will be cluttered up if we hardcode this exception into the policy!
	Instead, you can privilege certain functions to override your policies.  This should only be done with functions which cannot be exploited to defeat the security of your site or users.  A function can be marked as privileged inside of the controller where it appears, and the privlege will allow the function to execute without considering ANY GuardRails policies.  A privilege annotation looks like this:

	#TODO: get this example

UNIMPLEMENTED FUNCTIONALITY

KNOWN BUGS

CREDITS

