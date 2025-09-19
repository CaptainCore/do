# Changelog

## [1.4] - 2025-09-19

### 🚀 New Features

* **Automated Remote Site Snapshots `disembark`:** A powerful new command that uses browser automation (Playwright) to remotely log into a WordPress site, install and activate the Disembark Connector plugin, retrieve a connection token, and initiate a backup. It's a complete, hands-off solution for snapshotting a remote site without prior access.
* **Debug Mode for Browser Automation `--debug`:** The `disembark` command now includes a `--debug` flag to run the browser automation in a visible (headed) mode, making it easy to troubleshoot login or installation issues.

### ✨ Improvements

* **Selective Backups `backup --exclude`:** The `backup` command now accepts multiple `--exclude="<pattern>"` flags, allowing you to easily omit specific files or directories (like large cache folders) from the backup archive.
* **Script-Friendly Backups `backup --quiet`:** Added a `--quiet` flag to the `backup` command to suppress all informational output and print only the final backup URL, perfect for scripting and automation.
* **Contextual Performance Testing `find slow-plugins`:** The `find slow-plugins` command can now test performance against a specific front-end page render (e.g., `_do find slow-plugins /about-us`) instead of just the WP-CLI bootstrap, providing more relevant and accurate results for front-end slowdowns.

## [1.3] - 2025-08-16

### 🚀 New Features

* **Quick Archiving `zip`:** A new utility to create a zip archive of any specified folder. When run within a WordPress site, it provides a public URL for the generated archive, making it easy to share.
* **Plugin Cleanup `clean plugins`:** A new subcommand to find and delete all inactive plugins. It works safely on both single-site and multisite installations, only removing plugins that are not active anywhere in a network.

### ✨ Improvements

* **⚡️ High-Speed Image Conversion `convert-to-webp`:** The image conversion utility has been massively overhauled for performance and flexibility.
    * It now accepts an optional folder path to convert images outside the default `wp-content/uploads` directory.
    * Performance is dramatically improved by processing multiple images in parallel.
    * The script now provides clearer feedback by indicating which image detection method (`identify` or a PHP fallback) is being used.
* **Smarter Naming `dump`:** The output file from the `dump` command is now intelligently named based on the source directory (e.g., `my-plugin-dump.txt`) for better organization.

### 🐛 Bug Fixes

* **Robust Image Handling `convert-to-webp`:** The command is now more reliable, as it verifies that an image file exists before attempting to process it, preventing errors from broken file paths.

## [1.2] - 2025-07-10

### 🚀 New Features

* **🏦 Secure Snapshot Vault `vault`:** A comprehensive suite of commands for managing secure, remote, full-site snapshots using Restic and Backblaze B2. Includes creating, listing, deleting, and browsing snapshots, as well as mounting the entire backup repository.
* **🔍 Advanced Diagnostics `find`:** Centralizes several diagnostic tools under a single powerful command.
    * `find recent-files`: Finds recently modified files.
    * `find slow-plugins`: Identifies plugins slowing down WP-CLI.
    * `find hidden-plugins`: Detects active plugins hidden from the admin list.
    * `find malware`: Scans for suspicious code and verifies file integrity.
    * `find php-tags`: Scans for outdated PHP short tags.
* **🔌 Easy Plugin Installation `install`:** Simplifies installing common helper and premium plugins.
    * `install kinsta-mu`: Installs the Kinsta Must-Use plugin.
    * `install helper`: Installs the CaptainCore Helper plugin.
    * `install events-calendar-pro`: Installs The Events Calendar Pro after prompting for a license.
* **New Standalone Utilities:**
    * `https`: Applies HTTPS to all site URLs with an interactive prompt for `www` preference.
    * `launch`: A dedicated command to launch a site, updating the URL from a dev to a live domain.
    * `upgrade`: Allows the `_do` script to upgrade itself to the latest version.
    * `email`: Provides an interactive prompt to send an email using `wp_mail` via WP-CLI.
* **⚙️ Database Prefix Changer `db change-prefix`:** Safely changes the database table prefix after automatically creating a backup.

### ✨ Improvements

* **New Command Flags:** Added several flags for non-interactive use and more control:
    * `--all` for `convert-to-webp` to convert all images regardless of size.
    * `--domain` for `launch` to specify the new domain for scripting.
    * `--force` for `install kinsta-mu` to bypass the Kinsta environment check.
    * `--output` for `vault snapshots` to provide a non-interactive list.
