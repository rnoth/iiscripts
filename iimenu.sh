#!/bin/ksh -x

dmenu='-n'
dir=/tmp
cd "$dir"

channels=*.*.*/*/out
chanstat=$(stat -c "%Y %n" $channels)

echo $chanstat
selserv=$(<<< "$chanstat" cut -d"/" -f 1 | sort -u -k2 | cut -d" " -f 2 | dmenu $dmenu -p "Server:")
test -z "$selserv" && exit 1

selchan=$(<<< "$chanstat" grep "$selserv" | sort -r | cut -d"/" -f 2 | grep -Ev "(^irc$|^global$|^nickserv$|^py-ctcp$)" | dmenu $dmenu -p "Channel:")
test -z "$selchan" && exit 1

while 	text=$(</dev/null dmenu -p "${selchan}" \
		| sed -r 's|^/me (.*)$|ACTION \1|')
	[ -n "$text" ]
do	printf "%s\n" "$text" > "$selserv"/"$selchan"/in
done
