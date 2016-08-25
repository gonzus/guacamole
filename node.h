#ifndef NODE_H__
#define NODE_H__

#include <stdio.h>

// Possible types of Node
typedef enum NodeType
{
    NODE_VALI, // Integer
    NODE_VALR, // Real
    NODE_VALS, // String

    NODE_SYMB, // Symbol

    NODE_OPER, // Operation
} NodeType;

// A Node in the AST, could point to its children
typedef struct Node
{
    NodeType type;
    union {
        long vali;
        double valr;
        char* vals;
        struct Symbol* symb;
        struct Oper* oper;
    };
} Node;

Node* node_vali(long value);
Node* node_valr(double value);
Node* node_vals(const char* value);
Node* node_symb(struct Symbol* symb);
Node* node_oper(int oper, int nchildren, ...);

void node_destroy(Node* node);

void node_dump(Node* node, int parent, int level, FILE* fp);

#endif
