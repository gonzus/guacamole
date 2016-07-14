%{

#include "expr.h"
#include "parser.h"
#include "lexer.h"

int yyerror(YYLTYPE* yyloc, Expression **expr, yyscan_t scanner, const char *msg) {
    fprintf(stderr, "ERROR: %s\n", msg);
    return 0;
}

%}

%locations
%code requires {

#ifndef YY_TYPEDEF_YY_SCANNER_T
#define YY_TYPEDEF_YY_SCANNER_T
typedef void* yyscan_t;
#endif

}

%output  "parser.c"
%defines "parser.h"

%define api.pure
%lex-param   { yyscan_t scanner }
%parse-param { Expression **expr }
%parse-param { yyscan_t scanner }

// Possible value types for terminals and nonterminals
%union {
    int value;
    Expression* expr;
}

// Terminals without precedence or value
%token TOKEN_SEMICOLON
%token TOKEN_LPAREN
%token TOKEN_RPAREN
%token TOKEN_PLUS
%token TOKEN_MULTIPLY

// Terminals without precedence but with a specific value type
%token <value> TOKEN_NUMBER

// Terminals with a specific precedence
%left TOKEN_PLUS
%left TOKEN_MULTIPLY

// Nonterminals, with their corresponding types
%type <expr> input
%type <expr> exprs
%type <expr> expr

%%

input
    : exprs[S] {
          *expr = $S;
      }
    ;

exprs
    : expr[E] { $$ = $E; }
    | exprs[S] TOKEN_SEMICOLON expr[E] { setNext($S, $E); $$ = $S; }
    ;

expr
    : expr[L] TOKEN_PLUS expr[R] { $$ = createOperation(EXP_OP_ADD, $L, $R); }
    | expr[L] TOKEN_MULTIPLY expr[R] { $$ = createOperation(EXP_OP_MUL, $L, $R); }
    | TOKEN_LPAREN expr[E] TOKEN_RPAREN { $$ = $E; }
    | TOKEN_NUMBER { $$ = createNumber($1); }
    ;

%%
