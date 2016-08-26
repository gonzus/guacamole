#include <ctype.h>
#include <stdlib.h>
#include "gmem.h"
#include "ast.h"
#include "parser.h"

AST* ast_create(void)
{
    AST* ast;
    GMEM_NEW(ast, AST*, sizeof(AST));
    ast->symtab = symtab_create(0); // use default symtab size
    ast->root = NULL;
    return ast;
}

void ast_destroy(AST* ast)
{
    if (!ast) {
        return;
    }

    node_destroy(ast->root);
    symtab_destroy(ast->symtab);
    GMEM_DEL(ast, AST*, sizeof(AST));
}

void ast_dump(AST* ast, FILE* fp)
{
    fprintf(fp, "=== AST ===\n");
    node_dump(ast->root, 0, 0, fp);
    symtab_dump(ast->symtab, fp);
}
