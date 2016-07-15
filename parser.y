%{

#include "ast.h"
#include "node.h"
#include "symtab.h"
#include "parser.h"
#include "lexer.h"

int yyerror(YYLTYPE* yyllocp,
            AST** ast,
            yyscan_t yyscanner,
            const char *msg)
{
    fprintf(stderr, "From %d:%d to %d:%d - ERROR: %s\n",
            yyllocp->first_line, yyllocp->first_column,
            yyllocp->last_line, yyllocp->last_column,
            msg);
    return 0;
}

%}

%define api.pure full
%locations
%param   { AST** ast }
%param   { yyscan_t yyscanner }

%code requires {

#ifndef YY_TYPEDEF_YY_SCANNER_T
#define YY_TYPEDEF_YY_SCANNER_T
typedef void* yyscan_t;
#endif
}

%code provides {

#define YY_DECL \
    int yylex(YYSTYPE* yylval_param, \
              YYLTYPE* yylloc_param, \
              AST** ast, \
              yyscan_t yyscanner)
YY_DECL;

int yyerror(YYLTYPE* yyllocp,
            AST** ast,
            yyscan_t yyscanner,
            const char *msg);
}

%output  "parser.c"
%defines "parser.h"



// Possible value types for terminals and nonterminals
%union {
    long vali;
    double valr;
    char* vals;
    Symbol* symb;
    Node* node;
}

// Terminals without precedence but with a specific value type
%token <vali> INTEGER
%token <valr> REAL
%token <vals> STRING
%token <symb> IDENTIFIER

%token WHILE IF PRINT
%nonassoc NO_ELSE
%nonassoc ELSE

// Terminals with a specific precedence
%left GT LT GE LE EQ NE
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

// Nonterminals, with their corresponding types
%type <node> stmt expr stmt_list

%start program

%%

program
    : stmt_list                           { (*ast)->root = $1; }
    ;

stmt_list
    : stmt                                { $$ = $1; }
    | stmt_list stmt                      { $$ = node_oper(';', 2, $1, $2); }
    ;

stmt
    : ';'                                 { $$ = node_oper(';', 0); }
    | IDENTIFIER '=' expr ';'             { $$ = node_oper('=', 2, node_symb($1), $3); }
    | expr ';'                            { $$ = $1; }
    | PRINT expr ';'                      { $$ = node_oper(PRINT, 1, $2); }
    | WHILE '(' expr ')' stmt             { $$ = node_oper(WHILE, 1, $3, $5); }
    | IF '(' expr ')' stmt %prec NO_ELSE  { $$ = node_oper(IF, 2, $3, $5); }
    | IF '(' expr ')' stmt ELSE stmt      { $$ = node_oper(IF, 3, $3, $5, $7); }
    | '{' stmt_list '}'                   { $$ = $2; }
    ;

expr
    : INTEGER                             { $$ = node_vali($1); }
    | REAL                                { $$ = node_valr($1); }
    | STRING                              { $$ = node_vals($1); }
    | IDENTIFIER                          { $$ = node_symb($1); }
    | '-' expr %prec UMINUS               { $$ = node_oper(UMINUS, 1, $2); }
    | expr '+' expr                       { $$ = node_oper('+', 2, $1, $3); }
    | expr '-' expr                       { $$ = node_oper('-', 2, $1, $3); }
    | expr '*' expr                       { $$ = node_oper('*', 2, $1, $3); }
    | expr '/' expr                       { $$ = node_oper('/', 2, $1, $3); }
    | expr GT expr                        { $$ = node_oper(GT, 2, $1, $3); }
    | expr GE expr                        { $$ = node_oper(GE, 2, $1, $3); }
    | expr LT expr                        { $$ = node_oper(LT, 2, $1, $3); }
    | expr LE expr                        { $$ = node_oper(LE, 2, $1, $3); }
    | expr EQ expr                        { $$ = node_oper(EQ, 2, $1, $3); }
    | expr NE expr                        { $$ = node_oper(NE, 2, $1, $3); }
    | '(' expr ')'                        { $$ = $2; }
    ;

%%
