// blueutil
// Command-line utility to control Bluetooth.
// Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).
// http://www.frederikseiffert.de/blueutil
//
// This software is public domain. It is provided without any warranty
// whatsoever, and may be modified or used without attribution.
//
// Written by Frederik Seiffert <ego@frederikseiffert.de>
//
// Further development by Ivan Kuchin
// https://github.com/toy/blueutil

#define VERSION "2.1.0"

#import <IOBluetooth/IOBluetooth.h>

#include <getopt.h>
#include <regex.h>

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

// short names
typedef int (*getterFunc)();
typedef bool (*setterFunc)(int);

int BTSetParamState(int state, getterFunc getter, void (*setter)(int), char *name) {
	if (state == getter()) return true;

	setter(state);

	for (int i = 0; i <= 100; i++) {
		if (i) usleep(100000);
		if (state == getter()) return true;
	}

	fprintf(stderr, "Failed to switch bluetooth %s %s in 10 seconds\n", name, state ? "on" : "off");
	return false;
}

#define BTAvaliable IOBluetoothPreferencesAvailable

#define BTPowerState IOBluetoothPreferenceGetControllerPowerState
bool BTSetPowerState(int state) {
	return BTSetParamState(state, BTPowerState, IOBluetoothPreferenceSetControllerPowerState, "power");
}

#define BTDiscoverableState IOBluetoothPreferenceGetDiscoverableState
bool BTSetDiscoverableState(int state) {
	return BTSetParamState(state, BTDiscoverableState, IOBluetoothPreferenceSetDiscoverableState, "discoverable");
}

#define io_puts(io, string) fputs (string"\n", io)

void usage(FILE *io) {
	io_puts(io, "blueutil v"VERSION);
	io_puts(io, "");
	io_puts(io, "Usage:");
	io_puts(io, "  blueutil [options]");
	io_puts(io, "");
	io_puts(io, "Without options outputs current state");
	io_puts(io, "");
	io_puts(io, "    -p, --power               output power state as 1 or 0");
	io_puts(io, "    -p, --power STATE         set power state");
	io_puts(io, "    -d, --discoverable        output discoverable state as 1 or 0");
	io_puts(io, "    -d, --discoverable STATE  set discoverable state");
	io_puts(io, "");
	io_puts(io, "        --connect ADDRESS     create a connection to device with address");
	io_puts(io, "        --disconnect ADDRESS  close the connection to device with address");
	io_puts(io, "");
	io_puts(io, "    -h, --help                this help");
	io_puts(io, "    -v, --version             show version");
	io_puts(io, "");
	io_puts(io, "STATE can be one of: 1, on, 0, off, toggle");
}

// getopt_long doesn't consume optional argument separated by space
// https://stackoverflow.com/a/32575314
void extend_optarg(int argc, char *argv[]) {
	if (
		!optarg &&
		optind < argc &&
		NULL != argv[optind] &&
		'-' != argv[optind][0]
	) {
		optarg = argv[optind++];
	}
}

bool parse_state_arg(char *arg, int *state) {
	if (
		0 == strcasecmp(arg, "1") ||
		0 == strcasecmp(arg, "on")
	) {
		if (state) *state = 1;
		return true;
	}

	if (
		0 == strcasecmp(arg, "0") ||
		0 == strcasecmp(arg, "off")
	) {
		if (state) *state = 0;
		return true;
	}

	if (
		0 == strcasecmp(arg, "toggle")
	) {
		if (state) *state = -1;
		return true;
	}

	return false;
}

bool check_device_address_arg(char *arg) {
	regex_t regex;

	if (0 != regcomp(&regex, "^[0-9a-f]{2}([0-9a-f]{10}|(-[0-9a-f]{2}){5}|(:[0-9a-f]{2}){5})$", REG_EXTENDED | REG_ICASE | REG_NOSUB)) {
		fprintf(stderr, "Failed compiling regex");
		exit(EXIT_FAILURE);
	}

	int result = regexec(&regex, arg, 0, NULL, 0);

	regfree(&regex);

	switch (result) {
		case 0:
			return true;
		case REG_NOMATCH:
			return false;
		default:
			fprintf(stderr, "Failed matching regex");
			exit(EXIT_FAILURE);
	}
}

int main(int argc, char *argv[]) {
	if (!BTAvaliable()) {
		io_puts(stderr, "Error: Bluetooth not available!");
		return EXIT_FAILURE;
	}

	if (argc == 1) {
		printf("Power: %d\nDiscoverable: %d\n", BTPowerState(), BTDiscoverableState());
		return EXIT_SUCCESS;
	}

	const char* optstring = "p::d::hv";
	static struct option long_options[] = {
		{"power",           optional_argument, NULL, 'p'},
		{"discoverable",    optional_argument, NULL, 'd'},
		{"connect",         required_argument, NULL, '1'},
		{"disconnect",      required_argument, NULL, '0'},
		{"help",            no_argument,       NULL, 'h'},
		{"version",         no_argument,       NULL, 'v'},
		{NULL, 0, NULL, 0}
	};

	int ch;
	while ((ch = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
		switch (ch) {
			case 'p':
			case 'd':
				extend_optarg(argc, argv);

				if (optarg && !parse_state_arg(optarg, NULL)) {
					fprintf(stderr, "Unexpected value: %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
			case '1':
			case '0':
				if (!check_device_address_arg(optarg)) {
					fprintf(stderr, "Unexpected address: %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
			case 'v':
				io_puts(stdout, VERSION);
				return EXIT_SUCCESS;
			case 'h':
				usage(stdout);
				return EXIT_SUCCESS;
			default:
				usage(stderr);
				return EXIT_FAILURE;
		}
	}

	if (optind < argc) {
		fprintf(stderr, "Unexpected arguments: %s", argv[optind++]);
		while (optind < argc) {
			fprintf(stderr, ", %s", argv[optind++]);
		}
		fprintf(stderr, "\n");
		return EXIT_FAILURE;
	}

	optind = 1;
	while ((ch = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
		switch (ch) {
			case 'p':
			case 'd':
				extend_optarg(argc, argv);

				if (optarg) {
					setterFunc setter = ch == 'p' ? BTSetPowerState : BTSetDiscoverableState;

					int state;
					parse_state_arg(optarg, &state);
					if (state == -1) {
						getterFunc getter = ch == 'p' ? BTPowerState : BTDiscoverableState;

						state = !getter();
					}

					if (!setter(state)) {
						return EXIT_FAILURE;
					}
				} else {
					getterFunc getter = ch == 'p' ? BTPowerState : BTDiscoverableState;

					printf("%d\n", getter());
				}

				break;
			case '1':
			case '0': {
				IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:[NSString stringWithCString:optarg encoding:[NSString defaultCStringEncoding]]];

				if (!device) {
					fprintf(stderr, "Device not found: %s\n", optarg);
					return EXIT_FAILURE;
				}

				if ((ch == '1' ? [device openConnection] : [device closeConnection]) != kIOReturnSuccess) {
					return EXIT_FAILURE;
				}
			} break;
		}
	}

	return EXIT_SUCCESS;
}
