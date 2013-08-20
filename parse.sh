#!/bin/bash

#########################################################
# Flatmate surveillance					#
# (Yet another DHCP log parser for a custom logfile)	#
# 2013. Daniel Megyesi <daniel.megyesi@gmail.com>	#
#							#
# Last modified: 08.20.2013				#
#########################################################

# Modification history:
#
# 08.20.2013 Efficiency enhancements & diff file by file
# 08.17.2013 Initial version

# Requirements:
# - router's log is sent by mail to this machine automatically, hourly
# - the new e-mails are in the ~/Maildir/new folder
# - only the router sends e-mails to this address (we assume that every message
# in the folder contains router logs)


# Concept:
#
# This script produces a parsable output from the logs received by e-mail.
# Every e-mail contains the current syslog dump from the router, without
# paying attention to repeated lines. We need to parse only the new lines and
# then we can process them.
#
# The script is called from crontab every hour.
#
# Every message will be compared with 'diff'. The e-mail headers are always
# different, but we don't want to deal with them, therefore they'll be stripped
# off. We store these cleaned files in a separate directory and also there is
# a status file which stores the last processed e-mail. 


#########################################################
# SUMMARY
#
#
# Is this the first run?
# 1) Yes -> clean the headers from all of the e-mails.
#  1.1) Check if some of the files are already cleaned -> don't process those
#  -> headers cleaned -> process all of the new files
#
# 2) No -> last processed file == newest file?
#  2.1) Yes -> nothing to do.
#
#  2.2) No -> last processed file == the second oldest e-mail?
#   2.2.1) Yes -> process the newest (after header clean), store it as last
#   processed file
#
#   2.2.2) No -> error, possible interrupt happened -> go to 1.1
#
#########################################################

BASEDIR=~/flatmate-surveil
MAILDIR=~/Maildir/new

LOGSTORE=$BASEDIR/emails # processed e-mails go here
RESULTSTORE=$BASEDIR/result # processed logfile lines go here
#(each file only stores the diff)

LASTFILE=$BASEDIR/last-processed # stores the name of the last processed file


#LOGFILE=$BASEDIR/logs/`date +%F`.log # exec log for this script


#########################################################
# Avoiding "directory doesn't exists" errors:		#
#########################################################

if [ ! -d $LOGSTORE ]; then
  # Log store doesn't exist; create it!

  mkdir -p $LOGSTORE
  echo "Log store didn't exist -> created: $LOGSTORE"
fi

if [ ! -d $RESULTSTORE ]; then
  # Result store doesn't exist; create it!

  mkdir -p $RESULTSTORE
  echo "Result store didn't exist -> created: $RESULTSTORE"
fi



#########################################################
# Helper functions					#
#########################################################

function stripheader {
# Strip the first 35 lines (the e-mail header)
# and also, only save the DHCP service related lines, drop everything else

  if [ ! -e $LOGSTORE/$1 ]; then

    tail -n +35 $MAILDIR/$1 | grep -e "DHCPS.*from" > $LOGSTORE/$1
    echo "Strip header: $1 -> LOGSTORE"

  else

    echo "Already in LOGSTORE: $1"

  fi
  
  echo $1 > $LASTFILE # Store what was the last processed file

}

function diffit { # diffit FILE1 FILE2 <- please note that FILE1 is the older
# Don't process the repeated lines, only the new ones
# - grep is for suppressing diff comments (beginning with a and d)
# - awk is to only store date and event from the logfile line, the rest is surplus

# Only the new data goes to the result/ folder

  diff --suppress-common-lines -n $LOGSTORE/$1 $LOGSTORE/$2 | grep -v "^[a|d]" | awk -F"\t" '{print $1 "\t" $4}' > $RESULTSTORE/$2
  echo "Diff: $2 -> RESULTSTORE"
  
  echo $2 > $LASTFILE # Store what was the last processed file

}

function processall {
# Function for processing every e-mail

  # Array: the first item will be the oldest e-mail
  eval OLDEST=( $(find $MAILDIR -type f -printf '%T@ %P\n' | sort -n | awk '{print $2}') )
  
  cnt=0

  # iterate through the array
  for i in "${OLDEST[@]}"; do

    stripheader $i

    # if the diff wasn't created yet, create it:
    if [ $cnt -gt 0 ] && [ ! -e $RESULTSTORE/$i ]; then			
      diffit ${OLDEST[cnt - 1]} ${OLDEST[cnt]}
    fi
	
   ((cnt++))
		
  done
}



#########################################################
# Finally getting things done ;)			#
#########################################################

if [ ! -f $LASTFILE ]; then

  echo "No LASTFILE. First run ever."
  processall

else

  LAST=`cat $LASTFILE`

  echo "LASTFILE set: $LAST"

  # Now store the filenames in an array, ordered by date descending (first will be the newest):

  eval NEWEST=( $(find $MAILDIR -type f -printf '%T@ %P\n' | sort -nr | awk '{print $2}' | head -n 2) )
  
  
  # Check if the newest file is the same we processed the last time:

  if [[ ${NEWEST[0]} == $LAST ]]; then

    echo "No new mail. Terminating."

  else

    # Check if the 2nd newest file is the same we processed the last time: 
    
    if [[ ${NEWEST[1]} == $LAST ]]; then

      echo "There's a new file."
      # Only need to process the new one:

      stripheader ${NEWEST[0]}

      diffit ${NEWEST[1]} ${NEWEST[0]}

    else

      echo "ERROR: multiple new files. Starting from scratch."

      processall

    fi

  fi

fi
