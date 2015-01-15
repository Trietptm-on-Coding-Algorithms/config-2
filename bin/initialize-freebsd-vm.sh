#!/bin/sh
# Available at: http://goo.gl/24idVT


#
# Print commands as they're run, and fail on error.
#
set -ex

install() {
    pkg install --quiet --yes $*
}

src_install() {
    cd /usr/ports/*/$1
    shift
    sudo make -DBATCH batch=yes install clean $*
}


if ! which sudo >/dev/null; 
then
    # Set up ports and sudo
    portsnap fetch
    portsnap extract
    
    src_install pkg
    install sudo
    
    # Set things up as root
    
    useradd
    echo 'vagrant ALL=(ALL:ALL) NOPASSWD: ALL' || tee /usr/local/etc/sudoers.d/vagrant
fi


#
# Don't run as root
#
if [ $UID -eq 0 ] ; then
    cat <<EOF
Run as a regular user with sudo access
# useradd -m user -p password
# echo "user ALL=(ALL:ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers.d/user
EOF
    exit
fi

cat <<EOF > /etc/rc.conf
sshd_enable="YES"
ifconfig_em0="DHCP"
hostname=$(uname -n)_$(uname -m)
EOF

# Make fetching faster on modern FreeBSD
pkg install lang/python
pkg install ports-mgmt/fastest_sites
fastest_sites > /usr/local/etc/ports_sites.conf
cat >> /etc/make.conf <<EOF
.include "/usr/local/etc/ports_sites.conf"
EOF

# bash requires fdescfs
cat >> /etc/fstab <<EOF
fdesc   /dev/fd         fdescfs         rw      0       0
EOF

# Install things we want
install compat6x-i386
install git
install nc
install vim
install zsh
install bash
install nmap
install nasm
install autoconf
install cmake
install clang34
install gcc49
install tree
install bzip
install binutils
install the_silver_searcher
install vim
install p7zip
install readline
install htop
src_install gdb WITH="PYTHON"


# Audit the ports for security issues
pkg install portaudit
rehash
portaudit -Fda

# Set up git
cd ~
git init
git remote add https://github.com/zachriggle/tools.git
git pull
git checkout -f master
git submodule update --init --recursive


#
# Force pyenv for this script
#
PYENV_ROOT="$HOME/.pyenv"
PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

#
# Install python
#
pyenv install 2.7.6
pyenv local 2.7.6

pip_install() {
    pip install --allow-all-external --allow-unverified $* $*
}
pip_install pygments
pip_install pexpect
pip_install hg+http://hg.secdev.org/scapy || true # scapy is down
pip_install tldr
pip_install httpie

cd ~/pwntools
pip install -r requirements.txt
cd ~

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
gem install gist

rbenv rehash

#
# Because fuck waiting for CTF binaries that don't SO_REUSEADDR
#
sysctl net.inet.tcp.nolocaltimewait=1

#
# Compatibility
#
cat >> /etc/fstab <<EOF
proc                /proc                        procfs    rw       0       0
linproc             /compat/linux/proc           linprocfs rw,late  0       0
EOF

mkdir -p /usr/compat/linux/proc
ln -s /usr/compat /compat
mount linproc
