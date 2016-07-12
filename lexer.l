%{

#include <stdio.h>
#include "expr.h"
#include "parser.h"
%}

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
