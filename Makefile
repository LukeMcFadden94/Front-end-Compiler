# parse:	mini_l.l mini_l.y
# 		bison -v -d --file-prefix=y mini_l.y
# 		flex mini_l.l
# 		gcc -o parser y.tab.c lex.yy.c -lfl

parser:	mini_l.l mini_l.y
		bison -d -v --file-prefix=y mini_l.y
		flex mini_l.l
		g++ -g -Wall -ansi -pedantic -std=c++11 lex.yy.c y.tab.c -lfl -o parser

mil:
		cat fibonacci.min | parser > fibonacci.mil

test:
	mil_run fibonacci.mil < input.txt
	
clean:
		rm -f lex.yy.c y.tab.* y.output *.o parser

both: 	mini_l.l mini_l.y
		bison -d -v --file-prefix=y mini_l.y
		flex mini_l.l
		g++ -g -Wall -ansi -pedantic -std=c++11 lex.yy.c y.tab.c -lfl -o parser
		cat fibonacci.min | parser > fibonacci.mil