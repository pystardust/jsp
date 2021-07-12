#!/bin/sh

# Json Shell Parser
# dependencies (POSIX): sed
# contact: { "github": "pystardust", "email": "notpiestardust@gmail.com" }

usage () {
	while IFS= read line; do
		printf '%s\n' "$line"
	done<<-!
	USAGE: jsp <filter>
	Json Shell Parser
	  filter format
	    .key1
	    .key1.key2
	  Input needs to be fed as stdin

	  example
	    printf '%s' '{
	      "user": "notroot",
	      "shell": {"name":"dash", "path":"/usr/bin/dash"},
          "interactiveShell": {"name": "bash", "path":"/usr/bin/bash/"}
	    }' | ./jsp .interactiveShell.name
	!
}

remove_newlines () {
	while IFS= read line; do
		printf '%s' "$line"
	done
}

print_child () {
	child=0
	while IFS= read line; do
		case $line in
			'<child>')
				[ $child -gt 0 ] &&
					printf '%s\n' "$line"
				: $((child+=1))
				;;
			'</child>')
				: $((child-=1))
				[ $child -gt 0 ] &&
					printf '%s\n' "$line" ||
					return
				;;
			*)
				[ $child -gt 0 ] &&
					printf '%s\n' "$line"
				;;
		esac
	done
}

pick_key () {
	filter=$1
	child=0
	while IFS= read line; do
		case $line in
			'<bracket>'|'</bracket>')
				:
				;;
			'<child>')
				: $((child+=1))
				;;
			'</child>')
				: $((child-=1))
				;;
			*)
				[ $child -eq 0 ] &&
					skey=${line#\"}
					skey=${skey%\"}
					[ "${skey#\"}" = "$filter" ] &&
					print_child
				;;
		esac
	done
}

j_decode () {
	remove_newlines | sed -E '
		s/\\"/<esquote>/g

		:loop
		/"/{
			s/"/\n--->/
			s/"/\n/
			b loop
		}
		s/<esquote>/"/g
	' | sed -E '
		/^--->/!{
			s/,/\n<\/child>\n/g
			s/\}/\n<\/child>\n<\/bracket>\n/g
			s/\{/\n<bracket>\n/g
			s/:/\n<child>\n/g
		}
		/^--->/{
			s/--->(.*)/"\1"/
		}
	' | sed -E '
		/^\s*$/d
		/^("|<)/!{
			s/\s*//g
		}
	'
}

to_json () {
	if [ $close_child -eq 1 ]; then
		if [ ! "$1" = '</bracket>' ]; then
			printf ','
		fi
		close_child=0
	fi

	case $1 in
		'<bracket>')
			printf '{'
			;;
		'</bracket>')
			printf '}'
			;;
		'<child>')
			printf ':'
			;;
		'</child>')
			#printf ','
			close_child=1
			;;
		*)
			printf '%s' "$line"
			;;
	esac
}

j_encode () {
	close_child=0
	while IFS= read line; do
		to_json "$line"
	done
}

case $1 in
	'--help'|'-?'|'-h')
		usage
		exit
		;;
esac

tempfile1=$(mktemp)
tempfile2=$(mktemp)
filters=$1

j_decode <&0 > "$tempfile1"

IFS=.
for key in ${filters#.}; do
	pick_key "$key" < "$tempfile1" > "$tempfile2"
	mv "$tempfile2" "$tempfile1"
done

j_encode < "$tempfile1"
printf '\n'

rm "$tempfile1"
