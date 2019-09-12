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
   local NEW_OWNER=$2

   local CURRENT_OWNER=`getUserOfDirectory $START_DIRECTORY`
   if [ $CURRENT_OWNER == $NEW_OWNER ]; then
      # For all all first-level subdirectories of START_DIRECTORY
      for directory in `find $START_DIRECTORY/* -maxdepth 0 -type d`; do
         CURRENT_OWNER=`getUserOfDirectory $directory`
         if [ $CURRENT_OWNER != $NEW_OWNER ]; then
            echo "Changing owner of directory $directory"
            chown -R $NEW_OWNER:$NEW_OWNER $directory
         fi
      done
   else
      echo "Changing owner of directory $START_DIRECTORY"
      chown -R $NEW_OWNER:$NEW_OWNER $START_DIRECTORY
   fi
}