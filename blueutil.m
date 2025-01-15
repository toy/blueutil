// blueutil
//
// CLI for bluetooth on OSX: power, discoverable state, list, inquire devices, connect, info, …
// Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).
// https://github.com/toy/blueutil
//
// Originally written by Frederik Seiffert <ego@frederikseiffert.de> http://www.frederikseiffert.de/blueutil/
//
// Copyright (c) 2011-2024 Ivan Kuchin. See <LICENSE.txt> for details.

#define VERSION "2.10.0"

#import <IOBluetooth/IOBluetooth.h>

#include <getopt.h>
#include <regex.h>
#include <signal.h>
#include <sysexits.h>

#define EX_SIGABRT (128 + SIGABRT)

#define eprintf(...) fprintf(stderr, ##__VA_ARGS__)

void *assert_alloc(void *pointer) {
  if (pointer == NULL) {
    eprintf("%s\n", strerror(errno));
    exit(EX_OSERR);
  }
  return pointer;
}

int assert_reg(int errcode, const regex_t *restrict preg, char *reason) {
  if (errcode == 0 || errcode == REG_NOMATCH) return errcode;

  size_t errbuf_size = regerror(errcode, preg, NULL, 0);
  char *restrict errbuf = assert_alloc(malloc(errbuf_size));
  regerror(errcode, preg, errbuf, errbuf_size);

  eprintf("%s: %s\n", reason, errbuf);
  exit(EX_SOFTWARE);
}

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

// short names
typedef int (*GetterFunc)();
typedef bool (*SetterFunc)(int);

enum state {
  toggle = -1,
  off = 0,
  on = 1,
};

