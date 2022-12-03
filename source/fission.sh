#!/bin/sh
# ------------------------------------------------------------------------------
# @author      Kaya Unalmis
# @license     GNU GPLv3
# @date        2022 October 23
# @command     sh fission.sh
# @description Set up and maintain RPM or Debian based systems
#              (tested on Fedora and Ubuntu)
# ------------------------------------------------------------------------------

# This code mostly avoids operating system specific routines.
# When it should not be avoided, the OS is inferred as documented below.
# https://www.freedesktop.org/software/systemd/man/os-release.html

# The standard practice is to put user executables in the user's local bin.
# https://www.freedesktop.org/software/systemd/man/file-hierarchy.html#~/.local/bin/
USER_BIN="${HOME}/.local/bin"

# path to store .AppImage files (feel free to change)
APPIMAGE_PATH="${HOME}/appimage/"

# To avoid use of multiple system package managers,
# the set_manager_priority() function assigns which ones to use.
USE_DNF='False'
USE_APT='False'
USE_FLAT='False'
USE_SNAP='False'

# Only one apt process at a time should be live.
# A timeout set to -1 seconds will wait for a live apt process to finish.
# @citation Chris Sinjakli,
# https://blog.sinjakli.co.uk/2021/10/25/waiting-for-apt-locks-without-the-hacky-bash-scripts/
WAIT_APT='DPkg::Lock::Timeout=-1'

# output text settings
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)

# read without echoing input to terminal
read_silent() {
    # POSIX shell does not support the 'read -s' bash command.
    # @citation Adapted from: Susam Pal, https://stackoverflow.com/a/28393320

    terminal_settings=$(stty --save) # save current settings

    # EXIT: signal via exit command
    # HUP: hang up signal via closing the terminal
    # INT: interrupt signal via ctrl+c
    # TERM: terminate signal
    # ensure terminal settings are restored if the program stops
    trap 'stty "$terminal_settings"; trap - EXIT; exit' EXIT HUP INT TERM

    stty -echo # disable terminal echo
    read -r REPLY
    stty "$terminal_settings" # restore terminal settings
    trap - EXIT HUP INT TERM  # unset traps
    printf '\n'
}

# return true if the user replies 'yes', false if the user replies 'no'
reply_yes() {
    printf '%s (%s / %s) ' "$1" "${GREEN}yes${NORMAL}" "${YELLOW}no${NORMAL}"
    read -r REPLY
    case "$REPLY" in
        yes) return 0 ;;
        no) return 1 ;;
    esac
    reply_yes
}

