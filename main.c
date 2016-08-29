#include <stdio.h>
#include "ast.h"
#include "parser.h"
#include "lexer.h"

static AST* create_and_populate_ast(void)
{
    static struct Reserved {
        const char* word;
        int token;
    } reserved[] = {
        { "package" , PACKAGE   },
        { "use"     , USE       },
        { "parent"  , PARENT    },
        { "require" , REQUIRE   },
        { "my"      , MY        },
        { "our"     , OUR       },
        { "local"   , LOCAL     },
        { "print"   , PRINT     },
        { "while"   , WHILE     },
        { "if"      , IF        },
        { "else"    , ELSE      },
    };

    AST* ast = ast_create();
    for (int j = 0; j < sizeof(reserved) / sizeof(reserved[0]); ++j) {
        symtab_lookup(ast->symtab, reserved[j].word, reserved[j].token, 1);
    }
    return ast;
}

static void process(FILE* fp)
{
    // yyin = fp;
    yyscan_t scanner;
    if (yylex_init(&scanner)) {
        fprintf(stderr, "Could not initialize lexer\n");
        return;
    }

    AST* ast = create_and_populate_ast();
    if (yyparse(&ast, scanner)) {
        fprintf(stderr, "Could not parse input\n");
    }
    else {
        ast_dump(ast, stdout);
    }

    ast_destroy(ast);
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
