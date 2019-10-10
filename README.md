# Lenovo X1 Yoga (3rd Gen) Suspend-to-Ram on Linux

Prior to BIOS version 1.34, the Lenovo X1 Yoga (3rd Gen) (X1YG3) BIOS did not expose support for Suspend-to-Ram
(S3). Instead, it exposed only [Modern
Standby](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby) (Si03)
which is a low-power idle approach to suspend. Unfortunately, Linux does not
currently provide good support for Modern Standby which leads to awful power drain
when trying to put the X1YG3 to sleep.

Thankfully, Lenovo finally added S3 support in BIOS 1.34 and I can report that it works
correctly. The instructions to patch your DSDT to enable S3 can still be found below
but as of 1.34 this is no longer necessary. If you're running a prior BIOS
version you may still find the instructions helpful.

You may still need to configure _deep_ sleep as the default so review the [Make
sleep default to deep](#make-sleep-default-to-deep) section. You may also want
to review the [Potential issues](#potential-issues) section which provides fixes
for some common issues related to sleep but unrelated to the BIOS S3 support.

### BIOS 1.36:

No new functionality but includes a security fix and resolves a problem with
Thunderbolt docks. `S3` support remains the same as in [BIOS 1.34](#bios-134)
and works as expected. This from the [release notes](https://download.lenovo.com/pccbbs/mobiles/n25ur26w.txt):

> [Important updates]
> - Update includes a security fix.
>
> [New functions or enhancements]
>   Nothing.
>
> [Problem fixes]
> - Fixed an issue where system may enter shutdown after press power button of
>   Thunderbolt 3 Dock Gen2/Thunderbolt 3 Workstation Dock to resume sleep state.

### BIOS 1.35:

It adds no new functionality or fixes but renames the "Modern Standby" setting
added in BIOS 1.34 to "Sleep State" and changes the values to "Linux" and
"Windows 10". `S3` support remains the same as in [BIOS 1.34](#bios-134) and
works as expected. This from the [release notes](https://download.lenovo.com/pccbbs/mobiles/n25et49w.txt):

> [Important updates]
> Nothing.
>
> [New functions or enhancements]
> Nothing.
>
> [Problem fixes]
> - Change Setup item wording from "Modern Standby" to "Sleep State" in ThinkPad Setup - Config - Power.
>  (Note) "Linux" option is optimized for Linux OS, Windows user must select "Windows 10" option.

As with 1.34, I have left `Sleep State->Windows 10` (same as `Modern
Standby->Enabled`) and have proper `S3` support in Linux and proper Modern
Standby support retained in Windows 10 (dual-boot).

### BIOS 1.34:

It adds a new BIOS setting under `Config > Power` called "Modern Standby" which
is `enabled` by default. This from the [release
notes](https://download.lenovo.com/pccbbs/mobiles/n25ur23w.txt):

  > - (New) Support Optimized Sleep State for Modern Standby in ThinkPad Setup - Config - Power.
  >      (Note) "Enabled" selection is optimized for Windows OS,
  >             "Disabled" selection is optimized for Linux OS.

However, my experience has been that _there is no need to change this setting to
enable S3 in Linux._ Simply leave it set to `enabled`, boot into Linux, and
[confirm that S3 is supported](#confirm-s3-support). You _can_ change the
_"Modern Standby"_ setting to `disabled` but it seems to have no bearing S3
support in Linux. Also, I dual-boot and don't want to re-install Windows ([see
below](#dual-booting-windows-modern-standby-and-s3)) so I leave Modern Standby
`enabled`.

### Dual-Booting Windows, Modern Standby, and S3

If you dual-boot Linux & Windows, you may want to leave the Modern Standby
alone as Microsoft claims that you [can't enable S3 support with a BIOS
setting](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby):

  > You cannot switch between S3 and Modern Standby by changing a setting in the
  > BIOS. Switching the power model is not supported in Windows without a
  > complete OS re-install.

Some X1YG3 users have claimed that [S3 works fine in Windows without a
re-install](https://forums.lenovo.com/t5/Other-Linux-Discussions/X1-Yoga-3rd-Gen-S3-Sleep-Linux/m-p/4444072/highlight/true#M13292)
after disabling "Modern Standby" but I haven't tested this myself.

---

## _Legacy Instructions for patching DSDT prior to BIOS 1.34_

These instructions are for Fedora but hopefully they can at least be a helpful
guide for other distributions.

### Prerequisites

This should go without saying, but **if you follow this guide you are
responsible for any damage you do to your machine.** These instructions worked
for me and I have no reason to believe they will cause problems but proceed at
your own risk.

#### Disable SecureBoot

If you see `SecureBoot disabled` after running the following command, you're all
set. If you don't, you need to disable SecureBoot in the BIOS.

``` shell
mokutil --sb-state # should display SecureBoot disabled
```

#### Check current ACPI support

``` shell
dmesg | grep "ACPI: (supports"
```

This command should return something like `ACPI: (supports S0 S4 S5)` which as
you can see is missing S3 support.

#### Ensure _iasl_ is installed

``` shell
which iasl
```

Should return the path to `iasl` like `/usr/bin/iasl`. If it is not
installed, you can install it with:

``` shell
sudo dnf install acpica-tools
```

#### Check your BIOS version

``` shell
sudo dmidecode -s bios-version
```
Should return something like `N25ET44W (1.30 )`. _These instructions were
written with BIOS version_ `1.30`.

If `dmidecode` is missing, you can install it with:

``` shell
sudo dnf dmidecode
```

#### Clone this repository and change directory

``` shell
git clone https://github.com/zachsmith/x1yg3-suspend-to-ram.git
cd x1yg3-suspend-to-ram
```

### Patch the Differentiated System Description Table (DSDT)

#### Copy the current DSDT table exposed by the BIOS

``` shell
sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.dat
```

#### Decompile the DSDT

This will produce a _dsdt.dsl_ file:

``` shell
iasl -d dsdt.dat
```

#### Patch the DSL file

``` shell
patch --verbose < x1yg3-s3-override.patch
```

The output should look something like this:

```
--------------------------
|--- dsdt.dsl  2019-05-05 21:42:46.137486914 -0700
|+++ dsdt.dsl  2019-05-05 21:45:23.489591442 -0700
--------------------------
patching file dsdt.dsl
Using Plan A...
Hunk #1 succeeded at 21.
Hunk #2 succeeded at 265.
Hunk #3 succeeded at 266.
Hunk #4 succeeded at 27770.
done
```

If this patch fails to apply, please open an issue and be sure to include
your _dsdt.dst_ file and the version of your BIOS.

#### Recompile the DSDT

This will produce a _dsdt.aml_ file:

``` shell
iasl -tc -ve dsdt.dsl
```

### Update _initramfs_ image

We are going to utilize `dracut` which is used by Fedora (and numerous other
distributions) to build initramfs images. `dracut` allows you to provide
overridden ACPI tables to build into an image which is exactly what we need.
This approach will include our updated tables in future initramfs images
generated automatically (by kernel updates) or manually (like we'll do here).

#### Copy updated DSDT table

``` shell
sudo mkdir /boot/acpi_override
sudo cp dsdt.aml /boot/acpi_override/x1yg3-s3-override.aml
```

#### Configure ACPI override for `dracut`

Create `/etc/dracut.conf.d/acpi.conf` and add the following lines:

``` shell
acpi_override="yes"
acpi_table_dir="/boot/acpi_override"
```

#### Rebuild your initramfs image

Update the initramfs image for your _current_ kernel.

``` shell
cd /boot
sudo dracut --force initramfs-$(uname -r).img
```

### Make sleep default to _deep_

First, look at your current `mem_sleep` values

``` shell
cat /sys/power/mem_sleep
```

Which should return `[s2idle]`. We want to make sure that `deep` (S3) becomes
the default. To do that, we need to pass a parameter to the kernel at boot time
which we can do by editing our `grub` configuration. This change will insure that
future kernels will also receive this parameter at boot.

#### Edit `/etc/default/grub`

Append the following to the end of the string defined by `GRUB_CMDLINE_LINUX`:

`mem_sleep_default=deep`

#### Rebuild `grub.cfg`

``` shell
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

### Final Steps

At this point you should have patched your DSDT, rebuilt your `initramfs` for
your current kernel, and rebuilt your `grub` configuration. You should be ready
to reboot your computer to check that everything works.

_**Note: If you haven't already disabled secure boot, make sure to do it now before your
system boots with the overridden DSDT table.**_

### Reboot

#### Confirm S3 support

``` shell
dmesg | grep "ACPI: (supports"
```

It should now display `ACPI: (supports S0 S3 S4 S5)` which includes S3. This
means that your patched DSDT loaded.

#### Confirm _deep_ sleep is default

``` shell
cat /sys/power/mem_sleep
```

This should now display `s2idle [deep]` (_the `[]`'s indicate default_). This means
that your `grub` configuration passed the parameter to the kernel at boot.

#### Go to sleep!

Go ahead and enjoy the convenience of putting your computer to sleep!

---

## Potential Issues

You may still encounter suspend related issues. Here are some I've encountered
and fixes where I have them.

### PM: Device 0000:00:14.0 failed to suspend async: error -16

If you see errors like these in your `journal`, it may be related to a problem
suspending your XHCI controller:

```
pci_pm_suspend(): hcd_pci_suspend+0x0/0x30 returns -16
dpm_run_callback(): pci_pm_suspend+0x0/0x120 returns -16
PM: Device 0000:00:14.0 failed to suspend async: error -16
PM: Some devices failed to suspend, or early wake event detected
```

I found this [great
hack](https://gist.github.com/ioggstream/8f380d398aef989ac455b93b92d42048#file-system-sleep-xhci-sh)
and made a few modifications and improvements in the `xhci.sh` script included
in this repo. You can have systemd run this script at `pre` and `post` suspend
by placing it in the `/usr/lib/systemd/system-sleep` directory. I encourage your
to read and understand the script before installing it as it will run with root
privileges. _Read more about this in the [systemd-suspend](http://man7.org/linux/man-pages/man8/systemd-sleep.8.html) man page_.

``` shell
cp xhci.sh /usr/lib/systemd/system-sleep
```

### Touchscreen or stylus unresponsive after resume from suspend

The Wacom touchscreen is often unresponsive after resuming from sleep.
A user discovered that when waking from `s2idle`, the touchscreen worked
correctly and posted this clever solution in a [Lenovo forum
post](https://forums.lenovo.com/t5/Other-Linux-Discussions/X1Y3-Touchscreen-not-working-after-resume-on-Linux/td-p/4021200)
which makes use of `rtcwake` triggered by a `systemd` `oneshot` service after
`suspend.target`. I modified it to also trigger after `suspend-then-hibernate.target`
and `hibernate.target`. This will add a slight delay to the resume so you may
only want to enable this if you like having the touch display working.

``` shell
sudo cp wake_wacom_hack.service /etc/systemd/system/`
sudo systemctl enable wake_wacom_hack.service
```

An alternative is to just disable the touchscreen and not worry about it
resuming after wake. You may prefer to do this if you are also experiencing
ghost/phantom touch issues. See the next section...

### Ghost/Phantom touch events

Unfortunately, I've experienced a lot of ghost/phantom touch events on my X1YG3 and it
can get pretty irritating. Because I typically don't use the touchscreen, I went
ahead and just disabled it using a custom `udev` rule. It's disappointing that there
are issues with the touchscreen since that is one of the key features of the
X1YG3 but I prefer not having phantom touch events to having a touchscreen that
I use very infrequently.

``` shell
sudo cp 99-x1yg3-touchscreen.rules /etc/udev/rules.d/
sudo udevadm trigger --verbose --type=devices --attr-match=idVendor=056a --attr-match=idProduct=5146
```

You can always re-enable by editing `99-x1yg3-touchscreen.rules` and setting
`ATTR{authorized}="1"` before running the `udevadm trigger` command listed
above. _Alternatively, I wrote [a little
script](https://gist.github.com/zachsmith/30f69276f3df613bbb72736e9fd30d71) to
toggle the enable/disable the touchscreen by automating the editing of the rule file
and invoking the trigger but I'm not convinced this is the right approach._

_If you plan to disable your touch screen entirely you don't need to use the
`wake_wacom_hack.service` [described above](#touchscreen-or-stylus-unresponsive-after-resume-from-suspend)._

### /sys/class/rtc/rtc0/wakealarm: Device or resource busy

_**UPDATE:** **The fix for this issue is available in [systemd
243](https://github.com/systemd/systemd/tree/v243)**. Check the version of systemd
installed with your distribution: `systemctl --version`_

_**UPDATE:** This issue should be fixed with [PR
#12591](https://github.com/systemd/systemd/pull/12591) and should be in a future
version of `systemd`. The PR removes the dependency on rtc wakealarm and uses
`CLOCK_BOOTTIME_ALARM` instead thus eliminating the error trying to write to
`/sys/class/rtc/rtc0/wakealarm` when a pre-existing alarm is already set._

If you use `suspend-then-hibernate` you may encounter a situation where your
system will not properly suspend. This can be caused by an error writing to the
`/sys/class/rtc/rtc0/wakealarm`. You'll see something like this in your `journal`:

```
Failed to write '1557511414' to /sys/class/rtc/rtc0/wakealarm: Device or resource busy
systemd-suspend-then-hibernate.service: Main process exited, code=exited, status=1/FAILURE
systemd-suspend-then-hibernate.service: Failed with result 'exit-code'.
Failed to start Suspend; Hibernate if not used for a period of time.
Dependency failed for Suspend; Hibernate if not used for a period of time.
suspend-then-hibernate.target: Job suspend-then-hibernate.target/start failed with result 'dependency'.
Stopped target Sleep.
```

This happens because there is a value already
present in the `wakealarm` and a new value cannot be written until the timer has
triggered or has been reset. In general, I am more concerned with my computer
suspending properly than any other random wakealarm scheduled by the system or
firmware and this has been the most vexing suspend problem I have faced. The
solution I came up with is inspired by the touchscreen fix above; use a `systemd`
`oneshot` service to fire before `suspend-then-hibernate` target and reset the
`wakealarm`.

``` shell
sudo cp wakealarm-reset.service /etc/systemd/system/`
sudo systemctl enable wakealarm-reset.service
```

Of course, this is only relevant if you're making use of
`suspend-then-hibernate` which was added in [version
239](https://github.com/systemd/systemd/blob/master/NEWS#L1036-L1038) of
systemd.

_I opened [an issue](https://github.com/systemd/systemd/issues/12567) with
`systemd` to track getting a fix for this_

### Fan not working

Thinkpads are notoriously problematic when it comes to getting the fans to work.
Thankfully, there is a the `thinkfan` package that can be installed and
configured to make sure your computer stays cool.

``` shell
sudo dnf install lm_sensors thinkfan
```

Next, detect the sensors and reload kernel modules that are needed after detection:

```shell
sudo sensors-detect --auto
systemctl restart systemd-modules-load
```

You'll need to create a configuration file in `/etc/thinkfan.conf` with
information about your sensors. Originally, I did this manually by running

``` shell
find /sys/devices -type f -name 'temp*_input'
```

and using the values in `/etc/thinkfile.conf` but I realized that the values can
change and kernel modules can be loaded in inconsistent orders. This can
result in `thinkfan` crashing or failing to start. I found [this
gist](https://gist.github.com/abn/de81ba413f860b00c2db3ee4aa83e035) with some
great notes and ideas for configuring `thinkfan` on an X1 Carbon Gen 5 and
adapted them a bit for my X1YG3. The configurations and modified script I used
are in the `thinkfan` directory of this repo. Inside you will find a script that
generates the `/etc/thinkfan.conf` file and 3 `.conf` files to configure
`thinkfan` to adjust how the service is started and restarted. This should work
with an X1YG3 but if you have another Thinkpad you'll probably want to
experiment a bit to make sure this works before installing. **WARNING:** the
script and service runs as `root` so read them and understand it before running
it on your system!

``` shell
chmod +x thinkfan/thinkfan-config
sudo cp thinkfan/thinkfan-config /usr/local/bin/.
sudo /usr/local/bin/thinkfan-config
cat /etc/thinkfan.conf
```

This should install the `thinkfan-conf` script and generate an
`/etc/thinkfan.conf` file for your system.

The `thinkfan` rpm should have installed two systemd unit files;
`/usr/lib/systemd/system/thinkfan.service` and
`/usr/lib/systemd/system/thinkfan-wakeup.service`. You can confirm
and review them with:

``` shell
systemctl cat thinkfan.service
```

Next, install the additional `thinkfan` service configurations, start the
service, and check that it is running. There are three `.conf` files to install:

* `00-generate-config.conf` will regenerate the `/etc/thinkfan.conf` file on
  service start or restart. This will ensure that you have a config file that
  `thinkfan` can use even if some of the sensor names have changed or kernel
  modules have loaded in different orders. It runs the `thinkfan-conf` script
  you just installed.
* `10-restart-on-failure.conf` will restart `thinkfan` if it fails to help make
  sure it is always running.
* `override.conf` provides arguments for the `thinkfan` that are called by the service.

``` shell
sudo mkdir -p /etc/systemd/system/thinkfan.service.d
sudo cp thinkfan/thinkfan.service.d/* /etc/systemd/system/thinkfan.service.d
sudo systemctl enable thinkfan.service
sudo systemctl start thinkfan.service
journalctl status thinkfan.service
```

Hopefully that will keep `thinkfan` running smoothly and help keep your X1YG3 cool!

---

## Help

### Linux Distributions

If you'd like to adapt these instructions for your distribution, please add
changes to the README and submit a pull request. Make sure that your changes
diverge only where instructions need to be different and insure that other
distribution notes stay in place.

### Pull Requests

Please submit pull requests from a branch with the following naming convention:

`<BIOS_VERSION>-<BRIEF-DESCRIPTION>` such as `1_30-ubuntu-instructions`

---

## Resources

I followed numerous other guides, scripts, and docs to create these
instructions. Here are a few that were particularly helpful.

- https://delta-xi.net/blog/#056
- https://github.com/ryankhart/x1carbon2018s3
- https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Yoga_(Gen_3)
- https://forums.lenovo.com/t5/Other-Linux-Discussions/X1-Yoga-3rd-Gen-S3-Sleep-Linux/td-p/4235264
- https://forums.lenovo.com/t5/Other-Linux-Discussions/Linux-on-the-ThinkPad-X1-Yoga-3rd-Gen/m-p/4242717
- https://uefi.org/acpi/specs
- http://man7.org/linux/man-pages/man5/dracut.conf.5.html
- http://man7.org/linux/man-pages/man8/systemd-sleep.8.html
- https://gist.github.com/ioggstream/8f380d398aef989ac455b93b92d42048#file-system-sleep-xhci-sh
- https://forums.lenovo.com/t5/Other-Linux-Discussions/X1Y3-Touchscreen-not-working-after-resume-on-Linux/td-p/4021200
- https://projectgus.com/2014/09/blacklisting-a-single-usb-device-from-linux/
- https://gist.github.com/abn/de81ba413f860b00c2db3ee4aa83e035