# is the queried app installed?
is_installed() {
    if [ $# -eq 1 ]; then # if number of arguments is 1
        command -v -- "$1" 1>/dev/null
    elif [ "$1" = 'flatpak' ]; then
        if is_installed 'flatpak'; then
            flatpak list --app --columns application | grep -q --line-regexp -- "$2"
        fi
    elif [ "$1" = 'snap' ]; then
        is_installed 'snap' && snap list | grep -q --word-regexp -- "$2"
    elif [ "$1" = 'gnome extension' ]; then
        is_installed 'gnome-extensions' && gnome-extensions list | grep -q --line-regexp -- "$2"
    elif [ "$1" = 'office extension' ]; then
        is_installed 'unopkg' && unopkg list | grep -q --word-regexp -- "$2"
    else
        return 1 # false
    fi
}

# set priority for the duration of this program to avoid conflicts
set_manager_priority() {
    is_installed 'dnf' && USE_DNF='True'
    is_installed 'apt' && USE_APT='True'
    if [ "$USE_DNF" = 'True' ] && [ "$USE_APT" = 'True' ]; then
        if reply_yes 'Detected two package managers. Use dnf instead of apt?'; then
            USE_APT='False'
        else
            USE_DNF='False'
        fi
    fi

    is_installed 'flatpak' && USE_FLAT='True'
    is_installed 'snap' && USE_SNAP='True'
    if [ "$USE_FLAT" = 'True' ] && [ "$USE_SNAP" = 'True' ]; then
        if reply_yes 'Detected two package managers. Use flatpak instead of snap?'; then
            USE_SNAP='False'
        else
            USE_FLAT='False'
        fi
    fi
}

# ------------------------------------------------------------------------------

# good for security
enable_firewall() {
    if is_installed 'firewalld'; then
        # https://docs.fedoraproject.org/en-US/quick-docs/firewalld/#starting-firewalld-fedora
        if ! firewall-cmd -q --state; then
            printf '%s\n' 'Enabling the firewall...'
            sudo systemctl enable firewalld
        fi
    elif is_installed 'ufw'; then
        printf '%s\n' 'Checking if firewall is active...'
        if sudo ufw status | grep -q --word-regexp 'inactive'; then
            printf '%s\n' 'Enabling the firewall...'
            sudo ufw enable
        fi
    fi
}

set_battery_charge_thresholds() {
    # https://support.system76.com/articles/laptop-battery-thresholds/
    # Linux kernel API states these files control charge thresholds.
    # https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-power
    control_lo='/sys/class/power_supply/BAT0/charge_control_start_threshold'
    control_hi='/sys/class/power_supply/BAT0/charge_control_end_threshold'
    # If the files do not exist, battery charge thresholds are not supported.
    [ -f "$control_lo" ] && [ -f "$control_hi" ] || return 0

    # pause to give user time to read previous screen
    printf 'Press enter to continue. '
    read_silent
    clear
    cat <<BATTERY
    Charging thresholds allow your machine to avoid charging the battery
    until it has dropped below a lower bound (the start threshold),
    and to stop charging when it reaches an upper bound (the end threshold).

    This is useful if your machine is often plugged into an AC power
    adapter, as it prevents unnecessary micro-charging that would reduce
    battery longevity.

                      start:end
    1) ${YELLOW}full charge${NORMAL}       96:99
    2) ${CYAN}balanced${NORMAL}          85:90
    3) ${GREEN}max lifespan${NORMAL}      40:50

BATTERY

    # threshold values from https://support.lenovo.com/us/en/solutions/
    # ht078208-how-can-i-increase-battery-life-thinkpad-and-lenovo-vbke-series-notebooks
    printf 'Select an option: '
    read -r REPLY
    lo='96'
    hi='99'
    case "$REPLY" in
        2)
            lo='85'
            hi='90'
            ;;
        3)
            lo='40'
            hi='50'
            ;;
    esac
    # write values to protected files
    # silence stderr as tee incorrectly complains file is invalid
    sudo --remove-timestamp
    printf '%s\n' "$lo" | sudo tee "$control_lo" 1>/dev/null 2>/dev/null
    printf '%s\n' "$hi" | sudo tee "$control_hi" 1>/dev/null 2>/dev/null
}

tweak_git() {
    is_installed 'git' || return 0

    git config --global init.defaultBranch main
    printf '%s\n' 'Default git branch set to main'
    git config --global fetch.prune true
    printf '%s\n' 'Git fetch with prune'
    git config --global pull.ff only
    printf '%s\n' 'Fast forward git pull only'
    if reply_yes 'Sign git commits automatically?'; then
        git config --global commit.gpgsign true
        # git config --global user.signingkey KEY
        # You can find your KEY using the below command.
        # gpg --list-secret-keys --keyid-format=long
    fi
    if reply_yes 'Set global git commit credentials?'; then
        printf 'Enter your git commit username: '
        read -r git_username
        git config --global user.name "$git_username"
        printf 'Enter your git commit email: '
        read -r git_email
        git config --global user.email "$git_email"
    fi
    printf '\n'
}

tweak_gnome() {
    is_installed 'gsettings' || return 0

    if is_installed 'gnome-shell'; then
        gsettings set org.gnome.shell app-picker-layout '[]'
        printf '%s\n' 'Applications menu sorted'
    fi
    gsettings set org.gnome.desktop.privacy recent-files-max-age 30
    printf '%s\n' 'File history retention reduced to 30 days'
    gsettings set org.gnome.desktop.privacy remove-old-trash-files true
    gsettings set org.gnome.desktop.privacy remove-old-temp-files true
    printf '%s\n' 'Trash and temporary file retention reduced to 30 days'

    button_layout=$(gsettings get org.gnome.desktop.wm.preferences button-layout)
    if [ "$button_layout" = 'appmenu:close' ]; then
        if reply_yes 'Add buttons to minimize and maximize windows?'; then
            button_layout='appmenu:minimize,maximize,close'
            gsettings set org.gnome.desktop.wm.preferences button-layout "$button_layout"
        # reset to default with: gsettings reset org.gnome.desktop.wm.preferences button-layout
        fi
    fi
    printf '\n'
}

