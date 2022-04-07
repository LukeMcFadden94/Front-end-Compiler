// How to use:
// 1) chmod +x mil_run
// 2) make parser
// 3) make mil
// 4) (if necessary) make input.txt with 4.5)
//      4.5) make input.txt with
//         echo 5 > input.txt
// 5) make test
// 6) ???
// 7) profit
// 
// The newly created .mil file lists productions and where they did what, etc
// Also shows where the earliest error occured which stopped the program

%{
//#define YY_NO_UNPUT
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string>
#include <string.h>
#include <set>
#include <map>

// test purposes
// 0 -> no test output
// 1 -> enables test output
bool codeTest = 0;
// 0 -> no printf statements
// 1 -> enables printf statements
bool printTest = 0;

int tempCount = 0;
int labelCount = 0;
bool mainFunc = false;
extern int currLine;
extern int currPos;
extern char* yytext;
std::map<std::string, std::string> varTemp;
std::map<std::string, int> arrSize;
std::set<std::string> funcs;
std::set<std::string> reserved {"NUMBER", "IDENT", "RETURN", "FUNCTION", "SEMICOLON", "BEGIN_PARAMS", "END_PARAMS",
        "BEGIN_BODY", "END_BODY", "BEGINLOOP", "ENDLOOP", "COLON", "INTEGER", "COMMA", "ARRAY", "L_BRACKET", "R_BRACKET",
        "CONTINUE", "ENDIF", "OF", "READ", "WRITE", "DO", "WHILE", "FOR", "TRUE", "FALSE", "ASSIGN", "EQ", "NEQ", "MOD",
        "AND", "OR", "NOT", "L_PAREN", "R_PAREN", "function", "make_declarations", "declaration", "make_vars", "var", "make_expressions", "expression", 
        "bool_exp", "rel_and_exp", "make_rel_exp", "rel_exp", "endif", "comp", "mult_exp", "term", 
        "funcIdent", "idents", "make_statements"};

void yyerror(const char *msg);
int yylex();
std::string new_temp();
std::string new_label();
extern FILE *yyin;
%}

%union{
    int num;
    char* id;

    struct Msg {
            char* code;
    } statement;

    struct Expr {
            char* place;
            char* code;
            bool arr;
    } expression;
}

%error-verbose
%start program
%token <id> IDENT
%token <num> NUMBER
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS
BEGIN_BODY END_BODY ARRAY OF IF THEN ENDIF ELSE WHILE INTEGER
FOR DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE SEMICOLON 
COLON COMMA L_PAREN R_PAREN L_BRACKET R_BRACKET ASSIGN RETURN ENUM

%type <statement> make_statements statement
%type <expression> program function funcIdent make_declarations declaration make_vars var make_expressions expression 
%type <expression> idents bool_exp rel_and_exp make_rel_exp rel_exp comp mult_exp term funcCall

%right ASSIGN
%left OR
%left AND
%right NOT 
%left LT LTE GT GTE EQ NEQ
%left ADD SUB 
%left MULT DIV MOD

// Production: action
%%

program: %empty
        {
                // checks for Semantic Error #3
                if (!mainFunc)
                {
                        printf("No main function!\n" );
                }
        }
        | function program
        {
                if(printTest == 1)
                {
                        printf("program -> function\n");
                }
                
        }
        ;


function: FUNCTION funcIdent SEMICOLON BEGIN_PARAMS make_declarations END_PARAMS BEGIN_LOCALS make_declarations END_LOCALS BEGIN_BODY make_statements END_BODY
        {       
                if(printTest == 1)
                {
                        printf("function -> FUNCTION funcIdent SEMICOLON BEGIN_PARAMS make_declarations END_PARAMS BEGIN_LOCALS make_declarations END_LOCALS BEGIN_BODY make_statements END_BODY\n");
                }

                std::string temp;
                temp = "func ";
                temp.append($2.place);
                temp.append("\n");
                std::string msg = $2.place;
                if (msg == "main")
                {
                        mainFunc = true;
                }
                
                temp.append($5.code);
                std::string decs = $5.code;
                int decNum = 0;
                while(decs.find(".") != std::string::npos)
                {
                        int pos = decs.find(".");
                        decs.replace(pos, 1, "=");
                        std::string part = ", $" + std::to_string(decNum) + "\n";
                        decNum++;
                        decs.replace(decs.find("\n", pos), 1, part);
                }
                temp.append(decs);

                std::string statements = $11.code;
                // checks for Semantic Error #9
                if (statements.find("continue") != std::string::npos)
                {
                        printf("ERROR: Continue outside loop in function %s\n", $2.place);
                        exit(1);
                }
                temp.append(statements);
                temp.append("endfunc\n\n");
                printf(temp.c_str());
        }
        ;

