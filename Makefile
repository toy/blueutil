CFLAGS = -Wall -Wextra -framework IOBluetooth

test: blueutil
	./test

.PHONY: test
