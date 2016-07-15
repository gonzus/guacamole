#include <stdlib.h>
#include <string.h>
#include "symtab.h"

// It is better when this is a prime
#define SYMTAB_DEFAULT_SIZE 997

static unsigned long hash(const char* str);

SymTab* symtab_create(int size)
{
    size = (size <= 0) ? SYMTAB_DEFAULT_SIZE : size;
    SymTab* symtab = (SymTab*) malloc(sizeof(SymTab) +
                                      sizeof(Symbol*) * size);
    symtab->used = 0;
    symtab->size = size;
    for (int j = 0; j < size; ++j) {
        symtab->buckets[j] = 0;
    }
    return symtab;
}

void symtab_destroy(SymTab* symtab)
{
    for (int j = 0; j < symtab->size; ++j) {
        for (Symbol* s = symtab->buckets[j]; s != 0; ) {
            Symbol* q = s;
            s = s->next;
            free(q->name);
            free(q);
        }
    }
    free(symtab);
}

Symbol* symtab_lookup(SymTab* symtab,
                      const char* name,
                      int type,
                      int create)
{
    unsigned long h = hash(name);
    int p = h % symtab->size;
    Symbol* sym = 0;
    for (sym = symtab->buckets[p]; sym != 0; sym = sym->next) {
        if (strcmp(sym->name, name) == 0) {
            break;
        }
    }
    if (!sym && create) {
        sym = (Symbol*) malloc(sizeof(Symbol));
        sym->name = strdup(name);
        sym->type = type;
        sym->next = symtab->buckets[p];
        symtab->buckets[p] = sym;
        ++symtab->used;
    }
    return sym;
}

void symtab_dump(SymTab* symtab, FILE* fp)
{
    if (!symtab) {
        return;
    }

    fprintf(fp, "--- symtab[%p]: %d used / %d total ---\n",
            symtab, symtab->used, symtab->size);
    for (int j = 0; j < symtab->size; ++j) {
        int count = 0;
        for (Symbol* s = symtab->buckets[j]; s; s = s->next) {
            if (!count++) {
                printf("<%d>", j);
            }
            printf(" [%d:%s]", s->type, s->name);
        }
        if (count) {
            printf("\n");
        }
    }
}

// djb2 hash function
unsigned long hash(const char* str)
{
    unsigned long hash = 5381;
    int c;

    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }

    return hash;
}
