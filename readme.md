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
alias _do='bash <(curl -sL https://captaincore.io/do)'
```

 That allows you to use `_do` without installing anything. The alias will last for the duration of your terminal session. Want to make it persistent? Then add the alias to your `~/.bash_aliases` file or `~/.zshrc` if you use ZSH.

SSH in non-interactive mode doesn't support aliases. For that we can use the following method.
```bash
ssh username@ip-address -p 22 "bash <(curl -sL https://captaincore.io/do) help version"
```

Response would be:

```bash
Displays the current version of the _do script.

Usage: _do version
```

## Usage

The main command structure is `_do <command> [arguments]`.

Here are some real-world examples of how to use the `_do` script for common WordPress management tasks. 

### `update`: Run WordPress Updates

The `update` command streamlines the entire update process by integrating with the checkpoint system. 

  * **Run all updates securely:**
    This command will automatically create a "before" checkpoint, run all available core, theme, and plugin updates, create an "after" checkpoint, and log the changes. 

    ```bash
    _do update all
    ```

  * **Review past updates:**
    This command interactively lists all past update events, allowing you to select one and see exactly what changed (file and version differences) between the "before" and "after" states. 

    ```bash
    _do update list
    ```

### `checkpoint`: Create and Restore Manual Backups

The `checkpoint` command allows you to capture the state of your site's files (core, themes, and plugins) at any time and revert back to that state if needed. 

  * **Create a new file checkpoint:**
    Use this before making significant file changes, like editing a theme or installing a large plugin. 

    ```bash
    _do checkpoint create
    ```

  * **Revert to a previous state:**
    If a change causes an issue, you can run this command to interactively select a recent checkpoint and restore all your files to that state. 

    ```bash
    _do checkpoint revert
    ```

  * **Show what changed in a specific checkpoint:**
    Provide a checkpoint hash to see a detailed view of all file and version changes within that checkpoint. 

    ```bash
    _do checkpoint show <hash>
    ```

### `db`: Database Management

The `db` command group handles database-specific tasks like backups and optimization. 

  * **Create a database-only backup:**
    This quickly backs up just the WordPress database to a secure, private directory on the server. 

    ```bash
    _do db backup
    ```

  * **Check for large autoloaded options:**
    This helps diagnose performance issues by showing the total size of autoloaded data and listing the 25 largest options. 

    ```bash
    _do db check-autoload
    ```

  * **Optimize the database:**
    This command converts tables to the more efficient InnoDB format, cleans out expired transient records, and reports the largest tables. 

    ```bash
    _do db optimize
    ```

### `monitor`: Real-time Log Monitoring

The `monitor` command provides several ways to watch server activity as it happens. 

  * **Watch for website errors:**
    Stream your `access.log` and `error.log` in real-time, but only show lines that contain HTTP 500 status codes or PHP "Fatal" errors. 

    ```bash
    _do monitor errors
    ```

  * **See top website visitors:**
    Get a continuously updating table of the top IP addresses hitting your site, along with hit counts and status codes. 

    ```bash
    _do monitor traffic
    ```

### `slow-plugins`: Diagnose WP-CLI Performance

If `wp-cli` commands are running slowly, this tool can help identify which plugin might be the cause. 

  * **Find plugins slowing down WP-CLI:**
    This command measures the execution time of WP-CLI with each active plugin disabled one-by-one to measure its performance impact. 

    ```bash
    _do slow-plugins
    ```

### `migrate`: Automated Site Migrations

The `migrate` command automates the process of importing a WordPress site from a backup file. 

  * **Migrate a site and update its URL:**
    This will download a backup from a URL, extract it, import the database, move all files to the correct locations, and run a search-and-replace to update the site's URL to the destination environment. 

    ```bash
    _do migrate --url=https://example.com/site-backup.zip --update-urls
    ```

### `cron`: Schedule a Task

The `cron` command set allows you to schedule other `_do` commands to run automatically. 

  * **Schedule a daily update:**
    This example adds a new cron job to run the `_do update all` command every day at 4am, based on the server's timezone. 

    ```bash
    _do cron add "update all" "4am" "1 day"
    ```

### `dump`: Concatenate File Contents

This utility is useful for dumping the contents of multiple source files into a single text file for analysis or context. 

  * **Dump all shell scripts in a directory into one file:**
    This command finds all files ending in `.sh` within the `./commands/` directory and dumps their contents into a single `commands.txt` file. 

    ```bash
    _do dump "./commands/*.sh"
    ```
-----

### `vault`: Secure, Remote Snapshots

The `vault` command manages secure, full-site snapshots in a remote Restic repository, providing an off-site backup solution.

-----

#### Method 1: Piping Credentials from a File (Recommended)

This is the most secure method for running commands manually, as your credentials don't get saved in your shell's history.

**Step 1: Create a `secrets.txt` file**

First, create a file (e.g., `secrets.txt`) that contains your B2 and Restic credentials. **The order of the lines is critical.** The file must contain these five lines in this specific order:

```text
<your-b2-bucket-name>
<your-b2-repository-path>
<your-b2-key-id>
<your-b2-application-key>
<your-restic-repository-password>
```

**Step 2: Run `_do vault` Commands by Piping the File**

You can now pipe this file into any `_do vault` command.

  * **Example: Create a new snapshot**
    This command securely reads your credentials and runs a complete, encrypted backup of your WordPress files and database to the B2 repository.

    ```bash
    cat secrets.txt | _do vault create
    ```

  * **Example: List and browse existing snapshots**
    This fetches a list of all snapshots from your remote repository and allows you to interactively select one to browse its contents, view file diffs, or restore individual files.

    ```bash
    cat secrets.txt | _do vault snapshots
    ```

  * **Example: View repository information**
    This connects to the remote repository and displays statistics like total size, file count, and the dates of the oldest and newest snapshots.

    ```bash
    cat secrets.txt | _do vault info
    ```

  * **Example: Clean up the repository**
    This command safely removes old data that is no longer referenced by any snapshots, freeing up storage space. This is a potentially long-running process that locks the repository.

    ```bash
    cat secrets.txt | _do vault prune
    ```

-----

#### Method 2: Using Environment Variables (For Automation)

This method is useful for cron jobs or other automated scripts where you can securely define environment variables.

**Step 1: Export the required variables**

Set the following five environment variables in your terminal session:

```bash
export B2_BUCKET="<your-b2-bucket-name>"
export B2_PATH="<your-b2-repository-path>"
export B2_ACCOUNT_ID="<your-b2-key-id>"
export B2_ACCOUNT_KEY="<your-b2-application-key>"
export RESTIC_PASSWORD="<your-restic-repository-password>"
```

**Step 2: Run `_do vault` Commands**

Once the variables are set, you can run the commands directly.

  * **Example: Create a new snapshot**

    ```bash
    _do vault create
    ```

  * **Example: Mount the repository for Browse**
    This command mounts the entire repository as a local filesystem, allowing you to browse it with `ls` or `cd`. The mount point will be created for you, and the command runs in the foreground until you stop it with `Ctrl+C`.

    ```bash
    _do vault mount
    ```
Of course. It's a great idea to document best practices for securely handling credentials. Storing them on the same server you're backing up defeats the purpose of a secure, off-site backup.

Here is a refined version of your ideas, formatted for inclusion in the usage documentation.

-----

### Securely Running `vault` on a Remote Server

For security, you should never store your B2 or Restic credentials in a file on the WordPress server. If the server were ever compromised, your backups would be compromised as well. The `vault` command is designed to be run from a trusted local machine, sending commands and credentials to the remote server over SSH.

Here are two effective methods for secure remote execution.

#### Method 1: Simple Remote Execution (Piping Credentials)

This method is ideal when you have the `_do` script already installed on the remote server. It works by keeping the `secrets.txt` file on your local machine and piping its contents to the `_do vault` command running on the remote server.

The `_do` script is designed to read credentials from standard input if they are not set as environment variables.

  * **Example: Remotely Create a Vault Snapshot**

    This command reads your local `secrets.txt` file and pipes it over SSH to the `_do` script on the remote machine. The `_do` script then authenticates to B2 and creates the snapshot.

    ```bash
    cat /path/to/your/local/secrets.txt | ssh username@hostname.tld '_do vault create'
    ```

#### Method 2: Advanced Remote Execution (Self-Contained Payload Script)

This method is more powerful because it **does not require the `_do` script to be pre-installed** on the remote server. You create a temporary script on your local machine that bundles the credentials and the `_do` script together, send it over SSH, and execute it in one go.

You can create a reusable helper script on your local machine (e.g., `local_run_vault.sh`) to automate this process.

  * **The Workflow:**

    1.  The local script reads your `secrets.txt` file.
    2.  It generates a temporary payload file (e.g., `/tmp/payload.sh`).
    3.  It writes the credentials into the payload file as `export` commands (e.g., `export B2_BUCKET=...`).
    4.  It then appends the entire `_do.sh` script to the end of the payload file.
    5.  Finally, it pipes this complete payload file over SSH to be executed by `bash`.

  * **Example: Conceptual `local_run_vault.sh` execution**

    Once you've created your local helper script based on the logic above, running a remote vault command becomes simple and secure.

    ```bash
    # This single local command bundles and sends everything needed to the remote server.
    ./local_run_vault.sh
    ```

This approach ensures that neither the credentials nor the script itself needs to be permanently stored on the remote WordPress server, providing a high level of security for your automated backups.

```bash
#!/bin/bash

