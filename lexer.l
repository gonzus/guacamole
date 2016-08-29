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

typedef struct qw_info {
    char beg;
    char end;
    int pos;
    char tok[1024];
} qw_info;

static qw_info qw;

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

%x QW

/* some macros to makes things more readable */

WS          [ \r\n\t]
NWS         [^ \r\n\t]
NUMBER      [0-9]
ALPHA       [a-zA-Z_]
ALNUM       [a-zA-Z0-9_]
IDENT       {ALPHA}{ALNUM}*

INTEGER     {NUMBER}+
REAL        {NUMBER}+\.{NUMBER}*|{NUMBER}*\.{NUMBER}+

%%

{WS}+           { /* Skip blanks */   }
#.*             { /* Skip comments; TODO fix, this is valid: $x =~ s/#/ok/g; */ }

"qw".           {
                    BEGIN(QW);
                    qw.pos = 0;
                    qw.beg = yytext[2];
                    switch (qw.beg) {
                        case '{':
                            qw.end = '}';
                            break;
                        case '[':
                            qw.end = ']';
                            break;
                        case '(':
                            qw.end = ')';
                            break;
                        case '<':
                            qw.end = '>';
                            break;
                        default:
                            qw.end = qw.beg;
                            break;
                    }
                    printf("INITIAL => QW [%c:%c]\n", qw.beg, qw.end);
                    return '(';
                }
<QW>{WS}+       {
                    if (qw.pos > 0) {
                        qw.tok[qw.pos] = '\0';
                        printf("QW: WORD [%d:%s]\n", qw.pos, qw.tok);
                        printf("QW: WS\n");
                        qw.pos = 0;

                        SymTab* symtab = (*ast)->symtab;
                        /* TODO treat as string, not symbol */
                        Symbol* s = symtab_lookup(symtab, qw.tok, IDENTIFIER, 1);
                        yylval->symb = s;
                        return s->type;
                    }
                    printf("QW: WS\n");
                }
<QW>{NWS}       {
                    if (yytext[0] == qw.end) {
                        if (qw.pos > 0) {
                            qw.tok[qw.pos] = '\0';
                            printf("QW: WORD [%d:%s]\n", qw.pos, qw.tok);
                            qw.pos = 0;
                            yyless(0);

                            SymTab* symtab = (*ast)->symtab;
                            /* TODO treat as string, not symbol */
                            Symbol* s = symtab_lookup(symtab, qw.tok, IDENTIFIER, 1);
                            yylval->symb = s;
                            return s->type;
                        }
                        BEGIN(INITIAL);
                        printf("QW => INITIAL\n");
                        return ')';
                    } else {
                        qw.tok[qw.pos++] = yytext[0];
                        // printf("QW [%c]\n", yytext[0]);
                    }
                }

{INTEGER}       { sscanf(yytext, "%ld", &yylval->vali); return INTEGER; }
{REAL}          { sscanf(yytext, "%lf", &yylval->valr); return REAL;    }

\'[^\']*\'      { yylval->vals = yytext; return STRING; }
\"[^\"]*\"      { yylval->vals = yytext; return STRING; }

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
