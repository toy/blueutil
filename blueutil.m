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

#define eprintf(...) fprintf(stderr, ##__VA_ARGS__)

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

// short names
typedef int (*getterFunc)();
typedef bool (*setterFunc)(int);

bool BTSetParamState(int state, getterFunc getter, void (*setter)(int), char *name) {
	if (state == getter()) return true;

	setter(state);

	for (int i = 0; i <= 100; i++) {
		if (i) usleep(100000);
		if (state == getter()) return true;
	}

	eprintf("Failed to switch bluetooth %s %s in 10 seconds\n", name, state ? "on" : "off");
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
	io_puts(io, "        --favourites          list favourite devices");
	io_puts(io, "        --inquiry [T]         inquiry devices in range, 10 seconds duration by default excluding time for name updates");
	io_puts(io, "        --paired              list paired devices");
	io_puts(io, "        --recent [N]          list recent devices, 10 by default");
	io_puts(io, "");
	io_puts(io, "        --info ADDR           show information about device with address");
	io_puts(io, "        --is-connected ADDR   device with address connected state as 1 or 0");
	io_puts(io, "        --connect ADDR        create a connection to device with address");
	io_puts(io, "        --disconnect ADDR     close the connection to device with address");
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
		eprintf("Failed compiling regex");
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
			eprintf("Failed matching regex");
			exit(EXIT_FAILURE);
	}
}

bool parse_unsigned_long_arg(char *arg, unsigned long *number) {
	regex_t regex;

	if (0 != regcomp(&regex, "^[[:digit:]]+$", REG_EXTENDED | REG_NOSUB)) {
		eprintf("Failed compiling regex");
		exit(EXIT_FAILURE);
	}

	int result = regexec(&regex, arg, 0, NULL, 0);

	regfree(&regex);

	switch (result) {
		case 0:
			if (number) *number = strtoul(arg, NULL, 10);
			return true;
		case REG_NOMATCH:
			return false;
		default:
			eprintf("Failed matching regex");
			exit(EXIT_FAILURE);
	}
}

IOBluetoothDevice *get_device(char *address) {
	IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:[NSString stringWithCString:address encoding:[NSString defaultCStringEncoding]]];

	if (!device) {
		fprintf(stderr, "Device not found: %s\n", address);
		exit(EXIT_FAILURE);
	}

	return device;
}

void list_devices(NSArray *devices) {
	for (IOBluetoothDevice* device in devices) {
		printf("address: %s", [[device addressString] UTF8String]);
		if ([device isConnected]) {
			printf(", connected (%s, %d dBm)", [device isIncoming] ? "slave" : "master", [device rawRSSI]);
		} else {
			printf(", not connected");
		}
		printf(", %s", [device isFavorite] ? "favourite" : "not favourite");
		printf(", %s", [device isPaired] ? "paired" : "not paired");
		printf(", name: \"%s\"", [[device name] UTF8String]);
		printf(", recent access date: %s", [[[device recentAccessDate] description] UTF8String]);
		printf("\n");
	}
}

@interface DeviceInquiryRunLoopStopper : NSObject <IOBluetoothDeviceInquiryDelegate>
@end
@implementation DeviceInquiryRunLoopStopper
- (void)deviceInquiryComplete:(__unused IOBluetoothDeviceInquiry *)sender error:(__unused IOReturn)error aborted:(__unused BOOL)aborted {
	CFRunLoopStop(CFRunLoopGetCurrent());
}
@end

