#include <ctype.h>
#include <stdlib.h>
#include "ast.h"

static void dump_node(Node* node, int parent, FILE* fp, int level);

AST* ast_create(void)
{
    AST* ast = (AST*) malloc(sizeof(AST));
    ast->symtab = symtab_create(0); // use default symtab size
    ast->root = NULL;
    return ast;
}

void ast_destroy(AST* ast)
{
    node_destroy(ast->root);
    symtab_destroy(ast->symtab);
    free(ast);
}

void ast_dump(AST* ast, FILE* fp)
{
    fprintf(fp, "=== AST ===\n");

    dump_node(ast->root, 0, fp, 0);

    fprintf(fp, "--- symtab: %d used / %d total ---\n",
            ast->symtab->used, ast->symtab->size);
    for (int j = 0; j < ast->symtab->size; ++j) {
        Symbol* l = ast->symtab->buckets[j];
        for (Symbol* s = l; s; s = s->next) {
            printf("%d: [%s]\n", s->type, s->name);
        }
    }
}

static void dump_node(Node* node, int parent, FILE* fp, int level)
{
    if (!node) {
        return;
    }

    int delta = 2;
    if (parent == ';' &&
        node->type == NODE_OPER &&
        node->oper->oper == ';') {
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
            fprintf(fp, "SYMB\n");
            break;

        case NODE_OPER:
            if (delta) {
                if (isprint(node->oper->oper)) {
                    fprintf(fp, "OPER[%c]\n", node->oper->oper);
                }
                else {
                    fprintf(fp, "OPER[%d]\n", node->oper->oper);
                }
            }
            for (int j = 0; j < node->oper->nchildren; ++j) {
                dump_node(node->oper->children[j], node->oper->oper, fp, level);
            }
            break;
    }
    level -= delta;
}
