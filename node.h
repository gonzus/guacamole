#ifndef NODE_H__
#define NODE_H__

#include <stdio.h>
#include "symtab.h"

// Possible types of Node
typedef enum NodeType
{
    NODE_VALI, // Integer
    NODE_VALR, // Real
    NODE_VALS, // String

    NODE_SYMB, // Symbol

    NODE_OPER, // Operation
} NodeType;

// Struct to hold an operation (root in a subtree)
typedef struct Oper
{
    int oper;                 // the operator itself: +, *, IF, etc.
    int nchildren;            // how many children
    struct Node* children[];  // the children themselves
} Oper;

// A Node in the AST, could point to its children
typedef struct Node
{
    NodeType type;
    union {
        long vali;
        double valr;
        char* vals;
        Symbol* symb;
        Oper* oper;
    };
} Node;

Node* node_vali(long value);
Node* node_valr(double value);
Node* node_vals(const char* value);
Node* node_symb(Symbol* symb);
Node* node_oper(int oper, int nchildren, ...);

void node_destroy(Node* node);

void node_dump(Node* node, int parent, int level, FILE* fp);

#endif
