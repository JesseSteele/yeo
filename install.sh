#!/bin/bash

### Create worker user
/usr/bin/groupadd worker
/usr/bin/useradd -g worker worker
#/usr/bin/usermod -a -G wheel worker # Should not be necessary with the sudoers.d/ entry
/usr/bin/mkdir -p /opt/vrk/worker
/usr/bin/chown -R worker:worker /opt/vrk/worker
/usr/bin/usermod -d /opt/vrk/worker worker
/usr/bin/echo 'worker ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/worker
/usr/bin/usermod -L worker
/usr/bin/chsh -s /usr/sbin/bash worker 1> /dev/null 2>& 1 # It generates STDOUT and STDERR

### Let's use sudo
/usr/bin/groupadd sudo
/usr/bin/sed -i "s?# %sudo\tALL=(ALL) ALL?%sudo\tALL=(ALL) ALL?" /etc/sudoers

## yay AUR manager
if which yay > /dev/null 2>&1; then
  echo "yay already installed, moving on..."
else
  ## Install AUR manager
  cd /opt/vrk/worker || exit 0
  /usr/bin/sudo -u worker /bin/bash -c '/usr/bin/git clone https://aur.archlinux.org/yay.git'
  cd yay || exit 0
  /usr/bin/sudo -u worker /bin/bash -c '/usr/bin/makepkg -si --noconfirm'
  cd .. || exit 0
  /usr/bin/rm -rf yay
fi

## Let's use the yeo helper
/usr/bin/ln -sfn /opt/vrk/donjon/yeo.sh /usr/local/bin/yeo

## Update yay
/usr/bin/sudo -u worker /bin/bash -c '/usr/bin/yay -Syyu --noconfirm'
/usr/bin/sudo -u worker /bin/bash -c '/usr/bin/yay -Scc --noconfirm'
/usr/bin/sudo -u worker /bin/bash -c '/usr/bin/yay -Yc --noconfirm'

## Create yeo helper script
sudo cat <<'EOF' > /opt/yeo.sh
#!/bin/bash
if [ "$(id -u)" != "0" ]; then
  /usr/bin/echo "Must run as root or sudo!"
  exit 1
fi

/usr/bin/echo $@ | /usr/bin/grep -q '"'
if [ "$?" != "0" ]; then
  /usr/bin/echo $@ | /usr/bin/grep -q "'"
  if [ "$?" != "0" ]; then
    args="$@"
    /usr/bin/sudo -u worker /bin/bash -c "/usr/bin/yay $args"
    exit $?
  else
    /usr/bin/echo "No 'quotes' allowed!"
    exit 1
  fi
else
  /usr/bin/echo "No \"quotes\" allowed!"
  exit 1
fi
EOF
sudo chmod 755 /opt/yeo.sh
sudo ln -sfn /opt/yeo.sh /usr/local/bin/yeo