make_declarations: declaration SEMICOLON make_declarations
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
        }
        | %empty
        {
                $$.code = strdup("");
                $$.place = strdup("");  
        }
        ;

declaration: idents COLON INTEGER
        {
                int left = 0;
                int right = 0;
                std::string parse($1.place);
                std::string temp;
                bool ex = false;

                while(!ex)
                {
                        right = parse.find("|", left);
                        temp.append(". ");
                        if (right == std::string::npos)
                        {
                                std::string ident = parse.substr(left, right);
                                if (reserved.find(ident) != reserved.end())
                                {
                                        printf("Can't use %s as a identifier name - already a reserved word.\n", ident.c_str());
                                }
                                if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
                                {
                                        printf("Identifier %s previously declared, cannot reuse.\n", ident.c_str());
                                }
                                else
                                {
                                        varTemp[ident] = ident;
                                        arrSize[ident] = 1;
                                }

                                temp.append(ident);
                                ex = true;
                        }
                        else{
                                std::string ident = parse.substr(left, right-left);
                                if (reserved.find(ident) != reserved.end())
                                {
                                        printf("Can't use %s as a identifier name - already a reserved word.\n", ident.c_str());
                                }
                                if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
                                {
                                        printf("Identifier %s previously declared, cannot reuse.\n", ident.c_str());
                                }
                                else
                                {
                                        varTemp[ident] = ident;
                                        arrSize[ident] = 1;
                                }

                                temp.append(ident);
                                left = right + 1;
                        }

                        temp.append("\n");
                }
                $$.code = strdup(temp.c_str());
        }
        | idents COLON ARRAY L_BRACKET NUMBER R_BRACKET OF INTEGER 
        {
                size_t left = 0;
                size_t right = 0;
                std::string parse($1.place);
                std::string temp;
                bool ex = false;

                while(!ex)
                {
                        right = parse.find("|", left);
                        temp.append(".[] ");

                        if (right == std::string::npos)
                        {
                                std::string ident = parse.substr(left, right);
                                if (reserved.find(ident) != reserved.end())
                                {
                                        printf("Can't use %s as a identifier name - already a reserved word.\n", ident.c_str());
                                }
                                if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
                                {
                                        printf("Identifier %s previously declared, cannot reuse.\n", ident.c_str());
                                }
                                else
                                {       // checks for Semantic Error #8
                                        if ($5 <= 0)
                                        {         
                                                printf("Cannot declare array ident %s of size <= 0.\n", ident.c_str());
                                        }  
                                        varTemp[ident] = ident;
                                        arrSize[ident] = $5;
                                }

                                temp.append(ident);
                                ex = true;
                        }
                        else
                        {
                                std::string ident = parse.substr(left, right-left);
                                if (reserved.find(ident) != reserved.end())
                                {
                                        printf("Can't use %s as a identifier name - already a reserved word.\n", ident.c_str());
                                }
                                if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
                                {
                                        printf("Identifier %s previously declared, cannot reuse.\n", ident.c_str());
                                }
                                else
                                {       // checks for Semantic Error #8
                                        if ($5 <= 0)
                                        {
                                                printf("Cannot declare array ident %s of size <= 0.\n", ident.c_str());
                                        }
                                        varTemp[ident] = ident;
                                        arrSize[ident] = $5;
                                }

                                temp.append(ident);
                                left = right + 1;
                        }

                        temp.append(", ");
                        temp.append(std::to_string($5));
                        temp.append("\n");
                }

                
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");                
        }
        | ENUM L_PAREN idents R_PAREN
        {
                // extra credit
        }
        ;

make_statements: statement SEMICOLON make_statements
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                
        }
        | statement SEMICOLON
        {
                std::string temp;
                temp.append($1.code);
                $$.code = strdup(temp.c_str());
        }
        ;

