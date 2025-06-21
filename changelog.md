# Changelog

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