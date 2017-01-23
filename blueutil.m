// blueutil
// Command-line utility to control Bluetooth.
// Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).
// http://www.frederikseiffert.de/blueutil
//
// This software is public domain. It is provided without any warranty whatsoever,
// and may be modified or used without attribution.
//
// Written by Frederik Seiffert <ego@frederikseiffert.de>

#define VERSION "1.1.0"

#import <IOBluetooth/IOBluetooth.h>

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

// dry
int BTSetParamState(int state, int (*getter)(), void (*setter)(int), char *name) {
	if (state == getter()) return true;

	setter(state);

	for (int i = 0; i < 101; i++) {
		if (i) usleep(100000);
		if (state == getter()) return true;
	}

	fprintf(stderr, "Failed to switch bluetooth %s %s in 10 seconds\n", name, state ? "on" : "off");
	return false;
}

// short names
typedef int (*getterFunc)();
typedef bool (*setterFunc)(int);

#define BTAvaliable IOBluetoothPreferencesAvailable

#define BTPowerState IOBluetoothPreferenceGetControllerPowerState
bool BTSetPowerState(int state) {
	return BTSetParamState(state, BTPowerState, IOBluetoothPreferenceSetControllerPowerState, "power");
}

#define BTDiscoverableState IOBluetoothPreferenceGetDiscoverableState
bool BTSetDiscoverableState(int state) {
	return BTSetParamState(state, BTDiscoverableState, IOBluetoothPreferenceSetDiscoverableState, "discoverable state");
}

#define io_puts(io, string) fputs (string"\n", io)

void printHelp(FILE *io) {
	io_puts(io, "blueutil v"VERSION);
	io_puts(io, "");
	io_puts(io, "blueutil h[elp] - this help");
	io_puts(io, "blueutil v[ersion] - show version");
	io_puts(io, "");
	io_puts(io, "blueutil - show state");
	io_puts(io, "blueutil p[ower]|d[iscoverable] - show state 1 or 0");
	io_puts(io, "blueutil p[ower]|d[iscoverable] 1|0 - set state");
	io_puts(io, "");
	io_puts(io, "Also original style arguments:");
	io_puts(io, "blueutil s[tatus] - show status");
	io_puts(io, "blueutil on - power on");
	io_puts(io, "blueutil off - power off");
}

static inline bool is_abbr_arg(const char* name, const char* arg) {
	size_t length = strlen(arg);
	return strncmp(name, arg, length ? length : 1) == 0;
}

int main(int argc, const char * argv[]) {
	if (!BTAvaliable()) {
		io_puts(stderr, "Error: Bluetooth not available!");
		return EXIT_FAILURE;
	}
	switch (argc) {
		case 1: {
			printf("Power: %d\nDiscoverable: %d\n", BTPowerState(), BTDiscoverableState());
			return EXIT_SUCCESS;
		}
		case 2: {
			if (is_abbr_arg("help", argv[1])) {
				printHelp(stdout);
				return EXIT_SUCCESS;
			}
			if (is_abbr_arg("version", argv[1])) {
				io_puts(stdout, VERSION);
				return EXIT_SUCCESS;
			}
			if (is_abbr_arg("status", argv[1])) {
				printf("Status: %s\n", BTPowerState() ? "on" : "off");
				return EXIT_SUCCESS;
			}
			if (strcmp("on", argv[1]) == 0) {
				return BTSetPowerState(1) ? EXIT_SUCCESS : EXIT_FAILURE;
			}
			if (strcmp("off", argv[1]) == 0) {
				return BTSetPowerState(0) ? EXIT_SUCCESS : EXIT_FAILURE;
			}
		}
		case 3: {
			getterFunc getter = NULL;
			setterFunc setter = NULL;

			if (is_abbr_arg("power", argv[1])) {
				getter = BTPowerState;
				setter = BTSetPowerState;
			} else if (is_abbr_arg("discoverable", argv[1])) {
				getter = BTDiscoverableState;
				setter = BTSetDiscoverableState;
			} else {
				printHelp(stderr);
				return EXIT_FAILURE;
			}

			if (argc == 2) {
				printf("%d\n", getter());
				return EXIT_SUCCESS;
			} else {
				if (strcmp("1", argv[2]) == 0) {
					return setter(1) ? EXIT_SUCCESS : EXIT_FAILURE;
				} else if (strcmp("0", argv[2]) == 0) {
					return setter(0) ? EXIT_SUCCESS : EXIT_FAILURE;
				} else {
					printHelp(stderr);
					return EXIT_FAILURE;
				}
			}
		}
		default: {
			printHelp(stderr);
			return EXIT_FAILURE;
		}
	}
}
