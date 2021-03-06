#!/bin/bash
#******************************************************************************
#                                   WARNING
#******************************************************************************
#
#  This script will install my public keys in your ~/.ssh/authorized_keys
#  This script also grants PASSWORDLESS sudo to the user who runs it.
#
#  You may not want this.  If you are not me, you should remove the SSH keys
#  and sudoers file.
#
#  For the sake of convenience, this file is available at config.riggle.me
#
#******************************************************************************

#
# Print commands as they're run, and fail on error.
#
set -ex

#
# Don't run as root
#
if [ $UID -eq 0 ] ; then
    cat <<EOF
Run as a regular user with sudo access
# useradd -m user -p password
# echo "user ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/user
EOF
    exit
fi

if [ ! -f "/etc/sudoers.d/$USER" ]; then
sudo bash <<EOF
umask 377
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$USER

if ! grep "includedir /etc/sudoers.d" /etc/sudoers; then
    echo "#includedir /etc/sudoers.d" >> /etc/sudoers
fi
EOF
fi

#
# Useful environment variables
#
case "$(uname -m)" in
    i686)   ARCH="i386" ;;
    x86_64) ARCH="amd64" ;;
esac

DISTRO="$(lsb_release -is)"   # 'Ubuntu'
RELEASE="$(lsb_release -cs)"  # 'trusty'

#
# Add source repositories so that we can:
#
# - apt-get source
# - apt-get build-dep
#
sudo mv -n /etc/apt/sources.list{,.original}

while read line; do
    echo $line
    echo $line | sed 's|deb |deb-src |'
done < /etc/apt/sources.list.original | sudo tee /etc/apt/sources.list

#
# Default mirrors are sloooooooow
#
# us.archive.ubuntu.com => Ubuntu DVD install
# archive.ubuntu.com    => DigitalOcean install
# ftp.us.debian.org     => Debian DVD install
#
slow="(ftp|https?)://.*/(ubuntu|debian)"
fast="\1://mirrors.mit.edu/\2"
sudo sed -i -E "s $slow $fast i" /etc/apt/sources.list

#
# Get around proxy filtering for external repos
#
sudo tee /etc/apt/apt.conf.d/10-no-proxy <<EOF
Acquire::http::Proxy::mirrors.mit.edu DIRECT;
Acquire::http::Proxy::www.emdebian.org DIRECT;
EOF

#
# Don't ever prompt me to use the new or old version
# of a configuration file.
#
sudo tee /etc/apt/apt.conf.d/80confold <<EOF
DPkg::Options {"--force-confold"; };
DPkg::Options {"--force-confdef"; };
EOF

#
# Upgrade the system first
#
sudo apt-get -qq -y update
sudo apt-get -qq -y dist-upgrade


#
# Start installing packages.  We have to
# Add the debian keyring first.
#
install() {
    sudo apt-get install -qq --yes $*
}

install debian-keyring
install debian-archive-keyring
install emdebian-archive-keyring

#
# Binaries and prerequisites
#
sudo apt-get -qq update
install ack-grep
install autoconf
install binutils
install build-essential
install clang
install cmake
install curl
install libc6:i386 || true
install libc6-dbg:i386 || true
install libc6-dev-i386
install dissy
install dpkg-dev
install emacs
install expect{,-dev}
install fortune
install gcc-aarch64-linux-gnu || true
install g++-aarch64-linux-gnu || true
install gcc-arm-linux-gnueabihf || true
install g++-arm-linux-gnueabihf || true
install gcc-powerpc-linux-gnu || true
install g++-powerpc-linux-gnu || true
install gcc-powerpc64-linux-gnu || true
install g++-powerpc64-linux-gnu || true
install gcc-mips-linux-gnu || true
install g++-mips-linux-gnu || true
install gcc-mipsel-linux-gnu || true
install g++-mipsel-linux-gnu || true
install gdb
install gdb-multiarch || true
install git-core
install htop || true
install irssi
install libbz2-dev
install libc6-dev
install libexpat1-dev
install libgdbm-dev
install libglib2.0-dev # unicorn
install libgmp-dev
install liblzma-dev # binwalk
install libncurses5-dev
install libpcap0.8{,-dev}
install libpng-dev
install libpq-dev
install libpython2.7:i386 || true # IDA python
install libreadline6-dev
install libsqlite3-dev
install libssl-dev
install libssl0.9.8:i386 || true # IDA python
install libssl1.0.0:i386 || true # IDA python
install libtool
install libxml2
install libxml2-dev
install libxslt1-dev
install "linux-headers-$(uname -r)"
install llvm
install mercurial
install nasm
install netcat-traditional
install nmap
install nodejs
install npm
install ntp
install openssh-blacklist
install openssh-blacklist-extra
install openssh-server
install openvpn
install patch
install pwgen
install qemu-system\*  || true
install qemu-user
install rar || true
install realpath
install silversearcher-ag || true
install socat
install ssh
install subversion
install tk-dev # required for ipython %paste
install tmux
install tree
install uncrustify
install vim
install yodl
install zlib1g-dev
install zsh
install unzip

