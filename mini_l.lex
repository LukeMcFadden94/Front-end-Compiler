/* CS152 Project 3 Spring 2021 */
/* Made by Luke McFadden & Evan Stewart */    

/* Variable Declarations */
%{
#include "y.tab.h"
int currLine = 1, currPos = 1;
int numIntegers = 0;
int numOperators = 0;
int numParens = 0;
int numEquals = 0;
%}

DIGIT                           [0-9]
LETTER                          [a-zA-Z]
COMMENT                         ##.*
ID                              ({LETTER})(({LETTER}|{DIGIT}|[_])*({LETTER}|{DIGIT}))?
ERROR_START_ID                  ({DIGIT}|[_])({LETTER}|{DIGIT}|[_])*
ERROR_END_UNDERSCORE            ({LETTER})({LETTER}|{DIGIT}|[_])*[_]

%%

 /* Reserved words */
function             {return FUNCTION; currPos += yyleng;}
beginparams          {return BEGIN_PARAMS; currPos += yyleng;}
endparams            {return END_PARAMS; currPos += yyleng;}
beginlocals          {return BEGIN_LOCALS; currPos += yyleng;}
endlocals            {return END_LOCALS; currPos += yyleng;}
beginbody            {return BEGIN_BODY; currPos += yyleng;}
endbody              {return END_BODY; currPos += yyleng;}
integer              {return INTEGER; currPos += yyleng;}
array                {return ARRAY; currPos += yyleng;}
enum                 {return ENUM; currPos += yyleng;}
of                   {return OF; currPos += yyleng;}
if                   {return IF; currPos += yyleng;}
then                 {return THEN; currPos += yyleng;}
endif                {return ENDIF; currPos += yyleng;}
else                 {return ELSE; currPos += yyleng;}
while                {return WHILE; currPos += yyleng;}
do                   {return DO; currPos += yyleng;}
beginloop            {return BEGINLOOP; currPos += yyleng;}
endloop              {return ENDLOOP; currPos += yyleng;}
continue             {return CONTINUE; currPos += yyleng;}
read                 {return READ; currPos += yyleng;}
write                {return WRITE; currPos += yyleng;}
and                  {return AND; currPos += yyleng;}
or                   {return OR; currPos += yyleng;}
not                  {return NOT; currPos += yyleng;}
true                 {return TRUE; currPos += yyleng;}
false                {return FALSE; currPos += yyleng;}
return               {return RETURN; currPos += yyleng;}

 /* Arithmetic operators */
"-"         {return SUB; currPos += yyleng;}
"+"         {return ADD; currPos += yyleng;}
"*"         {return MULT; currPos += yyleng;}
"/"         {return DIV; currPos += yyleng;}
"%"         {return MOD; currPos += yyleng;}

 /* Comparison operators */
"=="        {return EQ; currPos += yyleng;}
"<>"        {return NEQ; currPos += yyleng;}
"<"         {return LT; currPos += yyleng;}
">"         {return GT; currPos += yyleng;}
"<="        {return LTE; currPos += yyleng;}
">="        {return GTE; currPos += yyleng;}

 /* Special symbols */
";"         {return SEMICOLON; currPos += yyleng;}
":"         {return COLON; currPos += yyleng;}
","         {return COMMA; currPos += yyleng;}
"("         {return L_PAREN; currPos += yyleng;}
")"         {return R_PAREN; currPos += yyleng;}
"["         {return L_BRACKET; currPos += yyleng;}
"]"         {return R_BRACKET; currPos += yyleng;}
":="        {return ASSIGN; currPos += yyleng;}

(\.{DIGIT}+)|({DIGIT}+(\.{DIGIT}*)?([eE][+-]?[0-9]+)?)  {currPos += yyleng; yylval.num = atoi(yytext); return NUMBER; }

[ \t]+   {/* ignore spaces */ currPos += yyleng;}

"\n"    {currLine++; currPos = 1;}

{ID}                                {currPos += yyleng; yylval.id = strdup(yytext); return IDENT;}                                                                     
{COMMENT}                           {currLine++; currPos = 1;}
{ERROR_START_ID}                    {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); exit(0);}
{ERROR_END_UNDERSCORE}              {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currLine, currPos, yytext); exit(0);}

.       {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%
