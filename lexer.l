%{

#include <stdio.h>
#include "ast.h"
#include "node.h"
#include "symtab.h"
#include "parser.h"

// Make sure we keep the location (line/col) updated
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

/* Define the desired output file names */
%option outfile="lexer.c" header-file="lexer.h"

/* track line count in yylineno */
%option yylineno

/* generate warnings */
%option warn

/* suppress default rule to ECHO unmatched text */
%option nodefault

/* generate a batch (not an interactive) scanner ??? */
%option never-interactive

/* do not include <unistd.h> */
%option nounistd

/* scanner for bison pure parser */
%option bison-bridge

/* include yylloc support */
%option bison-locations

/* generate a reentrant C scanner */
%option reentrant

/* ??? */
%option noyywrap

INTEGER     [0-9]+
REAL        [0-9]+\.([0-9]+)?|([0-9]+)?\.[0-9]+

%%

[ \r\n\t]+      { /* Skip blanks */ }

{INTEGER}       { sscanf(yytext, "%ld", &yylval->vali); return INTEGER; }
{REAL}          { sscanf(yytext, "%lf", &yylval->valr); return REAL;    }

while           { return WHILE; }
if              { return IF;    }
else            { return ELSE;  }
print           { return PRINT; }

[a-zA-Z_][0-9a-zA-Z_]+    { yylval->vals = strdup(yytext); return STRING; }

[-+*/();]       { return yytext[0]; }

.               { yyerror(yylloc_param, ast, yyscanner, "WTF? Unknown character");  }

%%