int main(int argc, char *argv[]) {
	if (!BTAvaliable()) {
		io_puts(stderr, "Error: Bluetooth not available!");
		return EXIT_FAILURE;
	}

	if (argc == 1) {
		printf("Power: %d\nDiscoverable: %d\n", BTPowerState(), BTDiscoverableState());
		return EXIT_SUCCESS;
	}

	enum {
		arg_power = 'p',
		arg_discoverable = 'd',
		arg_help = 'h',
		arg_version = 'v',

		arg_favourites = 256,
		arg_inquiry,
		arg_paired,
		arg_recent,
		arg_info,
		arg_is_connected,
		arg_connect,
		arg_disconnect,
	};

	const char* optstring = "p::d::hv";
	static struct option long_options[] = {
		{"power",           optional_argument, NULL, arg_power},
		{"discoverable",    optional_argument, NULL, arg_discoverable},

		{"favourites",      no_argument,       NULL, arg_favourites},
		{"inquiry",         optional_argument, NULL, arg_inquiry},
		{"paired",          no_argument,       NULL, arg_paired},
		{"recent",          optional_argument, NULL, arg_recent},

		{"info",            required_argument, NULL, arg_info},
		{"is-connected",    required_argument, NULL, arg_is_connected},
		{"connect",         required_argument, NULL, arg_connect},
		{"disconnect",      required_argument, NULL, arg_disconnect},

		{"help",            no_argument,       NULL, arg_help},
		{"version",         no_argument,       NULL, arg_version},

		{NULL, 0, NULL, 0}
	};

	int ch;
	while ((ch = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
		switch (ch) {
			case arg_power:
			case arg_discoverable:
				extend_optarg(argc, argv);

				if (optarg && !parse_state_arg(optarg, NULL)) {
					eprintf("Unexpected value: %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
			case arg_favourites:
			case arg_paired:
				break;
			case arg_inquiry:
			case arg_recent:
				extend_optarg(argc, argv);

				if (optarg && !parse_unsigned_long_arg(optarg, NULL)) {
					eprintf("Expected number, got: %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
			case arg_info:
			case arg_is_connected:
			case arg_connect:
			case arg_disconnect:
				if (!check_device_address_arg(optarg)) {
					eprintf("Unexpected address: %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
			case arg_version:
				io_puts(stdout, VERSION);
				return EXIT_SUCCESS;
			case arg_help:
				usage(stdout);
				return EXIT_SUCCESS;
			default:
				usage(stderr);
				return EXIT_FAILURE;
		}
	}

	if (optind < argc) {
		eprintf("Unexpected arguments: %s", argv[optind++]);
		while (optind < argc) {
			eprintf(", %s", argv[optind++]);
		}
		eprintf("\n");
		return EXIT_FAILURE;
	}

	optind = 1;
	while ((ch = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
		switch (ch) {
			case arg_power:
			case arg_discoverable:
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
			case arg_favourites:
				list_devices([IOBluetoothDevice favoriteDevices]);

				break;
			case arg_paired:
				list_devices([IOBluetoothDevice pairedDevices]);

				break;
			case arg_inquiry: {
				IOBluetoothDeviceInquiry *inquirer = [IOBluetoothDeviceInquiry inquiryWithDelegate:[[DeviceInquiryRunLoopStopper alloc] init]];

				extend_optarg(argc, argv);
				if (optarg) {
					unsigned long t;
					parse_unsigned_long_arg(optarg, &t);
					[inquirer setInquiryLength:t];
				}

				[inquirer start];
				CFRunLoopRun();
				[inquirer stop];

				list_devices([inquirer foundDevices]);

			} break;
			case arg_recent: {
				unsigned long n = 10;

				extend_optarg(argc, argv);
				if (optarg) parse_unsigned_long_arg(optarg, &n);

				list_devices([IOBluetoothDevice recentDevices:n]);

			} break;
			case arg_info:
				list_devices(@[get_device(optarg)]);

				break;
			case arg_is_connected:
				printf("%d\n", [get_device(optarg) isConnected] ? 1 : 0);

				break;
			case arg_connect:
				if ([get_device(optarg) openConnection] != kIOReturnSuccess) {
					eprintf("Failed to connect %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
			case arg_disconnect:
				if ([get_device(optarg) closeConnection] != kIOReturnSuccess) {
					eprintf("Failed to disconnect %s\n", optarg);
					return EXIT_FAILURE;
				}

				break;
		}
	}

	return EXIT_SUCCESS;
}
