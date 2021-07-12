# jsp

Json shell parser  
Using POSIX shell and sed


## usage

```
jsp <filter>
```
Json is fed through stdin.

* filter format
	```
	.key1.key2
	```
* example

	```sh
	printf '%s' '{
	  "user": "notroot",
	  "shell": {"name":"dash", "path":"/usr/bin/dash"},
		  "interactiveShell": {"name": "bash", "path":"/usr/bin/bash/"}
	}' | ./jsp .interactiveShell.name
	```

