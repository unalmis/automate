# Tips

Below is a collection of tips and guides that may be useful.

---

## Nvidia drivers with secure boot on Fedora 36+

This guide is based on the following sources:

- [RPM Fusion configuration](https://rpmfusion.org/Configuration/)
- [RPM Fusion secure boot](https://rpmfusion.org/Howto/Secure%20Boot)
- [RPM Fusion Nvidia](https://rpmfusion.org/Howto/NVIDIA)

Before continuing, make sure you currently have secure boot enabled and do not
have proprietary Nvidia drivers installed.

### Installation

```sh
# ensure secure boot is enabled
fwupdmgr security

# if it is not already enabled, enable rpm fusion nonfree repository
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf group upgrade core
```

```sh
# to automatically rebuild and sign on boot
sudo dnf install akmods
# Now there should be instructions in '/usr/share/doc/akmods/README.secureboot'.
# Read it to ensure the instructions I am providing are not out of date.

# generate a signing key
sudo kmodgenca -a

# Enroll the key with a secure password.
# Save the password to your password manager.
# (need to use sudo)
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

# On next boot, MOK Management is launched.
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

The signing key should stay there until you delete it from MOK management or
perhaps reset the UEFI to defaults. The Nvidia drivers should (in theory) get
signed automatically after any driver or kernel update.

### Back up keys

Make encrypted backups of the
1. private key in `/etc/pki/akmods/private/`
2. public key in `/etc/pki/akmods/certs/`
3. akmod key generated from `mokutil --export`

### Removal

If you decide to remove the `akmod-nvidia` package, you should also delete the
signing key.

You may find the `mokutil --help` command helpful.

1. The output of `mokutil --list-enrolled` shows the enrolled keys in order
2. If the akmod key was labeled key 2, its key number should be `0002`
3. Mark the akmod key for deletion
    - `mokutil --export`
    - `sudo mokutil --delete MOK-0002.der` would mark key 2 for deletion
    - Create a password which you will later use to delete the key
4. On reboot, MOK management will appear
    - The numbering of the keys in MOK management may differ from step 1, so you
    should remember some of the akmod key's details to delete the correct key

---

## Pairing Apple airpods with Linux machines

The initial pairing process with Linux machines currently has a bug. Below is a
patch that actually works. You only have to do this when pairing airpods for
the first time.

```sh
# turn off bluetooth on Apple devices so they don't hijack the connection
# put airpods back in case
# turn off bluetooth on Linux machine

# uncomment ControllerMode = dual
# change 'dual' to 'bredr'
sudo nano /etc/bluetooth/main.conf

# turn on bluetooth on Linux machine
# pair airpods then put airpods back in case
# turn off bluetooth on Linux machine
# revert your changes
sudo nano /etc/bluetooth/main.conf
```

---

## File security

Some versions of Windows OS set the executable bit on files by default.
This is bad for security.
You should check that only files you plan to execute have this permission.

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

## Customize Gnome

Add buttons to minimize and maximize windows:

```sh
# default key is 'appmenu:close'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
```

Reset window button layout:

```sh
gsettings reset org.gnome.desktop.wm.preferences button-layout
```

---

## Terminal shortcuts

Create soft links of my programs in the user's local bin, which allows running
the program from any directory:

```sh
mkdir -p "${HOME}/.local/bin"
# replace first path with your path to the file
ln -s "${HOME}/Documents/project/automate/fission.sh" "${HOME}/.local/bin/fission.sh"
ln -s "${HOME}/Documents/project/automate/linearize.sh" "${HOME}/.local/bin/linearize.sh"
ln -s "${HOME}/Documents/project/automate/mitosis.sh" "${HOME}/.local/bin/mitosis.sh"
ln -s "${HOME}/Documents/project/automate/pull.sh" "${HOME}/.local/bin/pull.sh"
ln -s "${HOME}/Documents/project/automate/replace.sh" "${HOME}/.local/bin/replace.sh"
```

---

## Recommended web browser extensions

- [Bitwarden](https://bitwarden.com/download/)
- [old reddit redirect](https://github.com/tom-james-watson/old-reddit-redirect)
- [uBlock Origin](https://github.com/gorhill/uBlock#ublock-origin)
    - Enable `AdGuard Annoyances` and `uBlock filters - Annoyances` filters
- [Zotero connector](https://www.zotero.org/download/connectors)
