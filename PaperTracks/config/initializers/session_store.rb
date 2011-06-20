# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_PaperTracks_session',
  :secret      => '4b1f0006456d5b3ba8c24cd9468e10ad063810789fa79149d0328468ce4188dfdb15afb25ec1f808d773ca90de4ba516677fd7e34333e54d18e726b38c2202a9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
