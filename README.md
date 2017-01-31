# Palette Insight Architecture

![Palette Insight Architecture](https://github.com/palette-software/palette-insight/blob/master/insight-system-diagram.png?raw=true)

# Palette Insight Toolkit

[Palette Insight]: https://github.com/palette-software/palette-insight
[LoadTables]:      https://github.com/palette-software/insight-gp-import
[Reporting]:       https://github.com/palette-software/insight-reporting-framework


## What is Palette Insight Toolkit?

This repository contains various helper scripts which are essential for running
and updating the [Palette Insight] software.

## How do I set up Palette Insight Toolkit?

### Packaging

To build the package you may use the [create_rpm.sh](create_rpm.sh) script:

```bash
export VERSION=v2.0.123

./create_rpm.sh
```

### Installation

The most convenient is to build the RPM package and install it using either yum or rpm.
It does require and install the other necessary components and services.

The following process is executed by the installer:

- the `/var/log/insight-toolkit` directory is created
- the `/var/lib/palette` directory is created
- the files from the `scripts` directory are copied to `/opt/insight-toolkit`
- creates the `insight` sudoer without tty and passwordless user
- installs the [insight-toolkit-cron](insight-toolkit-cron) crontab file for `insight` user
  - it schedules the periodical execution of [LoadTables] and [Reporting]
- makes sure that the `python3` and `pip3` executables exist

## How can I test-drive Palette Insight Toolkit?

You may execute the files in the script directory.

## Is Palette Insight Toolkit supported?

Palette Insight Toolkit is licensed under the GNU GPL v3 license. For professional support please contact developers@palette-software.com

Any bugs discovered should be filed in the [Palette Insight Toolkit Git issue tracker](https://github.com/palette-software/insight-toolkit/issues) or contribution is more than welcome.