tweak_text_editor() {
    if is_installed 'gnome-text-editor' && ! is_installed 'gedit'; then
        gsettings set org.gnome.TextEditor show-line-numbers true
        printf '%s\n' 'Text editor set to show line numbers'
        gsettings set org.gnome.TextEditor right-margin-position 'uint32 100'
        gsettings set org.gnome.TextEditor show-right-margin true
        printf '%s\n' 'Text editor right margin position set to 100'
        gsettings set org.gnome.TextEditor indent-style 'space'
        gsettings set org.gnome.TextEditor tab-width 'uint32 4'
        printf '%s\n' 'Text editor tabs set to 4 spaces'
        gsettings set org.gnome.TextEditor restore-session false
        printf '%s\n' 'Text editor will not restore previous session on start'
        printf '\n'
    fi
    # terminal text editor
    if is_installed 'nano' && [ ! -f "${HOME}/.nanorc" ]; then
        printf '%s\n%s\n%s\n' 'set tabsize 4' 'set tabstospaces' 'set trimblanks' \
            >"${HOME}/.nanorc"
    fi
}

# driver function that calls subroutines
tweak_settings() {
    printf '\n'
    enable_firewall
    tweak_git
    tweak_gnome
    tweak_text_editor
    set_battery_charge_thresholds
}

# ------------------------------------------------------------------------------

# upgrade dnf or apt, flatpak or snap, conda, and firmware
upgrade_system() {
    if [ "$USE_DNF" = 'True' ]; then
        sudo dnf --refresh upgrade
        sudo dnf autoremove
    elif [ "$USE_APT" = 'True' ]; then
        # safer and more robust than simply doing 'apt update && apt upgrade'
        sudo apt-get -qq --option "$WAIT_APT" autoclean
        sudo apt-get -y --fix-missing --option "$WAIT_APT" update \
            && sudo dpkg --configure -a
        sudo apt-get -qq --fix-broken --option "$WAIT_APT" install
        sudo apt-get --option "$WAIT_APT" full-upgrade
        sudo apt-get -q --option "$WAIT_APT" autopurge
    fi

    if [ "$USE_FLAT" = 'True' ]; then
        flatpak update -y
        flatpak uninstall -y --noninteractive --delete-data --unused
    elif [ "$USE_SNAP" = 'True' ]; then
        sudo snap refresh
    fi

    # Some conda base environments are read-only.
    # https://src.fedoraproject.org/rpms/conda
    # Attempts to update them will yield an ignorable 'NoBaseEnvironmentError'.
    if is_installed 'conda'; then
        conda update -q -y --name base --all
        conda clean -q -y --all
    fi

    if [ -f '/var/run/reboot-required' ]; then
        reply_yes 'I need to reboot. Reboot?' && reboot
    fi

    if is_installed 'fwupdmgr' && [ -f '/sys/class/power_supply/AC/online' ]; then
        read -r is_plugged_in <'/sys/class/power_supply/AC/online'
        if [ "$is_plugged_in" = '1' ] && reply_yes 'Upgrade firmware?'; then
            fwupdmgr --force refresh && fwupdmgr update
        fi
    fi
}

# ------------------------------------------------------------------------------

# https://bitwarden.com/
install_bitwarden() {
    if [ "$USE_SNAP" = 'True' ]; then
        sudo snap install bitwarden
        return
    fi

    if [ -d "$APPIMAGE_PATH" ]; then
        app=$(find "$APPIMAGE_PATH" -type f -iname 'Bitwarden*.AppImage' -print -quit)
        [ -f "$app" ] && return 0 # already installed
    fi
    reply_yes 'Install Bitwarden?' || return 0

    app='Bitwarden.AppImage'
    url='https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage'
    if wget -q --output-document "$app" "$url"; then
        chmod +x "$app"
        mkdir --parents "$APPIMAGE_PATH"
        mv "$app" "$APPIMAGE_PATH"
        printf '%s %s%s%s\n' 'Downloaded to' "$CYAN" "${APPIMAGE_PATH}${app}" "$NORMAL"
    fi
}

