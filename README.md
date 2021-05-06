# blueutil

CLI for bluetooth on OSX: power, discoverable state, list, inquire devices, connect, info, …

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
                              list favourite devices
        --inquiry [T]         inquiry devices in range, 10 seconds duration by default excluding time for name updates
        --paired              list paired devices
        --recent [N]          list recently used devices, 10 by default, 0 to list all
        --connected           list connected devices

        --info ID             show information about device
        --is-connected ID     connected state of device as 1 or 0
        --connect ID          create a connection to device
        --disconnect ID       close the connection to device
        --pair ID [PIN]       pair with device, optional PIN of up to 16 characters will be used instead of interactive input if requested in specific pair mode
        --add-favourite ID, --add-favorite ID
                              add to favourites
        --remove-favourite ID, --remove-favorite ID
                              remove from favourites

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
ID can be either address in form xxxxxxxxxxxx, xx-xx-xx-xx-xx-xx or xx:xx:xx:xx:xx:xx, or name of device to search in used devices
OP can be one of: >, >=, <, <=, =, !=; or equivalents: gt, ge, lt, le, eq, ne
PERIOD is in seconds, defaults to 1
TIMEOUT is in seconds, default value 0 doesn't add timeout
FORMAT can be one of:
  default - human readable text output not intended for consumption by scripts
  new-default - human readable comma separated key-value pairs (EXPERIMENTAL, THE BEHAVIOUR MAY CHANGE)
  json - compact JSON
  json-pretty - pretty printed JSON

Due to possible problems, blueutil will refuse to run as root user (see https://github.com/toy/blueutil/issues/41).
Use environment variable BLUEUTIL_ALLOW_ROOT=1 to override (sudo BLUEUTIL_ALLOW_ROOT=1 blueutil …).

Exit codes:
   0 Success
   1 General failure
  64 Wrong usage like missing or unexpected arguments, wrong parameters
  69 Bluetooth not available
  70 Internal error
  71 System error like shortage of memory
  75 Timeout error
```
<!--]USAGE-->

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

## Notes

Uses private API from IOBluetooth framework (i.e. `IOBluetoothPreference*()`).

Opening Bluetooth preference pane always turns on discoverability if bluetooth power is on or if it is switched on when preference pane is open, this change of state is not reported by the function used by `blueutil`.

### Development

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

## Copyright

Originally written by Frederik Seiffert ego@frederikseiffert.de http://www.frederikseiffert.de/blueutil/
Copyright (c) 2011-2021 Ivan Kuchin. See [LICENSE.txt](LICENSE.txt) for details.
