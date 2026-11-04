/* Parity sample for C. */
#include <stdio.h>
#include <stdlib.h>
#include "local.h"

#define MAX_LEN 64
#define SQUARE(x) ((x) * (x))

typedef enum { RED, GREEN = 2, BLUE } color_t;

struct point {
    double x, y;
    const char *label;
};

typedef struct point point_t;

static int counter = 0;

/* Sum the squares of values. */
static long sum_squares(const int *values, size_t n) {
    long total = 0;
    for (size_t i = 0; i < n; ++i) {
        total += SQUARE(values[i]);
    }
    return total;
}

int main(int argc, char **argv) {
    point_t p = {.x = 1.5, .y = -2.0, .label = "origin\n"};
    char buf[MAX_LEN];
    int values[] = {1, 2, 3, 0x10};
    unsigned char c = 'a';
    color_t color = GREEN;

    if (argc > 1 && argv[1] != NULL) {
        snprintf(buf, sizeof(buf), "%s: %d\n", argv[1], argc);
    } else {
        buf[0] = '\0';
    }

    switch (color) {
    case RED:
        break;
    default:
        counter++;
    }

    while (counter < 3) {
        counter += 1;
    }

    printf("%ld %f %c %s\n", sum_squares(values, 4), p.x, c, buf);
    return EXIT_SUCCESS;
}
