#include <stdio.h>
#include "expr.h"
#include "parser.h"
#include "lexer.h"

static Expression* parse(const char* text)
{
    if (!text) {
        fprintf(stderr, "Could not parse null string\n");
        return NULL;
    }

    yyscan_t scanner;
    if (yylex_init(&scanner)) {
        fprintf(stderr, "Could not initialize lexer\n");
        return NULL;
    }

    Expression* expr = 0;
    YY_BUFFER_STATE state = yy_scan_string(text, scanner);
    if (yyparse(&expr, scanner)) {
        fprintf(stderr, "Could not parse [%s]\n", text);
        expr = 0;
    }

    yy_delete_buffer(state, scanner);
    yylex_destroy(scanner);
    return expr;
}

static int evaluate(Expression* expr)
{
    if (!expr) {
        fprintf(stderr, "Could not evaluate null expression\n");
        return 0;
    }

    switch (expr->type) {
        case EXP_VALUE:
            return expr->val.value;
        case EXP_OP_MUL:
            return evaluate(expr->op.left) * evaluate(expr->op.right);
        case EXP_OP_ADD:
            return evaluate(expr->op.left) + evaluate(expr->op.right);
        default:
            fprintf(stderr, "Could not evaluate invalid expression (type %d)\n",
                    expr->type);
            return 0;
    }
}

static int process(const char* text)
{
    int count = 0;
    for (Expression* expr = parse(text); expr; expr = expr->next) {
        printf("Evaluating [%p]\n", expr);
        int result = evaluate(expr);
        printf("%s = %d\n", text, result);
        ++count;
    }
    deleteExpression(expr);
    return count;
}

int main(int argc, char* argv[])
{
    for (int j = 1; j < argc; ++j) {
        process(argv[j]);
    }

    return 0;
}
