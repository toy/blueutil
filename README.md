# blueutil

CLI for bluetooth on OSX: power, discoverable state, list, inquire devices, connect, info, …

## Usage

```
Usage:
  blueutil [options]

Without options outputs current state

    -p, --power               output power state as 1 or 0
    -p, --power STATE         set power state
    -d, --discoverable        output discoverable state as 1 or 0
    -d, --discoverable STATE  set discoverable state

        --favourites          list favourite devices
        --inquiry [T]         inquiry devices in range, 10 seconds duration by default excluding time for name updates
        --paired              list paired devices
        --recent [N]          list recently used devices, 10 by default

        --info ID             show information about device
        --is-connected ID     connected state of device as 1 or 0
        --connect ID          create a connection to device
        --disconnect ID       close the connection to device
        --pair ID [PIN]       pair with device, optional PIN of up to 16 characters will be used instead of interactive input if requested in specific pair mode

    -h, --help                this help
    -v, --version             show version

STATE can be one of: 1, on, 0, off, toggle
ID can be either address in form xxxxxxxxxxxx, xx-xx-xx-xx-xx-xx or xx:xx:xx:xx:xx:xx, or name of device to search in used devices
```

## Installation

`blueutil` is avaible trough the package manager homebrew:

```sh
brew install blueutil
```

to build it from source run:

```sh
git clone git@github.com:toy/blueutil.git
cd blueutil
make
```

## Notes

Uses private API from IOBluetooth framework (i.e. `IOBluetoothPreference*()`).

Opening Bluetooth preference pane always turns on discoverability if bluetooth power is on or if it is switched on when preference pane is open, this change of state is not reported by the function used by `blueutil`.

Originally written by Frederik Seiffert ego@frederikseiffert.de http://www.frederikseiffert.de/blueutil/
Further development by Ivan Kuchin https://github.com/toy/blueutil