* **🛠️ Advanced Dependency Sideloading:** `_do` can now automatically download and use tools like `restic`, `git`, and `imagemagick` in a private directory if they aren't installed system-wide. The ImageMagick setup cleverly extracts the `identify` binary from an AppImage to avoid system installation and FUSE issues.
* **Reliable WebP Detection:** The `convert-to-webp` command no longer requires a system-installed `identify` command. It now uses the automatically sideloaded ImageMagick binary and includes a PHP fallback to reliably check if an image is already a WebP file.
* **Command Organization:** Refactored several commands into logical groups for better usability (e.g., `reset-wp` is now `reset wp`, `slow-plugins` is now `find slow-plugins`).
* **Private Directory Discovery:** The script is now much smarter at finding a writable private directory, checking WP-CLI configs, WPEngine paths, and common parent structures (`../private`) before falling back to the home directory.
* **Public Dump URL:** The `dump` command now generates a public URL for the created text file if run within a WordPress site.

### 🐛 Bug Fixes

* **Cross-Platform PHP Tag Scanning `php-tags`:** Rewrote the command to use a more portable `grep` syntax, ensuring it works correctly on systems like macOS where the `-P` flag is not available by default.

## [1.1] - 2025-06-21

### 🚀 New Features

* **💾 Checkpoint Management `checkpoint`:** A full suite to create, list, show, and revert WordPress installation checkpoints. Capture the state of your site's core, themes, and plugins and easily roll back changes.
* **🔄 Integrated Update Management `update`:** Streamlines the WordPress update process. `update all` automatically creates 'before' and 'after' checkpoints around the updates, logging all changes for easy review.
* **⏰ Cron Job Management `cron`:** Schedule any `_do` command to run at specific intervals. Includes commands to `enable`, `list`, `add`, `delete`, and `run` scheduled tasks.
* **🩺 WP-CLI Health Checker `wpcli`:** A new utility to diagnose issues with WP-CLI itself by identifying themes or plugins that cause warnings.
* **💥 Site Reset `reset-wp`:** A powerful command to reset a WordPress installation to its default state, reinstalling core and the latest default theme.
* **🧹 Advanced Cleaning `clean`:**
    * `clean themes`: Deletes all inactive themes while preserving the latest default WordPress theme.
    * `clean disk`: Launches an interactive disk usage analyzer to find and manage large files.
* **⚙️ Database Optimization `db optimize`:** A new command to convert tables to InnoDB, clean transients, and report the largest tables.

### ✨ Improvements

* **Command Structure:** Refactored commands for better organization. `backup-db` is now `db backup`, and `monitor` is now a subcommand with specific targets (`traffic`, `errors`, etc.).
* **🛠️ Automated Dependency Handling:** The script now automatically checks for, downloads, and installs missing dependencies like `gum`, `cwebp`, and `rclone` into a `~/private` directory.
* **🏗️ Development Workflow:** Added `compile.sh` and `watch.sh` scripts to streamline development by combining source files into a single distributable script automatically.
* **Flexible Migrations `migrate`:** Added an `--update-urls` flag to control URL replacement and improved temporary file handling.
* **File Exclusion `dump`:** The `dump` command was enhanced with an `-x` flag to exclude specific files or directories.

### 🐛 Bug Fixes

* **Migration File Handling:** The `migrate` function now handles cases where `wp-content` exists but contains no plugins or themes, preventing errors.
* **Dump Self-Exclusion:** The `dump` command now explicitly excludes its own output file to prevent it from being included in the dump.

## [1.0] - 2025-06-10

### 🎉 Initial Release

* **Full and Database Backups `backup`, `backup-db`**: Create full-site (files + DB) and database-only backups.
* **Real-time Traffic Monitoring `monitor`**: Watch server access logs in real-time with a summarized view of top hits.
* **Performance Profiling `slow-plugins`**: Identify WordPress plugins that slow down WP-CLI commands.
* **Image Optimization `convert-to-webp`**: Find and convert large JPG/PNG images to the modern WebP format.
* **Site Migration `migrate`**: Automate migrating a WordPress site from a backup URL or local file.
* **File Content Dumper `dump`**: Concatenate the contents of files matching a pattern into a single text file.
* **Database Autoload Checker `db-check-autoload`**: Check the size of autoloaded options in the database.
* **Permission Resetter `reset-permissions`**: Reset file and folder permissions to standard defaults (755/644).
* **Site Suspension `suspend`**: Activate or deactivate a "Website Suspended" maintenance page.