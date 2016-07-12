/*
 * Definition of the structure used to build the syntax tree.
 */
#ifndef __EXPR_H__
#define __EXPR_H__

/**
 * @brief The expression type
 */
typedef enum ExpType
{
    // literal value
    EXP_VALUE,

    // operations in the AST
    EXP_OP_ADD,
    EXP_OP_MUL,
} ExpType;

typedef struct ExpVal
{
    int value;
} ExpVal;

typedef struct ExpOp
{
    // We will coopt the type field to track the operation
    struct Expression* left;
    struct Expression* right;
} ExpOp;

/**
 * @brief The expression structure
 */
typedef struct Expression
{
    ExpType type;
    struct Expression* next;
    union {
        ExpVal val;
        ExpOp  op;
    };
} Expression;

/**
 * @brief Create a number expression
 * @param value The number value
 * @return The expression or NULL in case of no memory
 */
Expression* createNumber(int value);

/**
 * @brief Create an operation expression
 * @param type The operation type
 * @param left The left operand
 * @param right The right operand
 * @return The expression or NULL in case of no memory
 */
Expression* createOperation(ExpType type,
                            Expression* left,
                            Expression* right);

/**
 * @brief Set next expression
 * @param exp The expression to set next for
 * @param next The next expression
 */
Expression* setNext(Expression* expr,
                    Expression* next);

/**
 * @brief Delete an expression
 * @param expr The expression
 */
void deleteExpression(Expression* expr);

#endif
