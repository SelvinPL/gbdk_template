#include <gbdk/platform.h>
#include <stdio.h>

void main(void)
{
#ifndef NINTENDO_NES
	set_default_palette();
#endif
	printf("Hello World!");
}