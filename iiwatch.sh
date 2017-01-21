#! /bin/sh


dispsh='sleep 1;				'\
'[ -d \"${WENDY_INODE}\" ] && exit;		'\
'message=$(tail -n1 \"${WENDY_INODE}\"/out);	'\
'name=\"${message#.*<}\";			'\
'name=${name%%>.*};				'\
'message=\"${message#.*>}\";			'\
'drwbar -p \"${WENDY_INODE}\"/${name};		\'\
'-m \"${message}\";				'

[ -d "$1" -o $# -eq 0 ] || {
		echo "provide a directory"
		exit
}

wendy -m 256 -f "$1" sh -x -c "${dispsh}"