# --- Configuration ---
# Customize these paths for your local machine
SECRETS_FILE="/Users/username/Documents/secrets.txt"
DO_SCRIPT_PATH="/Users/username/Downloads/_do.sh"
SSH_TARGET="username@ipaddress -p 22"

# --- Argument Parsing for Debug Mode ---
DEBUG_MODE=false
if [[ "$1" == "--debug" ]]; then
  DEBUG_MODE=true
  echo "🐛 Debug mode enabled. SSH command will be printed instead of executed."
fi

# --- 1. Generate a unique, random name for the temporary payload file ---
RANDOM_TOKEN=$(head /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | head -c 8)
PAYLOAD_FILE="/tmp/do_vault_payload_${RANDOM_TOKEN}.sh"

echo "📝 Creating temporary payload file at: $PAYLOAD_FILE"

# --- 2. Read secrets and write 'export' commands to the payload file ---
# This block reads each line from your secrets file and builds the export commands.
{
  echo "export B2_BUCKET='$(sed -n 1p "$SECRETS_FILE")'"
  echo "export B2_PATH='$(sed -n 2p "$SECRETS_FILE")'"
  echo "export B2_ACCOUNT_ID='$(sed -n 3p "$SECRETS_FILE")'"
  echo "export B2_ACCOUNT_KEY='$(sed -n 4p "$SECRETS_FILE")'"
  echo "export RESTIC_PASSWORD='$(sed -n 5p "$SECRETS_FILE")'"
} > "$PAYLOAD_FILE"