# https://code-industry.net/masterpdfeditor/
install_master_pdf_editor() {
    if is_installed 'masterpdfeditor5' \
        || ! reply_yes 'Install Master PDF editor? (needs license)'; then
        return 0
    fi

    url='https://code-industry.net/public/'
    app="master-pdf-editor-5.9.10-qt5.$(arch)"
    if [ "$USE_DNF" = 'True' ]; then
        sudo dnf -q -y install "${url}${app}.rpm"
    elif [ "$USE_APT" = 'True' ] && wget -q "${url}${app}.deb"; then
        sudo apt-get -qq --option "$WAIT_APT" install "./${app}.deb"
        rm --force -- "${app}.deb"
    fi
}

# https://reference.wolfram.com/language/tutorial/InstallingMathematica.html
install_mathematica() {
    if is_installed 'mathematica' || ! reply_yes 'Install Mathematica? (needs license)'; then
        return 0
    fi

    url='https://account.wolfram.com/download/mathematica/desktop/LINUX?type=full'
    xdg-open "$url" 1>/dev/null 2>/dev/null
    printf 'When the download finishes, press enter to continue. '
    read_silent

    app=$(find "${HOME}/Downloads" -type f -name 'Mathematica_*_LINUX.sh' -print -quit)
    [ -f "$app" ] || return 1
    if bash "$app" -- -auto -execdir="$USER_BIN" -selinux='n' -targetdir="${HOME}/mathematica"; then
        rm --force -- "$app"
    fi
}

install_matlab() {
    if is_installed 'matlab' || ! reply_yes 'Install Matlab? (needs license)'; then
        return 0
    fi

    cat <<MATLAB

    The matlab GUI installer will ask some questions.
    For it to work properly, you should answer:
    1. Install matlab in ${CYAN}${HOME}/matlab${NORMAL}
    2. Put links in ${CYAN}${USER_BIN}${NORMAL}
    3. Set user name to ${CYAN}${USER}${NORMAL}

    Once installed, you can enter ${CYAN}matlab${NORMAL} in terminal to start it.

    If installation fails, try again after temporarily switching to a Xorg session.
    https://docs.fedoraproject.org/en-US/quick-docs/configuring-xorg-as-default-gnome-session/

    You can also use matlab from a web browser.
    https://matlab.mathworks.com

MATLAB

    app_tmp="${HOME}/Downloads/matlab_tmp"
    if [ ! -d "$app_tmp" ]; then
        xdg-open 'https://www.mathworks.com/downloads/' 1>/dev/null 2>/dev/null
        printf 'When the download finishes, press enter to continue. '
        read_silent

        app_zip=$(find "${HOME}/Downloads" -type f -name 'matlab_R*_glnxa64.zip' -print -quit)
        [ -f "$app_zip" ] && unzip -q "$app_zip" -d "$app_tmp"
        rm --force -- "$app_zip"
    fi
    [ -d "$app_tmp" ] && sh "${app_tmp}/install" && rm --recursive --force -- "$app_tmp"
}

