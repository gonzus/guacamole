/*
 * Implementation of functions used to build the syntax tree.
 */

#include <stdio.h>
#include <stdlib.h>
#include "expr.h"

Expression* createNumber(int value)
{
    Expression* expr = (Expression*) malloc(sizeof(Expression));
    if (!expr) {
        return NULL;
    }

    expr->type = EXP_VALUE;
    expr->next = 0;
    expr->val.value = value;
    return expr;
}

Expression* createOperation(ExpType type,
                            Expression* left,
                            Expression* right)
{
    Expression* expr = (Expression*) malloc(sizeof(Expression));
    if (!expr) {
        return NULL;
    }

    expr->type = type;
    expr->next = 0;
    expr->op.left = left;
    expr->op.right = right;
    return expr;
}

Expression* setNext(Expression* expr,
                    Expression* next)
{
    if (expr) {
        expr->next = next;
    }
    return expr;
}

void deleteExpression(Expression* expr)
{
    if (!expr) {
        return;
    }

    deleteExpression(expr->next);
    if (expr->type != EXP_VALUE) {
        deleteExpression(expr->op.left);
        deleteExpression(expr->op.right);
    }
    free(expr);
}
