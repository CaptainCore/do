# CaptainCore `_do`

A collection of useful command-line utilities for managing WordPress websites. These tools are designed to streamline common administrative tasks such as backups, performance analysis, media optimization, and site migrations.

## Features

-   **Database & Full Site Backups**: Easily create database-only or full-site (files + database) backups.
-   **Real-time Traffic Monitoring**: Watch your server's access logs in real-time with a clean, readable table format.
-   **Performance Profiling**: Identify slow WordPress plugins that may be impacting WP-CLI performance.
-   **Disk Usage Analysis**: Interactively analyze disk space usage to find large files and directories.
-   **Image Optimization**: Find and convert large images to the modern, efficient WebP format.
-   **Automated Site Migrations**: Migrate a WordPress site from a URL or local backup file with a single command.

## Prerequisites

Before using these tools, you need to have the following command-line utilities installed on your server:

-   **[wp-cli](https://wp-cli.org/)**: The command-line interface for WordPress.
-   **[wget](https://www.gnu.org/software/wget/)**: For downloading files from the web.
-   **[zip](https://infozip.sourceforge.net/Zip.html)** / **[unzip](https://infozip.sourceforge.net/UnZip.html)**: For creating and extracting zip archives.
-   **[tar](https://www.gnu.org/software/tar/)**: For handling `.tar.gz` archives.
-   **[rsync](https://rsync.samba.org/)**: For efficient file transfers.
-   **[ImageMagick](https://imagemagick.org/)**: Specifically, the `identify` command is used for checking image formats.
-   **[mysqldump](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)** or **[mariadb-dump](https://mariadb.com/kb/en/mariadb-dump/)**: For creating database backups.

### Automatic Dependencies

The script will automatically handle the installation of the following tools if they are not found:

-   **[gum](https://github.com/charmbracelet/gum)**: A tool for creating glamorous shell scripts. Used by the `monitor_traffic` command.
-   **[cwebp](https://developers.google.com/speed/webp/docs/cwebp)**: The WebP encoder. Used by the `convert_to_webp` command.
-   **[rclone](https://rclone.org/)**: A versatile cloud storage tool. Used by the `clean disk` command for its interactive disk usage feature.

These tools will be downloaded and installed into a `~/private` directory in your home folder.

## Installation

The easiest way to use CaptainCore `_do` is by defining an alias to [captaincore.io/do](https://captaincore.io/do).

```bash
alias _do='curl -sL https://captaincore.io/do | bash -s'
```

 That allows you to use `_do` without installing anything. The alias will last for the duration of your terminal session. Want to make it persistent? Then add the alias to your `~/.bash_aliases` file or `~/.zshrc` if you use ZSH.

SSH in non-interactive mode doesn't support aliases. For that we can use the following method.
```bash
ssh username@ip-address -p 22 "_do() { curl -sL https://captaincore.io/do | bash -s -- \"\$@\"; }; \
_do help version"
```

Response would be:

```bash
Displays the current version of the _do script.

Usage: _do version
```

## Usage

The main command structure is `_do <command> [arguments]`.

## Development

The project includes shell scripts for development purposes:

`compile.sh`: This script combines the main script file and individual command files into a single, distributable script named `_do.sh`. It organizes the functions and adds the final execution call at the end.

`watch.sh`: This utility uses `fswatch` to monitor the main and commands directories for changes and automatically triggers the `compile.sh` script, streamlining the development process.