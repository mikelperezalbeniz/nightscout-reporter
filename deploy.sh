#!/bin/bash

typeset PUB=/usr/lib/dart/bin/pub
export https_proxy="http://10.230.1.1:8080"
if [ "$1" == "all" ]
then
  echo "======================"
  echo "refreshing build stack"
  echo "======================"
  $PUB get
  $PUB global activate webdev
fi

if [ "$1" == "all" -o "$1" == "build" ]
then
  echo 
  echo "======================"
  echo "running build"
  echo "======================"
  $PUB global run webdev build --output=web:build
fi

typeset INSTALLDIR=/tmp/NightScoutReporter.$$
echo 
echo "======================"
echo "installing to $INSTALLDIR"
echo "======================"
rm -rf $INSTALLDIR
mkdir $INSTALLDIR
cp -r build/* $INSTALLDIR
cp settings.json $INSTALLDIR
unrar x nr-pdfmake.rar $INSTALLDIR
tar -cvzf /tmp/NightScoutReporter.tar.gz -C $INSTALLDIR .
typeset TARGETLOCATION
[ "$2" == "dev" ] && TARGETLOCATION=myroot@devubuntu:/home/myroot/Software/NightScoutReporter
[ "$2" == "ref" ] && TARGETLOCATION=myroot@devubuntu:/home/myroot/Software/NightScoutReporter
[ "$2" == "prod" ] && TARGETLOCATION=myroot@devubuntu:/home/myroot/Software/NightScoutReporter
echo 
echo "======================"
echo "deploying to $TARGETLOCATION"
echo "======================"
ssh $(echo $TARGETLOCATION | cut -d":" -f1) "rm -rf $(echo $TARGETLOCATION | cut -d":" -f2-)/*"
scp /tmp/NightScoutReporter.tar.gz $TARGETLOCATION
ssh $(echo $TARGETLOCATION | cut -d":" -f1) "cd $(echo $TARGETLOCATION | cut -d":" -f2-) && tar -xvzf NightScoutReporter.tar.gz && rm -f NightScoutReporter.tar.gz"
echo 
echo "======================"
echo "deployed"
echo "FINISHED"
echo "======================"

