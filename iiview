#!/bin/sh

printf "\e]2;%s\a" "${1%/}";
printf "\e[?1049h";		# save scren
printf "\e[J";			# clear screen
printf "\e[0;0H";		# goto @(1,1)
printf "\e[?25l";		# hide cursor
stty -echo;

defbg="\e[48;2;25;25;25m"
bg="\e[48;2;30;30;30m";
bgn="40";

channel="$1"

trap 'cleanup' INT;

cleanup() {
	trap '' TERM;
	stty sane;
	pkill -t `tty | cut -c 6-`; 
	printf '\e[?1049l';
	printf '\e[?25h';
	printf '\e[0m';
	exit;
}

function color_nick
{
	#if ! test "$name" = "$oldname";
	#then	bgn=$(expr 70 - $bgn);
	#	bg="\e[48;2;$bgn;$bgn;${bgn}m";
	#fi;
	#[ -n "$oldname" ] && printf "\n";
	hash=$(<<< $name md5sum | cut -c -6);
	hash=$(<<<"$hash" sed -re y/abcdef/ABCDEF/ -e "s/(..)(..)(..)/\1;\2;\3/");
	rgb=$(<<< "$hash" xargs echo "obase=10;ibase=16;" | bc);
	test $(echo $rgb | sed 's/ /+/g' | bc) -gt 150 || {
		max=$(echo "$rgb" | sort -rh | head -n1)
		rgb=$(echo "$rgb" | sed -e "s/$max/$(expr 255 - $max)/" -e /"$max"/q)
	}
	rgb=$(<<< "$rgb" tr "\n" \; | cut -d\; -f-3);
	cname=$(printf '\e[38;2;%sm%s\e[39m' "$rgb" "$name");
	printf "\n${defbg}%s│\e[49m%s%s%s%s" "$time" \
		"$lbracket" "$cname" "$rbracket" "$partmessage";
}

draw() {
	printf '\e[1;1H\e[J'
	
}

main() {
	tail -n $(tput lines) -f "$channel"/out \
	| while read -r message;
	do	oldname="$name";
		message="${message:11}";
		case $message in
		(*:*\<*\>*)
			time=${message:0:5};
			lbracket='<';
			name=${message:7};
			name=${name%%> *};
			rbracket='>'
			message=${message#*>};
			test -n "$(<<< "$message" grep "ACT")" && {
				message=$(<<< $message sed -r 's/ACTION (.*)/\1/');
				lbracket="* ";
				rbracket=' ';
			}	
			prefix=$(expr ${#time} + 3 + ${#lbracket} + ${#name});
			linelen=$(expr `tput cols` - $prefix);
			partmessage=${message:0:$linelen};
			color_nick;
			while	lineoff=$(expr ${lineoff:-0} + $linelen);
				partmessage=${message:$lineoff:$linelen};
				test -n "$partmessage";
			do	printf "${bg}\n${defbg}%s│\e[49m %s%s%s%s" "${time//?/ }" \
				"${lbracket//?/ }" "${name//?/ }" "${rbracket//?/ }"\
				"$partmessage";
			done;
			lineoff=;
			printf '\a';
		;;
		(*)
			time=${message:0:5};
			lbracket='-';
			rbracket=' ';
			name=${message:10};
			name=${name%(*};
			name=${name%% *};
			partmessage=${message#* * * };
			partmessage=${message##*) };
			#bg="$defbg";
			color_nick;
		;;
		esac;
	done;
}

main &
pid=$!;

stty raw;
while read -n 1 char;
do	test "$char" = 'q' && break;
	test "$char" = '' && break;
done
cleanup 2>/dev/null
