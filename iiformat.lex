%{
#include <stdio.h>
#include <sys/inotify.h>
#include <openssl/md5.h>

MD5_CTX ctx;
unsigned char hash[MD5_DIGEST_LENGTH];
%}

%x NICK
%x TEXT
%x ALERT
%x HOST

%%

<INITIAL>....-..-..\  ;
<INITIAL>..:..\  {
	printf ("%s", yytext);
	BEGIN (NICK);
}

<NICK>\<	{ printf ("<"); }
<NICK>-!-\  	{
	printf("\033[32m%s\033[0m", yytext);
}

<NICK>[^\ <>(]+ {
	size_t bytes;
	MD5_Init(&ctx);
	bytes = strlen (yytext);
	MD5_Update (&ctx, yytext, bytes);
	MD5_Final (hash, &ctx);
	printf ("\a\033[38;2;%01d;%01d;%01dm%s\033[0m", hash[0], hash[1], hash[2], yytext);
}

<NICK>\>	{
	printf (">");
	BEGIN (TEXT);
}

<NICK>\(	{ BEGIN (HOST); }
<NICK>\ 	{
	printf (" ");
	BEGIN (ALERT);
}
<NICK>\"\n	{
	printf ("\"\n");
	BEGIN (INITIAL);
}

<ALERT>.*\n	{
	printf ("%s", yytext);
	BEGIN (INITIAL);
}

<ALERT>changed\ nick\ to\ \"	{
	printf ("%s", yytext);
	BEGIN (NICK);
}

<TEXT>.*\n 	{
	printf("%s", yytext);
	BEGIN(INITIAL);
	}

<HOST>[^ ]+\)	{ BEGIN(TEXT); }

%%

#define	BUF_LEN 1024 * sizeof *ev
#define EVENT_SIZE sizeof *ev

int
main(int argc, char** argv)
{
	char buf[100];
	int fd, wd;
	FILE *f;
	YY_BUFFER_STATE y;
	struct inotify_event *ev;
	char evbuf[BUF_LEN];

	if ((fd = inotify_init1(0)) < 0) {
		perror ("inotify_init");
		exit (1);
	}

	f = fopen (argv[1], "r");
	while (fgets (buf, 100, f)) {
		y = yy_scan_string (buf);
		yylex();
		yy_delete_buffer (y);
	}
	if (!feof (f)) {
		perror ("fopen");
		exit (1);
	}

	wd = inotify_add_watch (fd, argv[1], IN_MODIFY);
	if (wd < 0) {
		perror ("inotify_add_watch");
		exit (1);
	}
	for (;;) {
		int i, len;
		len = read (fd, evbuf, BUF_LEN);
		if (!len || len < 0) {
			perror ("read");
			exit (1);
		}
		for (i = 0; i < len; i += EVENT_SIZE + ev->len) {
			ev = (struct inotify_event *) buf + i;
			if (ev->mask & IN_IGNORED)
				exit (1);
			fgets (buf, 100, f);
			y = yy_scan_string (buf);
			yylex();
			yy_delete_buffer (y);
		}
	}
	
	fclose (f);
}

