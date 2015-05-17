#include <stdio.h>
#include <unistd.h>
int main() {
    char buffer[32];

    puts("What's your name!?");
    write(1, "> ", 2);
    read(0, buffer, 512);

	return 0;
}
