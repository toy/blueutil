get/set bluetooth power and discoverable state

    blueutil - show state
    blueutil power|discoverable - show state 1 or 0
    blueutil power|discoverable 1|0 - set state

Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).

Originally written by Frederik Seiffert <ego@frederikseiffert.de> <http://www.frederikseiffert.de/blueutil/>
