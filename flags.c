#include "flags.h"

static int flags = 0;

void srx(int value)
{
    flags = value;
}

int grx(void)
{
    return flags;
}
