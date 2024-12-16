#include <stdio.h>
#include <string.h>

#define MAX_BOUNDARY_SIZE 10
#define INBOX_BOUNDARIES 6

char inboxBoundaries[INBOX_BOUNDARIES][MAX_BOUNDARY_SIZE] = {
    "## Inbox", "### Inbox", "## Input", "---", "## In", "### In"};
char *cmpPtrs[INBOX_BOUNDARIES] = {NULL};
_Bool found = 0;

void clearCmpPtrs()
{
    for (unsigned char i = 0; i < INBOX_BOUNDARIES; i++)
    {
        const unsigned short len = strlen(inboxBoundaries[i]);
        cmpPtrs[i] = &(inboxBoundaries[i][len - 1]);
    }
}

void stepMatching(char c)
{
    for (unsigned char i = 0; i < INBOX_BOUNDARIES; i++)
    {
        char *ptr = cmpPtrs[i];
        if (ptr == NULL)
            continue;

        if (*ptr == c)
        {
            if (ptr == &inboxBoundaries[i][0])
            {
                found = 1;
                cmpPtrs[i] = NULL;
            }
            else
                cmpPtrs[i]--;
        }
        else
        {
            cmpPtrs[i] = NULL;
        }
    }
}

int main(int argc, char *argv[])
{
    unsigned long long lines = 0;
    unsigned short bufIndex = 0;

    if (argc != 2)
    {
        fprintf(stderr, "Please provide path as argument\n");
        return 1;
    }

    FILE *f = fopen(argv[1], "r");

    if (f == NULL)
    {
        fprintf(stderr, "File not found\n");
        return 1;
    }

    fseek(f, 0, SEEK_END);
    clearCmpPtrs();

    while (fseek(f, -2, SEEK_CUR) == 0)
    {
        char c = fgetc(f);

        if (c == '\n')
        {
            if (found)
            {
                printf("%lld", lines);
                fclose(f);
                return 0;
            }

            lines++;
            clearCmpPtrs();
        }
        else if (c >= ' ' && c <= '~')
        {
            found = 0;
            stepMatching(c);
        }
    };

    fclose(f);
    printf("0");
}