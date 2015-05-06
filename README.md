# usbkill

usbkill waits for a change on your USB ports, then immediately turns off
your computer without prompts or signaling other open applications.
Depending on your point of view, it's an un-clean shutdown and may
trigger fsck or other file integrity checks on re-start.

It works on Mac OS X and Ubuntu.

To run: sudo usbkill.sh

## Why?
This is for the security paranoid - if law enforcement surprises you or
confiscates your laptop from you when you are at a public library.

Law enforcement will use a "mouse jiggler" [0] to keep the screensaver
and sleep mode from activating. If someone inserts a mouse jiggler, it
would be much more secure for the laptop to immediately turn off,
re-protecting all your data with your whole-disk encryption.

The usbkill daemon monitors for devices that are inserted since it
started running and for devices that were removed since it started.

A settings file at `/etc/usbkill/settings` can be configured to use a
list of whitelisted USB devices so that you may still use an external
mouse or USB storage device you trust. The check interval can also be
modified - the default is to check every second.

Make sure to use whole-disk encryption! Otherwise, your adversary will
just re-start the computer and make a copy of all your files.

[0] http://www.amazon.com/gp/product/B00MTZY7Y4/ref=as_li_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=B00MTZY7Y4&linkCode=as2&tag=deekayen-20&linkId=H362AOTAVTL2CVPZ

# Contact
david@dkn.email - 7E38 B4FF 0A7C 2F28 5C31  2C8C EFD7 EC8D B5D4 C172
