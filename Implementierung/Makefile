CFLAGS=-O3

.PHONY: all
all: laplace
laplace: laplace.c laplace.S simd.S
	$(CC) $(CFLAGS) -o $@ $^

.PHONY: clean
clean:
	rm -f laplace out.bmp
