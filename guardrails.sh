#! /bin/bash
app_name=$1

# Delete existing app in ProdApps
rm -r ProdApps/$app_name

# Copy the raw application folder into the production applications folder
cp -R RawApps/$app_name ProdApps

# Put all models/controllers/helpers/views in a GuardRails folder
cd ProdApps/$app_name/app
mkdir -p GuardRails
cp -R controllers GuardRails
cp -R models GuardRails
cp -R helpers GuardRails
cp -R views GuardRails

# Run GuardRails - CHANGE ruby1.9.1 to whatever ruby command you have installed
cd ../../.. 
cd GuardRails
ruby GCompiler.rb ../ProdApps/$app_name/

# Place Wrapper.rb, GActiveRecord.rb in lib folder
cd ..
cp GuardRails/wrapper.rb ProdApps/$app_name/lib
cp GuardRails/GActiveRecord.rb ProdApps/$app_name/lib


