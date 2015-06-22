
#!/bin/bash

if [ "$#" -ne 1 ]; then
    	echo "Usage: $0 <marathon-task.json>"
	exit 1;
fi

# How do dynamically detect Marathon master (in fact any Marathon instance will do)
MARATHON=192.168.99.101

curl -X POST -H "Content-Type: application/json" $MARATHON:8080/v2/apps -d@"$@"