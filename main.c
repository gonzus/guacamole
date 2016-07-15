#include <stdio.h>
#include "ast.h"
#include "parser.h"
#include "lexer.h"

static void process(FILE* fp)
{
    // yyin = fp;
    yyscan_t scanner;
    if (yylex_init(&scanner)) {
        fprintf(stderr, "Could not initialize lexer\n");
        return;
    }

    AST* ast = ast_create();
    if (yyparse(&ast, scanner)) {
        fprintf(stderr, "Could not parse input\n");
    }
    else {
        ast_dump(ast, stdout);
    }

    yylex_destroy(scanner);
}

int main(int argc, char* argv[])
{
    if (argc <= 1) {
        process(stdin);
    }
    else {
        for (int j = 1; j < argc; ++j) {
            FILE* fp = fopen(argv[j], "r");
            if (!fp) {
                fprintf(stderr, "Could not open %s\n", argv[j]);
                continue;
            }
            process(fp);
            fclose(fp);
        }
    }

    return 0;
}
