#!/bin/sh


if [ $# -lt 1 ]; then
    echo ""
    echo "resign.sh Usage:"
    echo "\t required: ./resign.sh APP_NAME.ipa true/free"
    echo "\t true is optional feature which allow you set get-task-allow to true"
    echo "\t free is optional feature which allow you codesign ipa with free apple id"

    exit 0
fi

echo "read cofig from resign.config"
source resign.config


TARGET_IPA_PACKAGE_NAME=$1                                                         
TM_IPA_PACKAGE_NAME="${TARGET_IPA_PACKAGE_NAME%.*}_MC.ipa"                         # resigned ipa name
PAYLOAD_DIR="Payload"
APP_DIR=""
PROVISION_FILE=$NEW_MOBILEPROVISION
CODESIGN_KEY=$CODESIGN_IDENTITIES
ENTITLEMENTS_FILE=$ENTITLEMENTS


if [[ $2 == 'true' ]]; then
  echo "resign with development type"
    PROVISION_FILE=$NEW_MOBILEPROVISION_DEV
    CODESIGN_KEY=$CODESIGN_IDENTITIES_DEV
    ENTITLEMENTS_FILE=$ENTITLEMENTS_DEV
fi

if [[ $2 == 'free' ]]; then
  echo "resign with free developer type"
    PROVISION_FILE=$NEW_MOBILEPROVISION_FREE
    CODESIGN_KEY=$CODESIGN_IDENTITIES_FREE
    ENTITLEMENTS_FILE=$ENTITLEMENTS_FREE
fi

echo -e ""
echo -e "the new ipa named:${TM_IPA_PACKAGE_NAME}"
echo -e "use provision file:${PROVISION_FILE}"
echo -e "use entitlements file:${ENTITLEMENTS_FILE}"
echo -e "use codesign:${CODESIGN_KEY}"

OLD_MOBILEPROVISION="embedded.mobileprovision"
DEVELOPER=`xcode-select -print-path`
TARGET_APP_FRAMEWORKS_PATH=""

SDK_DIR="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
echo -e "SDK_DIR*$SDK_DIR"

if [ ! -e $TARGET_IPA_PACKAGE_NAME ]; then
    echo "ipa file ($TARGET_IPA_PACKAGE_NAME) not exist"
    exit 0
fi

if [ ! -e $PROVISION_FILE ]; then
    echo "provision file ($PROVISION_FILE) not exist"
    exit 0
fi

if [ -e $TM_IPA_PACKAGE_NAME ]; then
    echo "rm $TM_IPA_PACKAGE_NAME"
    rm $TM_IPA_PACKAGE_NAME
fi

if [ -d $PAYLOAD_DIR ]; then
    echo "delete old ipa:$PAYLOAD_DIR"
    rm -rf $PAYLOAD_DIR
fi

echo ""
echo "1. unzip $TARGET_IPA_PACKAGE_NAME"
unzip $TARGET_IPA_PACKAGE_NAME > /dev/null

if [ ! -d $PAYLOAD_DIR ]; then
    echo "unzip $TARGET_IPA_PACKAGE_NAME fail"
fi

APP_DIR="Payload/fuck.app"

FUCK_APP_DIR=$(find ${PAYLOAD_DIR} -type d | grep ".app$" | head -n 1)

# incase of some app name with white space
# eg. "hello world.app"
echo "rename ${FUCK_APP_DIR} to ${APP_DIR}"
mv -i "$FUCK_APP_DIR" "$APP_DIR"

echo "set Minimum support os version:${MINIMUMOSVERSION}"
plutil -replace MinimumOSVersion -string $MINIMUMOSVERSION $APP_DIR/Info.plist
# plutil -insert UISupportedDevices.4 -string "iPhone11,6" $APP_DIR/Info.plist 
# we don't need the this feature
echo "delete UISupportedDevices keypath in Info.plist"
plutil -remove UISupportedDevices $APP_DIR/Info.plist

if [ -d "$APP_DIR/_CodeSignature" ]; then
    echo ""
    echo "rm $APP_DIR/_CodeSignature"
    rm -rf $APP_DIR/_CodeSignature

    echo ""
    echo "cp $SDK_DIR/ResourceRules.plist $APP_DIR/"
    cp $SDK_DIR/ResourceRules.plist $APP_DIR/
    echo ""
    echo "cp $PROVISION_FILE $APP_DIR/$OLD_MOBILEPROVISION"
    cp $PROVISION_FILE $APP_DIR/$OLD_MOBILEPROVISION
    echo ""
    echo "*************start codesign*************"

    #codesign frameworks
    TARGET_APP_FRAMEWORKS_PATH="$APP_DIR/Frameworks"
    if [[ -d "$TARGET_APP_FRAMEWORKS_PATH" ]]; then
        for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*; do
            FILENAME=$(basename $FRAMEWORK)
            /usr/bin/codesign -f -s "$CODESIGN_KEY" "$FRAMEWORK"
        done
    fi
    echo "codesign frameworks done."

    #codesign plugins
    TARGET_APP_PLUGINS_PATH="$APP_DIR/PlugIns"
    if [[ -d "$TARGET_APP_PLUGINS_PATH" ]]; then
        for PLUGIN in "$TARGET_APP_PLUGINS_PATH/"*; do
            FILENAME=$(basename $PLUGIN)
            /usr/bin/codesign -f -s "$CODESIGN_KEY" "$PLUGIN"
        done
    fi
    echo "codesign plugins done."
    
    #codesign the fuck dylib
    for FDYLIB in "$APP_DIR/"*; do
            #statements
            DYLIB=${FDYLIB##*.}
            if [[ $DYLIB == dylib ]]; then
                    #statements
                    echo "codesign ${FDYLIB}"
                    /usr/bin/codesign -f -s "$CODESIGN_KEY" "$FDYLIB"
            fi
    done
    echo "codesign dylibs done."

    echo "codesign ${APP_DIR} with entitlements file"
    /usr/bin/codesign -f -s "$CODESIGN_KEY" --entitlements $ENTITLEMENTS_FILE  $APP_DIR

    echo "*************end codesign*************"

    if [ -d $APP_DIR/_CodeSignature ]; then
        echo ""
        echo "zip -r $TARGET_IPA_PACKAGE_NAME $APP_DIR/"
        zip -r $TM_IPA_PACKAGE_NAME $APP_DIR/ > /dev/null
        echo "delete ${APP_DIR}"
        rm -rf $APP_DIR
        echo " @@@@@@@ resign success !!!  @@@@@@@ "
        exit 0
    fi
fi

echo "oops! resign fail !!!"
