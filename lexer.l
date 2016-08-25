%{

#include <stdio.h>
#include "ast.h"
#include "symtab.h"
#include "node.h"
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

/* some macros to makes things more readable */

BLANK       [ \r\n\t]
NUMBER      [0-9]
ALPHA       [a-zA-Z_]
ALNUM       [a-zA-Z0-9_]
IDENT       {ALPHA}{ALNUM}*

INTEGER     {NUMBER}+
REAL        {NUMBER}+\.{NUMBER}*|{NUMBER}*\.{NUMBER}+

%%

{BLANK}+        { /* Skip blanks */   }
#.*             { /* Skip comments; TODO fix, this is valid: $x =~ s/#/ok/g; */ }

{INTEGER}       { sscanf(yytext, "%ld", &yylval->vali); return INTEGER; }
{REAL}          { sscanf(yytext, "%lf", &yylval->valr); return REAL;    }

{IDENT}(::{IDENT})+ {
                    /* Fully qualified identifier => Foo::Bar::baz */
                    SymTab* symtab = (*ast)->symtab;
                    /* Look it up; if not there, create */
                    /* TODO symbol should be created in parser: $x, @x, %x */
                    Symbol* s = symtab_lookup(symtab, yytext, FULL_IDENTIFIER, 1);
                    yylval->symb = s;
                    return s->type;
                }
{IDENT}         {
                    /* Simple identifier => baz; could be a reserved word */
                    SymTab* symtab = (*ast)->symtab;
                    /* Look it up; if not there, create */
                    /* TODO symbol should be created in parser: $x, @x, %x */
                    Symbol* s = symtab_lookup(symtab, yytext, IDENTIFIER, 1);
                    yylval->symb = s;
                    return s->type;
                }

"<="            { return LE; }
">="            { return GE; }
"=="            { return EQ; }
"!="            { return NE; }
"<"             { return LT; }
">"             { return GT; }

[-+*/(){}=;$@%] {
                    /* These are valid one-character tokens */
                    return yytext[0];
                }

.               {
                    /* Anything else, complain loudly */
                    char msg[1024];
                    sprintf(msg, "WTF? Unknown character [%c]", yytext[0]);
                    yyerror(yylloc_param, ast, yyscanner, msg);
                }

%%
