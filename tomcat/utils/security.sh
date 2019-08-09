#!/bin/bash

# Return user of directory
getUserOfDirectory() {
   local DIRECTORY=$1
   echo $(stat -c '%U' $DIRECTORY)
}

# Change file owner and group
# First parameter is the start folder and the second is the new user
changeOwnerAndGroup() {
   local START_DIRECTORY=$1
   local NEW_USER=$2

   local DIRECTORY_USER=`getUserOfDirectory $START_DIRECTORY`
   if [ $DIRECTORY_USER == $NEW_USER ]; then
      # For all all first-level subdirectories of START_DIRECTORY
      for directory in `find $START_DIRECTORY/* -maxdepth 0 -type d`; do
         DIRECTORY_USER=`getUserOfDirectory $directory`
         if [ $DIRECTORY_USER != $NEW_USER ]; then
            echo "Changing owner of directory $directory"
            chown -R $NEW_USER:$NEW_USER $directory
         fi
      done
   else
      echo "Changing owner of directory $START_DIRECTORY"
      chown -R $NEW_USER:$NEW_USER $START_DIRECTORY
   fi
}