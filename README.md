# blueutil

CLI for bluetooth on OSX: power, discoverable state, list, inquire devices, connect, info, …

## Notes

Uses private API from IOBluetooth framework (i.e. `IOBluetoothPreference*()`).

Opening Bluetooth preference pane always turns on discoverability if bluetooth power is on or if it is switched on when preference pane is open, this change of state is not reported by the function used by `blueutil`.

## Alternative Method

By default, `blueutil` uses IOBluetooth framework APIs to query paired devices. As an alternative, you can set the `BLUEUTIL_USE_SYSTEM_PROFILER=1` environment variable to use the `system_profiler` command instead.

The system_profiler method resolves an issue where some multi-point Bluetooth devices (devices that can connect to multiple devices simultaneously) may not report their connection status correctly through the IOBluetooth APIs, but do show the correct status via system_profiler.

**Note:** The system_profiler method is experimental and may have compatibility issues with some blueutil commands.

## Bluetooth Low Energy discovery

`--inquiry` scans for both Bluetooth Classic and Bluetooth Low Energy (BLE) devices.
BLE discovery uses CoreBluetooth on macOS 10.13 and later. Put the device in pairing
mode so that it advertises, for example by holding Easy-Switch on an unused channel
of a Logitech MX mouse for three seconds.

Classic devices retain their existing output. BLE devices report `uuid`, `transport`
(`BLE`), `name`, `RSSI`, and `connectable`, including in JSON output. BLE advertisements
do not report pairing status. Use the UUID returned by discovery with device commands:

```sh
blueutil --inquiry --format json-pretty
blueutil --pair <BLE-UUID>
blueutil --connect <BLE-UUID>
blueutil --info <BLE-UUID>
```

The device must still be advertising (in pairing mode) when `--pair` or `--connect`
is run, so use a UUID from a fresh `--inquiry`. Devices that rotate their Bluetooth
address for privacy (many keyboards and mice) get a **new UUID each time they enter
pairing mode**, so run `--inquiry` again right before pairing.

`--pair` and `--connect` both connect through CoreBluetooth; macOS performs BLE
pairing automatically during the connection when the peripheral requires security,
showing the system pairing request if needed. `--pair` allows two minutes for the
request to be answered, `--connect` 15 seconds. `--info` resolves the UUID to an
IOBluetooth device using a private framework bridge that is experimental and can
change between macOS versions. Bluetooth addresses and paired device names remain
supported as before.

Once bonded, a BLE device also appears in `--paired` and `--connected` with a
Bluetooth address, and supports the other device commands by name or address,
including `--disconnect`. Note that macOS reconnects bonded HID devices (like
keyboards) immediately after `--disconnect`.

`--unpair` only removes Classic bonds: macOS does not expose any way for an
application to remove a BLE bond, so use System Settings → Bluetooth →
"Forget This Device" for BLE devices.

The application running blueutil (such as your terminal) needs Bluetooth permission
in System Settings. A denied permission now causes inquiry to return an error.

## Usage

