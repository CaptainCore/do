# CaptainCore Do

A collection of useful command-line utilities for managing WordPress hosting environments. These tools are designed to streamline common administrative tasks such as backups, performance analysis, media optimization, and site migrations.

## Features

-   **Database & Full Site Backups**: Easily create database-only or full-site (files + database) backups.
-   **Real-time Traffic Monitoring**: Watch your server's access logs in real-time with a clean, readable table format.
-   **Performance Profiling**: Identify slow WordPress plugins that may be impacting WP-CLI performance.
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

These tools will be downloaded and installed into a `~/private` directory in your home folder.

## Installation

The easiest way to try CaptainCore Do is by defining an alias to [captaincore.io/do](https://captaincore.io/do). That allows you to use `captaincore-do` without actually installing anything. This will last for the duration of your terminal session. You can also shorthand the alias. Maybe `_do` fits your style better?

```bash
alias captaincore-do='curl -sL https://captaincore.io/do | bash -s'
alias _do='curl -sL https://captaincore.io/do | bash -s'
```

SSH in non-interactive mode doesn't support aliases. For that we can use the following patch in method.
```bash
ssh username@ip-address -p 22 "captaincore-do() { curl -sL https://captaincore.io/do | bash -s -- \"\$@\"; }; \
captaincore-do version"

captaincore-do version 1.0
```

Lastly, to install `captaincore-do`, follow these steps (coming soon).

## Usage

The main command structure is `captaincore-do <command> [arguments]`.