statement: var ASSIGN expression
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                std::string middle = $3.place;

                if ($1.arr && $3.arr)
                        temp += "[] =";

                else if ($1.arr)
                        temp += "[] =";

                else if ($3.arr)
                        temp += "= ";

                else
                        temp += "= ";

                temp.append($1.place);
                temp.append(", ");
                temp.append(middle);
                temp += "\n";
                $$.code = strdup(temp.c_str());
        }
        | IF bool_exp THEN make_statements ENDIF
        {
                std::string ifS = new_label();
                std::string after = new_label();
                std::string temp;

                temp.append($2.code);
                temp += "?:= " + ifS + ", " + $2.place + "\n";  // jump to :ifS if true, do code from $4
                temp += ":= " + after + "\n"; // if above not true, skip $4
                temp += ": " + ifS + "\n";
                temp.append($4.code);
                temp += ": " + after + "\n";

                $$.code = strdup(temp.c_str());
                
        }
        | IF bool_exp THEN make_statements ELSE make_statements ENDIF
        {
                std::string ifS = new_label();
                std::string after = new_label();
                std::string temp;
                temp.append($2.code);
                
                temp += "?:= " + ifS + ", " + $2.place + "\n"; // jump to :ifS if true, do code from $4
                temp.append($6.code); // if above is not true, do $5 code
                temp += ":= " + after + "\n"; // prevent else code from doing if code
                temp += ": " + ifS + "\n";

                temp.append($4.code); // reached by :ifS jump
                temp += ": " + after + "\n";
                $$.code = strdup(temp.c_str());
        }
        | WHILE bool_exp BEGINLOOP make_statements ENDLOOP
        {
                std::string temp;
                temp.append($2.code);
                temp.append($4.code);
                $$.code = strdup(temp.c_str());
        }
        | DO BEGINLOOP make_statements ENDLOOP WHILE bool_exp
        {
                std::string temp;
                temp.append($3.code);
                temp.append($6.code);
                $$.code = strdup(temp.c_str());
        }
        | READ make_vars
        {
                std::string temp;
                temp.append(".< ");
                temp.append($2.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
        }
        | WRITE make_vars
        {
                std::string temp;
                temp.append(".> ");
                temp.append($2.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
        }
        | CONTINUE
        {

        }
        | RETURN make_expressions
        {
                std::string temp;
                std::string tplace;
           
                temp.append($2.code);
                temp += "ret ";
                temp.append($2.place);
                temp += "\n";
                $$.code = strdup(temp.c_str());
        }
        ;

bool_exp: rel_and_exp
        {
                std::string temp;
                temp.append($1.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
        }
        | rel_and_exp OR bool_exp
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
        }
        ;

rel_and_exp: make_rel_exp
        {
                std::string temp;
                temp.append($1.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
        }
        | make_rel_exp AND rel_and_exp
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
        }
        ;

make_rel_exp: NOT rel_exp
        {
                std::string temp;
                temp.append($2.code);
                $$.code = strdup(temp.c_str());
        }
        | rel_exp
        {
                std::string temp;
                temp.append($1.code);

                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
        }
        ;

rel_exp: expression comp expression
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);

                temp += ". " + dst + "\n";
                temp += $2.place  + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | TRUE
        {
                std::string temp;
                temp.append("1");
                $$.code = strdup("");
                $$.place = strdup(temp.c_str());
        }
        | FALSE
        {
                std::string temp;
                temp.append("0");
                $$.code = strdup("");
                $$.place = strdup(temp.c_str());  
        }
        | L_PAREN bool_exp R_PAREN
        {
                std::string temp;
                temp.append($2.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup($2.place);  
        }
        ;

comp:   EQ
        {
                $$.code = strdup("");
                $$.place = strdup("== ");
        }
        | NEQ
        {
                $$.code = strdup("");
                $$.place = strdup("!= ");
        }
        | LT
        {
                $$.code = strdup("");
                $$.place = strdup("< ");
        }
        | LTE
        {
                $$.code = strdup("");
                $$.place = strdup("<= ");
        }
        | GT
        {
                $$.code = strdup("");
                $$.place = strdup("> ");
        }
        | GTE
        {
                $$.code = strdup("");
                $$.place = strdup(">= ");
        }
        ;
// for term production
make_expressions: expression
        {
                std::string temp;
                temp.append($1.code);
                
                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
        }
        |
        {

        }
        | expression COMMA make_expressions
        {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);

                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
        }
        ;

expression: mult_exp ADD expression
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);

                temp += ". " + dst + "\n";
                temp += "+ " + dst + ", ";
                temp.append($1.place);

                temp += ", ";
                temp.append($3.place);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | mult_exp SUB expression
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);

                temp += ". " + dst + "\n";
                temp += "- " + dst + ", ";
                temp.append($1.place);

                temp += ", ";
                temp.append($3.place);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | mult_exp
        {
                std::string temp;
                temp.append($1.code);

                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
        }
        ;