# Other things which may be missing, if this is e.g. a minimal install.
install tasksel
sudo tasksel install server

#
# Source URIs for goobuntu
#
if which goobuntu-config; then
    sudo goobuntu-config set include_deb_src true
fi

#
# Configure automatic updates
#
# Automation
install unattended-upgrades

sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
        "\${distro_id}:\${distro_codename}-security";
        "\${distro_id}:\${distro_codename}-updates";
};

Unattended-Upgrade::Mail "root";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
sudo tee /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

sudo tee /etc/sysctl.d/10-ptrace.conf <<EOF
kernel.yama.ptrace_scope = 0
EOF

sudo tee /etc/sysctl.d/10-so_reuseaddr.conf <<EOF
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
EOF

sudo sysctl --system || sudo service procps start

#
# Required for 'nc -e'
#
sudo update-alternatives --set nc /bin/nc.traditional

# XXX: Fix this for 16.04
# apt-get source libc6 # for debugging libc

# GUI install?
if dpkg -l xorg > /dev/null 2>&1; then


    # Automatically log in as the current user
    lightdm=/etc/lightdm/lightdm.conf.d
    [[ -d $lightdm ]] || sudo mkdir -p $lightdm
    sudo tee $lightdm/20-autologin.conf <<EOF
[SeatDefaults]
autologin-user=$USER
EOF

    # Set Solarized colors in Gnome-Terminal, which doesn't
    # have an actual config file but uses gconf bullshit.
    wget -nc https://github.com/Anthony25/gnome-terminal-colors-solarized/archive/master.zip
    unzip master.zip
    (echo 1; echo YES) | ~/gnome-terminal-colors-solarized-master/set_dark.sh
    rm -rf gnome-terminal-colors-solarized-master

    # Disable the login prompt when the screensaver pops
    gsettings set org.gnome.desktop.screensaver lock-delay 3600
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
    gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false || true
    dconf write /org/compiz/profiles/unity/plugins/unityshell/shortcut-overlay false

    install compiz
    install compiz-plugins
    install compizconfig-settings-manager
    install dconf-tools
    install gnome-system-monitor
    # install rescuetime
    install network-manager-openvpn

    wget -nc http://ftp.ussg.iu.edu/eclipse/technology/epp/downloads/release/mars/2/eclipse-cpp-mars-2-linux-gtk-x86_64.tar.gz
    tar xf eclipse*gz

    # install eclipse # Don't install eclipse, since Ubuntu's is OLD
    sudo debconf-set-selections <<EOF
ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true
EOF
    install wine1.8 || install wine1.7
    install winetricks || true
    wget -nc https://www.python.org/ftp/python/2.7.11/python-2.7.11.msi
    wine msiexec /i python-2.7.11.msi /quiet  ALLUSERS=1

    gsettings set org.gnome.desktop.wm.preferences theme 'Greybird'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Droid Sans 10'

    # wget -nc https://www.rescuetime.com/installers/rescuetime_current_$ARCH.deb
    wget -nc https://download.sublimetext.com/sublime-text_build-3103_amd64.deb
    wget -nc https://dl.google.com/linux/direct/google-chrome-stable_current_$ARCH.deb
fi