# Error handling in case the secrets file is not found
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to create export commands. Check SECRETS_FILE path: '$SECRETS_FILE'" >&2
    rm -f "$PAYLOAD_FILE"
    exit 1
fi

# --- 3. Append the main _do script to the payload file ---
cat "$DO_SCRIPT_PATH" >> "$PAYLOAD_FILE"

# Error handling in case the _do script is not found
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to append _do script. Check DO_SCRIPT_PATH: '$DO_SCRIPT_PATH'" >&2
    rm -f "$PAYLOAD_FILE"
    exit 1
fi

# --- 4. Execute or Display the Command based on Debug Mode ---
if [[ "$DEBUG_MODE" == "true" ]]; then
  echo
  echo "--- SSH Command (not executed) ---"
  echo "cat \"$PAYLOAD_FILE\" | ssh $SSH_TARGET 'cd public/ && bash -s -- vault'"
  echo "------------------------------------"
  
  # In debug mode, ask if the user wants to keep the payload file for inspection
  read -p "Keep payload file for inspection? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    rm "$PAYLOAD_FILE"
    echo "🔥 Temporary payload file removed."
  fi
else
  # --- Execute the command for real ---
  echo "🚀 Executing remote vault command..."
  cat "$PAYLOAD_FILE" | ssh $SSH_TARGET "cd public/ && bash -s -- vault"
  
  # --- 5. Clean up the local temporary file ---
  echo "🔥 Cleaning up temporary payload file..."
  rm "$PAYLOAD_FILE"
fi

echo "Done."
```

## Development

The project includes shell scripts for development purposes:

`compile.sh`: This script combines the main script file and individual command files into a single, distributable script named `_do.sh`. It organizes the functions and adds the final execution call at the end.

`watch.sh`: This utility uses `fswatch` to monitor the main and commands directories for changes and automatically triggers the `compile.sh` script, streamlining the development process.