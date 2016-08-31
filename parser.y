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

/* generate yytname, a table of token names */
%token-table

/* generate and pass location information (line:col) */
%locations

%define api.pure full

/* pass these parameters to lexer and parser */
%param   { AST** ast }
%param   { yyscan_t yyscanner }

/* add this early to the generated header file */
%code requires {

#ifndef YY_TYPEDEF_YY_SCANNER_T
#define YY_TYPEDEF_YY_SCANNER_T
typedef void* yyscan_t;
#endif

}

/* add this later to the generated header file */
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

const char* token_name(int token);
}

/* name outputs */
%output  "parser.c"
%defines "parser.h"

/* Possible value types for terminals and nonterminals */
%union {
    long vali;
    double valr;
    char* vals;
    Symbol* symb;
    Node* node;
}

/* Terminals without precedence but with a specific value type */
%token <vali> INTEGER
%token <valr> REAL
%token <vals> STRING
%token <symb> IDENTIFIER FULL_IDENTIFIER

/* Terminals for reserved words, with some precedende for dangling else */
%token PACKAGE USE REQUIRE PARENT CONSTANT
%token MY OUR LOCAL
%token WHILE PRINT
%token IF
%nonassoc ELSE
%token DOTDOT ARROW

/* Terminals with a specific precedence */
%left GT LT GE LE EQ NE
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

/* Nonterminals, with their corresponding types */
%type <node> stmt expr stmt_list
%type <node> simple_stmt block_stmt
%type <node> package_stmt use_stmt require_stmt decl_stmt
%type <node> assign_stmt
%type <node> symbol name
%type <node> aref_reference href_reference
%type <node> method_call invoker
%type <node> variable scalar_variable array_variable hash_variable
%type <node> initializer method_spec package_spec
%type <node> symbol_list symbol_list_full
%type <node> value value_list value_list_full value_interval
%type <node> init_single init_list init_aref init_href

/* Explicitly define starting rule */
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
    : package_stmt ';'                    { $$ = $1; }
    | use_stmt ';'                        { $$ = $1; }
    | require_stmt ';'                    { $$ = $1; }
    | decl_stmt ';'                       { $$ = $1; }
    | simple_stmt ';'                     { $$ = $1; }
    | simple_stmt IF expr ';'             { $$ = node_oper(IF, 2, $3, $1); }
    | simple_stmt WHILE expr ';'          { $$ = node_oper(WHILE, 2, $3, $1); }
    | block_stmt                          { $$ = $1; }
    | WHILE '(' expr ')' block_stmt       { $$ = node_oper(WHILE, 2, $3, $5); }
    | IF '(' expr ')' block_stmt          { $$ = node_oper(IF, 2, $3, $5); }
    | IF '(' expr ')' block_stmt ELSE block_stmt    { $$ = node_oper(IF, 3, $3, $5, $7); }
    ;

package_stmt
    : PACKAGE symbol                      { $$ = node_oper(PACKAGE, 1, $2); }
    ;

use_stmt
    : USE symbol method_spec              { $$ = node_oper(USE, 2, $2, $3); }
    | USE PARENT package_spec             { $$ = node_oper(PARENT, 1, $3); }
    | USE CONSTANT symbol ',' initializer { $$ = node_oper(CONSTANT, 2, $3, $5); }
    ;

require_stmt
    : REQUIRE symbol                      { $$ = node_oper(REQUIRE, 1, $2); }
    ;

method_spec
    :                                     { $$ = node_oper(';', 0); }
    | '(' ')'                             { $$ = node_oper(';', 0); }
    | symbol                              { $$ = $1; }
    | '(' symbol_list_full ')'            { $$ = $2; }
    ;

package_spec
    : symbol                              { $$ = $1; }
    | '(' symbol_list_full ')'            { $$ = $2; }
    ;

symbol_list_full
    : symbol_list                         { $$ = $1; }
    | symbol_list ','                     { $$ = $1; }
    ;