# enables playing various videos and audios
install_media_codecs() {
    reply_yes 'Install media codecs?' || return 0

    if [ "$USE_DNF" = 'True' ] && grep -q 'ID=fedora' '/etc/os-release'; then
        # https://rpmfusion.org/Configuration
        # rpm fusion free    needed for ffmpeg-libs, which has the H.264 codec
        # rpm fusion nonfree needed for drivers and hardware acceleration
        free='https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-'
        nonfree='https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-'
        version=$(rpm --eval %fedora)
        sudo dnf -y install "${free}${version}.noarch.rpm"
        sudo dnf install "${nonfree}${version}.noarch.rpm"
        sudo dnf group upgrade core # show rpm fusion repositories in software GUI

        sudo dnf -y install ffmpeg-libs gstreamer1-plugin-libav \
            gstreamer1-plugins-base 'gstreamer1-plugins-good-*'
        # https://docs.fedoraproject.org/en-US/quick-docs/
        # assembly_installing-plugins-for-playing-movies-and-music/
        # Although recommended in the link above, we forgo installing the packages listed below.
        # 1. non-existent 'Multimedia' group
        # 2. 'lame*'
        #    mp3 patents expired in 2016, allowing Fedora to ship with mp3 support
        # 3. gstreamer1-libav
        #    replaced with 'gstreamer1-plugin-libav' in fedora 37+ repo
        # 4. 'gstreamer1-plugins-ugly-*'
        #    use VLC media player instead to avoid licensing issues
        # 5. 'gstreamer1-plugins-bad-*'
        #    use VLC to play media which needs such codecs instead of these bad quality plugins
        # 6. gstreamer1-plugin-openh264
        #    Cisco's H.264 codec has awful performance compared to ffmpeg's

        printf '\n%s %s%s%s\n\n' 'For hardware acceleration drivers, see' \
            "$CYAN" 'https://rpmfusion.org/Howto/Multimedia' "$NORMAL"

    elif [ "$USE_APT" = 'True' ] && grep -q 'ID=ubuntu' '/etc/os-release'; then
        # https://help.ubuntu.com/community/RestrictedFormats
        # I recommend ubuntu-restricted-extras even on ubuntu derivatives.
        # The [k,l,x]ubuntu-restricted-extras packages are not well maintained.
        sudo apt-get -qq --option "$WAIT_APT" install ubuntu-restricted-extras \
            ttf-mscorefonts-installer- unrar- # trailing dash prevents install
    fi
}

# https://conda.io/projects/conda/en/latest/user-guide/install/linux.html
install_miniconda() {
    if is_installed 'conda' || ! reply_yes 'Install Miniconda?'; then
        return 0
    fi

    app="Miniconda3-latest-Linux-$(arch).sh"
    wget -q "https://repo.anaconda.com/miniconda/$app" && bash "$app"
    rm --force -- "$app"
    # alternatives (not recommended)
    # dnf install conda
    # https://conda.io/projects/conda/en/latest/user-guide/install/rpm-debian.html
}

# https://extensions.gnome.org/extension/2236/night-theme-switcher/
install_night_theme_switcher() {
    # https://gitlab.com/rmnvgr/nightthemeswitcher-gnome-shell-extension
    # #something-doesnt-work-on-ubuntu
    grep -q 'ID=ubuntu' '/etc/os-release' && return 0 # Ubuntu is not supported.

    app_uuid='nightthemeswitcher@romainvigier.fr'
    if is_installed 'gnome extension' "$app_uuid"; then
        if gnome-extensions info "$app_uuid" | grep -q --ignore-case 'state: initialized'; then
            # need to enable extensions on the next login session after installation
            # initialized state implies the extension was never enabled (or disabled)
            gnome-extensions enable "$app_uuid"
        fi
        return 0
    fi
    is_installed 'gnome-extensions' && reply_yes 'Install Night theme switcher?' || return 0

    gnome_version=$(gnome-extensions version | cut --characters -2)
    if [ "$gnome_version" -eq 43 ] 2>/dev/null; then
        app_version='71'
    elif [ "$gnome_version" -eq 42 ] 2>/dev/null; then
        app_version='65'
    else
        return 1
    fi
    app="nightthemeswitcherromainvigier.fr.v${app_version}.shell-extension.zip"
    wget -q "https://extensions.gnome.org/extension-data/$app" && gnome-extensions install "$app"
    rm --force -- "$app"
}

# https://protonvpn.com/support/linux-vpn-setup/
install_proton_vpn() {
    if is_installed 'protonvpn' || ! reply_yes 'Install Proton VPN?'; then
        return 0
    fi

    if [ "$USE_DNF" = 'True' ]; then
        url='https://repo.protonvpn.com/fedora-36-stable/release-packages/'
        app='protonvpn-stable-release-1.0.1-1.noarch.rpm'
        sudo dnf -q -y install "${url}${app}" && sudo dnf -q -y --refresh install protonvpn

    elif [ "$USE_APT" = 'True' ]; then
        url='https://repo.protonvpn.com/debian/dists/stable/main/binary-all/'
        app='protonvpn-stable-release_1.0.3_all.deb'
        wget -q "${url}${app}" \
            && sudo apt-get -qq --option "$WAIT_APT" install "./$app" \
            && sudo apt-get -qq update \
            && sudo apt-get -qq install protonvpn
        rm --force -- "$app"
    fi
}

