#!/bin/bash
## DESCRIPTION: Automatically keeping your itservice database
##              up to date using the Administration Console
## AUTHOR: Thomas Jällbrink
## CREATION DATE: 05/27/14
##

TQPATH=/opt/teamquest
ITSARDB=data/itservice
FILE=/tmp/nodelist.txt
 
#backup the old tqmetadef
cp $TQPATH/$ITSARDB/tqmetadef $TQPATH/$ITSARDB/tqmetadef.old
 
#create tqmetadef header
if [ ! -f $TQPATH/$ITSARDB/tqmetadef.org ]; then
        echo "meta format=agent version=1%2E1 charset=us%2Dascii revision=1   notification=0" > $TQPATH/$ITSARDB/tqmetadef.org
        echo "" >> $TQPATH/$ITSARDB/tqmetadef.org
        echo "options name=options" >> $TQPATH/$ITSARDB/tqmetadef.org
        echo " mtime=1339503977" >> $TQPATH/$ITSARDB/tqmetadef.org
        echo " synctime=5 syncfreq=720 retry_limit=0 request_limit=4" >> $TQPATH/$ITSARDB/tqmetadef.org
        echo "" >> $TQPATH/$ITSARDB/tqmetadef.org
fi
 
#set postgresql password variable so that the password won’t be shown in clear text in the history
export PGPASSWORD="password"
 
#extracting a list of servers and https port from the console database
$TQPATH/manager/bin/psql -U pgadmin -w -d console -t -A -F"," -c "select dns_name, https_port, host from nodes order by 1" > $FILE
 
#clear password variable
export PGPASSWORD=""
 
if [ ! -f $FILE ]; then
        echo "File $FILE do not exist! "
        exit 1
fi
 
#writing tqmetadef header to the new temp file
cat $TQPATH/$ITSARDB/tqmetadef.org > tqmetadef.new
 
ip=`cat $FILE`
 
#start the population of a new tqmetadef file
echo "$ip" |
(
while read line; do
        echo $line | awk -F"," '{ print $1 }' | awk -F"." '{ print "sysentry name="$1"%2E"$2"%2E"$3"%2E"$4"%3A"$5"%3Aproduction%3A" }' >> tqmetadef.new
        echo -e "mtime=0 \nitrtime=0 \nlictime=0 \ndataloc="  >> tqmetadef.new
        echo $line | awk -F"," '{ print $1 }' | awk -F"." '{ print "host="$1"%2E"$2"%2E"$3"%2E"$4}'  >> tqmetadef.new
        echo $line | awk -F"," '{ print "shost="$3}' | sed -e 's/\./\%2E/g' -e 's/\-/\%2D/g'  >> tqmetadef.new
        echo -e "Disabled=0" >> tqmetadef.new
        echo $line | awk -F"," '{ print "port="$2 }' >> tqmetadef.new
        echo -e "https=1\ndtimeout=14400\nmdtimeout=300\nrdtimeout=1800\nadtimeout=300\nctimeout=15\ndb=production\nvirtdir=\nuserauth=\n" >> tqmetadef.new
done
)
 
#replacing the old tqmetadef with the new one
mv tqmetadef.new $TQPATH/$ITSARDB/tqmetadef
 
#removing the “/tmp/nodelist.txt” file
rm $FILE
 
exit 0
