iiformat:
	lex iiformat.lex
	cc -D_POSIX_C_SOURCE -W -Wall -Wextra -Wpedantic -pedantic-errors -std=c99 -lfl lex.yy.c -lssl -lcrypto
