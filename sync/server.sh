#!/bin/bash

# check for changes of the directory and run commands.sh

$project_dir="/root/project-dir"

inotifywait -m -r -e modify,create,delete $project_dir |
while read path action file; do
    echo "Detected $action on $file"
    $project_dir/commands.sh
done