# https://www.zotero.org/
install_zotero() {
    oxt_name='Zotero_OpenOffice_Integration.oxt'
    if [ "$USE_FLAT" = 'True' ] && flatpak install flathub org.zotero.Zotero; then
        oxt=$(find '/var/lib/flatpak/app/org.zotero.Zotero' -type f -name "$oxt_name" -print -quit)
    elif [ "$USE_SNAP" = 'True' ] && sudo snap install zotero-snap; then
        oxt=$(find '/snap/zotero-snap' -type f -name "$oxt_name" -print -quit)
    else
        return 0
    fi

    # exit early if lock file exists
    [ -f "${HOME}/.config/libreoffice/4/.lock" ] && return 1
    # integrate zotero with libre office
    if [ -f "$oxt" ] && is_installed 'unopkg'; then
        is_installed 'office extension' 'org\.Zotero\.integration\.openoffice' || unopkg add "$oxt"
    fi
}

install_apps() {
    clear
    cat <<INSTALL_LIST
    I will prompt you to install the following.

     1) media codecs            enables playing various videos (recommended)
     2) Chromium                web browser
     3) qPDF                    CLI tool for PDF files
     4) Texmaker                Latex editor
     5) uBlock Origin           ad content blocker (recommended)
     6) CLion                   C and C++ IDE
     7) Discord                 messaging (proprietary)
     8) Extensions              manage Gnome extensions
     9) Flatseal                manage flatpak permissions
    10) Foliate                 ebook viewer
    11) Gimp                    image editor
    12) IntelliJ                Java IDE
    13) Kdenlive                video editor
    14) PyCharm                 Python IDE
    15) Signal                  messaging (open source, encrypted)
    16) Slack                   messaging (proprietary)
    17) VLC                     reliable media player
    18) Zoom                    video conferencing
    19) Bitwarden               password manager
    20) Master PDF editor       portable document format file editor
    21) Matlab                  scientific computing software
    22) Mathematica             scientific computing software
    23) Miniconda               programming environment and package manager
    24) Night theme switcher    automatically toggle light and dark theme
    25) Proton VPN              virtual private network
    26) Zotero                  reference manager

INSTALL_LIST

    install_media_codecs # do first

    if [ "$USE_DNF" = 'True' ]; then
        if ! is_installed 'chromium' && ! is_installed 'snap' 'chromium'; then
            # rpm preferred over flatpak as rpm has Wayland support and more secure sandboxing
            dnf repolist --enabled | grep -q 'rpmfusion-free' && sudo dnf install chromium-freeworld
        fi
        sudo dnf install qpdf
        sudo dnf install texlive-scheme-basic texmaker
        sudo dnf install mozilla-ublock-origin
    elif [ "$USE_APT" = 'True' ]; then
        sudo apt-get --option "$WAIT_APT" install qpdf
        sudo apt-get --option "$WAIT_APT" install texlive texmaker
        sudo apt-get --option "$WAIT_APT" install webext-ublock-origin-firefox
    fi

    # flatpak and snap provide sandboxing, making them more secure than rpm or deb
    if [ "$USE_FLAT" = 'True' ]; then
        sudo flatpak remote-add --if-not-exists flathub \
            'https://flathub.org/repo/flathub.flatpakrepo'
        sudo flatpak remote-modify --enable flathub
        flatpak install flathub com.jetbrains.CLion
        flatpak install flathub com.discordapp.Discord
        flatpak install flathub org.gnome.Extensions
        flatpak install flathub com.github.tchx84.Flatseal
        flatpak install flathub com.github.johnfactotum.Foliate
        flatpak install flathub org.gimp.GIMP
        flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community
        flatpak install flathub org.kde.kdenlive
        flatpak install flathub com.jetbrains.PyCharm-Community
        flatpak install flathub org.signal.Signal
        flatpak install flathub com.slack.Slack
        flatpak install flathub org.videolan.VLC
        flatpak install flathub us.zoom.Zoom
    elif [ "$USE_SNAP" = 'True' ]; then
        if ! is_installed 'chromium' && ! is_installed 'chromium-freeworld'; then
            sudo snap install chromium
        fi
        sudo snap install clion --classic
        sudo snap install discord
        sudo snap install foliate
        sudo snap install gimp
        sudo snap install intellij-idea-community --classic
        sudo snap install kdenlive
        sudo snap install pycharm-community --classic
        sudo snap install signal-desktop
        sudo snap install slack
        sudo snap install vlc
        sudo snap install zoom-client
    fi

    install_bitwarden
    install_master_pdf_editor
    install_matlab
    install_mathematica
    install_miniconda
    install_night_theme_switcher
    install_proton_vpn
    install_zotero
}

