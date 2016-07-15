#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"
#include "node.h"

Node* node_vali(long value)
{
    fprintf(stderr, "Node VALI[%ld]\n", value);
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_VALI;
    node->vali = value;
    return node;
}

Node* node_valr(double value)
{
    fprintf(stderr, "Node VALR[%lf]\n", value);
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_VALR;
    node->valr = value;
    return node;
}

Node* node_vals(const char* value)
{
    fprintf(stderr, "Node VALS[%s]\n", value);
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_VALS;
    node->vals = strdup(value);
    return node;
}

Node* node_symb(Symbol* symb)
{
    fprintf(stderr, "Node SYMB[%d:%s]\n", symb->type, symb->name);
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_SYMB;
    node->symb = symb;
    return node;
}

Node* node_oper(int oper, int nchildren, ...)
{
    fprintf(stderr, "Node OPER[%d:%d]\n", oper, nchildren);
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_OPER;

    node->oper = (Oper*) malloc(sizeof(Oper) + sizeof(Node*) * nchildren);
    node->oper->oper = oper;
    node->oper->nchildren = nchildren;

    va_list ap;
    va_start(ap, nchildren);
    for (int j = 0; j < nchildren; ++j) {
        node->oper->children[j] = va_arg(ap, Node*);
    }
    va_end(ap);
    return node;
}

void node_destroy(Node* node)
{
    if (!node) {
        return;
    }

    switch (node->type) {
        case NODE_VALS:
            free(node->vals);
            break;

        case NODE_OPER:
            for (int j = 0; j < node->oper->nchildren; ++j) {
                node_destroy(node->oper->children[j]);
            }
            free(node->oper);
            break;

        default:
            break;
    }
    free(node);
}
