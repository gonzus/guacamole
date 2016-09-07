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
%token <vals> STRING UNDEF
%token <symb> IDENTIFIER FULL_IDENTIFIER

/* Terminals for reserved words, with some precedende for dangling else */
%token PACKAGE USE NO REQUIRE PARENT CONSTANT SUB
%token MY OUR LOCAL DEFINED
%token WHILE PRINT RETURN
%token IF
%nonassoc ELSE
%token DOTDOT ARROW

/* Terminals with a specific precedence */
%left ASS ASS_AND ASS_OR ASS_NULL_OR ASS_ADD ASS_SUB ASS_MUL ASS_DIV
%left COMMA FAT_COMMA
%left GT LT GE LE EQ NE        /* maybe nonassoc? */
%left SGT SLT SGE SLE SEQ SNE  /* maybe nonassoc? */
%left AND OR NULL_OR
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

/* Nonterminals, with their corresponding types */
%type <node> stmt stmt_list
%type <node> simple_stmt block_stmt labeled_stmt sub_stmt
%type <node> package_stmt use_stmt require_stmt
%type <node> decl_stmt
%type <node> name
%type <node> aref_reference href_reference take_reference
%type <node> aref_dereference href_dereference
%type <node> method_call invoker
%type <node> variable scalar_variable array_variable hash_variable pointer_variable
%type <node> method_spec package_spec
%type <node> name_list name_list_full
%type <node> expr expr_any labeled_expr

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
    : ';'                                 { $$ = node_oper(';', 0); }
    | package_stmt                        { $$ = $1; }
    | use_stmt                            { $$ = $1; }
    | require_stmt                        { $$ = $1; }
    | decl_stmt                           { $$ = $1; }
    | simple_stmt                         { $$ = $1; }
    | simple_stmt IF expr                 { $$ = node_oper(IF, 2, $3, $1); }
    | simple_stmt WHILE expr              { $$ = node_oper(WHILE, 2, $3, $1); }
    | labeled_stmt                        { $$ = $1; }
    | block_stmt                          { $$ = $1; }
    | sub_stmt                            { $$ = $1; }
    | WHILE '(' expr ')' block_stmt       { $$ = node_oper(WHILE, 2, $3, $5); }
    | IF '(' expr ')' block_stmt          { $$ = node_oper(IF, 2, $3, $5); }
    | IF '(' expr ')' block_stmt ELSE block_stmt    { $$ = node_oper(IF, 3, $3, $5, $7); }
    ;

package_stmt
    : PACKAGE name                        { $$ = node_oper(PACKAGE, 1, $2); }
    ;

use_stmt
    : USE name method_spec              { $$ = node_oper(USE, 2, $2, $3); }
    | NO  name method_spec              { $$ = node_oper(NO, 2, $2, $3); }
    | USE PARENT package_spec             { $$ = node_oper(PARENT, 1, $3); }
    | USE CONSTANT name comma expr      { $$ = node_oper(CONSTANT, 2, $3, $5); }
    ;

comma
    : COMMA                               { printf("<comma> COMMA\n"); }
    | FAT_COMMA                           { printf("<comma> FAT_COMMA\n"); }
    ;

require_stmt
    : REQUIRE name                       { $$ = node_oper(REQUIRE, 1, $2); }
    ;

method_spec
    :                                     { $$ = node_oper(';', 0); }
    | '(' ')'                             { $$ = node_oper(';', 0); }
    | name                              { $$ = $1; }
    | '(' name_list_full ')'            { $$ = $2; }
    ;

package_spec
    : name                              { $$ = $1; }
    | STRING                              { $$ = node_vals($1); }
    | '(' name_list_full ')'            { $$ = $2; }
    ;

name_list_full
    : name_list                         { $$ = $1; }
    | name_list comma                   { $$ = $1; }
    ;

name_list
    : name                              { $$ = $1; }
    | name_list comma name              { $$ = node_oper(';', 2, $1, $3); }
    ;

decl_stmt
    : MY    expr                          { $$ = node_oper(MY, 1, $2); }
    | OUR   expr                          { $$ = node_oper(OUR, 1, $2); }
    | LOCAL expr                          { $$ = node_oper(LOCAL, 1, $2); }
    ;

simple_stmt
    : expr                                { $$ = $1; }
    | PRINT expr                          { $$ = node_oper(PRINT, 1, $2); }
    | RETURN expr                         { $$ = node_oper(RETURN, 1, $2); }
    ;

block_stmt
    : '{' stmt_list '}'                   { $$ = $2; }
    ;

labeled_stmt
    : IDENTIFIER '{' stmt_list '}'        { $$ = $3; }
    ;

labeled_expr
    : IDENTIFIER '{' expr '}' expr      { $$ = $3; }
    ;

sub_stmt
    : SUB IDENTIFIER '{' stmt_list '}'    { $$ = node_oper(SUB, 2, node_symb($2), $4); }
    ;

