%{

#include <stdio.h>
#include "expr.h"
#include "parser.h"

static void update_loc(YYLTYPE *loc, char *txt)
{
    loc->first_line = loc->last_line;
    loc->first_column = loc->last_column;
    for (int i = 0; txt[i] != '\0'; i++) {
        if (txt[i] == '\n') {
            loc->last_line++;
            loc->last_column = 0;
        }
        else {
            loc->last_column++;
        }
    }
}

#define YY_USER_ACTION update_loc(yylloc, yytext);
%}

%option yylineno

%option outfile="lexer.c" header-file="lexer.h"
%option warn nodefault

%option reentrant noyywrap never-interactive nounistd
%option bison-bridge

SEMICOLON   ";"
LPAREN      "("
RPAREN      ")"
PLUS        "+"
MULTIPLY    "*"

NUMBER      [0-9]+
WS          [ \r\n\t]*

%%

{WS}            { /* Skip blanks */ }
{NUMBER}        { sscanf(yytext, "%d", &yylval->value); return TOKEN_NUMBER; }

{MULTIPLY}      { return TOKEN_MULTIPLY;  }
{PLUS}          { return TOKEN_PLUS;      }
{LPAREN}        { return TOKEN_LPAREN;    }
{RPAREN}        { return TOKEN_RPAREN;    }
{SEMICOLON}     { return TOKEN_SEMICOLON; }
.               {  }

%%
