#!/bin/sh
#
# This script should prevent the following suspend errors
# which can prevent the laptop from suspending properly
#
# The PCI 00:14.0 device is the usb xhci controller.
#
#    kernel: pci_pm_suspend(): hcd_pci_suspend+0x0/0x30 returns -16
#    kernel: dpm_run_callback(): pci_pm_suspend+0x0/0x120 returns -16
#    kernel: PM: Device 0000:00:14.0 failed to suspend async: error -16
#    kernel: PM: Some devices failed to suspend, or early wake event detected
#
# This script is a variation of https://gist.github.com/ioggstream/8f380d398aef989ac455b93b92d42048#file-system-sleep-xhci-sh
#
# This version logs to the journal and adds additional messages
# Copy to /usr/lib/systemd/system-sleep
#

LOG_CMD='systemd-cat -t system-sleep/xhci -p info'
TOGGLE_XHCI='echo XHC > /proc/acpi/wakeup'

if [ "${1}" == "pre" ]; then
  xhci_enabled=$(grep XHC.*enable /proc/acpi/wakeup)
  if [[ -n $xhci_enabled ]]
  then
    echo "xhci module enabled; disabling before suspending" | ${LOG_CMD}
    eval ${TOGGLE_XHCI}
  else
    echo "xhci disabled; no action needed at suspend" | ${LOG_CMD}
  fi
elif [ "${1}" == "post" ]; then
  xhci_disabled=$(grep XHC.*disable /proc/acpi/wakeup)
  if [[ -n $xhci_disabled ]]
  then
    echo "xhci module disabled; enabling at wake" | ${LOG_CMD}
    eval ${TOGGLE_XHCI}
  else
    echo "xhci enabled; no action need at wake" | ${LOG_CMD}
  fi
fi