expr
    : INTEGER                             { $$ = node_vali($1); }
    | REAL                                { $$ = node_valr($1); }
    | STRING                              { $$ = node_vals($1); }
    | name                                { $$ = $1; }
    | UNDEF                               { $$ = node_vals($1); }
    | variable                            { $$ = $1; }
    | aref_reference                      { $$ = $1; }
    | href_reference                      { $$ = $1; }
    | take_reference                      { $$ = $1; }
    | aref_dereference                    { $$ = $1; }
    | href_dereference                    { $$ = $1; }
    | method_call                         { $$ = $1; }
    | '-' expr %prec UMINUS               { $$ = node_oper(UMINUS, 1, $2); }
    | expr '+' expr                       { $$ = node_oper('+', 2, $1, $3); }
    | expr '-' expr                       { $$ = node_oper('-', 2, $1, $3); }
    | expr '*' expr                       { $$ = node_oper('*', 2, $1, $3); }
    | expr '/' expr                       { $$ = node_oper('/', 2, $1, $3); }
    | expr AND expr                       { $$ = node_oper(AND, 2, $1, $3); }
    | expr OR expr                       { $$ = node_oper(OR, 2, $1, $3); }
    | expr NULL_OR expr                       { $$ = node_oper(NULL_OR, 2, $1, $3); }
    | expr ASS expr                       { $$ = node_oper(ASS, 2, $1, $3); }
    | expr ASS_AND expr            { $$ = node_oper(ASS_AND, 2, $1, $3); }
    | expr ASS_OR expr            { $$ = node_oper(ASS_OR, 2, $1, $3); }
    | expr ASS_NULL_OR expr            { $$ = node_oper(ASS_NULL_OR, 2, $1, $3); }
    | expr ASS_ADD expr            { $$ = node_oper(ASS_ADD, 2, $1, $3); }
    | expr ASS_SUB expr            { $$ = node_oper(ASS_SUB, 2, $1, $3); }
    | expr ASS_MUL expr            { $$ = node_oper(ASS_MUL, 2, $1, $3); }
    | expr ASS_DIV expr            { $$ = node_oper(ASS_DIV, 2, $1, $3); }
    | expr FAT_COMMA expr                     { $$ = node_oper(FAT_COMMA, 2, $1, $3); }
    | expr_any FAT_COMMA expr                     { $$ = node_oper(FAT_COMMA, 2, $1, $3); }
    | expr COMMA expr                     { $$ = node_oper(COMMA, 2, $1, $3); }
    | expr COMMA                          { $$ = $1; }
    | expr DOTDOT expr                    { $$ = node_oper(DOTDOT, 2, $1, $3); }
    | expr GT expr                        { $$ = node_oper(GT, 2, $1, $3); }
    | expr GE expr                        { $$ = node_oper(GE, 2, $1, $3); }
    | expr LT expr                        { $$ = node_oper(LT, 2, $1, $3); }
    | expr LE expr                        { $$ = node_oper(LE, 2, $1, $3); }
    | expr EQ expr                        { $$ = node_oper(EQ, 2, $1, $3); }
    | expr NE expr                        { $$ = node_oper(NE, 2, $1, $3); }
    | expr SGT expr                        { $$ = node_oper(SGT, 2, $1, $3); }
    | expr SGE expr                        { $$ = node_oper(SGE, 2, $1, $3); }
    | expr SLT expr                        { $$ = node_oper(SLT, 2, $1, $3); }
    | expr SLE expr                        { $$ = node_oper(SLE, 2, $1, $3); }
    | expr SEQ expr                        { $$ = node_oper(SEQ, 2, $1, $3); }
    | expr SNE expr                        { $$ = node_oper(SNE, 2, $1, $3); }
    | '[' ']'                        { $$ = node_oper('@', 0); }
    | '{' '}'                        { $$ = node_oper('%', 0); }
    | '(' expr ')'                        { $$ = $2; }
    | '[' expr ']'                        { $$ = $2; }
    | '{' expr '}'                        { $$ = $2; }
    | labeled_expr                       { $$ = $1; }
    | DEFINED expr                       { $$ = node_oper(DEFINED, 1, $2); }
    ;

expr_any
    : NO                                  { $$ = node_vals("no"); }
    ;

method_call
    : invoker ARROW name            { $$ = $1; }
    | invoker ARROW name '(' ')'    { $$ = $1; }
    | invoker ARROW name '(' expr ')'    { $$ = $1; }
    | name '(' ')'                        { $$ = $1; }
    | name '(' expr ')'                   { $$ = $1; }
    ;

invoker
    : name                                { $$ = $1; }
    | method_call                         { $$ = $1; }
    | scalar_variable                     { $$ = $1; }
    | aref_reference                      { $$ = $1; }
    | href_reference                      { $$ = $1; }
    ;

aref_reference
    : invoker ARROW '[' expr ']'          { $$ = $4; }
    ;

take_reference
    : '\\' scalar_variable                { $$ = $2; }
    ;

href_reference
    : invoker ARROW '{' expr '}'          { $$ = $4; }
    ;

aref_dereference
    : '@' '{' expr '}'          { $$ = $3; }
    ;

href_dereference
    : '%' '{' expr '}'          { $$ = $3; }
    ;

name
    : IDENTIFIER                          { $$ = node_symb($1); }
    | FULL_IDENTIFIER                     { $$ = node_symb($1); }
    ;

variable
    : scalar_variable                     { $$ = $1; }
    | array_variable                      { $$ = $1; }
    | hash_variable                       { $$ = $1; }
    | pointer_variable                    { $$ = $1; }
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

pointer_variable
    : '*' name                            { $$ = $2; }
    ;

%%

/* Provide a function to get a token name given its number */
const char* token_name(int token)
{
    return yytname[YYTRANSLATE(token)];
}
