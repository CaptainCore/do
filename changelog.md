# Changelog

An analysis of the two script versions reveals significant enhancements in version 1.2, focusing on new features, improved dependency management, and increased command organization.

## [1.2] - 2025-07-10

### Added

* **New `vault` Command Suite:** A comprehensive set of commands for managing secure, remote, full-site snapshots using Restic and Backblaze B2. This includes creating, listing, deleting, and Browse snapshots, as well as mounting the entire backup repository.
* **New `find` Command Suite:** Centralizes several diagnostic tools under a single command:
    * `find recent-files`: Finds files modified within a specified number of days.
    * `find slow-plugins`: Relocated from a top-level command to identify plugins that may be slowing down WP-CLI.
    * `find hidden-plugins`: Detects active plugins that may be hidden from the standard list.
    * `find malware`: Scans for suspicious code patterns and verifies core and plugin file integrity.
    * `find php-tags`: Scans for outdated PHP short tags.
* **New `install` Command Suite:** Simplifies the installation of helper and premium plugins:
    * `install kinsta-mu`: Installs the Kinsta Must-Use plugin.
    * `install helper`: Installs the CaptainCore Helper plugin.
    * `install events-calendar-pro`: Installs The Events Calendar Pro after prompting for a license.
* **New Standalone Commands:**
    * `https` Applies HTTPS to all site URLs with an interactive prompt for 'www' preference.
    * `launch`: A dedicated command to launch a site, updating the URL from a development to a live domain.
    * `upgrade`: Allows the `_do` script to upgrade itself to the latest version.
    * `email`: Provides an interactive prompt to send an email using `wp_mail` via WP-CLI.
* **New `db` Subcommand:**
    * `db change-prefix`: Safely changes the database table prefix after creating a backup.
* **Advanced Dependency Sideloading:**
    * Introduced new `setup_restic`, `setup_imagemagick`, and `setup_git` functions to automatically download and use these tools in a private directory if they are not installed system-wide.
    * The ImageMagick setup cleverly extracts the `identify` binary from an AppImage to avoid system-level installation and FUSE issues.
* **New Flags:**
    * `--all` for `convert-to-webp` to convert all images regardless of their file size.
    * `--domain` for `launch` to specify the new domain non-interactively.
    * `--force` for `install kinsta-mu` to bypass the Kinsta environment check.
    * `--output` for `vault snapshots` to provide a non-interactive list.

### Changed

* **Command Refactoring:**
    * The `reset-wp` command has been moved to `reset wp`. It now features a more user-friendly interactive selector for choosing the admin user, rather than requiring a command-line flag.
    * The `reset-permissions` command has been moved to `reset permissions`.
    * The `slow-plugins` command has been moved to `find slow-plugins`.
* **Dependency Management Overhaul:** The `setup_*` functions (e.g., `setup_gum`, `setup_cwebp`, `setup_rclone`) have been completely rewritten. They are now more robust, checking for existing local binaries, using `curl` for downloads, and intelligently finding the executable within archives before extraction.
* **Private Directory Discovery:** The `_get_private_dir` helper function is now significantly more intelligent. It checks WP-CLI configurations, WPEngine-specific paths, and common parent directory structures (`../private`, `../tmp`) before falling back to the user's home directory.
* **WebP Conversion:** The `convert-to-webp` command no longer relies on a system-installed `identify` command. It now uses the sideloaded ImageMagick binary and includes a PHP-based fallback (`_is_webp_php`) to check if a file is already in WebP format.
* **Dump Command URL:** The `dump` command will now generate and display a public URL for the created text file if the script is run within a WordPress installation.
* **Database Autoload Check:** The query in `db check-autoload` was updated to check for `autoload IN ('yes', 'on')` to be compatible with more database configurations.

### Fixed

* **PHP Tag Scanning Portability:** The `php-tags` command was rewritten to use a more portable `grep` syntax, removing the dependency on the `-P` (Perl-compatible regex) flag. This ensures the command works correctly on systems like macOS where this flag is not available by default.

## [1.1] - 2025-06-21

### Features

-   **Checkpoint Management (`checkpoint`)**: A comprehensive suite of commands has been added to create, list, show, and revert WordPress installation checkpoints.  This feature allows users to capture the state of their site's core, themes, and plugins and revert to a previous state if needed.
    -   `checkpoint create`: Creates a new checkpoint. 
    -   `checkpoint list`: Interactively lists all available checkpoints for inspection. 
    -   `checkpoint list-generate`: Generates a detailed, cached list of checkpoints for faster access. 
    -   `checkpoint revert [<hash>]`: Reverts the site's files to a specified checkpoint. 
    -   `checkpoint show <hash>`: Shows the changes within a specific checkpoint, including file and manifest diffs. 
    -   `checkpoint latest`: Displays the hash of the most recent checkpoint. 
