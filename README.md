get/set bluetooth power and discoverable state

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
        --recent [N]          list recent devices, 10 by default

        --info ADDRESS        show information about device with address
        --connect ADDRESS     create a connection to device with address
        --disconnect ADDRESS  close the connection to device with address

    -h, --help                this help
    -v, --version             show version

STATE can be one of: 1, on, 0, off, toggle
```

Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).

Opening Bluetooth preference pane always turns on discoverability if bluetooth power is on or if it is switched on when preference pane is open, this change of state is not reported by the function used by `blueutil`.

Originally written by Frederik Seiffert ego@frederikseiffert.de http://www.frederikseiffert.de/blueutil/
Further development by Ivan Kuchin https://github.com/toy/blueutil
