#ifndef OPER_H__
#define OPER_H__

#include <stdarg.h>
#include <stdio.h>

// Struct to hold an operation (root in a subtree)
typedef struct Oper
{
    int type;                 // the operator itself: +, *, IF, etc.
    int nchildren;            // how many children
    struct Node* children[];  // the children themselves
} Oper;

Oper* oper_create(int type, int nchildren, va_list ap);
void oper_destroy(Oper* oper);

void oper_dump(Oper* oper, int level, FILE* fp);

#endif
