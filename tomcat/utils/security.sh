#!/bin/bash

# Change file owner and group
# First parameter is the start folder and the second is the new user
changeOwnerAndGroup() {
   FOLDER_USER=$(stat -c '%U' $1)
   if [ $FOLDER_USER == $2 ]; then
      for folder in $(find $1/* -maxdepth 0 -type d); do
         FOLDER_USER=$(stat -c '%U' $folder)
         if [ $FOLDER_USER != $2 ]; then
            echo "Changing owner of folder $folder"
            chown -R $2:$2 $folder
         fi
      done
   else
      echo "Changing owner of folder $1"
      chown -R $2:$2 $1
   fi
}
