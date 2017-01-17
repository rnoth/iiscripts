#!/bin/ksh

trap "cleanup; exit;" TERM QUIT INT;

# globals
typeset -A hashtable		# note, not actually a hashtable
typeset -a line;

channel="$1";

function init
{
	printf "\E]2;%s\a" "${channel%/}";	# set term title
	printf "\E[0m";				# unset graphic effects
	printf "\E[?1049h";			# save scren
	printf "\E[?25l";			# hide cursor
	stty -echo;
	defbg=$'\E[48;2;20;20;20m';
	screen=$(tput lines);
}

function cleanup
{
	trap '' TERM;
	stty sane;
	pkill -t $(tty | cut -c 6-); 
	printf "\e[H\e[J";
	printf "\E[?1049l";
	printf "\E[?25h";
	printf "\E[0m";
}

function color_nick
{
	typeset -u hash;
	typeset -A -i rgb;
	typeset nick;
	nick=${line[2]};
	#if ! test "$name" = "$oldname";
	#then	bgn=$((70 - bgn));
	#	bg="\E[48;2;$bgn;$bgn;${bgn}m";
	#fi;
	[ ${#hashtable[$name]} -gt 0 ] || {
		hash=$(<<< $nick md5sum);
		hash=${hash:0:6}
		hash=${hash/@(??)@(??)@(??)/16#\1\;16#\2\;16#\3};
		<<< "$hash" IFS=\; read rgb[0] rgb[1] rgb[2];
		((rgb[0] + rgb[1] + rgb[2] > 50 )) || {
			max=$(print -f "%s\n" "${rgb[@]}" | sort -h | head -n1)
			<<< ${rgb/$max/$((255 - $max))} read rgb[0] rgb[1] rgb[2]
		}
		hashtable[$nick]=$(print -f "\E[38;2;%d;%d;%dm%s\E[39m" ${rgb[@]} $nick);
	}
	line[2]=${hashtable[$nick]};
}

function parse
{
	typeset tmp;
	tmp="$1";
	line[0]="${tmp:0:5}";
	line[2]="${tmp:7}";
	if [[ "$tmp" =~ "..:.. <.+" ]];
	then
		line[1]="<";
		line[3]=">";
		line[2]="${line[2]%%\> *}";
		line[5]="${tmp#*\> }"$'\a';
	else
		line[1]="- ";
		line[3]="";
		line[2]=${line[2]:3};
		line[2]=${line[2]%\(*};
		line[2]=${line[2]%% *};
		line[5]=${tmp#*-!- * };
	fi;
	[[ "${line[5]}" =~ "ACT.+.?" ]] && {
		line[1]="* ";
		line[3]=" ";
		line[5]=${line[4]/ACTION (.*)/\1/};
	}
}

draw()
	while read -r message;
	do
		typeset -i lineoff;
		oldname="$name";
		message="${message:11}";
		parse "$message";
		prefix=$(( ${#line[0]} + ${#line[1]} + ${#line[2]} + ${#line[3]} + 5));
		linelen=$(($(tput cols) - $prefix));
		curnick=${line[2]};
		color_nick;
		lineoff=0;
		while	line[4]="${line[5]/#{$lineoff}(?)}";
			[ ${#line[4]} -lt $linelen ] || \
				line[4]="${line[4]/#{1,$linelen}(?) */\1}";
			line4len=${#line[4]};
			[ "${line4len}" -gt 0 ];
		do
			[ -n "$oldnick" ] && printf "\n\r";
			printf "%b%s│\E[0m%s%b%s %s\E[0m" "$defbg" "${line[0..4]}";
			lineoff=$((lineoff + line4len));
			line[0]="${line[0]//?/ }";
			line[1]="${line[1]//?/ }";
			line[2]="${curnick//?/ }";
			line[3]="${line[3]//?/}";    # this is a hack, dont look too hard
			(( topline -= 1 ));
			(( botline -= 1 ));
		done;
		oldnick=$curnick
	done;

function redraw
{
	printf "\e[H\e[J";
	lines=$(tput lines);
	screen=$lines;
	len=$(wc -l "$channel"/out | cut -d\  -f 1);
	botline=$(max $len $lines);
	topline=$(max 1 $((len - lines)));
	page $topline $botline;#$((top + lines));
}

function scroll
{
	printf "\e[H\e[J";
	direc=$1;
	lines=$2;
	len=$(wc -l "$channel"/out);
	len=${len% *};
	#((page = direc * lines));
	page=$((direc * lines));
	topline=$(max 1 $((topline + page)) );
	botline=$(min $len $((botline + page)) );
	#((topline = topline + page));
	#((botline = botline + page));
	((botline - topline == screen)) \
		|| ((botline = (topline + screen) ));
	page $topline $botline;
}

function wcl
{
	typeset tmp;
	tmp=$(< $1);
	tmp=$(("${tmp//[^
]}" + 1));
	printf %s ${#tmp};
}

function page	{ (( $1 * $2 > 0 )) || return; sed -n ${1},${2}p "$channel"/out | draw; }
function follow	{ tail -n 0 -f "$channel"/out | draw; }
function max	{ (( $1 > $2 )) && printf "%s"  $1 || printf "%s" $2; }
function min	{ (( $1 < $2 )) && printf "%s" $1 || printf "%s" $2; }

function main
{
	trap 'redraw' WINCH;
	while read -n 1 char;
	do	case $char in
		('r')	redraw;
			;;
		('q')	break;
			;;
		('j')	scroll -1 2
			;;
		('k')	scroll 1 2
			;;
		('f')	scroll -1 $(($(tput lines) - 1));
			;;
		('b')	scroll 1 $(($(tput lines) - 1));
			;;
		('')	# FIXME: this doesn't even halfway work
			read -t .1 seq && \
			case seq in
			('[5~')
				scroll 1 $(($(tput lines) - 1));
				break;
				;;
			('[6~')
				scroll -1 $(($(tput lines) - 1));
				break;
				;;
			esac;
			;;
		('')	break;
			;;
		esac
	done
}

init;
redraw;
follow& 2>/dev/null
main;
cleanup 2>/dev/null;