<!--USAGE[-->
```
Usage:
  blueutil [options]

Without options outputs current state

    -p, --power               output power state as 1 or 0
    -p, --power STATE         set power state
    -d, --discoverable        output discoverable state as 1 or 0
    -d, --discoverable STATE  set discoverable state

        --favourites, --favorites
                              list favourite devices; returns empty list starting with macOS 12/Monterey
        --inquiry [T]         discover Classic and BLE devices in range, 10 seconds by default
        --paired              list paired devices
        --recent [N]          list recently used devices, 10 by default, 0 to list all; returns empty list starting with macOS 12/Monterey
        --connected           list connected devices

        --info ID             show information about device
        --is-connected ID     connected state of device as 1 or 0
        --connect ID          create a connection to device
        --disconnect ID       close the connection to device
        --pair ID [PIN]       pair with device, optional PIN of up to 16 characters will be used instead of interactive input if requested in specific pair mode
        --unpair ID           EXPERIMENTAL unpair the device
        --add-favourite ID, --add-favorite ID
                              add to favourites; does nothing starting with macOS 12/Monterey
        --remove-favourite ID, --remove-favorite ID
                              remove from favourites; does nothing starting with macOS 12/Monterey

        --format FORMAT       change output format of info and all listing commands

        --wait-connect ID [TIMEOUT]
                              EXPERIMENTAL wait for device to connect
        --wait-disconnect ID [TIMEOUT]
                              EXPERIMENTAL wait for device to disconnect
        --wait-rssi ID OP VALUE [PERIOD [TIMEOUT]]
                              EXPERIMENTAL wait for device RSSI value which is 0 for golden range, -129 if it cannot be read (e.g. device is disconnected)

    -h, --help                this help
    -v, --version             show version

STATE can be one of: 1, on, 0, off, toggle
ID can be an address in form xxxxxxxxxxxx, xx-xx-xx-xx-xx-xx or xx:xx:xx:xx:xx:xx, a BLE UUID from --inquiry, or the name of a device in the paired or recent lists
OP can be one of: >, >=, <, <=, =, !=; or equivalents: gt, ge, lt, le, eq, ne
PERIOD is in seconds, defaults to 1
TIMEOUT is in seconds, default value 0 doesn't add timeout
FORMAT can be one of:
  default - human readable text output not intended for consumption by scripts
  new-default - human readable comma separated key-value pairs (EXPERIMENTAL, THE BEHAVIOUR MAY CHANGE)
  json - compact JSON
  json-pretty - pretty printed JSON

Favourite devices and recent access date are not stored starting with macOS 12/Monterey, current time is returned for recent access date by framework instead.

Due to possible problems, blueutil will refuse to run as root user (see https://github.com/toy/blueutil/issues/41).
Use environment variable BLUEUTIL_ALLOW_ROOT=1 to override (sudo BLUEUTIL_ALLOW_ROOT=1 blueutil …).

Environment variables:
  BLUEUTIL_USE_SYSTEM_PROFILER=1  EXPERIMENTAL: use system_profiler instead of IOBluetoothDevice API for paired device queries

Exit codes:
   0 Success
   1 General failure
  64 Wrong usage like missing or unexpected arguments, wrong parameters
  69 Bluetooth or interface not available
  70 Internal error
  71 System error like shortage of memory
  75 Timeout error
 134 Abort signal may indicate absence of access to Bluetooth API
```
<!--]USAGE-->

### Examples

List paired devices using IOBluetooth API (default):
```sh
blueutil --paired
```

Use system_profiler for a single command:
```sh
BLUEUTIL_USE_SYSTEM_PROFILER=1 blueutil --paired
```

Use system_profiler outside of shell (e.g., in scripts):
```sh
/usr/bin/env BLUEUTIL_USE_SYSTEM_PROFILER=1 blueutil --paired
```

Set environment variable to always use system_profiler:
```sh
export BLUEUTIL_USE_SYSTEM_PROFILER=1
blueutil --paired
blueutil --connected
```

## Install/update/uninstall

### Homebrew

Using package manager [Homebrew](https://brew.sh/):

```sh
# install
brew install blueutil

# update
brew update
brew upgrade blueutil

# uninstall
brew remove blueutil
```

### MacPorts

Using package manager [MacPorts](https://www.macports.org/):

```sh
# install
port install blueutil

# update
port selfupdate
port upgrade blueutil

# uninstall
port uninstall blueutil
```

You will probably need to prefix all commands with `sudo`.

### From source

```sh
git clone https://github.com/toy/blueutil.git
cd blueutil

# build
make

# install/update
git pull
make install

# uninstall
make uninstall
```

You may need to prefix install/update and uninstall make commands with `sudo`.

## Alternative Interface
For a TUI (text-based user interface) build on top of `blueutil`, you can take a look at [blueutil-tui](https://github.com/Zaloog/blueutil-tui).
It offers a simple interface for the following `blueutil` functionalities:
- displaying paired devices
- searching devices
- pairing and unpairing devices
- connecting and disconnecting devices

It's written in python using the [textual](https://textual.textualize.io) framework.

## Development

To build and update usage:

```sh
make build update_usage
```

To apply clang-format:

```sh
make format
```

To test:

```sh
make test
```

To release new version:

```sh
./release major|minor|patch
```

To create release on github:

```sh
./verify_release
```

If there are no validation errors, copy generated markdown to description of new release:

```sh
open "https://github.com/toy/blueutil/releases/new?tag=$(git describe --tags --abbrev=0)"
```

## Copyright

Originally written by Frederik Seiffert ego@frederikseiffert.de http://www.frederikseiffert.de/blueutil/

Copyright (c) 2011-2026 Ivan Kuchin. See [LICENSE.txt](LICENSE.txt) for details.