-   **Update Management (`update`)**: This new command set streamlines the WordPress update process by integrating with the checkpoint system. 
    -   `update all`: Automatically creates a 'before' checkpoint, runs all core, plugin, and theme updates, creates an 'after' checkpoint, and logs the changes. 
    -   `update list`: Shows a list of past update events, allowing users to inspect the changes between the 'before' and 'after' states. 
    -   `update list-generate`: Generates a detailed, cached list of all update events. 
-   **Cron Job Management (`cron`)**: Enables the scheduling of `_do` commands. 
    -   `cron enable`: Configures a system cron job to run scheduled `_do` tasks. 
    -   `cron list`: Lists all scheduled commands. 
    -   `cron add`: Adds a new command to the schedule with a specified start time and frequency. 
    -   `cron delete`: Removes a scheduled command by its ID. 
    -   `cron run`: Executes any due commands. 
-   **WP-CLI Health Checker (`wpcli`)**: A new utility to diagnose issues with WP-CLI itself. 
    -   `wpcli check`: Helps identify themes or plugins that are causing warnings or errors in WP-CLI. 
-   **Site Reset (`reset-wp`)**: A command to reset a WordPress installation to its default state.  It reinstalls the latest WordPress core, removes all plugins and themes, and installs the latest default theme.
-   **PHP Tag Checker (`php-tags`)**: Scans a directory for outdated PHP short tags (`<?`) that can cause issues on modern servers. 
-   **Inactive Theme Cleaner (`clean themes`)**: Deletes all inactive themes, but intelligently preserves the latest default WordPress theme as a fallback. 
-   **Interactive Disk Cleaner (`clean disk`)**: Launches an interactive disk usage analyzer to help find and manage large files and directories. 
-   **Database Optimization (`db optimize`)**: A new command to optimize the WordPress database by converting tables to InnoDB, cleaning transients, and reporting the largest tables. 

### Improvements

-   **Command Structure & Aliases**: The script has been refactored for better organization. Commands like `backup-db` and `db-check-autoload` are now subcommands under the `db` command (`db backup`, `db check-autoload`). 
-   **Dependency Management**:
    -   The script now automatically checks for, downloads, and installs missing dependencies like `gum`, `cwebp`, and `rclone` into a `~/private` directory to avoid system-wide installations. 
    -   `git` is now a required dependency for the new `checkpoint` and `update` features. 
-   **Compilation and Development**:
    -   `compile.sh`: A new compilation script is introduced to combine the main script and individual command files from the `commands` directory into a single distributable file (`_do.sh`). 
    -   `watch.sh`: A watcher script has been added to automatically re-compile the script when changes are detected in the source files, streamlining development. 
-   **Monitor Command**: The `monitor` command is now a subcommand with more specific targets: `traffic`, `errors`, `access.log`, and `error.log`. 
-   **Suspend Command**: The `suspend` command now uses a more specific filename (`do-suspend.php`) for the mu-plugin to avoid conflicts. 
-   **Migration (`migrate`)**:
    -   The `migrate` command now has a `--update-urls` flag to control whether the site's URL should be updated after import. 
    -   It now intelligently finds a private directory for storing temporary files. 
-   **File Dumper (`dump`)**: The `dump` command has been enhanced with an `-x` flag to allow for the exclusion of specific files or directories from the dump. 

### Fixes

-   **Migration File Handling**: The `migrate_site` function was updated to handle cases where `wp-content` exists in the backup but contains no plugins or themes to move, preventing potential errors.
-   **Dump Command Self-Exclusion**: The `run_dump` function now explicitly excludes its own output file from the list of files to be dumped, preventing it from including itself in the generated text file. 

## [1.0] - 2025-06-10

### Added

-   **Initial Release**: The first version of the `_do` script.
-   **Full and Database Backups (`backup`, `backup-db`)**: Utilities to create full-site (files + database) backups and database-only backups. 
-   **Real-time Traffic Monitoring (`monitor`)**: A command to watch server access logs in real-time, displaying top hits in a readable format. 
-   **Performance Profiling (`slow-plugins`)**: A tool to identify WordPress plugins that may be slowing down WP-CLI command execution. 
-   **Image Optimization (`convert-to-webp`)**: Finds and converts large JPG and PNG images to the more efficient WebP format. 
-   **Site Migration (`migrate`)**: A command to automate the migration of a WordPress site from a backup URL or local file. 
-   **File Content Dumper (`dump`)**: A utility to concatenate the contents of files matching a specific pattern into a single text file. 
-   **Database Autoload Checker (`db-check-autoload`)**: A tool to check the size and top 25 largest autoloaded options in the WordPress database. 
-   **Permission Resetter (`reset-permissions`)**: A command to reset file and folder permissions to standard defaults (755 for directories, 644 for files). 
-   **Site Suspension (`suspend`)**: A utility to activate or deactivate a "Website Suspended" message for visitors. 
-   **Automatic Dependency Installation**: The script automatically downloads and installs `gum` and `cwebp` if they are not found on the system.