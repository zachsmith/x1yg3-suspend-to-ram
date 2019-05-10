# Lenovo X1 Yoga (3rd Gen) Suspend-to-Ram on Linux

The Lenovo X1 Yoga (3rd Gen) (X1YG3) BIOS does not expose support for Suspend-to-Ram
(S3). Instead, it exposes [Modern
Standby](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby) (Si03)
which is a low-power idle approach to suspend. Unfortunately, Linux does not
currently provide good support for Modern Standby which leads to awful power drain
when trying to put the X1YG3 to sleep. Lenovo has implemented S3 support as an
option in a BIOS update to the X1 Carbon (6th Gen) (X1CG6) but has thus far opted not to port the
same support to the X1YG3 BIOS.

Fortunately, you can enable S3 support by modifying the firmwares ACPI Differentiated
System Description Table (DSDT) that is loaded by your Linux kernel. It would be
nice if Lenovo would add support but it has been over a year so I'm not holding
out much hope at this point. That said, if you dual-boot your X1YG3, you may not
want to enable S3 support in the BIOS and might want to keep patching your DSDT
because Windows would need to be reinstalled. Yes, you read that right - there is no way
to configure Windows that was installed on a Modern Standby system to use S3
once enabled; you need to reinstall.

These instructions are for Fedora but I hope others can provide pull requests with
updated instructions for other distributions.

## Prerequisites

This should go without saying, but **if you follow this guide you are
responsible for any damage you do to your machine.** These instructions worked
for me and I have no reason to believe they will cause problems but proceed at
your own risk.

### Disable SecureBoot

If you see `SecureBoot disabled` after running the following command, you're all
set. If you don't, you need to disable SecureBoot in the BIOS.

``` shell
mokutil --sb-state # should display SecureBoot disabled
```

### Check current ACPI support

``` shell
dmesg | grep "ACPI: (supports"
```

This command should return something like `ACPI: (supports S0 S4 S5)` which as
you can see is missing S3 support.

### Ensure _iasl_ is installed

``` shell
which iasl
```

Should return the path to `iasl` like `/usr/bin/iasl`. If it is not
installed, you can install it with:

``` shell
sudo dnf install acpica-tools
```

### Check your BIOS version

``` shell
sudo dmidecode -s bios-version
```
Should return something like `N25ET44W (1.30 )`. _These instructions were
written with BIOS version_ `1.30`.

If `dmidecode` is missing, you can install it with:

``` shell
sudo dnf dmidecode
```

### Clone this repository and change directory

``` shell
git clone https://github.com/zachsmith/x1yg3-suspend-to-ram.git
cd x1yg3-suspend-to-ram
```

## Patch the Differentiated System Description Table (DSDT)

### Copy the current DSDT table exposed by the BIOS

``` shell
sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.dat
```

### Decompile the DSDT

This will produce a _dsdt.dsl_ file:

``` shell
iasl -d dsdt.dat
```

### Patch the DSL file

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

### Recompile the DSDT

This will produce a _dsdt.aml_ file:

``` shell
iasl -tc -ve dsdt.dsl
```

## Update _initramfs_ image

We are going to utilize `dracut` which is used by Fedora (and numerous other
distributions) to build initramfs images. `dracut` allows you to provide
overridden ACPI tables to build into an image which is exactly what we need.
This approach will include our updated tables in future initramfs images
generated automatically (by kernel updates) or manually (like we'll do here).

### Copy updated DSDT table

``` shell
sudo mkdir /boot/acpi_override
sudo cp dsdt.aml /boot/acpi_override/x1yg3-s3-override.aml
```

### Configure ACPI override for `dracut`

Create `/etc/dracut.conf.d/acpi.conf` and add the following lines:

``` shell
acpi_override="yes"
acpi_table_dir="/boot/acpi_override"
```

### Rebuild your initramfs image

Update the initramfs image for your _current_ kernel.

``` shell
cd /boot
sudo dracut --force initramfs-$(uname -r).img
```

## Make sleep default to _deep_

First, look at your current `mem_sleep` values

``` shell
cat /sys/power/mem_sleep
```

Which should return `[s2idle]`. We want to make sure that `deep` (S3) becomes
the default. To do that, we need to pass a parameter to the kernel at boot time
which we can do by editing our `grub` configuration. This change will insure that
future kernels will also receive this parameter at boot.

### Edit `/etc/default/grub`

Append the following to the end of the string defined by `GRUB_CMDLINE_LINUX`:

`mem_sleep_default=deep`

### Rebuild `grub.cfg`

``` shell
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

## Final Steps

At this point you should have patched your DSDT, rebuilt your `initramfs` for
your current kernel, and rebuilt your `grub` configuration. You should be ready
to reboot your computer to check that everything works.

_**Note: If you haven't already disabled secure boot, make sure to do it now before your
system boots with the overridden DSDT table.**_

## Reboot

### Confirm S3 support

``` shell
dmesg | grep "ACPI: (supports"
```

It should now display `ACPI: (supports S0 S3 S4 S5)` which includes S3. This
means that your patched DSDT loaded.

### Confirm _deep_ sleep is default

``` shell
cat /sys/power/mem_sleep
```

This should now display `s2idle [deep]` (_the `[]`'s indicate default_). This means
that your `grub` configuration passed the parameter to the kernel at boot.

### Go to sleep!

Go ahead and enjoy the convenience of putting your computer to sleep!

### Going forward

You should probably repeat these steps after each BIOS update. I'll try and keep the
patch updated for new BIOS versions (if needed) or accept pull requests if
anybody would like to pitch in. See the _Pull Requests_ guidelines below.

## Help

### Linux Distributions

If you'd like to adapt these instructions for your distribution, please add
changes to the README and submit a pull request.

### Pull Requests

Please submit pull requests from a branch with the following naming convention:

`<BIOS_VERSION>-<BRIEF-DESCRIPTION>` such as `1_30-ubuntu-instructions`

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
