CFLAGS = -Wall -Wextra -Werror -framework IOBluetooth

test: blueutil
	./test

.PHONY: test
