#!/bin/sh

dmenu=''
dir=~/irc

#channels=*.*.*/*/out
channels=${dir}/*/*/out
chanstat=$(stat -f "%m %N" $channels | sed "s:${dir}/::")

selserv=$(echo "$chanstat" | cut -d/ -f 1 | sort -k2 | uniq -f 1 | cut -d" " -f 2 | dmenu $dmenu -p "Server:")
test -z "$selserv" && exit 1

selchan=$(echo "$chanstat" | grep "$selserv" | sort -r | cut -d"/" -f 2 | grep -Ev "(^irc$|^global$|^nickserv$|^py-ctcp$)" | dmenu $dmenu -p "Channel:")
test -z "$selchan" && exit 1

while 	text=$(</dev/null dmenu -p "${selchan}" \
		| sed -r 's|^/me (.*)$|ACTION \1|')
	[ -n "$text" ]
do	printf "%s\n" "$text" > "$selserv"/"$selchan"/in
done