sudo dpkg --install ./*.deb || true
install -f --yes

sudo apt-get -f    --silent install
sudo apt-get --yes --silent autoremove


#
# Configure SSH for pubkey only
#
sudo service ssh restart
sudo mv -n /etc/ssh/sshd_config{,.original}
sudo sh -c "cat > /etc/ssh/sshd_config <<EOF
Protocol                        2
Port                            22
PubkeyAuthentication            yes

Ciphers                         aes256-ctr

UsePAM                          no
PermitRootLogin                 no
PasswordAuthentication          no
PermitEmptyPasswords            no
KerberosAuthentication          no
GSSAPIAuthentication            no
ChallengeResponseAuthentication no
HostbasedAuthentication         no
KbdInteractiveAuthentication    no

X11Forwarding                   yes
PermitTunnel                    no
AllowTcpForwarding              yes

UsePrivilegeSeparation          sandbox
UseDNS                          no
StrictModes                     yes
Compression                     delayed

Subsystem      sftp             /usr/lib/openssh/sftp-server

AcceptEnv LANG LC_*
AcceptEnv TZ
AcceptEnv COLORFGBG
AcceptEnv WINDOW
AcceptEnv TMUX
EOF"
sudo service ssh restart

#
# Put the IP address on the login screen
#
cat >issue <<EOF
if [[ "\$reason" == "BOUND" ]];
then
    rm /etc/issue
    lsb_release -ds       >> /etc/issue
    echo \$new_ip_address >> /etc/issue
    echo "\\n \\l"        >> /etc/issue
fi
EOF
sudo chown root.root issue
sudo mv    issue     /etc/dhcp/dhclient-enter-hooks.d

#
# Set up home directory repo
#
# This should set up pyenv and a bunch of other things
#
cd ~
[ -d .git ] && git submodule foreach 'rm -rf $(pwd)'
[ -d .git ] && rm -rf .git
git init
git remote add origin https://github.com/zachriggle/tools.git
git fetch -q --all
git checkout -f master
git reset -q --hard
git submodule update -f -q --init --recursive


# Pwndbg stuff should get installed before pyenv
install python-pip python3-pip
git clone https://github.com/pwndbg/pwndbg
pushd ~/pwndbg
sudo bash ./setup.sh
popd

#
# Force pyenv for this script
#
PYENV_ROOT="$PWD/.pyenv"
PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

#
# Install a local version of Python.
#
pyenv install "$(cat .python-version)"


#
# Python things
#
pip_force_install() {
    pip install --upgrade --allow-all-external --allow-unverified "$@" "$@"
}
pip_install() {
    pip install --upgrade "$@"
}
pip_install pygments
pip_install pexpect
pip_install scapy
pip_install tldr
pip_install httpie
pip_install ipython
pip_install hub
pip_install git-up

git clone https://github.com/Gallopsled/pwntools
cd ~/pwntools
bash travis/install.sh
bash travis/ssh_setup.sh
pip install --upgrade -e .
cd ~

#
# Pwntools binary requirements
#
# N.B. Xenial has all of these by default, yay!
#
install binutils-\*
install libc6\*-cross

sudo mkdir /etc/qemu-binfmt

for arch in aarch64 mips mipsel mips64 mips64el powerpc powerpc64 powerpc64le s390x sparc64; do
    sudo ln -sf /usr/$arch-linux-gnu /etc/qemu-binfmt/$arch
done

# Sigh
sudo ln -sf /usr/arm-linux-gnueabihf /etc/qemu-binfmt/arm


#
# Ruby things
#
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
git clone git://github.com/jamis/rbenv-gemset.git     ~/.rbenv/plugins/rbenv-gemset
PATH="$PATH:$HOME/.rbenv/shims:$HOME/.rbenv/bin"
rbenv install        2.3.1
rbenv gemset  create 2.3.1 gems
rbenv rehash

gem install bundler
gem install gist
gem install git-up

rbenv rehash

#
# Node things
#
sudo ln -s $(which nodejs) /usr/bin/node
sudo npm install -g workit
sudo npm install -g completion
sudo npm install -g git-travis

#
# Set up metasploit
#
# case "$(uname -m)" in
#     "x86_64" ) metasploit_url="http://goo.gl/G9oxTe" ;;
#     "i686" )   metasploit_url="http://goo.gl/PwzxlC" ;;
# esac
# wget  -O ./metasploit-installer "$metasploit_url"
# chmod +x ./metasploit-installer
# sudo     ./metasploit-installer --mode unattended
# rm       ./metasploit-installer
# sudo     update-rc.d metasploit disable
# sudo     service metasploit stop
if false; then
    cd ~
    wget -nc https://github.com/rapid7/metasploit-framework/archive/release.zip
    unzip release.zip
    cd metasploit-framework-*
    rm -f .ruby-version
    gem install bundler # metasploit has its own gemset
    bundle install
fi

#
# Set up binwalk
#
if false; then
    cd ~
    git clone git://github.com/devttys0/binwalk.git
    cd binwalk
    python setup.py install
    sudo rm -rf binwalk
fi

#
# Update TMUX
#
TMUXVER=2.3
if ! tmux -V | grep $TMUXVER &>/dev/null; then
    sudo apt-get build-dep tmux
    wget https://github.com/tmux/tmux/releases/download/$TMUXVER/tmux-$TMUXVER.tar.gz
    tar xf tmux-$TMUXVER.tar.gz
    pushd tmux-$TMUXVER
    ./configure
    make -j$(nproc)
    sudo make install
    popd
    rm -rf tmux*
fi

#
# Use zsh
#
sudo chsh -s $(which zsh) $(whoami)

#
# Clean up
#
rm -rf ./*.gz ./*.zip ./*.msi ./*.deb ./*.xz ./*.dsc

#
# Change the password if we're in an SSH session
#
if [ ! -z "$SSH_CONNECTION" ];
then
  password=$(pwgen -s 64 1)
  sudo passwd -u -d "$USER"
  (echo "$password"; echo "$passwd") | passwd
  echo Password is "$password"
fi

#
# Reboot
#
while true; do
    read -p "Reboot? [yn] " yn
    case $yn in
        [Yy]* ) sudo reboot; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done
