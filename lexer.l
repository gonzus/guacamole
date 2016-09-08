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
    int sep;
    char tok[1024];
} qw_info;

static qw_info qw;

static void qw_begin(qw_info* qw, char beg) {
    qw->pos = qw->sep = 0;
    qw->beg = beg;
    switch (beg) {
        case '{':
            qw->end = '}';
            break;
        case '[':
            qw->end = ']';
            break;
        case '(':
            qw->end = ')';
            break;
        case '<':
            qw->end = '>';
            break;
        default:
            qw->end = qw->beg;
            break;
    }
}

static void qw_text(qw_info* qw, char text) {
    qw->tok[qw->pos++] = text;
}

static Symbol* qw_separator(qw_info* qw, AST** ast) {
    if (qw->pos <= 0) {
        return 0;
    }

    qw->tok[qw->pos] = '\0';
    printf("QW: WORD [%d:%s]\n", qw->pos, qw->tok);
    printf("QW: skip WS\n");
    qw->pos = 0;

    SymTab* symtab = (*ast)->symtab;
    /* TODO treat as string, not symbol */
    Symbol* s = symtab_lookup(symtab, qw->tok, IDENTIFIER, 1);
    return s;
}

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
%x EQ_FOR

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

#.*             { /* Skip comments; TODO fix, this is valid: $x =~ s/#/ok/g; */ }

"qw"{WS}*.      {
                    qw_begin(&qw, yytext[yyleng - 1]);
                    printf("INITIAL => QW [%c:%c]\n", qw.beg, qw.end);
                    BEGIN(QW);
                    printf("QW: LPAREN\n");
                    return '(';
                }
<QW>{WS}+       {
                    if (qw.sep) {
                        qw.sep = 0;
                        printf("QW: COMMA\n");
                        return COMMA;
                    }
                    Symbol* s = qw_separator(&qw, ast);
                    if (!s) {
                        printf("QW: skip WS\n");
                    } else {
                        qw.sep = 1;
                        yylval->symb = s;
                        return s->type;
                    }
                }
<QW>{NWS}       {
                    if (qw.sep) {
                        yyless(0);
                        qw.sep = 0;
                        printf("QW: COMMA\n");
                        return COMMA;
                    }
                    if (yytext[0] == qw.end) {
                        Symbol* s = qw_separator(&qw, ast);
                        if (!s) {
                            printf("QW: skip WS\n");
                        } else {
                            yyless(0);
                            qw.sep = 1;
                            yylval->symb = s;
                            return s->type;
                        }
                        printf("QW => INITIAL\n");
                        BEGIN(INITIAL);
                        printf("QW: RPAREN\n");
                        return ')';
                    } else {
                        qw_text(&qw, yytext[0]);
                        // printf("QW [%c]\n", yytext[0]);
                    }
                }

^=for.*$      {
                    printf("INITIAL => EQ_FOR [%s]\n", yytext);
                    BEGIN(EQ_FOR);
                }
<EQ_FOR>^=cut{WS}*$ {
                    printf("EQ_FOR => INITIAL\n");
                    BEGIN(INITIAL);
                }
<EQ_FOR>{WS}+   { /* ignore */ }
<EQ_FOR>.       { /* ignore */ }

{WS}+           { /* Skip blanks */   }

{INTEGER}       { sscanf(yytext, "%ld", &yylval->vali); return INTEGER; }
{REAL}          { sscanf(yytext, "%lf", &yylval->valr); return REAL;    }

\'[^\']*\'      { printf("STRINGS<%s>\n", yytext); yylval->vals = yytext; return STRING; }
\"[^\"]*\"      { printf("STRINGD<%s>\n", yytext); yylval->vals = yytext; return STRING; }

"&&="           { return ASS_AND; }
"||="           { return ASS_OR; }
"//="           { return ASS_NULL_OR; }

"&&"            { return AND; }
"||"            { return OR; }
"//"            { return NULL_OR; }

"+="            { return ASS_ADD; }
"-="            { return ASS_SUB; }
"*="            { return ASS_MUL; }
"/="            { return ASS_DIV; }

"=>"            { return FAT_COMMA; }
"->"            { printf("ARROW\n"); return ARROW; }
"\.\."          { return DOTDOT; }

"<="            { return LE; }
">="            { return GE; }
"=="            { return EQ; }
"!="            { return NE; }
"<"             { return LT; }
">"             { return GT; }

"le"            { return SLE; }
"ge"            { return SGE; }
"eq"            { return SEQ; }
"ne"            { return SNE; }
"lt"            { return SLT; }
"gt"            { return SGT; }

"=~"            { return REQ; }
"!~"            { return RNE; }

","             { return COMMA; }
"="             { return ASS; }

[\[\]\(\)\{\}\-\+\*/=;\$@%\\] {
                    /* These are valid one-character tokens */
                    return yytext[0];
                }

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
                    printf("%s<%s>\n", token_name(s->type), yytext);
                    return s->type;
                }

.               {
                    /* Anything else, complain loudly */
                    char msg[1024];
                    sprintf(msg, "WTF? Unknown character [%c]", yytext[0]);
                    yyerror(yylloc_param, ast, yyscanner, msg);
                }

%%