mult_exp: term MOD mult_exp
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);

                temp += ". " + dst + "\n";
                temp.append(dst);
                temp.append("\n");
                temp += "% t" + dst + ", ";

                temp.append($1.place);
                temp += ", ";
                temp.append($3.place);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | term DIV mult_exp
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);

                temp += ". " + dst + "\n";
                temp.append(dst);
                temp.append("\n");
                temp += "/ t" + dst + ", ";

                temp.append($1.place);
                temp += ", ";
                temp.append($3.place);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | term MULT mult_exp
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);

                temp += ". " + dst + "\n";
                temp.append(dst);
                temp.append("\n");
                temp += "* t" + dst + ", ";

                temp.append($1.place);
                temp += ", ";
                temp.append($3.place);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());                
        }
        | term
        {
                std::string temp;
                temp.append($1.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup($1.place);
        }
        ;

term:   var
        {
                // new
                std::string val;
                std::string temp;
                std::string dst = new_temp();

                temp += ". " + dst + "\n";
                temp += "= " + dst + ", " + $1.code + "\n"; 
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | SUB var
        {
                std::string temp;
                temp.append($2.place);
                temp += "\n";
                temp += "= "; 

                $$.place = strdup(temp.c_str());
                $$.code = strdup("");
        }
        | NUMBER
        {
                std::string val;
                std::string temp;
                std::string dst = new_temp();
                val = std::to_string($1);

                temp += ". " + dst + "\n";
                temp += "= " + dst + ", " + val + "\n"; 
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | SUB NUMBER
        {
                std::string val;
                std::string temp;
                std::string dst = new_temp();
                val = std::to_string($2);

                temp += ". " + dst + "\n";
                temp += "= " + dst + ", -" + val + "\n"; 
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
        }
        | L_PAREN make_expressions R_PAREN
        {
                std::string temp;
                std::string dst = new_temp();
                temp.append($2.code);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
        }
        | SUB L_PAREN make_expressions R_PAREN
        {
                std::string temp;
                temp.append($3.code);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
        }
        | funcCall L_PAREN make_expressions R_PAREN
        {
                std::string temp;
                std::string dst = new_temp();
                std::string ident = $1.place;
                if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end())
                        printf("Identifier %s has yet to be declared.\n", ident.c_str());
                else if (arrSize[ident] == 1)
                        printf("Non-array identifier %s was given an index.\n", ident.c_str());

                temp.append($1.code);
                temp.append($3.code);
                temp.append("param ");
                temp += $3.place;
                temp.append("\n");
                temp += ". " + dst + "\n";

                temp.append("call ");
                temp.append($1.place);
                temp.append(", ");
                temp.append(dst);
                temp += "\n";

                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
                $$.arr = true;
        }
        ;

make_vars: var
        {
                std::string temp;
                temp += ". ";
                if ($1.arr)
                        temp.append("[]");
                temp.append(" ");
                temp.append($1.place);
                $$.place = strdup($1.place);
                $$.code = strdup(temp.c_str());
        }
        | var COMMA make_vars
        {
                std::string temp;
                temp.append($1.place);
                if ($1.arr)
                        temp.append(".[], ");
                temp.append($3.code);

                $$.code = strdup($1.place);
                $$.place = strdup(temp.c_str());
        }
        ;

var:    idents
        {
                std::string temp;
                std::string ident = $1.place;

                if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end())
                        printf("Identifier %s has yet to be declared.\n", ident.c_str());
                else if (arrSize[ident] > 1)
                        printf("No index provided for array identifier %s", ident.c_str());

                temp.append($1.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup(ident.c_str());
                $$.arr = false;
        }
        | idents L_BRACKET expression R_BRACKET
        {
                std::string temp;
                std::string ident = $1.place;
                if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end())
                        printf("Identifier %s has yet to be declared.\n", ident.c_str());
                else if (arrSize[ident] == 1)
                        printf("Non-array identifier %s was given an index.\n", ident.c_str());

                temp.append($1.place);
                temp.append(", ");
                temp.append($3.place);

                $$.code = strdup($3.code);
                $$.place = strdup(temp.c_str());
                $$.arr = true;
        }
        ;

funcIdent: IDENT        
        {
                if (funcs.find($1) != funcs.end())
                {
                        printf("Function %s previously declared, cannot reuse.\n", $1);
                }
                else
                {
                        funcs.insert($1);
                }
                $$.code = strdup("");
                $$.place = strdup($1);
        }
        ;

funcCall: IDENT
        {
                $$.code = strdup("");
                $$.place = strdup($1);   
        }
        ;

idents: IDENT   
        {
                std::string temp;
                temp += ". ";
                temp.append($1);
                temp += "\n";
                $$.code = strdup($1);
                $$.place = strdup($1);
        }
        | IDENT COMMA idents
        {
                std::string temp;
                temp.append($1);
                temp.append("|");
                temp.append($3.place);
                $$.place = strdup(temp.c_str());
                $$.code = strdup("");
        }
        ;

%%

int main(int argc, char **argv) 
{
    if(argc >= 2)
    {
        yyin = fopen(argv[1], "r");
        if(yyin == NULL)
        {
            yyin = stdin;
        }
    }
   else
    {
       yyin = stdin;
    }
    
    yyparse();
    return 0;
}

void yyerror(const char *msg) 
{
    printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}

std::string new_temp()
{
        std::string t = "t" + std::to_string(tempCount);
        tempCount++;
        return t;
}

std::string new_label()
{
        std::string l = "L" + std::to_string(labelCount);
        labelCount++;
        return l;
}
