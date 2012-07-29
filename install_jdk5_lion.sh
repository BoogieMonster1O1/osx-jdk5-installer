#!/bin/bash

# By the way this script heavily inspired/copied from http://www.s-seven.net/java_15_lion
# 
# This script is edited by Brice Dutheil
# See there in french http://blog.arkey.fr/2011/08/22/script-pour-installer-le-jdk-5-sur-macosx-lion/
# Translate button is broken for now, please use Google to translate this website.
#
# 2O12/07/29 Added Moutain Lion support => Choose the 64bit JVM !
#            Can dowload the Java DMG itself if not present in same directory
#            Colored the output a bit, works well on a black background
#            Added tips for using the different JVMs
# 2011/12/04 Added warnings and some more information on gotchas
# 2011/08/25 link to blog post
# 2011/08/22 initial version
#





#some variables
javadmgurl='http://support.apple.com/downloads/DL1359/en_US/JavaForMacOSX10.5Update10.dmg'
javapkg='JavaForMacOSX10.5Update10'
jvmver='1.5.0_30'
jvms_path='/System/Library/Java/JavaVirtualMachines'
pushd `dirname $0` > /dev/null
script_location=`pwd -P`
popd > /dev/null

# 12.0.0 = Mountain Lion = 10.8
# 11.0.0 = Lion = 10.7
darwin_version=`uname -r`
osx_version=`sw_vers -productVersion`

# colors
RESET='\033[00m'
RED='\033[00;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
LIGHT_PURPLE='\033[1;35m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'

# colored echo
echo() { builtin echo -e $@; }



# Make sure only root can run the script
if [ $EUID -ne 0 ]; then
   echo $RED'This script must be run as root!'$RESET 1>&2
   exit 1
fi






# Make sure the user understand he is all alone if something goes wrong
if [ $darwin_version == '12.0.0' ]; then
    echo $YELLOW'=> You are using Mountain Lion, the script has been updated to work, however 
Mountain Lion is 64bits only! It means of course that only the 64bit version 
will work on your OS.'$RESET
    echo
fi
echo '=> The present script has been tested on my current setup and is far from 
bulletproof, it might not work at all on your system. And there is '$RED'*no 
uninstall script*'$RESET' for now!'
echo 
echo '=> Again this script touches system files, please be advised you are the sole
responsible to run or TO NOT run this script on your machine.'
echo

# Reminder about Apple JDK updates
echo $LIGHT_BLUE'NOTE : It seems that when applying a Java update from Apple, some important 
symbolic names that refer to this install are resetted to factory default 
values, you can just re-apply this script.'$RESET
echo


echo -n 'Do you still want to proceed ? (y/n)\ '
read answer
[ $answer != 'y' ] && echo 'JDK5 Lion Install script aborted' && exit 1
echo





# Here we go
if [ ! -f $javapkg.dmg ]; then
    echo 'The "Java for Mac OS X 10.5 Update 10" DMG ('"$javapkg.dmg"') was not found.'

    echo 'Now trying to download the DMG file from Apple website :'
    echo $javadmgurl
    curl -# -L $javadmgurl -o $javapkg.dmg

    if [ ! -f $javapkg.dmg ]; then
        echo 'Couldn'"'"'t download the uptate. Please download it from Apple at : 
http://support.apple.com/kb/DL1359'
        echo 'And place it in the same folder as this script : '$script_location
        exit 1
    fi
else
    echo 'Using '$javapkg'.dmg file as the "Java for Mac OS X 10.5 Update 10".'
fi





# Extracting the DMG content in temporary location
echo
echo 'Extracting Java for Mac OS X package'
mkdir /tmp/jdk5dmg
hdiutil attach -quiet -nobrowse -mountpoint /tmp/jdk5dmg/ $javapkg.dmg
cd /tmp/jdk5dmg/
# too bad pkgutil nor xar cannot stream package content
pkgutil --expand $javapkg.pkg /tmp/jdk5pkg

cd ..
hdiutil detach -quiet -force /tmp/jdk5dmg/
rm -rf /tmp/jdk5dmg/




# Prepare the System JVM path
if [ ! -e $jvms_path ]; then
    echo 'Create '$jvms_path', as it does not exist on your system (it might be because 
you don'"'"' t have another Java install)'
    mkdir -v -p $jvms_path
fi

echo
echo 'Removing previous Java 1.5 file / directory or symbolic links in :'
cd $jvms_path
pwd
rm -rf 1.5
rm -rf 1.5.0
cd /System/Library/Frameworks/JavaVM.framework/Versions
pwd
rm 1.5/ > /dev/null 2>&1 || rm -rf 1.5 > /dev/null 2>&1
rm 1.5.0/ > /dev/null 2>&1 || rm -rf 1.5.0 > /dev/null 2>&1
rm -rf $jvmver 2>&1




echo
echo 'Preparing JavaVM framework'
echo '=========================='

echo
echo 'Extracting JDK 1.5.0 from package payload in :'
cd /System/Library/Frameworks/JavaVM.framework/Versions
pwd
gzip -cd /tmp/jdk5pkg/$javapkg.pkg/Payload | pax -r -s                                 \
		',./System/Library/Frameworks/JavaVM.framework/Versions/1.5.0,./'"$jvmver"','  \
		'./System/Library/Frameworks/JavaVM.framework/Versions/1.5.0'
ls -Fld 1.5*

rm -rf /tmp/jdk5pkg/

echo
echo 'Recreating symbolic links to ./'"$jvmver"' for 1.5 and 1.5.0 :'
pwd
ln -sivh ./$jvmver 1.5
ln -sivh ./$jvmver 1.5.0

echo
echo 'Changing values in config files to make JDK work with Lion'
cd $jvmver
/usr/libexec/PlistBuddy -c "Set :JavaVM:JVMMaximumFrameworkVersion 14.*.*" ./Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :JavaVM:JVMMaximumSystemVersion "$osx_version".*" ./Resources/Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string libjava.jnilib" ./Resources/Info.plist
ln -siv ./Resources/Info.plist .

echo
echo 'Linking Apple native wrapper'
mkdir ./MacOS
ln -siv ../Libraries/libjava.jnilib ./MacOS

echo
echo 'Preparing Java Virtual Machines'
echo '==============================='
cd $jvms_path
mkdir -v 1.5.0
cd 1.5.0
pwd
ln -sivh /System/Library/Frameworks/JavaVM.framework/Versions/$jvmver ./Contents

echo
echo 'Almost over...'
echo

if [ $darwin_version == '12.0.0' ]; then
    echo $YELLOW'REMINDER : You are using Mountain Lion which is 64 bit only, at this point you 
have to the select the following entry :'
    echo $PURPLE'\t"J2SE 5.0\t64-bit"'$YELLOW
    echo 'in Java Preferences, otherwise you will experience segfaults error with the 32-bit version.'$RESET
    echo
fi

echo $BROWN'TIP : If you are using applications that need Java 6 :'
echo ' - keep the "Java SE 6" entry at the top in "Java Preferences"'
echo ' - use the Apple "/usr/libexec/java_home" tool, for example to choose the "J2SE 5.0 64-bit" version :'
echo $PURPLE'\texport JAVA_HOME=`/usr/libexec/java_home -F -v 1.5 -a x86_64 -d64`'$RESET
echo

echo -n 'Yeah I got it ! (Press Enter)'
read -s -n 0 key_press
echo

echo 'Now check that JDK 5 appears in Java Preference App, if yes the install is successful, otherwise 
try asking the internet :/'
echo

open "/Applications/Utilities/Java Preferences.app"

