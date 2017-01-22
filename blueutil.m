// blueutil
// Command-line utility to control Bluetooth.
// Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).
// http://www.frederikseiffert.de/blueutil
//
// This software is public domain. It is provided without any warranty whatsoever,
// and may be modified or used without attribution.
//
// Written by Frederik Seiffert <ego@frederikseiffert.de>

#define VERSION "1.0.0"

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

#define eputs(string) fputs (string"\n", stderr)
void printHelp() {
	eputs("blueutil v"VERSION);
	eputs("");
	eputs("blueutil help - this help");
	eputs("");
	eputs("blueutil - show state");
	eputs("blueutil p[ower]|d[iscoverable] - show state 1 or 0");
	eputs("blueutil p[ower]|d[iscoverable] 1|0 - set state");
	eputs("");
	eputs("Also original style arguments:");
	eputs("blueutil status - show status");
	eputs("blueutil on - power on");
	eputs("blueutil off - power off");
}

int main(int argc, const char * argv[]) {
	if (!BTAvaliable()) {
		eputs("Error: Bluetooth not available!");
		return EXIT_FAILURE;
	} else {
		switch (argc) {
			case 1: {
				printf("Power: %d\nDiscoverable: %d\n", BTPowerState(), BTDiscoverableState());
				return EXIT_SUCCESS;
			}
			case 2: {
				if (strcmp("help", argv[1]) == 0) {
					printHelp();
					return EXIT_SUCCESS;
				}
				if (strcmp("status", argv[1]) == 0) {
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

				if (strncmp("power", argv[1], strlen(argv[1]) || 1) == 0) {
					getter = BTPowerState;
					setter = BTSetPowerState;
				} else if (strncmp("discoverable", argv[1], strlen(argv[1]) || 1) == 0) {
					getter = BTDiscoverableState;
					setter = BTSetDiscoverableState;
				} else {
					printHelp();
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
						printHelp();
						return EXIT_FAILURE;
					}
				}
			}
			default: {
				printHelp();
				return EXIT_FAILURE;
			}
		}
	}
}
