#!/bin/sh
#start script for integration server

echo "Starting IBM® App Connect Enterprise for Developers..."

#set ACE environment variables
. /opt/ibm/ace-12/server/bin/mqsiprofile 

#set application name
if [ "$ACE_APPNAME" = "" ]; then
  ACE_APPNAME=integration-application
fi
#change source directory name to application name
mv src $ACE_APPNAME

#set up admin authentication
if [ "$ACE_ENABLE_ADMIN_AUTHENTICATION" = "true" ]; then
    echo "Enabling admin authentication..."
    #set admin user
    ACE_CONFIG_FILE=$ACE_WORKING_DIR/server.conf.yaml
    sed -i 's/#basicAuth: false/basicAuth: true/' $ACE_CONFIG_FILE
    sed -i 's/#authorizationEnabled: false/authorizationEnabled: false/' $ACE_CONFIG_FILE
    sed -i 's/#authorizationMode/authorizationMode/' $ACE_CONFIG_FILE
    sed -i 's/#adminRole/adminRole/' $ACE_CONFIG_FILE

    adminUser=admin
    if [ "$ACE_ADMIN_USER_NAME" != "" ]; then
        adminUser=$ACE_ADMIN_USER_NAME
    else
        echo "ACE_ADMIN_USER_NAME not set. Using default: $adminUser"
    fi

    if [ "$ACE_ADMIN_USER_PASSWORD" != "" ]; then
        adminPassword=$ACE_ADMIN_USER_PASSWORD
    else
        echo "ACE_ADMIN_USER_PASSWORD not set."
        echo "Can not continue."
        exit 1
    fi
    #create ACE web user with admin role
    mqsiwebuseradmin -w $ACE_WORKING_DIR -c -u $adminUser -a $adminPassword -r admin

    echo "Enabling admin authentication...done."

fi


#create bar
echo "Creating bar-file..."
ibmint package --input-path=$(pwd)/$ACE_APPNAME/ --output-bar-file $ACE_APPNAME.bar
echo "Creating bar-file...done."


#modify bar based on env variables (URLSUFFIX, MESSAGE, etc)
#set env variable ACE_PROPERTY_OVERRIDES and use comma-separated overrides
#example set user defined property value:
#ACE_PROPERTY_OVERRIDES=SampleFlow#message="Hello world too!!"
#set user defined property value and url suffix:
#ACE_PROPERTY_OVERRIDES=SampleFlow#message="Hello world too!!",SampleFlow#URLSpecifier=/hello
#see also documentation:
#https://www.ibm.com/docs/en/app-connect/12.0?topic=common-mqsiapplybaroverride-command
if [ "$ACE_PROPERTY_OVERRIDES" != "" ]; then
    echo "Overriding properties in bar-file..."
    override_file=override.properties
    #loop throug comma separated values (values can include space)
    #see: https://stackoverflow.com/a/68057222
    while true; do
        property_override="${ACE_PROPERTY_OVERRIDES%%,*}"
        echo $property_override >> $override_file
        if [ -z "${ACE_PROPERTY_OVERRIDES##*,*}" ]  &&  [ -n "${ACE_PROPERTY_OVERRIDES}" ]; then
            ACE_PROPERTY_OVERRIDES="${ACE_PROPERTY_OVERRIDES#*,}"
        else
            break
        fi
    done
    #override properies in bar file
    mqsiapplybaroverride -r -b $ACE_APPNAME.bar -p $override_file
    echo "Overriding properties in bar-file...done."
fi

#install bar file
echo "Installing bar-file..."
mqsibar -a $ACE_APPNAME.bar -w $ACE_WORKING_DIR
echo "Installing bar-file...done."


if [ "$ACE_START_BASH" = "true" ]; then
    #start bash if env var is true, useful for test/development
    echo "Starting bash..."
    #create start integration server script
cat > integrationserver-start << EOF
#!/bin/bash
IntegrationServer --work-dir $ACE_WORKING_DIR
EOF
    chmod 755 integrationserver-start
    echo "Start IntegrationServer using:"
    echo "$(pwd)/integrationserver-start"
    exec bash
else
    #start server
    exec IntegrationServer --work-dir $ACE_WORKING_DIR
fi