symbol_list
    : symbol                              { $$ = $1; }
    | symbol_list ',' symbol              { $$ = node_oper(';', 2, $1, $3); }
    ;

symbol
    : INTEGER                             { $$ = node_vali($1); }
    | REAL                                { $$ = node_valr($1); }
    | STRING                              { $$ = node_vals($1); }
    | variable                            { $$ = $1; }
    | name                                { $$ = $1; }
    ;

decl_stmt
    : MY variable                         { $$ = node_oper(MY, 1, $2); }
    | MY assign_stmt                      { $$ = node_oper(MY, 1, $2); }
    | OUR variable                        { $$ = node_oper(OUR, 1, $2); }
    | OUR assign_stmt                     { $$ = node_oper(OUR, 1, $2); }
    | LOCAL variable                      { $$ = node_oper(LOCAL, 1, $2); }
    | LOCAL assign_stmt                   { $$ = node_oper(LOCAL, 1, $2); }
    ;

simple_stmt
    :                                     { $$ = node_oper(';', 0); }
    | assign_stmt                         { $$ = $1; }
    | expr                                { $$ = $1; }
    | PRINT expr                          { $$ = node_oper(PRINT, 1, $2); }
    ;

assign_stmt
    : variable '=' initializer            { $$ = node_oper('=', 2, $1, $3); }
    ;

block_stmt
    : '{' stmt_list '}'                   { $$ = $2; }
    ;

expr
    : symbol                              { $$ = $1; }
    | aref_reference                      { $$ = $1; }
    | href_reference                      { $$ = $1; }
    | method_call                         { $$ = $1; }
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

initializer
    : init_single                         { $$ = $1; }
    | init_list                           { $$ = $1; }
    ;

init_single
    : expr                                { $$ = $1; }
    | init_aref                           { $$ = $1; }
    | init_href                           { $$ = $1; }
    ;

init_aref
    : '[' value_list_full ']'             { $$ = node_oper('@', 1, $2); }
    | '[' value_interval  ']'             { $$ = node_oper('@', 1, $2); }
    ;

init_href
    : '{' value_list_full '}'             { $$ = node_oper('%', 1, $2); }
    | '{' value_interval  '}'             { $$ = node_oper('%', 1, $2); }
    ;

init_list
    : value_interval                      { $$ = $1; }
    | '(' value_list_full  ')'            { $$ = $2; }
    ;

value_interval
    : expr DOTDOT expr                    { $$ = node_oper(DOTDOT, 2, $1, $3); }
    ;

method_call
    : invoker ARROW IDENTIFIER               { $$ = $1; }
    | invoker ARROW IDENTIFIER '(' ')'       { $$ = $1; }
    ;

invoker
    : name                                { $$ = $1; }
    | method_call                         { $$ = $1; }
    | scalar_variable                     { $$ = $1; }
    | aref_reference                      { $$ = $1; }
    | href_reference                      { $$ = $1; }
    ;

aref_reference
    : invoker ARROW '[' expr ']'   { $$ = $4; }
    ;

href_reference
    : invoker ARROW '{' expr '}'  { $$ = $4; }
    ;

value_list_full
    : value_list                          { $$ = $1; }
    | value_list ','                      { $$ = $1; }
    ;

value_list
    : value                               { $$ = $1; }
    | value_list ',' value                { $$ = node_oper(',', 2, $1, $3); }
    ;

value
    : init_single                         { $$ = $1; }
    ;

name
    : IDENTIFIER                          { $$ = node_symb($1); }
    | FULL_IDENTIFIER                     { $$ = node_symb($1); }
    ;

variable
    : scalar_variable                     { $$ = $1; }
    | array_variable                      { $$ = $1; }
    | hash_variable                       { $$ = $1; }
    ;

scalar_variable
    : '$' name                            { $$ = $2; }
    ;

array_variable
    : '@' name                            { $$ = $2; }
    ;

hash_variable
    : '%' name                            { $$ = $2; }
    ;

%%

/* Provide a function to get a token name given its number */
const char* token_name(int token)
{
    return yytname[YYTRANSLATE(token)];
}
