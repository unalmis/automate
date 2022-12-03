# Additional setup tips

Below is a collection of tips and guides that may be useful.

---

## Nvidia drivers with secure boot on Fedora 36+

This guide is based on the following sources.

- [RPM Fusion configuration](https://rpmfusion.org/Configuration/)
- [RPM Fusion secure boot](https://rpmfusion.org/Howto/Secure%20Boot)
- [RPM Fusion Nvidia](https://rpmfusion.org/Howto/NVIDIA)

Before continuing, make sure you currently have secure boot enabled and do not
have proprietary Nvidia drivers installed.

### Installation

```sh
# ensure secure boot is enabled
fwupdmgr security

# If it is not already enabled, enable rpm fusion nonfree repository.
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf group upgrade core
```

```sh
# to automatically rebuild and sign on boot
sudo dnf install akmods
# Now there should be instructions in '/usr/share/doc/akmods/README.secureboot'.
# Read it to ensure the instructions I am providing are not out of date.

# create the self generated key and certificate
sudo kmodgenca -a

# Enroll the key with a secure password.
# Save the password to your password manager.
# (need to use sudo)
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

# On next boot, MOK management is launched.
# Choose 'Enroll MOK' then 'Continue' to enroll the key.
# Confirm enrollment by selecting 'Yes'.
# Enter the password generated above.
reboot

# to confirm the enrollment of the new keypair
# should see an issuer with 'akmods' somewhere
mokutil --list-enrolled | grep Issuer

# install the Nvidia driver
sudo dnf install akmod-nvidia

# WAIT at least 5 minutes after the last command finishes for the kmod to build.
# Good time for a coffee break.

reboot
```

The signing key will stay there until you delete it from MOK management or reset
the secure boot keys to defaults in UEFI. The Nvidia drivers should (in theory)
get signed automatically after any driver or kernel upgrade.

Note that new kernels may drop support for old drivers. This would cause the
Nvidia drivers to fail building on the new kernel. To minimize risk, delay
kernel upgrades.

### Back up keys (optional)

Make encrypted backups of the
1. private key in `/etc/pki/akmods/private/`
2. public key in `/etc/pki/akmods/certs/`
3. akmod key generated from `mokutil --export`

### Removal

If you decide to remove the `akmod-nvidia` package, you should also delete the
signing key.

1. The output of `mokutil --list-enrolled` shows the enrolled keys in order
2. If the akmod key was labeled key 2, its key number should be `0002`
3. Mark the akmod key for deletion
    - `mokutil --export`
    - `sudo mokutil --delete MOK-0002.der` would mark key 2 for deletion
    - Create a password which you will later use to delete the key
4. On reboot, MOK management will appear
    - The numbering of the keys in MOK management differs from step 1, so try to
    remember an identifying detail of the akmod key to delete the correct key

---

## Pairing Apple airpods with Linux machines

The initial pairing process with Linux machines has a bug. To connect them,
follow these instructions. This only needs to be done once.

Before continuing, turn off bluetooth on Apple devices so they don't hijack the
connection. Also close your airpods in their case.

If you have previously attempted to pair your airpods, you need to remove them
from the bluetooth connections list.

```sh
bluetoothctl
[bluetooth]# devices
# A list of bluetooth devices with a KEY delemited by colons should be shown.
[bluetooth]# remove KEY
[bluetooth]# exit
```

Now we will edit the bluetooth configuration file.

```sh
# Turn off bluetooth.
sudo nano /etc/bluetooth/main.conf
# Uncomment the line with 'ControllerMode = dual' by removing leading hashtag.
# Change 'dual' to 'bredr'.
# You can exit nano (the text editor) with ctrl+o, enter, then ctrl+x.
# Log out and turn on bluetooth on next log in.
```

You may now pair your airpods using the settings GUI. After a successful
connection, disconnect your airpods and close them in their case. Revert the
changes to the bluetooth configuration file and restart bluetooth.

From now on, your airpods should connect automatically. You should not need to
edit the bluetooth configuration file again.

To use your airpods as both speakers and microphone, make sure to enable them as
both output and input devices under sound in the settings GUI.

---

## Recommended web browser extensions

- [Bitwarden](https://bitwarden.com/download/)
- [old reddit redirect](https://github.com/tom-james-watson/old-reddit-redirect#old-reddit-redirect)
- [uBlock Origin](https://github.com/gorhill/uBlock#ublock-origin-ubo)
    - Enable `AdGuard Annoyances` and `uBlock filters - Annoyances` filters
- [Zotero connector](https://www.zotero.org/download/connectors)

---

## Web apps

Chromium supports [progressive web apps](https://en.wikipedia.org/wiki/Progressive_web_app).

If a website has a PWA, a prompt to install it will show in the url bar.
Otherwise, you can make a web app with `Customize and control Chromium` ->
`More tools` -> `Create shortcut`.

An advantage of web apps is that they remain sandboxed. Extensions like uBlock
Origin will also work in them. For the Spotify web app, this means playback
lacks ads.

- [Gmail](https://mail.google.com/mail/u/0/#inbox)
- [GroupMe](https://web.groupme.com/)
- [Instagram](https://www.instagram.com/)
- [LinkedIn](https://www.linkedin.com/)
- [Outlook](https://outlook.office.com/mail/)
- [Snapchat](https://web.snapchat.com/)
- [Spotify](https://open.spotify.com/)
- [WhatsApp](https://web.whatsapp.com/)

---

## File security

Some versions of Windows OS set the executable bit on files by default.
This is bad for security.

Check that only files you plan to execute have this permission.

```sh
# find all executable files in the current directory, recursively
find . -type f -executable -print
```

Make sure you're in the right directory before using the following command.
Do not use this in a directory which contains files that should be executable.

```sh
# remove executable bit from all files in the current directory, recursively
find . -type f -execdir chmod -x '{}' '+'
```

---

## Terminal shortcuts

Create soft links of my programs in the user's local bin, which allows running
the program from any directory:

```sh
mkdir -p "${HOME}/.local/bin"
# replace first path with your path to the file
ln -s "${HOME}/Documents/project/automate/source/fission.sh" "${HOME}/.local/bin/fission.sh"
ln -s "${HOME}/Documents/project/automate/source/linearize.sh" "${HOME}/.local/bin/linearize.sh"
ln -s "${HOME}/Documents/project/automate/source/mitosis.sh" "${HOME}/.local/bin/mitosis.sh"
ln -s "${HOME}/Documents/project/automate/source/pull.sh" "${HOME}/.local/bin/pull.sh"
ln -s "${HOME}/Documents/project/automate/source/replace.sh" "${HOME}/.local/bin/replace.sh"
```