# This function is separate from install_apps() because after conda
# is installed, conda must be activated from a new terminal session.
install_jupyter_lab() {
    clear
    cat <<JUPYTER
    Enter ${CYAN}jupyter lab${NORMAL} in the base environment to start it.

    Note:
    To access environments other than base in a notebook,
    install the appropriate kernel in that environment.
    Then start jupyter lab from the base environment.
    Select the kernel of the desired environment for the notebook.

    You can find a list of programming language specific kernels here:
    https://docs.jupyter.org/en/latest/projects/kernels.html.

    As an example, the Python kernel is ${CYAN}ipykernel${NORMAL},
    which can be installed into the environment named ENVNAME with
    ${CYAN}conda install --name ENVNAME ipykernel${NORMAL}

JUPYTER

    if is_installed 'conda'; then
        conda install -q -y --name base jupyterlab nb_conda_kernels
    else
        printf '%s%s%s\n' "$YELLOW" 'conda not found' "$NORMAL"
    fi
}

# ------------------------------------------------------------------------------

help_package_management() {
    clear
    cat <<PACKAGE_MANAGEMENT
    ${CYAN}${BOLD}Package management advice${NORMAL}

    1) Install stuff from the app store or your package manager.
    2) Prefer default repositories over 3rd party ones.
    3) Use conda to manage coding project packages.
    4) Install with pip only after installing all you can with conda.
    5) Never use ${YELLOW}sudo pip${NORMAL}.
    6) Never use ${YELLOW}pip install --user${NORMAL} in a conda environment.

PACKAGE_MANAGEMENT
}

help_menu() {
    fedora_docs='https://docs.fedoraproject.org/'
    ubuntu_help='https://help.ubuntu.com/'
    clear
    cat <<HELP_MENU
    ${CYAN}${BOLD}HELP${NORMAL}

    ${CYAN}1${NORMAL}) What should I know about package management?
    ${CYAN}2${NORMAL}) $fedora_docs
    ${CYAN}3${NORMAL}) $ubuntu_help

    ${CYAN}0${NORMAL}) Go back

HELP_MENU

    printf 'Select an option: '
    read -r REPLY
    case "$REPLY" in
        1) help_package_management ;;
        2) xdg-open "$fedora_docs" 1>/dev/null 2>/dev/null ;;
        3) xdg-open "$ubuntu_help" 1>/dev/null 2>/dev/null ;;
        0) return 0 ;;
    esac
    printf 'Press enter to continue. '
    read_silent
    help_menu
}

menu() {
    clear
    cat <<MENU
    ${CYAN}${BOLD}Welcome!${NORMAL}

    I help set up and maintain RPM or Debian based systems.

    ${CYAN}1${NORMAL}) Tweak settings
    ${CYAN}2${NORMAL}) Upgrade
    ${CYAN}3${NORMAL}) Install apps
    ${CYAN}4${NORMAL}) Install jupyter lab
    ${CYAN}5${NORMAL}) Help

    ${CYAN}0${NORMAL}) Exit

MENU

    printf 'Select an option: '
    read -r REPLY
    case "$REPLY" in
        1) tweak_settings ;;
        2)
            set_manager_priority
            upgrade_system
            ;;
        3)
            set_manager_priority
            install_apps
            ;;
        4) install_jupyter_lab ;;
        5) help_menu ;;
        0) exit 0 ;;
    esac
    printf 'Press enter to continue. '
    read_silent
    menu
}

menu
