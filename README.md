# MahiruSleep-XOS16-G200

CPU screen-off power profile for Infinix X6885 (MediaTek Helio G200) running XOS 16.

## Scope

When the display turns off, this module applies a conservative CPU profile:
- CPU3, CPU4, CPU5, and CPU7 are taken offline (when supported).
- CPU policy governors are changed to `powersave`.
- CPU policy maximum frequencies are capped.

When the display turns on, the module restores the saved CPU online states, governors, and maximum frequencies.

This repository is CPU-only. It does not modify ZRAM, swap, VM tunables, or module-manager binaries/integration.

## Target device

- Device: Infinix X6885
- SoC: MediaTek Helio G200
- OS: XOS 16 / Android 16
- Tested sysfs layout:
  - Backlight: `/sys/class/leds/lcd-backlight/brightness`
  - CPU policy0: CPUs 0-5, stock governor observed: `schedutil`, maximum: `2200000`
  - CPU policy6: CPUs 6-7, stock governor observed: `schedutil`, maximum: `2600000`

The script discovers each policy's current governor and maximum frequency at runtime instead of assuming those saved values.

## Installation

1. Download the repository as a ZIP (Code -> Download ZIP).
2. Open your root module manager.
3. Install the ZIP using its local module installation option.
4. Reboot.
5. Verify the service is running and check the logs at:
   `/data/local/tmp/mahirusleep-xos16-g200.log`

Root access is required. Compatibility with other devices, kernels, or XOS versions is not guaranteed.

## Behaviour and safety

- The profile is applied only after the script detects the display is off.
- Original values are recorded before changes and restored when the display turns on.
- A cleanup trap attempts to restore the original values if the service exits.
- If the required sysfs nodes are unavailable, the script skips the unsupported operation.
- CPU hotplug and frequency controls are kernel-dependent. Test on the target device before relying on the module.

This is an experimental device-specific module. Keep a way to disable or uninstall it from recovery if your device behaves unexpectedly.

## Development status

Initial XOS 16 / Helio G200 implementation. Runtime behaviour still requires on-device testing, especially display transition detection and hotplug support.

## License

MIT. See [LICENSE](LICENSE).
