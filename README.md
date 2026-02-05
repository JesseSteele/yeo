# yeo - AUR helper helper for Arch Linux
`yay` helper to intput `sudo` password at command entry

With this script, you can run `sudo yeo -Syy some-package --noconfirm` and `sudo yeo -Syyu --noconfirm` (et al) instead of needing to babysit for a `sudo` password in the middle of the usual `yay -Syy some-package --noconfirm`

*Use at your own risk!*

**Disclaimer: Anything on this page could result in destroying your entire computer or bring the apocalypse or something less or between or far worse! Only use this tool if you know how to use [pacman](https://wiki.archlinux.org/title/pacman) and [yay](https://github.com/Jguer/yay/blob/next/README.md) and can install [Arch Linux](https://archlinux.org/) yourself and don't like SysAdmin wages for a CLI babysitting job!**

## Reasoning
- `yay` will prompt the SysAdmin or user for `sudo` passwords in the middle of its execution, meaning the SysAdmin must babysit the terminal during `yay` installs and updates
- This defeats the purpose of using the terminal and scripts, meaning SysAdmin-level hourly cost to watch `yay` work

However, the premise is correct...

- Compiling *must not* be done by `root` or `sudo`
- A `root` user compiler can cause many problems, including code not be executable by normal users
- But, `yay` both compiles and installs, and installing does require `sudo`

How `yeo` helps...

- `yeo` must be run as `sudo`, then runs `yay` as a user that does not need a password for `sudo` operations as they arise

## Solution
- Run a `sudo` command that takes the `sudo` password for the duration of the CLI execution, but runs `yay` through a normal user which has a no-password `sudo` permission
- This normal (`worker`) user requires a `sudo` password or `root` permissions to be initiated, but then does not need a password later
- The result is that:
  1. The `sudo` password CLI request moves up to the beginning of the workflow
  2. Where the `sudo` password only needs to be entered once
  3. Thus, we have a "press and walk" `sudo` command more like `pacman`

## Prerequesites:

1. `sudo`

Arch Linux does not come with `sudo` ready by default

*If you have not already enabled `sudo`, you can enable `sudo` with this, otherwise skip to 2...*

| **Turn on `sudo`**: # (must run as `root`)

```console
groupadd sudo
sed -i "s?# %sudo\tALL=(ALL) ALL?%sudo\tALL=(ALL) ALL?" /etc/sudoers
```

2. `yay`

*`yay` must be installed already, if it is then skip 2...*

| **Install `yay` AUR helper** : $

```console
sudo pacman -Syy --needed base-devel git
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay
```

## Install `yeo`

*First check for dependencies and any conflict*

| **Check for `yeo` tool dependencies & conflicts**: $

```console
if which yay && id -u worker; then if which yeo; then echo "yeo may already be installed!"; else echo "Ready to install yeo!"; fi else echo "Cannot install yeo, there is a conflict!"; fi
```

*If you see the message `Ready to install yeo!` then you are ready to proceed...*

| **`yeo` install**: $

```console
sudo groupadd worker
sudo useradd -g worker worker
sudo usermod -a -G wheel worker
sudo mkdir -p /opt/vrk/worker
sudo chown -R worker:worker /opt/vrk/worker
sudo usermod -d /opt/vrk/worker worker
sudo usermod -L worker
sudo chsh -s /usr/sbin/bash worker
sudo echo 'worker ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/worker
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
```

Now, you have the option to run `sudo yeo` where you would normally run `yay`, including with `--noconfirm` or such `yay` options if you like
