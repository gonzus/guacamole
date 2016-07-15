#ifndef AST_H_
#define AST_H_

/*
 * Data structure holding an Abstract Syntax Tree.
 */

#include <stdio.h>
#include "symtab.h"
#include "node.h"

typedef struct AST {
    SymTab* symtab;
    Node* root;
} AST;

AST* ast_create(void);
void ast_destroy(AST* ast);

void ast_dump(AST* ast, FILE* fp);

#endif
