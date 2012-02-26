// blueutil
// Command-line utility to control Bluetooth.
// Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).
// http://www.frederikseiffert.de/blueutil
//
// This software is public domain. It is provided without any warranty whatsoever,
// and may be modified or used without attribution.
//
// Written by Frederik Seiffert <ego@frederikseiffert.de>
// Last change: 2009-10-30

#import <Foundation/Foundation.h>

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

// dry
int BTSetParamState(int state, int (*getter)(), void (*setter)(int)) {
	if (state == getter()) {
		return EXIT_SUCCESS;
	} else {
		setter(state);

		usleep(1000000); // Just wait, checking getter even in 10 seconds gives old result
		return EXIT_SUCCESS;
	}
}

// short names
typedef int (*getterFunc)();
typedef int (*setterFunc)(int);

#define BTAvaliable IOBluetoothPreferencesAvailable

#define BTPowerState IOBluetoothPreferenceGetControllerPowerState
int BTSetPowerState(int state) {
	return BTSetParamState(state, BTPowerState, IOBluetoothPreferenceSetControllerPowerState);
}

#define BTDiscoverableState IOBluetoothPreferenceGetDiscoverableState
int BTSetDiscoverableState(int state) {
	return BTSetParamState(state, BTDiscoverableState, IOBluetoothPreferenceSetDiscoverableState);
}

void printHelp() {
	fprintf(stderr,
					"blueutil - show state\n" \
					"blueutil power|discoverable - show state 1 or 0\n" \
					"blueutil power|discoverable 1|0 - set state\n");
}

int main(int argc, const char * argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int result = EXIT_FAILURE;

	if (!BTAvaliable()) {
		fprintf(stderr, "Error: Bluetooth not available!\n");
	} else {
		switch (argc) {
			case 1: {
				printf("Power: %d\nDiscoverable: %d\n", BTPowerState(), BTDiscoverableState());
				result = EXIT_SUCCESS;
				break;
			}
			case 2:
			case 3: {
				getterFunc getter = NULL;
				setterFunc setter = NULL;

				if (strcmp("power", argv[1]) == 0) {
					getter = BTPowerState;
					setter = BTSetPowerState;
				} else if (strcmp("discoverable", argv[1]) == 0) {
					getter = BTDiscoverableState;
					setter = BTSetDiscoverableState;
				} else {
					printHelp();
					break;
				}

				if (argc == 2) {
					printf("%d\n", getter());
					result = EXIT_SUCCESS;
				} else {
					if (strcmp("1", argv[2]) == 0) {
						result = setter(1);
					} else if (strcmp("0", argv[2]) == 0) {
						result = setter(0);
					} else {
						printHelp();
						break;
					}
				}
				break;
			}
			default: {
				printHelp();
				break;
			}
		}
	}

	[pool release];
	return result;
}
