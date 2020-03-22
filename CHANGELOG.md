# ChangeLog

## unreleased

* Show underlying regex error messages in output, use default out of memory message [@toy](https://github.com/toy)
* Experimental use different failure exit codes from sysexits [@toy](https://github.com/toy)
* Add changelog [@toy](https://github.com/toy)
* Internal change to use blocks instead of going two times through options [@toy](https://github.com/toy)
* Mention in usage that requesting 0 recent devices will list all of them [@toy](https://github.com/toy)
* Introduce clang-format (required converting tabs to spaces) [@toy](https://github.com/toy)
* Experimental functionality to wait for device to connect, disconnect or for its RSSI to match expectation [@toy](https://github.com/toy)
* Fix probable leaks by using autoreleasepool in few places [@toy](https://github.com/toy)
* Add ability to add/remove favourites [#29](https://github.com/toy/blueutil/issues/29) [@toy](https://github.com/toy)
* Add instructions to update/uninstall [#28](https://github.com/toy/blueutil/issues/28) [@toy](https://github.com/toy)

## v2.5.1 (2019-08-27)

* Use last specified format for all output commands [#25](https://github.com/toy/blueutil/issues/25) [@toy](https://github.com/toy)
* Handle null for name and recent access date to fix an error for json output and ugly output in other formatters [#24](https://github.com/toy/blueutil/issues/24) [@toy](https://github.com/toy)

## v2.5.0 (2019-08-21)

* Allow switching default formatter to json, json-pretty and new-default (comma separated key-value pairs) [#17](https://github.com/toy/blueutil/issues/17) [@toy](https://github.com/toy)
* Add instructions to install from [MacPorts](https://www.macports.org/) [@toy](https://github.com/toy)
* Specify 10.9 as the minimum version explicitly [#16](https://github.com/toy/blueutil/issues/16) [@toy](https://github.com/toy)

## v2.4.0 (2019-01-25)

* Change license to MIT with [permission from Frederik Seiffert](https://github.com/toy/blueutil/issues/14#issuecomment-455985947) [#14](https://github.com/toy/blueutil/issues/14) [#15](https://github.com/toy/blueutil/pull/15) [@toy](https://github.com/toy)

## v2.3.0 (2019-01-14)

* Add pairing functionality [#13](https://github.com/toy/blueutil/issues/13) [@toy](https://github.com/toy)
* Add headings and install instructions to README [#11](https://github.com/toy/blueutil/pull/11) [@friedrichweise](https://github.com/friedrichweise)

## v2.2.0 (2018-10-11)

* Add ability to connect, disconnect, get information about, and check connected state of device by address or name from the list of recent devices [mentioned in #9](https://github.com/toy/blueutil/issues/9) [@toy](https://github.com/toy)
* Add inquiring devices in range and listing favourite, paired and recent devices [#9](https://github.com/toy/blueutil/issues/9) [@toy](https://github.com/toy)
* Fix missing newline after message about unexpected state value [@toy](https://github.com/toy)
* Set deployment target to 10.6 [@toy](https://github.com/toy)

## v2.1.0 (2018-04-19)

* Add ability to toggle power and discoverability state [#8](https://github.com/toy/blueutil/issues/8) [@toy](https://github.com/toy)
* Add note about effect of opening bluetooth preference pane on discoverability [suggested in #3](https://github.com/toy/blueutil/issues/3) [@toy](https://github.com/toy)
* Update xcode project to compatibility version 3.2 [missing part of #7](https://github.com/toy/blueutil/issues/7) [@toy](https://github.com/toy)

## v2.0.0 (2018-02-18)

* Change arguments specification to Unix/POSIX style [#7](https://github.com/toy/blueutil/issues/7) [@toy](https://github.com/toy)
* Don’t show the WARNING when piping yes to the test script [@toy](https://github.com/toy)
* Make error message for discoverable consistent [@toy](https://github.com/toy)
* Run make install/uninstall commands instead of only printing them [@toy](https://github.com/toy)

## v1.1.2 (2017-02-04)

* Add a warning and confirmation to the test script for users of wireless input devices [#6](https://github.com/toy/blueutil/issues/6) [@toy](https://github.com/toy)
* Add proper make targets: build (default), test, clean, install and uninstall [@toy](https://github.com/toy)
* Fix wrong handling of length in is_abbr_arg [#6](https://github.com/toy/blueutil/issues/6) [@toy](https://github.com/toy)

## v1.1.0 (2017-02-01)

* Add basic makefile as an alternative to using xcode [@toy](https://github.com/toy)
* Add simple test script for getting/setting power/discoverability [@toy](https://github.com/toy)
* Allow abbreviating help, version and status commands [@toy](https://github.com/toy)
* Add version command [@toy](https://github.com/toy)
* Restore waiting for state to change after setting it, check every 0.1 second for 10 seconds [@toy](https://github.com/toy)
* Add help command [@toy](https://github.com/toy)
* Restore original style arguments: status, on, off [#4](https://github.com/toy/blueutil/issues/4) [@toy](https://github.com/toy)
* Allow abbreviating power and discoverable arguments [@toy](https://github.com/toy)

## v1.0.0 (2012-02-26)

* Switch to unconditionally waiting 1 second after setting value as waiting for result to change was not working [@toy](https://github.com/toy)
* Allow getting and setting discoverable state alongside power state, use 1/0 instead of on/off [@toy](https://github.com/toy)
* Import original code by Frederik Seiffert [@triplef](https://github.com/triplef) from http://frederikseiffert.de/blueutil
