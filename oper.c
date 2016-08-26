#include <stdlib.h>
#include "gmem.h"
#include "symtab.h"
#include "ast.h"
#include "parser.h"
#include "node.h"
#include "oper.h"

Oper* oper_create(int type, int nchildren, va_list ap)
{
    Oper* oper;
    GMEM_NEW(oper, Oper*, sizeof(Oper) + sizeof(Oper*) * nchildren);
    oper->type = type;
    oper->nchildren = nchildren;

    for (int j = 0; j < nchildren; ++j) {
        oper->children[j] = va_arg(ap, Node*);
    }
    return oper;
}

void oper_destroy(Oper* oper)
{
    if (!oper) {
        return;
    }

    for (int j = 0; j < oper->nchildren; ++j) {
        node_destroy(oper->children[j]);
    }
    GMEM_DEL(oper, Oper*, sizeof(Oper) + sizeof(Oper*) * oper->nchildren);
}

void oper_dump(Oper* oper, int level, FILE* fp)
{
    if (!oper) {
        return;
    }

    fprintf(fp, "OPER[%s]\n", token_name(oper->type));
    for (int j = 0; j < oper->nchildren; ++j) {
        node_dump(oper->children[j], oper->type, level, fp);
    }
}
