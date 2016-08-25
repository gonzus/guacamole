#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"
#include "ast.h"
#include "parser.h"
#include "symtab.h"
#include "oper.h"
#include "node.h"

Node* node_vali(long value)
{
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_VALI;
    node->vali = value;
    return node;
}

Node* node_valr(double value)
{
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_VALR;
    node->valr = value;
    return node;
}

Node* node_vals(const char* value)
{
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_VALS;
    node->vals = strdup(value);
    return node;
}

Node* node_symb(Symbol* symb)
{
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_SYMB;
    node->symb = symb;
    return node;
}

Node* node_oper(int oper, int nchildren, ...)
{
    Node* node = (Node*) malloc(sizeof(Node));
    node->type = NODE_OPER;

    va_list ap;
    va_start(ap, nchildren);
    node->oper = oper_create(oper, nchildren, ap);
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

void node_dump(Node* node, int parent, int level, FILE* fp)
{
    if (!node) {
        return;
    }

    int delta = 2;
    if (parent == ';' &&
        node->type == NODE_OPER &&
        node->oper->type == ';') {
        delta = 0;
    }
    level += delta;

    if (delta) {
        for (int j = 0; j < level; ++j) {
            putc(' ', fp);
        }
    }

    switch (node->type) {
        case NODE_VALI:
            fprintf(fp, "VALI[%ld]\n", node->vali);
            break;

        case NODE_VALR:
            fprintf(fp, "VALR[%lf]\n", node->valr);
            break;

        case NODE_VALS:
            fprintf(fp, "VALS[%s]\n", node->vals);
            break;

        case NODE_SYMB:
            fprintf(fp, "SYMB[%s:%s]\n", token_name(node->symb->type), node->symb->name);
            break;

        case NODE_OPER:
            oper_dump(node->oper, level, fp);
            break;
    }
    level -= delta;
}
