#! /bin/bash
app_name=$1
if [ $# -ne 1 ]; then
  echo "Please Specify a Project to Transform!"
  exit 2
fi

echo $app_name

# Delete existing app in ProdApps
if [ -d "ProdApps/$app_name" ]; then 
  echo "Deleting Old Version..."
  rm -r ProdApps/$app_name
fi 

# Copy the raw application folder into the production applications folder
echo "Copying..."
if [ -d "RawApps/$app_name" ]; then
  cp -R RawApps/$app_name ProdApps
else
  echo "Could Not Find Project '$app_name'! Exiting..."
  exit 2
fi

# Put all models/controllers/helpers/views in a GuardRails folder
echo "Copying GuardRails Tools..."
cd ProdApps/$app_name/app
mkdir -p GuardRails
cp -R controllers GuardRails
cp -R models GuardRails
cp -R helpers GuardRails
cp -R views GuardRails

# Run GuardRails - CHANGE ruby1.9.1 to whatever ruby command you have installed
cd ../../.. 
cd GuardRails

# Place Wrapper.rb, GActiveRecord.rb, GObject.rb in lib folder
if [ ! -f "RawApps/$app_name/config/config.gr" ]
then
  echo "Adding a Blank Config File..."
  cd ..
  cp GuardRails/config.gr ProdApps/$app_name/config
  cd GuardRails
fi

echo "Transforming..."
ruby GCompiler.rb ../ProdApps/$app_name/

# Place Wrapper.rb, GActiveRecord.rb in lib folder
echo "Adding Library Files..."
cd ..
cp GuardRails/wrapper.rb ProdApps/$app_name/lib
cp GuardRails/GActiveRecord.rb ProdApps/$app_name/lib
cp GuardRails/GObject.rb ProdApps/$app_name/lib

cp GuardRails/taint_system.rb ProdApps/$app_name/lib
cp GuardRails/taint_types.rb ProdApps/$app_name/lib
cp GuardRails/extra_string.rb ProdApps/$app_name/lib
cp GuardRails/context_sanitization.rb ProdApps/$app_name/lib

echo "Running..."
# Make everything writable and run the app
chmod 777 -R ProdApps/$app_name/
cd ProdApps/$app_name
./script/server