bool BTSetParamState(enum state state, GetterFunc getter, void (*setter)(int), const char *name) {
  if (state == toggle) state = !getter();

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
bool BTSetPowerState(enum state state) {
  return BTSetParamState(state, BTPowerState, IOBluetoothPreferenceSetControllerPowerState, "power");
}

#define BTDiscoverableState IOBluetoothPreferenceGetDiscoverableState
bool BTSetDiscoverableState(enum state state) {
  return BTSetParamState(state, BTDiscoverableState, IOBluetoothPreferenceSetDiscoverableState, "discoverable");
}

void check_power_on_for(const char *command) {
  if (BTPowerState()) return;
  eprintf("Power is required to be on for %s command\n", command);
}

void usage(FILE *io) {
  static const char *lines[] = {
    ("blueutil v" VERSION),
    "",
    "Usage:",
    "  blueutil [options]",
    "",
    "Without options outputs current state",
    "",
    "    -p, --power               output power state as 1 or 0",
    "    -p, --power STATE         set power state",
    "    -d, --discoverable        output discoverable state as 1 or 0",
    "    -d, --discoverable STATE  set discoverable state",
    "",
    "        --favourites, --favorites",
    "                              list favourite devices; returns empty list starting with macOS 12/Monterey",
    "        --inquiry [T]         inquiry devices in range, 10 seconds duration by default excluding time for name updates",
    "        --paired              list paired devices",
    "        --recent [N]          list recently used devices, 10 by default, 0 to list all; returns empty list starting with macOS 12/Monterey",
    "        --connected           list connected devices",
    "",
    "        --info ID             show information about device",
    "        --is-connected ID     connected state of device as 1 or 0",
    "        --connect ID          create a connection to device",
    "        --disconnect ID       close the connection to device",
    "        --pair ID [PIN]       pair with device, optional PIN of up to 16 characters will be used instead of interactive input if requested in specific pair mode",
    "        --unpair ID           EXPERIMENTAL unpair the device",
    "        --add-favourite ID, --add-favorite ID",
    "                              add to favourites; does nothing starting with macOS 12/Monterey",
    "        --remove-favourite ID, --remove-favorite ID",
    "                              remove from favourites; does nothing starting with macOS 12/Monterey",
    "",
    "        --format FORMAT       change output format of info and all listing commands",
    "",
    "        --wait-connect ID [TIMEOUT]",
    "                              EXPERIMENTAL wait for device to connect",
    "        --wait-disconnect ID [TIMEOUT]",
    "                              EXPERIMENTAL wait for device to disconnect",
    "        --wait-rssi ID OP VALUE [PERIOD [TIMEOUT]]",
    "                              EXPERIMENTAL wait for device RSSI value which is 0 for golden range, -129 if it cannot be read (e.g. device is disconnected)",
    "",
    "    -h, --help                this help",
    "    -v, --version             show version",
    "",
    "STATE can be one of: 1, on, 0, off, toggle",
    "ID can be either address in form xxxxxxxxxxxx, xx-xx-xx-xx-xx-xx or xx:xx:xx:xx:xx:xx, or name of device to search in paired or recent devices",
    "OP can be one of: >, >=, <, <=, =, !=; or equivalents: gt, ge, lt, le, eq, ne",
    "PERIOD is in seconds, defaults to 1",
    "TIMEOUT is in seconds, default value 0 doesn't add timeout",
    "FORMAT can be one of:",
    "  default - human readable text output not intended for consumption by scripts",
    "  new-default - human readable comma separated key-value pairs (EXPERIMENTAL, THE BEHAVIOUR MAY CHANGE)",
    "  json - compact JSON",
    "  json-pretty - pretty printed JSON",
    "",
    "Favourite devices and recent access date are not stored starting with macOS 12/Monterey, current time is returned for recent access date by framework instead.",
    "",
    "Due to possible problems, blueutil will refuse to run as root user (see https://github.com/toy/blueutil/issues/41).",
    "Use environment variable BLUEUTIL_ALLOW_ROOT=1 to override (sudo BLUEUTIL_ALLOW_ROOT=1 blueutil …).",
    "",
    "Exit codes:",
  };

  for (size_t i = 0, _i = sizeof(lines) / sizeof(lines[0]); i < _i; i++) {
    fprintf(io, "%s\n", lines[i]);
  }

  struct exit_code {
    unsigned char code;
    const char *description;
  };

  struct exit_code exit_codes[] = {
    {EXIT_SUCCESS, "Success"},
    {EXIT_FAILURE, "General failure"},
    {EX_USAGE, "Wrong usage like missing or unexpected arguments, wrong parameters"},
    {EX_UNAVAILABLE, "Bluetooth or interface not available"},
    {EX_SOFTWARE, "Internal error"},
    {EX_OSERR, "System error like shortage of memory"},
    {EX_TEMPFAIL, "Timeout error"},
    {EX_SIGABRT, "Abort signal may indicate absence of access to Bluetooth API"},
  };

  for (size_t i = 0, _i = sizeof(exit_codes) / sizeof(exit_codes[0]); i < _i; i++) {
    fprintf(io, " %3d %s\n", exit_codes[i].code, exit_codes[i].description);
  }
}

void handle_abort(__unused int signal) {
  eprintf("Error: Received abort signal, it may be due to absence of access to Bluetooth API, check that current "
          "terminal application has access in System Settings > Privacy & Security > Bluetooth\n");

  // keep the exit code
  exit(EX_SIGABRT);
}

char *next_arg(int argc, char *argv[], bool required) {
  if (optind < argc && NULL != argv[optind] && (required || '-' != argv[optind][0])) {
    return argv[optind++];
  } else {
    return NULL;
  }
}

char *next_reqarg(int argc, char *argv[]) {
  return next_arg(argc, argv, true);
}

char *next_optarg(int argc, char *argv[]) {
  return next_arg(argc, argv, false);
}

// getopt_long doesn't consume optional argument separated by space
// https://stackoverflow.com/a/32575314
void extend_optarg(int argc, char *argv[]) {
  if (!optarg) optarg = next_optarg(argc, argv);
}

bool parse_state_arg(char *arg, enum state *state) {
  if (0 == strcmp(arg, "1") || 0 == strcasecmp(arg, "on")) {
    *state = on;
    return true;
  }

  if (0 == strcmp(arg, "0") || 0 == strcasecmp(arg, "off")) {
    *state = off;
    return true;
  }

  if (0 == strcasecmp(arg, "toggle")) {
    *state = toggle;
    return true;
  }

  return false;
}

bool check_device_address_arg(char *arg) {
  regex_t regex;
  int result;

  result = regcomp(&regex,
    "^[0-9a-f]{2}([0-9a-f]{10}|(-[0-9a-f]{2}){5}|(:[0-9a-f]{2}){5})$",
    REG_EXTENDED | REG_ICASE | REG_NOSUB);
  assert_reg(result, &regex, "Compiling device address regex");

  result = regexec(&regex, arg, 0, NULL, 0);
  assert_reg(result, &regex, "Matching device address regex");

  regfree(&regex);

  return result == 0;
}

bool parse_unsigned_long_arg(char *arg, unsigned long *number) {
  regex_t regex;
  int result;

  result = regcomp(&regex, "^[[:digit:]]+$", REG_EXTENDED | REG_NOSUB);
  assert_reg(result, &regex, "Compiling number regex");

  result = regexec(&regex, arg, 0, NULL, 0);
  assert_reg(result, &regex, "Matching number regex");

  regfree(&regex);

  if (result == 0) {
    *number = strtoul(arg, NULL, 10);
    return true;
  } else {
    return false;
  }
}

bool parse_signed_long_arg(char *arg, long *number) {
  regex_t regex;
  int result;

  result = regcomp(&regex, "^-?[[:digit:]]+$", REG_EXTENDED | REG_NOSUB);
  assert_reg(result, &regex, "Compiling number regex");

  result = regexec(&regex, arg, 0, NULL, 0);
  assert_reg(result, &regex, "Matching number regex");

  regfree(&regex);

  if (result == 0) {
    *number = strtol(arg, NULL, 10);
    return true;
  } else {
    return false;
  }
}

IOBluetoothDevice *get_device(char *id) {
  NSString *nsId = [NSString stringWithCString:id encoding:[NSString defaultCStringEncoding]];

  IOBluetoothDevice *device = nil;

  if (check_device_address_arg(id)) {
    device = [IOBluetoothDevice deviceWithAddressString:nsId];

    if (!device) {
      eprintf("Device not found by address: %s\n", id);
      exit(EXIT_FAILURE);
    }
  } else {
    NSMutableArray *searchDevices = [NSMutableArray new];

    NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
    if (pairedDevices) {
      [searchDevices addObjectsFromArray:pairedDevices];
    }

    NSArray *recentDevices = [IOBluetoothDevice recentDevices:0];
    if (recentDevices) {
      [searchDevices addObjectsFromArray:recentDevices];
    }

    if (searchDevices.count <= 0) {
      eprintf("No paired or recent devices to search for: %s\n", id);
      exit(EXIT_FAILURE);
    }

    NSArray *byName = [searchDevices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", nsId]];
    if (byName.count > 0) {
      device = byName.firstObject;
    }

    if (!device) {
      eprintf("Device not found by name: %s\n", id);
      exit(EXIT_FAILURE);
    }
  }

  return device;
}

void list_devices_default(NSArray *devices, bool first_only) {
  for (IOBluetoothDevice *device in devices) {
    printf("address: %s", [[device addressString] UTF8String]);
    if ([device isConnected]) {
      printf(", connected (%s, %d dBm)", [device isIncoming] ? "slave" : "master", [device rawRSSI]);
    } else {
      printf(", not connected");
    }
    printf(", %s", [device isFavorite] ? "favourite" : "not favourite");
    printf(", %s", [device isPaired] ? "paired" : "not paired");
    printf(", name: \"%s\"", [device name] ? [[device name] UTF8String] : "-");
    printf(", recent access date: %s",
      [device recentAccessDate] ? [[[device recentAccessDate] description] UTF8String] : "-");
    printf("\n");
    if (first_only) break;
  }
}

void list_devices_new_default(NSArray *devices, bool first_only) {
  const char *separator = first_only ? "\n" : ", ";
  for (IOBluetoothDevice *device in devices) {
    printf("address: %s%s", [[device addressString] UTF8String], separator);
    printf("recent access: %s%s",
      [device recentAccessDate] ? [[[device recentAccessDate] description] UTF8String] : "-",
      separator);
    printf("favourite: %s%s", [device isFavorite] ? "yes" : "no", separator);
    printf("paired: %s%s", [device isPaired] ? "yes" : "no", separator);
    printf("connected: %s%s", [device isConnected] ? ([device isIncoming] ? "slave" : "master") : "no", separator);
    printf("rssi: %s%s",
      [device isConnected] ? [[NSString stringWithFormat:@"%d", [device RSSI]] UTF8String] : "-",
      separator);
    printf("raw rssi: %s%s",
      [device isConnected] ? [[NSString stringWithFormat:@"%d", [device rawRSSI]] UTF8String] : "-",
      separator);
    printf("name: %s\n", [device name] ? [[device name] UTF8String] : "-");
    if (first_only) break;
  }
}

void list_devices_json(NSArray *devices, bool first_only, bool pretty) {
  NSMutableArray *descriptions = [NSMutableArray arrayWithCapacity:[devices count]];

  @autoreleasepool {
    // https://stackoverflow.com/a/16254918/96823
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    for (IOBluetoothDevice *device in devices) {
      NSMutableDictionary *description = [NSMutableDictionary dictionaryWithDictionary:@{
        @"address": [device addressString],
        @"name": [device name] ? [device name] : [NSNull null],
        @"recentAccessDate": [device recentAccessDate] ? [dateFormatter stringFromDate:[device recentAccessDate]]
                                                       : [NSNull null],
        @"favourite": [device isFavorite] ? @(YES) : @(NO),
        @"paired": [device isPaired] ? @(YES) : @(NO),
        @"connected": [device isConnected] ? @(YES) : @(NO),
      }];

      if ([device isConnected]) {
        description[@"slave"] = [device isIncoming] ? @(YES) : @(NO);
        description[@"RSSI"] = [NSNumber numberWithChar:[device RSSI]];
        description[@"rawRSSI"] = [NSNumber numberWithChar:[device rawRSSI]];
      }

      [descriptions addObject:description];
    }
  }

  NSOutputStream *stdout = [NSOutputStream outputStreamToFileAtPath:@"/dev/stdout" append:NO];
  [stdout open];
  id object = first_only ? [descriptions firstObject] : descriptions;
  NSJSONWritingOptions options = pretty ? NSJSONWritingPrettyPrinted : 0;
  [NSJSONSerialization writeJSONObject:object toStream:stdout options:options error:NULL];
  if (pretty) {
    [stdout write:(const uint8_t *)"\n" maxLength:1];
  }
  [stdout close];
}

void list_devices_json_default(NSArray *devices, bool first_only) {
  list_devices_json(devices, first_only, false);
}

void list_devices_json_pretty(NSArray *devices, bool first_only) {
  list_devices_json(devices, first_only, true);
}

typedef void (*FormatterFunc)(NSArray *, bool);

bool parse_output_formatter(char *arg, FormatterFunc *formatter) {
  if (0 == strcasecmp(arg, "default")) {
    *formatter = list_devices_default;
    return true;
  }

  if (0 == strcasecmp(arg, "new-default")) {
    *formatter = list_devices_new_default;
    return true;
  }

  if (0 == strcasecmp(arg, "json")) {
    *formatter = list_devices_json_default;
    return true;
  }

  if (0 == strcasecmp(arg, "json-pretty")) {
    *formatter = list_devices_json_pretty;
    return true;
  }

  return false;
}

@interface DeviceInquiryRunLoopStopper : NSObject <IOBluetoothDeviceInquiryDelegate>
@end
@implementation DeviceInquiryRunLoopStopper
- (void)deviceInquiryComplete:(__unused IOBluetoothDeviceInquiry *)sender
                        error:(__unused IOReturn)error
                      aborted:(__unused BOOL)aborted {
  CFRunLoopStop(CFRunLoopGetCurrent());
}
@end

static inline bool is_caseabbr(const char *name, const char *str) {
  size_t length = strlen(str);
  if (length < 1) length = 1;
  return strncasecmp(name, str, length) == 0;
}

const char *hci_error_descriptions[] = {
  [0x01] = "Unknown HCI Command",
  [0x02] = "No Connection",
  [0x03] = "Hardware Failure",
  [0x04] = "Page Timeout",
  [0x05] = "Authentication Failure",
  [0x06] = "Key Missing",
  [0x07] = "Memory Full",
  [0x08] = "Connection Timeout",
  [0x09] = "Max Number of Connections",
  [0x0a] = "Max Number of SCO Connections to a Device",
  [0x0b] = "ACL Connection Already Exists",
  [0x0c] = "Command Disallowed",
  [0x0d] = "Host Rejected Limited Resources",
  [0x0e] = "Host Rejected Security Reasons",
  [0x0f] = "Host Rejected Remote Device Is Personal / Host Rejected Unacceptable Device Address (2.0+)",
  [0x10] = "Host Timeout",
  [0x11] = "Unsupported Feature or Parameter Value",
  [0x12] = "Invalid HCI Command Parameters",
  [0x13] = "Other End Terminated Connection User Ended",
  [0x14] = "Other End Terminated Connection Low Resources",
  [0x15] = "Other End Terminated Connection About to Power Off",
  [0x16] = "Connection Terminated by Local Host",
  [0x17] = "Repeated Attempts",
  [0x18] = "Pairing Not Allowed",
  [0x19] = "Unknown LMP PDU",
  [0x1a] = "Unsupported Remote Feature",
  [0x1b] = "SCO Offset Rejected",
  [0x1c] = "SCO Interval Rejected",
  [0x1d] = "SCO Air Mode Rejected",
  [0x1e] = "Invalid LMP Parameters",
  [0x1f] = "Unspecified Error",
  [0x20] = "Unsupported LMP Parameter Value",
  [0x21] = "Role Change Not Allowed",
  [0x22] = "LMP Response Timeout",
  [0x23] = "LMP Error Transaction Collision",
  [0x24] = "LMP PDU Not Allowed",
  [0x25] = "Encryption Mode Not Acceptable",
  [0x26] = "Unit Key Used",
  [0x27] = "QoS Not Supported",
  [0x28] = "Instant Passed",
  [0x29] = "Pairing With Unit Key Not Supported",
  [0x2a] = "Different Transaction Collision",
  [0x2c] = "QoS Unacceptable Parameter",
  [0x2d] = "QoS Rejected",
  [0x2e] = "Channel Classification Not Supported",
  [0x2f] = "Insufficient Security",
  [0x30] = "Parameter Out of Mandatory Range",
  [0x31] = "Role Switch Pending",
  [0x34] = "Reserved Slot Violation",
  [0x35] = "Role Switch Failed",
  [0x36] = "Extended Inquiry Response Too Large",
  [0x37] = "Secure Simple Pairing Not Supported by Host",
  [0x38] = "Host Busy Pairing",
  [0x39] = "Connection Rejected Due to No Suitable Channel Found",
  [0x3a] = "Controller Busy",
  [0x3b] = "Unacceptable Connection Interval",
  [0x3c] = "Directed Advertising Timeout",
  [0x3d] = "Connection Terminated Due to MIC Failure",
  [0x3e] = "Connection Failed to Be Established",
  [0x3f] = "MAC Connection Failed",
  [0x40] = "Coarse Clock Adjustment Rejected",
};

@interface DevicePairDelegate : NSObject <IOBluetoothDevicePairDelegate>
@property (readonly) IOReturn errorCode;
@property char *requestedPin;
@end
@implementation DevicePairDelegate
- (const char *)errorDescription {
  if (_errorCode >= 0 && (unsigned)_errorCode < sizeof(hci_error_descriptions) / sizeof(hci_error_descriptions[0]) &&
    hci_error_descriptions[_errorCode]) {
    return hci_error_descriptions[_errorCode];
  } else {
    return "UNKNOWN ERROR";
  }
}

- (void)devicePairingFinished:(__unused id)sender error:(IOReturn)error {
  _errorCode = error;
  CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)devicePairingPINCodeRequest:(id)sender {
  BluetoothPINCode pinCode;
  ByteCount pinCodeSize;

  if (_requestedPin) {
    eprintf("Input pin %.16s on \"%s\" (%s)\n",
      _requestedPin,
      [[[sender device] name] UTF8String],
      [[[sender device] addressString] UTF8String]);

    pinCodeSize = strlen(_requestedPin);
    if (pinCodeSize > 16) pinCodeSize = 16;
    strncpy((char *)pinCode.data, _requestedPin, pinCodeSize);
  } else {
    eprintf("Type pin code (up to 16 characters) for \"%s\" (%s) and press Enter: ",
      [[[sender device] name] UTF8String],
      [[[sender device] addressString] UTF8String]);

    uint input_size = 16 + 2;
    char input[input_size];
    fgets(input, input_size, stdin);
    input[strcspn(input, "\n")] = 0;

    pinCodeSize = strlen(input);
    strncpy((char *)pinCode.data, input, pinCodeSize);
  }

  [sender replyPINCode:pinCodeSize PINCode:&pinCode];
}

- (void)devicePairingUserConfirmationRequest:(id)sender numericValue:(BluetoothNumericValue)numericValue {
  eprintf("Does \"%s\" (%s) display number %06u (yes/no)? ",
    [[[sender device] name] UTF8String],
    [[[sender device] addressString] UTF8String],
    numericValue);

  uint input_size = 3 + 2;
  char input[input_size];
  fgets(input, input_size, stdin);
  input[strcspn(input, "\n")] = 0;

  if (is_caseabbr("yes", input)) {
    [sender replyUserConfirmation:YES];
    return;
  }

  if (is_caseabbr("no", input)) {
    [sender replyUserConfirmation:NO];
    return;
  }
}

- (void)devicePairingUserPasskeyNotification:(id)sender passkey:(BluetoothPasskey)passkey {
  eprintf("Input passkey %06u on \"%s\" (%s)\n",
    passkey,
    [[[sender device] name] UTF8String],
    [[[sender device] addressString] UTF8String]);
}
@end

#define OP_FUNC(name, operator)                \
  bool op_##name(const long a, const long b) { \
    return a operator b;                       \
  }

OP_FUNC(gt, >);
OP_FUNC(ge, >=);
OP_FUNC(lt, <);
OP_FUNC(le, <=);
OP_FUNC(eq, ==);
OP_FUNC(ne, !=);

typedef bool (*OpFunc)(const long a, const long b);

#define PARSE_OP_ARG_MATCHER(name, operator)                    \
  if (0 == strcmp(arg, #name) || 0 == strcmp(arg, #operator)) { \
    *op = op_##name;                                            \
    *op_name = #operator;                                       \
    return true;                                                \
  }

bool parse_op_arg(const char *arg, OpFunc *op, const char **op_name) {
  PARSE_OP_ARG_MATCHER(gt, >);
  PARSE_OP_ARG_MATCHER(ge, >=);
  PARSE_OP_ARG_MATCHER(lt, <);
  PARSE_OP_ARG_MATCHER(le, <=);
  PARSE_OP_ARG_MATCHER(eq, =);
  PARSE_OP_ARG_MATCHER(ne, !=);

  return false;
}

@interface DeviceNotificationRunLoopStopper : NSObject
@end
@implementation DeviceNotificationRunLoopStopper {
  IOBluetoothDevice *expectedDevice;
}
- (id)initWithExpectedDevice:(IOBluetoothDevice *)device {
  expectedDevice = device;
  return self;
}
- (void)notification:(IOBluetoothUserNotification *)notification fromDevice:(IOBluetoothDevice *)device {
  if ([expectedDevice isEqual:device]) {
    [notification unregister];
    CFRunLoopStop(CFRunLoopGetCurrent());
  }
}
@end

struct args_state_get {
  GetterFunc func;
};

struct args_state_set {
  SetterFunc func;
  enum state state;
};

struct args_inquiry {
  unsigned long duration;
};

struct args_recent {
  unsigned long max;
};

struct args_device_id {
  char *device_id;
};

struct args_pair {
  char *device_id;
  char *pin_code;
};

struct args_wait_connection_change {
  char *device_id;
  bool wait_connect;
  unsigned long timeout;
};

struct args_wait_rssi {
  char *device_id;
  OpFunc op;
  const char *op_name;
  long value;
  unsigned long period;
  unsigned long timeout;
};

typedef int (^cmd)(void *args);
struct cmd_with_args {
  cmd cmd;
  void *args;
};

#define CMD_CHUNK 8
struct cmd_with_args *cmds = NULL;
size_t cmd_n = 0, cmd_reserved = 0;

#define ALLOC_ARGS(type) struct args_##type *args = assert_alloc(malloc(sizeof(struct args_##type)))

void add_cmd(void *args, cmd cmd) {
  if (cmd_n >= cmd_reserved) {
    cmd_reserved += CMD_CHUNK;
    cmds = assert_alloc(reallocf(cmds, sizeof(struct cmd_with_args) * cmd_reserved));
  }
  cmds[cmd_n++] = (struct cmd_with_args){.cmd = cmd, .args = args};
}

FormatterFunc list_devices = list_devices_default;

int main(int argc, char *argv[]) {
  signal(SIGABRT, handle_abort);

  if (geteuid() == 0) {
    char *allow_root = getenv("BLUEUTIL_ALLOW_ROOT");
    if (NULL == allow_root || 0 != strcmp(allow_root, "1")) {
      eprintf("Error: Not running as root user without environment variable BLUEUTIL_ALLOW_ROOT=1\n");
      return EXIT_FAILURE;
    }
  }

  if (!BTAvaliable()) {
    eprintf("Error: Bluetooth not available!\n");
    return EX_UNAVAILABLE;
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
    arg_connected,

    arg_info,
    arg_is_connected,
    arg_connect,
    arg_disconnect,
    arg_pair,
    arg_unpair,
    arg_add_favourite,
    arg_remove_favourite,

    arg_format,

    arg_wait_connect,
    arg_wait_disconnect,
    arg_wait_rssi,
  };

  const char *optstring = "p::d::hv";
  // clang-format off
  static struct option long_options[] = {
    {"power",           optional_argument, NULL, arg_power},
    {"discoverable",    optional_argument, NULL, arg_discoverable},

    {"favourites",      no_argument,       NULL, arg_favourites},
    {"favorites",       no_argument,       NULL, arg_favourites},
    {"inquiry",         optional_argument, NULL, arg_inquiry},
    {"paired",          no_argument,       NULL, arg_paired},
    {"recent",          optional_argument, NULL, arg_recent},
    {"connected",       no_argument,       NULL, arg_connected},

    {"info",            required_argument, NULL, arg_info},
    {"is-connected",    required_argument, NULL, arg_is_connected},
    {"connect",         required_argument, NULL, arg_connect},
    {"disconnect",      required_argument, NULL, arg_disconnect},
    {"pair",            required_argument, NULL, arg_pair},
    {"unpair",          required_argument, NULL, arg_unpair},
    {"add-favourite",    required_argument, NULL, arg_add_favourite},
    {"add-favorite",     required_argument, NULL, arg_add_favourite},
    {"remove-favourite", required_argument, NULL, arg_remove_favourite},
    {"remove-favorite",  required_argument, NULL, arg_remove_favourite},

    {"format",          required_argument, NULL, arg_format},

    {"wait-connect",    required_argument, NULL, arg_wait_connect},
    {"wait-disconnect", required_argument, NULL, arg_wait_disconnect},
    {"wait-rssi",       required_argument, NULL, arg_wait_rssi},

    {"help",            no_argument,       NULL, arg_help},
    {"version",         no_argument,       NULL, arg_version},

    {NULL, 0, NULL, 0}
  };
  // clang-format on

  int arg;
  while ((arg = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
    switch (arg) {
      case arg_power:
      case arg_discoverable: {
        extend_optarg(argc, argv);

        if (optarg) {
          ALLOC_ARGS(state_set);

          args->func = arg == arg_power ? BTSetPowerState : BTSetDiscoverableState;

          if (!parse_state_arg(optarg, &args->state)) {
            eprintf("Unexpected value: %s\n", optarg);
            return EX_USAGE;
          }

          add_cmd(args, ^int(void *_args) {
            struct args_state_set *args = (struct args_state_set *)_args;

            return args->func(args->state) ? EXIT_SUCCESS : EX_TEMPFAIL;
          });
        } else {
          ALLOC_ARGS(state_get);

          args->func = arg == arg_power ? BTPowerState : BTDiscoverableState;

          add_cmd(args, ^int(void *_args) {
            struct args_state_get *args = (struct args_state_get *)_args;

            printf("%d\n", args->func());

            return EXIT_SUCCESS;
          });
        }
      } break;
      case arg_favourites: {
        add_cmd(NULL, ^int(__unused void *_args) {
          list_devices([IOBluetoothDevice favoriteDevices], false);
          return EXIT_SUCCESS;
        });
      } break;
      case arg_paired: {
        add_cmd(NULL, ^int(__unused void *_args) {
          list_devices([IOBluetoothDevice pairedDevices], false);
          return EXIT_SUCCESS;
        });
      } break;
      case arg_inquiry: {
        ALLOC_ARGS(inquiry);

        extend_optarg(argc, argv);
        args->duration = 10;
        if (optarg) {
          if (!parse_unsigned_long_arg(optarg, &args->duration)) {
            eprintf("Expected numeric duration, got: %s\n", optarg);
            return EX_USAGE;
          }
        }

        add_cmd(args, ^int(void *_args) {
          struct args_inquiry *args = (struct args_inquiry *)_args;

          check_power_on_for("inquiry");

          @autoreleasepool {
            DeviceInquiryRunLoopStopper *stopper = [[[DeviceInquiryRunLoopStopper alloc] init] autorelease];
            IOBluetoothDeviceInquiry *inquirer = [IOBluetoothDeviceInquiry inquiryWithDelegate:stopper];

            [inquirer start];

            // inquiry length seems to be ingored starting with Monterey
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, args->duration * NSEC_PER_SEC),
              dispatch_get_main_queue(),
              ^{
                [inquirer stop];
              });

            CFRunLoopRun();

            list_devices([inquirer foundDevices], false);
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_recent: {
        ALLOC_ARGS(recent);

        extend_optarg(argc, argv);
        args->max = 10;
        if (optarg) {
          if (!parse_unsigned_long_arg(optarg, &args->max)) {
            eprintf("Expected numeric count, got: %s\n", optarg);
            return EX_USAGE;
          }
        }

        add_cmd(args, ^int(void *_args) {
          struct args_recent *args = (struct args_recent *)_args;

          list_devices([IOBluetoothDevice recentDevices:args->max], false);

          return EXIT_SUCCESS;
        });
      } break;
      case arg_connected: {
        add_cmd(NULL, ^int(__unused void *_args) {
          NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isConnected == YES"];
          list_devices([[IOBluetoothDevice pairedDevices] filteredArrayUsingPredicate:predicate], false);
          return EXIT_SUCCESS;
        });
      } break;
      case arg_info: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          list_devices(@[get_device(args->device_id)], true);

          return EXIT_SUCCESS;
        });
      } break;
      case arg_is_connected: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          printf("%d\n", [get_device(args->device_id) isConnected] ? 1 : 0);

          return EXIT_SUCCESS;
        });
      } break;
      case arg_connect: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          check_power_on_for("connect");

          if ([get_device(args->device_id) openConnection] != kIOReturnSuccess) {
            eprintf("Failed to connect \"%s\"\n", args->device_id);
            return EXIT_FAILURE;
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_disconnect: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          check_power_on_for("disconnect");

          @autoreleasepool {
            IOBluetoothDevice *device = get_device(args->device_id);

            DeviceNotificationRunLoopStopper *stopper =
              [[[DeviceNotificationRunLoopStopper alloc] initWithExpectedDevice:device] autorelease];

            [device registerForDisconnectNotification:stopper selector:@selector(notification:fromDevice:)];

            if ([device closeConnection] != kIOReturnSuccess) {
              eprintf("Failed to disconnect \"%s\"\n", args->device_id);
              return EXIT_FAILURE;
            }

            CFRunLoopRun();
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_add_favourite: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          if ([get_device(args->device_id) addToFavorites] != kIOReturnSuccess) {
            eprintf("Failed to add \"%s\" to favourites\n", args->device_id);
            return EXIT_FAILURE;
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_remove_favourite: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          if ([get_device(args->device_id) removeFromFavorites] != kIOReturnSuccess) {
            eprintf("Failed to remove \"%s\" from favourites\n", args->device_id);
            return EXIT_FAILURE;
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_pair: {
        ALLOC_ARGS(pair);

        args->device_id = optarg;
        args->pin_code = next_optarg(argc, argv);

        if (args->pin_code && strlen(args->pin_code) > 16) {
          eprintf("Pairing pin can't be longer than 16 characters, got %lu (%s)\n",
            strlen(args->pin_code),
            args->pin_code);
          return EX_USAGE;
        }

        add_cmd(args, ^int(void *_args) {
          struct args_pair *args = (struct args_pair *)_args;

          check_power_on_for("pair");

          @autoreleasepool {
            IOBluetoothDevice *device = get_device(args->device_id);
            DevicePairDelegate *delegate = [[[DevicePairDelegate alloc] init] autorelease];
            IOBluetoothDevicePair *pairer = [IOBluetoothDevicePair pairWithDevice:device];
            pairer.delegate = delegate;

            delegate.requestedPin = args->pin_code;

            if ([pairer start] != kIOReturnSuccess) {
              eprintf("Failed to start pairing with \"%s\"\n", args->device_id);
              return EXIT_FAILURE;
            }
            CFRunLoopRun();
            [pairer stop];

            if (![device isPaired]) {
              eprintf("Failed to pair \"%s\" with error 0x%02x (%s)\n",
                args->device_id,
                [delegate errorCode],
                [delegate errorDescription]);
              return EXIT_FAILURE;
            }
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_unpair: {
        ALLOC_ARGS(device_id);

        args->device_id = optarg;

        add_cmd(args, ^int(void *_args) {
          struct args_device_id *args = (struct args_device_id *)_args;

          IOBluetoothDevice *device = get_device(args->device_id);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
          if ([device respondsToSelector:@selector(remove)]) {
            [device performSelector:@selector(remove)];
#pragma clang diagnostic pop
            return EXIT_SUCCESS;
          } else {
            return EX_UNAVAILABLE;
          }
        });
      } break;
      case arg_format: {
        if (!parse_output_formatter(optarg, &list_devices)) {
          eprintf("Unexpected format: %s\n", optarg);
          return EX_USAGE;
        }
      } break;
      case arg_wait_connect:
      case arg_wait_disconnect: {
        ALLOC_ARGS(wait_connection_change);

        args->wait_connect = arg == arg_wait_connect;
        args->device_id = optarg;

        char *timeout_arg = next_optarg(argc, argv);
        args->timeout = 0;
        if (timeout_arg && !parse_unsigned_long_arg(timeout_arg, &args->timeout)) {
          eprintf("Expected numeric timeout, got: %s\n", timeout_arg);
          return EX_USAGE;
        }

        add_cmd(args, ^int(void *_args) {
          struct args_wait_connection_change *args = (struct args_wait_connection_change *)_args;

          @autoreleasepool {
            IOBluetoothDevice *device = get_device(args->device_id);

            DeviceNotificationRunLoopStopper *stopper =
              [[[DeviceNotificationRunLoopStopper alloc] initWithExpectedDevice:device] autorelease];

            CFRunLoopTimerRef timer =
              CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, 0, 0, 0, 0, ^(__unused CFRunLoopTimerRef timer) {
                if (args->wait_connect) {
                  if ([device isConnected]) {
                    CFRunLoopStop(CFRunLoopGetCurrent());
                  } else {
                    [IOBluetoothDevice registerForConnectNotifications:stopper
                                                              selector:@selector(notification:fromDevice:)];
                  }
                } else {
                  if ([device isConnected]) {
                    [device registerForDisconnectNotification:stopper selector:@selector(notification:fromDevice:)];
                  } else {
                    CFRunLoopStop(CFRunLoopGetCurrent());
                  }
                }
              });
            CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);

            if (args->timeout > 0) {
              if (kCFRunLoopRunTimedOut == CFRunLoopRunInMode(kCFRunLoopDefaultMode, args->timeout, false)) {
                eprintf("Timed out waiting for \"%s\" to %s\n", optarg, args->wait_connect ? "connect" : "disconnect");
                return EX_TEMPFAIL;
              }
            } else {
              CFRunLoopRun();
            }

            CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
            CFRelease(timer);
          }

          return EXIT_SUCCESS;
        });
      } break;
      case arg_wait_rssi: {
        ALLOC_ARGS(wait_rssi);

        args->device_id = optarg;

        char *op_arg = next_reqarg(argc, argv);
        if (!op_arg) {
          eprintf("%s: option `%s' requires 2nd argument\n", argv[0], argv[optind - 2]);
          usage(stderr);
          return EX_USAGE;
        } else if (!parse_op_arg(op_arg, &args->op, &args->op_name)) {
          eprintf("Expected operator, got: %s\n", op_arg);
          return EX_USAGE;
        }

        char *value_arg = next_reqarg(argc, argv);
        if (!value_arg) {
          eprintf("%s: option `%s' requires 3rd argument\n", argv[0], argv[optind - 3]);
          usage(stderr);
          return EX_USAGE;
        } else if (!parse_signed_long_arg(value_arg, &args->value)) {
          eprintf("Expected numeric value, got: %s\n", value_arg);
          return EX_USAGE;
        }

        char *period_arg = next_optarg(argc, argv);
        args->period = 1;
        if (period_arg) {
          if (!parse_unsigned_long_arg(period_arg, &args->period)) {
            eprintf("Expected numeric period, got: %s\n", period_arg);
            return EX_USAGE;
          } else if (args->period < 1) {
            eprintf("Expected period to be at least 1, got: %ld\n", args->period);
            return EX_USAGE;
          }
        }

        char *timeout_arg = next_optarg(argc, argv);
        args->timeout = 0;
        if (timeout_arg && !parse_unsigned_long_arg(timeout_arg, &args->timeout)) {
          eprintf("Expected numeric timeout, got: %s\n", timeout_arg);
          return EX_USAGE;
        }

        add_cmd(args, ^int(void *_args) {
          struct args_wait_rssi *args = (struct args_wait_rssi *)_args;

          IOBluetoothDevice *device = get_device(args->device_id);

          CFRunLoopTimerRef timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault,
            0,
            args->period,
            0,
            0,
            ^(__unused CFRunLoopTimerRef timer) {
              long rssi = [device RSSI];
              if (rssi == 127) rssi = -129;
              if (args->op(rssi, args->value)) {
                CFRunLoopStop(CFRunLoopGetCurrent());
              }
            });
          CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);

          if (args->timeout > 0) {
            if (kCFRunLoopRunTimedOut == CFRunLoopRunInMode(kCFRunLoopDefaultMode, args->timeout, false)) {
              eprintf("Timed out waiting for rssi of \"%s\" to be %s %ld\n",
                args->device_id,
                args->op_name,
                args->value);
              return EX_TEMPFAIL;
            }
          } else {
            CFRunLoopRun();
          }

          CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
          CFRelease(timer);

          return EXIT_SUCCESS;
        });
      } break;
      case arg_version: {
        printf(VERSION "\n");
        return EXIT_SUCCESS;
      }
      case arg_help: {
        usage(stdout);
        return EXIT_SUCCESS;
      }
      default: {
        usage(stderr);
        return EX_USAGE;
      }
    }
  }

  if (optind < argc) {
    eprintf("Unexpected arguments: %s", argv[optind++]);
    while (optind < argc) {
      eprintf(", %s", argv[optind++]);
    }
    eprintf("\n");
    return EX_USAGE;
  }

  for (size_t i = 0; i < cmd_n; i++) {
    int status = cmds[i].cmd(cmds[i].args);
    if (status != EXIT_SUCCESS) return status;
    free(cmds[i].args);
  }
  free(cmds);

  return EXIT_SUCCESS;
}
