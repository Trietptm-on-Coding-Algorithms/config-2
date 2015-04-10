#!/bin/bash
set -ex

# Turn off ptrace and most procfs stuff
cat > /etc/rc.local <<EOF
mount -o remount,hidepid=2 /proc
chmod 700 /proc
chmod o-r+wx  /tmp
iptables-restore < /etc/iptables.rules
echo 1 > /proc/sys/kernel/modules_disabled
exit
EOF
bash /etc/rc.local

# Kernel
apt-get -yq remove kexec-tools

rm -f /boot/System.map*

cat > /etc/default/kexec << EOF
LOAD_EXEC=false
EOF

# Automation
apt-get -yq install fail2ban kpartx unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
        "Ubuntu trusty-security";
        "Ubuntu trusty-updates";
};
EOF
cat > /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Unattended-Upgrade::Automatic-Reboot "true";
EOF


# Have to leave symlink stuff on for challenges.
cat > /etc/sysctl.conf << EOF
# fs.protected_hardlinks = 1
# fs.protected_symlinks = 1
kernel.kptr_restrict = 1
kernel.perf_event_paranoid = 2
kernel.randomize_va_space = 2
kernel.yama.ptrace_scope = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.disable_ipv6 = 1
kernel.core_pattern = core
EOF
sysctl --system


# All home directories should be owned by root:$user,
# and should only be readable by that user.
cd /home
for dir in $(ls);
do
    chown -R root.$dir $dir
    chmod -R o-rwx     $dir
    chmod -R g-w       $dir
done

# Nothing setuid outside of /home
for file in $(find /  ! -path /home -type f -perm +6000 2>/dev/null);
do
    chmod o-rwx $file
done

# Except su/sudo
chmod o+rx $(which su) $(which sudo)

# Disable 'last'
chmod o-r /var/*/{btmp,wtmp,utmp}

# Drop all outbound connections except root, and already-established connections
iptables -F OUTPUT
iptables -A OUTPUT -m owner --uid-owner root    -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -j REJECT
iptables-save > /etc/iptables.rules

# useradd -u 5000 -m -s $(which nologin) ru1337
# useradd -u 5001 -m -s $(which nologin) ll
# useradd -u 5002 -m -s $(which nologin) postit
# useradd -u 5003 -m -s $(which nologin) run_danbi
# useradd -u 5004 -s $(which nologin) final_danbi
