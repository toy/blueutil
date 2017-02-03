get/set bluetooth power and discoverable state

```
blueutil h[elp] - this help
blueutil v[ersion] - show version

blueutil - show state
blueutil p[ower]|d[iscoverable] - show state 1 or 0
blueutil p[ower]|d[iscoverable] 1|0 - set state

Also original style arguments:
blueutil s[tatus] - show status
blueutil on - power on
blueutil off - power off
```

Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).

Originally written by Frederik Seiffert <ego@frederikseiffert.de> <http://www.frederikseiffert.de/blueutil/>
