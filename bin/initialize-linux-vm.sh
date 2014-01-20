#!/bin/sh

#
# Setup script for Ubuntu and Debian VMs.
# TinyURL: This script is available at:
# $ wget https://goo.gl/3e2B0
# $ bash 3e2B0
#

#
# Fail early
#
set -e

#
# Default mirrors are sloooooooow
#
# us.archive.ubuntu.com => Ubuntu DVD install
# archive.ubuntu.com    => DigitalOcean install
# ftp.us.debian.org     => Debian DVD install
#
ubuntu="(us.)?archive.ubuntu.com"
debian="ftp.(us.)?debian.org"
sudo sed -i.original -E "s/($ubuntu|$debian)/mirror.anl.gov/g" /etc/apt/sources.list


#
# Binaries and prerequisites
#
sudo apt-get -q update
sudo apt-get -y -q dist-upgrade

while read -r package;
do sudo apt-get install -q --yes $package
done << EOF
ack-grep
binutils
build-essential
curl
dissy
emacs
fortune
gdb
git-core
libbz2-dev
libexpat1-dev
libgdb-dev
libgdbm-dev
libgmp-dev
libncurses5-dev
libncursesw5-dev
libpcap-dev
libpng-dev
libpq-dev
libreadline6-dev
libsqlite3-dev
libssl-dev
libxml2
libxml2-dev
libxslt1-dev
linux-headers-$(uname -r)
nasm
open-vm-tools
openssh-blacklist
openssh-blacklist-extra
openssh-server
patch
qemu-system-arm
realpath
shellnoob
silversearcher-ag
ssh
subversion
tk-dev
tree
vim
yodl
zlib1g-dev
zsh
EOF
sudo apt-get --yes --silent autoremove


#
# Configure SSH for pubkey only
#
sudo mv /etc/ssh/sshd_config{,.original}
sudo sh -c "cat > /etc/ssh/sshd_config <<EOF
Protocol                        2
Port                            22
PubkeyAuthentication            yes

UsePAM                          no
PermitRootLogin                 no
PasswordAuthentication          no
PermitEmptyPasswords            no
KerberosAuthentication          no
GSSAPIAuthentication            no
ChallengeResponseAuthentication no

Subsystem      sftp             /usr/lib/openssh/sftp-server
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
git init
git remote add origin https://github.com/zachriggle/tools.git
git pull -f origin master
git reset --hard
git submodule update --init --recursive

#
# Force pyenv for this script
#
PYENV_ROOT="$HOME/.pyenv"
PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

#
# Install a local version of Python.
#
pyenv install 2.7.6
pyenv local 2.7.6


#
# Python things
#
pip install ipython
pip install numpy
pip install matplotlib
pip install gmpy
pip install sympy
pip install pygments

#
# Ruby things
#
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
git clone git://github.com/jamis/rbenv-gemset.git     ~/.rbenv/plugins/rbenv-gemset
PATH="$PATH:$HOME/.rbenv/shims:$HOME/.rbenv/bin"
rbenv install        1.9.3-p484
rbenv gemset  create 1.9.3-p484 gems
rbenv rehash
gem install bundler
rbenv rehash

#
# Install pwntools
#
cd ~/pwntools
git pull origin master
sudo bash ./install.sh


#
# Set up metasploit
#
# cd ~
# git clone git://github.com/rapid7/metasploit-framework.git
# cd metasploit-framework
# git checkout release
# gem install bundler
# rbenv rehash
# bundle install
case "$(uname -m)" in
    x86_64 )
         metasploit_url="http://goo.gl/PwzxlC"
    i386 )
         metasploit_url="http://goo.gl/G9oxTe"
esac
wget  -O ./metasploit-installer "$metasploit_url"
chmod +x ./metasploit-installer
sudo     ./metasploit-installer --mode text --prefix metasploit --auto-update 1

#
# Set up binwalk
#
cd ~
git clone git://github.com/devttys0/binwalk.git
cd binwalk/src
sudo bash ./easy_install.sh

#
# Use zsh
#
chsh -s $(which zsh)

