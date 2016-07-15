#ifndef SYMTAB_H_
#define SYMTAB_H_

/*
 * Data structure holding a symbol table.
 */

#include <stdio.h>

typedef struct Symbol {
    char* name;
    int type;
    struct Symbol* next;
} Symbol;

typedef struct SymTab {
    int size;
    int used;
    Symbol* buckets[];
} SymTab;

SymTab* symtab_create(int size);
void symtab_destroy(SymTab* symtab);

Symbol* symtab_lookup(SymTab* symtab,
                      const char* name,
                      int type,
                      int create);
void symtab_dump(SymTab* symtab, FILE* fp);

#endif
