#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include "gmem.h"
#include "symtab.h"
#include "ast.h"
#include "parser.h"
#include "symtab.h"
#include "oper.h"
#include "node.h"

Node* node_vali(long value)
{
    Node* node = node_create();
    node->type = NODE_VALI;
    node->vali = value;
    return node;
}

Node* node_valr(double value)
{
    Node* node = node_create();
    node->type = NODE_VALR;
    node->valr = value;
    return node;
}

Node* node_vals(const char* value)
{
    Node* node = node_create();
    node->type = NODE_VALS;
    GMEM_NEWSTR(node->vals, value, -1);
    return node;
}

Node* node_symb(Symbol* symb)
{
    Node* node = node_create();
    node->type = NODE_SYMB;
    node->symb = symb;
    return node;
}

Node* node_oper(int oper, int nchildren, ...)
{
    Node* node = node_create();
    node->type = NODE_OPER;

    va_list ap;
    va_start(ap, nchildren);
    node->oper = oper_create(oper, nchildren, ap);
    va_end(ap);
    return node;
}

Node* node_create(void)
{
    Node* node;
    GMEM_NEW(node, Node*, sizeof(Node));
    return node;
}

void node_destroy(Node* node)
{
    if (!node) {
        return;
    }

    switch (node->type) {
        case NODE_VALS:
            GMEM_DELSTR(node->vals, -1);
            break;

        case NODE_OPER:
            oper_destroy(node->oper);
            break;

        default:
            break;
    }
    GMEM_DEL(node, Node*, sizeof(Node));
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
