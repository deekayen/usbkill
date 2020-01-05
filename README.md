# usbkill

[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)

`usbkill` waits for a change on your USB ports, then immediately turns
off your computer without prompts or signaling other open applications.
Depending on your point of view, it's an un-clean shutdown and may
trigger fsck or other file integrity checks on re-start even though
the `poweroff` signal syncs open files to disk first.

It works on Mac OS X and Ubuntu.

To run:

```shell
sudo usbkill.sh
```

## Linux

Try adding `usbkill.sh` to your `/etc/rc.local`. Any USB device
changes not whitelisted in `/etc/usbkill/settings` will cause your
computer to shutdown.

## Mac OS

Unlike the
[original Python-based version](https://github.com/hephaest0s/usbkill),
this Bash version does not require any additional programs like
`python3` or `lsusb` to be installed.

## Example configuration

The first run will create a default settings file at `/etc/usbkill/settings` with an empty whitelist. On MacOS, check the USB section of the System Information application for the Product ID. Alternatively, run `system_profiler SPUSBDataType` from a terminal to list connected USB devices.

```
# whitelist command lists the usb ids that you want whitelisted
# find the correct usbid for your trusted usb using
# the command 'system_profiler SPUSBDataType'
# Look for the Product ID, like 0x1a10
# Be warned! other parties can copy your trusted usbid to another usb device!
# Use whitelist command and single space separation as follows:
# for Mac:
# whitelist=( "0x0024" "0x8510" "0x0024" "0x2512" "0x4500" "0x8286" "0x0262" )
# for Linux:
# whitelist=( "8087:8000" "1d6b:0002" "0781:5580" "1d6b:0003" "0489:e056" "1bcf:2c67" "1d6b:0002" )
whitelist=( )

# allow for a certain amount of sleep time between checks, e.g. 1 second:
sleep=1
```

## Why?
This is for the security paranoid - if law enforcement surprises you or
confiscates your laptop from you when you are at a public library.

* Law enforcement will use a
[mouse jiggler](http://www.amazon.com/gp/product/B00MTZY7Y4/ref=as_li_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=B00MTZY7Y4&linkCode=as2&tag=deekayen-20&linkId=H362AOTAVTL2CVPZ)
to keep the screensaver and sleep mode from activating. If someone
inserts a mouse jiggler, it would be much more secure for the laptop to
immediately turn off, re-protecting all your data with your whole-disk
encryption.
* Blocking unauthorized USB devices prevents installing backdoors or
malware on your computer or to retrieve documents from your computer via
USB.

The usbkill daemon monitors for devices that are inserted since it
started running and for devices that were removed since it started.

A settings file at `/etc/usbkill/settings` can be configured to use a
list of whitelisted USB devices so that you may still use an external
mouse or USB storage device you trust. The check interval can also be
modified - the default is to check every second.

Make sure to use whole-disk encryption! Otherwise, your adversary will
just re-start the computer and make a copy of all your files.

### Other nasty ideas

Bash can trap signals to close `usbkill`, however a `kill -9` probably
won't get trapped. The other signals could still be trapped
and cause the computer to shutdown when the script is signaled to close.
Unfortunately, this can cause your computer to always have an unclean
shutdown since a normal shutdown would still signal the script to close
and thereby cause a premature `poweroff` event.

# Contact

[david@dkn.email](mailto:david@dkn.email)

## PGP/GPG Fingerprint

7E38 B4FF 0A7C 2F28 5C31  2C8C EFD7 EC8D B5D4 C172

## Issues

https://github.com/deekayen/usbkill
