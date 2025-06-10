#!/bin/bash

# --------------------------------------
#  Command: captaincore-do
#  Description: A collection of useful command-line utilities for managing WordPress sites.
#  Author: Austin Ginder
#  License: MIT
# --------------------------------------

# --- Global Variables ---
CAPTAINCORE_DO_VERSION="1.0"
GUM_VERSION="0.14.4"
CWEBP_VERSION="1.5.0"
GUM_CMD=""
CWEBP_CMD=""

# --- Helper Functions ---

# --------------------------------------
#  Checks for and installs 'gum' if not present. Sets GUM_CMD on success.
# --------------------------------------
function setup_gum() {
    #  Return if already found
    if [[ -n "$GUM_CMD" ]]; then return 0; fi

    #  If gum is already in the PATH, we're good to go.
    if command -v gum &> /dev/null; then
        GUM_CMD="gum"
        return 0
    fi

    local gum_dir="gum_${GUM_VERSION}_Linux_x86_64"
    local gum_executable="$HOME/private/${gum_dir}/gum"
    
    #  Check for a local installation
    if [ -f "$gum_executable" ] && "$gum_executable" --version &> /dev/null; then
        GUM_CMD="$gum_executable"
        return 0
    fi

    #  If not found or not working, download it
    echo "Required tool 'gum' not found. Installing to ~/private..." >&2
    mkdir -p "$HOME/private"
    cd "$HOME/private" || { echo "Error: Could not enter ~/private." >&2; return 1; }

    local gum_tarball="${gum_dir}.tar.gz"
    if ! wget --quiet "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/${gum_tarball}" || ! tar -xf "${gum_tarball}"; then
        echo "Error: Failed to download or extract gum." >&2
        cd - > /dev/null
        return 1
    fi
    rm -f "${gum_tarball}"

    #  Final check
    if [ -f "$gum_executable" ] && "$gum_executable" --version &> /dev/null; then
        echo "'gum' installed successfully." >&2
        GUM_CMD="$gum_executable"
    else
        echo "Error: gum installation failed." >&2
        cd - > /dev/null
        return 1
    fi
    cd - > /dev/null
}

# --------------------------------------
#  Checks for and installs 'cwebp' if not present. Sets CWEBP_CMD on success.
# --------------------------------------
function setup_cwebp() {
    #  Return if already found
    if [[ -n "$CWEBP_CMD" ]]; then return 0; fi

    #  If cwebp is already in the PATH, we're good to go.
    if command -v cwebp &> /dev/null; then
        CWEBP_CMD="cwebp"
        return 0
    fi
    
    local cwebp_dir="libwebp-${CWEBP_VERSION}-linux-x86-64"
    local cwebp_executable="$HOME/private/${cwebp_dir}/bin/cwebp"

    #  Check for a local installation
    if [ -f "$cwebp_executable" ] && "$cwebp_executable" -version &> /dev/null; then
        CWEBP_CMD="$cwebp_executable"
        return 0
    fi

    echo "Required tool 'cwebp' not found. Installing to ~/private..." >&2
    mkdir -p "$HOME/private"
    cd "$HOME/private" || { echo "Error: Could not enter ~/private." >&2; return 1; }

    local cwebp_tarball="${cwebp_dir}.tar.gz"
    if ! wget --quiet "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/${cwebp_tarball}" || ! tar -xzf "${cwebp_tarball}"; then
        echo "Error: Failed to download or extract cwebp." >&2
        cd - > /dev/null
        return 1
    fi
    rm -f "${cwebp_tarball}"

    #  Final check
    if [ -f "$cwebp_executable" ] && "$cwebp_executable" -version &> /dev/null;
        then
        echo "'cwebp' installed successfully." >&2
        CWEBP_CMD="$cwebp_executable"
    else
        echo "Error: cwebp installation failed." >&2
        cd - > /dev/null
        return 1
    fi
    cd - > /dev/null
}

# --------------------------------------
#  Displays detailed help for a specific command.
# --------------------------------------
function show_command_help() {
    local cmd="$1"
    #  If no command is specified, show the general usage.
    if [ -z "$cmd" ]; then
        show_usage
        return
    fi

    #  Display help text based on the command provided.
    case "$cmd" in
        backup)
            echo "Creates a full backup (files + DB) of a WordPress site." 
            echo
            echo "Usage: captaincore-do backup <folder>"
            ;;
        backup-db)
            echo "Performs a DB-only backup to a secure private directory."
            echo
            echo "Usage: captaincore-do backup-db"
            ;;
        db-check-autoload)
            echo "Checks the size and top 25 largest autoloaded options in the DB."
            echo
            echo "Usage: captaincore-do db-check-autoload"
            ;;
        dump)
            echo "Dumps the content of files matching a pattern into a single text file."
            echo
            echo "Usage: captaincore-do dump \"<path/to/folder/*.extension>\""
            echo
            echo "Arguments:"
            echo "  <pattern>   (Required) The path and file pattern to search for, enclosed in quotes."
            echo
            echo "Example:"
            echo "  captaincore-do dump \"wp-content/plugins/my-plugin/**/*.php\""
            ;;
        convert-to-webp)
            echo "Finds and converts large images (JPG, PNG) to WebP format."
            echo
            echo "Usage: captaincore-do convert-to-webp"
            ;;
        migrate)
            echo "Migrates a site from a backup snapshot."
            echo
            echo "Usage: captaincore-do migrate --url=<backup-url> [--update-urls]"
            echo
            echo "  --update-urls   Update urls to destination WordPress site. Default will keep source urls."
            ;;
        monitor)
            echo "Monitors server access logs in real-time."
            echo
            echo "Usage: captaincore-do monitor [--top=<number>] [--now]"
            echo
            echo "Optional Flags:"
            echo "  --top=<number>   The number of top IP/Status combinations to show. Default is 25."
            echo "  --now            Start processing from the end of the log file instead of the beginning."
            ;;
        reset-permissions)
            echo "Resets file and folder permissions to defaults (755 for dirs, 644 for files)."
            echo
            echo "Usage: captaincore-do reset-permissions"
            ;;
        slow-plugins)
            echo "Identifies plugins that may be slowing down WP-CLI."
            echo
            echo "Usage: captaincore-do slow-plugins"
            ;;
        suspend)
            echo "Activates or deactivates a suspend message shown to visitors."
            echo
            echo "Usage: captaincore-do suspend <subcommand> [flags]"
            echo
            echo "Subcommands:"
            echo "  activate      Activates the suspend message. Requires --name and --link flags."
            echo "  deactivate    Deactivates the suspend message."
            echo
            echo "Flags for 'activate':"
            echo "  --name=<business-name>      (Required) The name of the business to display."
            echo "  --link=<business-link>      (Required) The contact link for the business."
            echo "  --wp-content=<path>         (Optional) Path to wp-content directory. Defaults to 'wp-content'."
            echo
            echo "Flags for 'deactivate':"
            echo "  --wp-content=<path>         (Optional) Path to wp-content directory. Defaults to 'wp-content'."
            ;;
        version)
            echo "Displays the current version of the captaincore-do script."
            echo
            echo "Usage: captaincore-do version"
            ;;
        *)
            echo "Error: Unknown command '$cmd' for help." >&2
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# --------------------------------------
#  Displays the main help and usage information.
# --------------------------------------
function show_usage() {
    echo "CaptainCore Do (v$CAPTAINCORE_DO_VERSION)"
    echo "--------------------------"
    echo "A collection of useful command-line utilities."
    echo ""
    echo "Usage:"
    echo "  captaincore-do <command> [arguments] [--flags]"
    echo ""
    echo "Available Commands:"
    echo "  backup              Creates a full backup (files + DB) of a WordPress site."
    echo "  backup-db           Performs a DB-only backup to a secure private directory."
    echo "  convert-to-webp     Finds and converts large images (JPG, PNG) to WebP format."
    echo "  db-check-autoload   Checks the size of autoloaded options in the database."
    echo "  dump                Dumps the content of files matching a pattern into a single text file."
    echo "  migrate             Migrates a site from a backup URL or local file."
    echo "  monitor             Monitors server access logs in real-time with top IP/status hits."
    echo "  reset-permissions   Resets file and folder permissions to defaults."
    echo "  slow-plugins        Identifies plugins that may be slowing down WP-CLI."
    echo "  suspend             Activates or deactivates a suspend message shown to visitors."
    echo "  version             Displays the current version of the captaincore-do script."
    echo ""
    echo "Run 'captaincore-do help <command>' for more information on a specific command."
}

# --- Main Entry Point and Argument Parser ---

function main() {
    #  If no arguments are provided, show usage and exit.
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi

    # --- Help Flag Handling ---
    #  Detect 'help <command>' pattern
    if [[ "$1" == "help" ]]; then
        show_command_help "$2"
        exit 0
    fi

    #  Detect '<command> --help' pattern
    for arg in "$@"; do
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
            #  The first non-flag argument is the command we need help for.
            local help_for_cmd=""
            for inner_arg in "$@"; do
                #  Find the first argument that doesn't start with a hyphen.
                if [[ ! "$inner_arg" =~ ^- ]]; then
                    help_for_cmd="$inner_arg"
                    break
                fi
            done
            show_command_help "$help_for_cmd"
            exit 0
        fi
    done

    # --- Centralized Argument Parser ---
    #  This loop separates flags from commands.
    local url_flag=""
    local top_flag=""
    local name_flag=""
    local link_flag=""
    local wp_content_flag=""
    local update_urls_flag=""
    local now_flag=""
    local positional_args=() #  To store commands and their direct arguments
    
    while [[ $# -gt 0 ]]; do
      case $1 in
        --url=*)
          url_flag="${1#*=}"
          shift
          ;;
        --top=*)
          top_flag="${1#*=}"
          shift
          ;;
        --now)
          now_flag=true
          shift
          ;;
        --name=*)
          name_flag="${1#*=}"
          shift
          ;;
        --link=*)
          link_flag="${1#*=}"
          shift
          ;;
        --wp-content=*)
          wp_content_flag="${1#*=}"
          shift
          ;;
        --update-urls)
          update_urls_flag=true
          shift
          ;;
        -*)
          #  This will catch unknown flags like --foo
          echo "Error: Unknown flag: $1" >&2
          show_usage
          exit 1
          ;;
        *)
          #  It's a command or a positional argument
          positional_args+=("$1")
          shift #  past argument
          ;;
      esac
    done

    #  The first positional argument is the main command.
    local command="${positional_args[0]}"
    local arg1="${positional_args[1]}" 
    local arg2="${positional_args[2]}"

    # --- Command Router ---
    #  This routes to the correct function based on the parsed command.
    case "$command" in
        backup)
            full_backup "$arg1"
            ;;
        backup-db)
            db_backup
            ;;
        db-check-autoload)
            db_check_autoload
            ;;
        convert-to-webp)
            convert_to_webp
            ;;
        dump)
            # There should be exactly 2 positional args total: 'dump' and the pattern.
            # If there are more, the shell likely expanded a wildcard.
            if [ ${#positional_args[@]} -gt 2 ]; then
                echo -e "Error: Too many arguments. It's likely your pattern was expanded by the shell." >&2
                echo "Please wrap the pattern in double quotes to prevent this." >&2
                echo -e "\n  Example: captaincore-do dump \"wp-content/plugins/my-plugin/*.php\"" >&2
                return 1
            fi
            run_dump "${positional_args[1]}"
            ;;
        migrate)
            if [[ -z "$url_flag" ]]; then
                echo "Error: The 'migrate' command requires the --url=<...> flag." >&2
                show_command_help "migrate"
                exit 1
            fi
            migrate_site "$url_flag" "$update_urls_flag"
            ;;
        monitor)
            monitor_traffic "$top_flag" "$now_flag"
            ;;
        reset-permissions)
            reset_permissions
            ;;
        slow-plugins)
            identify_slow_plugins
            ;;
        suspend)
            case "$arg1" in
                activate)
                    suspend_activate "$name_flag" "$link_flag" "$wp_content_flag"
                    ;;
                deactivate)
                    suspend_deactivate "$wp_content_flag"
                    ;;
                *)
                    show_command_help "suspend"
                    exit 0
                    ;;
            esac
            ;;
        version|--version|-v)
            show_version
            ;;
        *)
            echo "Error: Unknown command '$command'." >&2
            show_usage
            exit 1
            ;;
    esac
}

#  Pass all script arguments to the main function.

# --- Sourced Command Functions ---
# The following functions are sourced from the 'commands/' directory.


# --------------------------------------
#  Performs a WordPress database-only backup to a secure, private directory.
# --------------------------------------
function db_backup() {
    echo "Starting database-only backup..."
    local home_directory; home_directory=$(pwd); local private_directory=""
    if [ -d "_wpeprivate" ]; then private_directory="${home_directory}/_wpeprivate"; elif [ -d "../private" ]; then private_directory=$(cd ../private && pwd); elif [ -d "../tmp" ]; then private_directory=$(cd ../tmp && pwd); fi
    cd "$home_directory"
    if [[ -z "$private_directory" ]]; then echo "Error: Can't find a private directory." >&2; return 1; fi
    if ! command -v wp &> /dev/null; then echo "Error: wp-cli is not installed." >&2; return 1; fi
    local database_name; database_name=$(wp config get DB_NAME --skip-plugins --skip-themes --quiet); local database_username; database_username=$(wp config get DB_USER --skip-plugins --skip-themes --quiet); local database_password; database_password=$(wp config get DB_PASSWORD --skip-plugins --skip-themes --quiet);
    local dump_command; if command -v mariadb-dump &> /dev/null; then dump_command="mariadb-dump"; elif command -v mysqldump &> /dev/null; then dump_command="mysqldump"; else echo "Error: Neither mariadb-dump nor mysqldump could be found." >&2; return 1; fi
    echo "Using ${dump_command} for the backup."
    local backup_file="${private_directory}/database-backup-$(date +"%Y-%m-%d").sql"
    if ! "${dump_command}" -u"${database_username}" -p"${database_password}" --max_allowed_packet=512M --default-character-set=utf8mb4 --add-drop-table --single-transaction --quick --lock-tables=false "${database_name}" > "${backup_file}"; then echo "Error: Database dump failed." >&2; rm -f "${backup_file}"; return 1; fi
    chmod 600 "${backup_file}"; echo "✅ Database backup complete!"; echo "   Backup file located at: ${backup_file}"
}
# --------------------------------------
#  Finds large images and converts them to the WebP format.
# --------------------------------------
function convert_to_webp() {
    echo "🚀 Starting WebP Conversion Process 🚀"
    if ! setup_cwebp; then
        echo "Aborting conversion: cwebp setup failed." >&2
        return 1
    fi
    if ! command -v identify &> /dev/null; then echo "❌ Error: 'identify' command not found. Please install ImageMagick." >&2; return 1; fi
    local uploads_dir="wp-content/uploads"; if [ ! -d "$uploads_dir" ]; then echo "❌ Error: Cannot find '$uploads_dir' directory." >&2; return 1; fi
    local before_size; before_size="$(du -sh "$uploads_dir" | awk '{print $1}')"; echo "Current uploads size: $before_size"
    local files; files=$(find "$uploads_dir" -type f -size +1M \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
    if [[ -z "$files" ]]; then echo "✅ No images larger than 1MB found to convert."; return 0; fi
    local count; count=$(echo "$files" | wc -l); echo "Found $count image(s) over 1MB to process..."; echo ""
    echo "$files" | while IFS= read -r file; do
        if [[ "$(identify -format "%m" "$file")" == "WEBP" ]]; then echo "Skipping (already WebP): $file"; continue; fi
        local temp_file="${file}.temp.webp"; local before_file_size; before_file_size=$(du -sh --apparent-size "$file" | awk '{print $1}')
        "$CWEBP_CMD" -q 80 "$file" -o "$temp_file" > /dev/null 2>&1
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$file"; local after_file_size; after_file_size=$(du -sh --apparent-size "$file" | awk '{print $1}')
            echo "✅ Converted ($before_file_size -> $after_file_size): $file"
        else
            rm -f "$temp_file"; echo "❌ Failed conversion: $file"
        fi
    done
    echo ""; local after_size; after_size="$(du -sh "$uploads_dir" | awk '{print $1}')"
    echo "-----------------------------------------------------"; echo "✅ Bulk conversion complete!"; echo "   Uploads folder size reduced from $before_size to $after_size."; echo "-----------------------------------------------------"
}
# --------------------------------------
#  Checks the size and contents of autoloaded options in the WordPress database.
# --------------------------------------
function db_check_autoload() {
    echo "Checking autoloaded options in the database..."
    if ! command -v wp &> /dev/null; then echo "Error: wp-cli is not installed." >&2; return 1; fi
    if ! command wp core is-installed --quiet; then echo "Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo
    echo "--- Total Autoloaded Size ---"
    wp db query "SELECT ROUND(SUM(LENGTH(option_value))/1024/1024, 2) as 'Autoload MB' FROM $(wp db prefix)options WHERE autoload='yes';"
    
    echo
    echo "--- Top 25 Autoloaded Options & Totals ---"
    wp db query "SELECT 'autoloaded data in MB' as name, ROUND(SUM(LENGTH(option_value))/ 1024 / 1024, 2) as value FROM $(wp db prefix)options WHERE autoload='yes' UNION SELECT 'autoloaded data count', count(*) FROM $(wp db prefix)options WHERE autoload='yes' UNION (SELECT option_name, round( length(option_value) / 1024 / 1024, 2) FROM $(wp db prefix)options WHERE autoload='yes' ORDER BY length(option_value) DESC LIMIT 25)"
    
    echo
    echo "✅ Autoload check complete."
}
# --------------------------------------
#  Dumps the content of files matching a pattern into a single text file.
# --------------------------------------
function run_dump() {
    # --- 1. Validate Input ---
    if [ -z "$1" ]; then
        echo "Error: No input pattern provided." >&2
        echo "Usage: captaincore-do dump \"<path/to/folder/*.extension>\"" >&2
        return 1
    fi

    local INPUT_PATTERN="$1"

    # --- 2. Determine Paths and Names ---
    # Extract the directory to search in (e.g., "wp-content/plugins/jetpack")
    local SEARCH_DIR
    SEARCH_DIR=$(dirname "$INPUT_PATTERN")
    # Extract the file name pattern (e.g., "*.php")
    local FILE_PATTERN
    FILE_PATTERN=$(basename "$INPUT_PATTERN")

    # Use the directory's name for the output file (e.g., "jetpack")
    local OUTPUT_BASENAME
    OUTPUT_BASENAME=$(basename "$SEARCH_DIR")
    if [ "$OUTPUT_BASENAME" == "." ]; then
        OUTPUT_BASENAME="dump"
    fi
    local OUTPUT_FILE="${OUTPUT_BASENAME}.txt"

    # --- 3. Process Files ---
    # Ensure the output file is empty before we start
    > "$OUTPUT_FILE"

    echo "Searching in '$SEARCH_DIR' for files matching '$FILE_PATTERN'..."

    # Find all files recursively (-type f) matching the name pattern.
    # The -print0 and `read -d ''` combo is the safest way to handle
    # filenames that might contain spaces or special characters.
    find "$SEARCH_DIR" -type f -name "$FILE_PATTERN" -print0 | while IFS= read -r -d '' file; do
        # Append a header with the file path to the output file
        echo "--- File: $file ---" >> "$OUTPUT_FILE"
        # Append the content of the file
        cat "$file" >> "$OUTPUT_FILE"
        # Add two newlines for separation between files
        echo -e "\n" >> "$OUTPUT_FILE"
    done

    # --- 4. Final Report ---
    # Check if the output file has content (-s checks if size is > 0)
    if [ ! -s "$OUTPUT_FILE" ]; then
        echo "Warning: No files found matching the pattern. No dump file created."
        rm "$OUTPUT_FILE" # Clean up the empty file
        return 0
    fi

    # Get the human-readable size of the generated file and trim whitespace
    local FILE_SIZE
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1 | xargs)

    echo "Generated $OUTPUT_FILE ($FILE_SIZE)"
}
# --------------------------------------
#  Migrates a site from a backup URL or local file.
#  Arguments:
#    $1 - The URL/path for the backup file.
#    $2 - A flag indicating whether to update URLs.
# --------------------------------------
function migrate_site() {
    local backup_url="$1"
    local update_urls_flag="$2"
    
    echo "🚀 Starting Site Migration 🚀"

    # --- Pre-flight Checks ---
    if ! command -v wp &>/dev/null; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! command -v wget &>/dev/null; then echo "❌ Error: wget not found." >&2; return 1; fi
    if ! command -v unzip &>/dev/null; then echo "❌ Error: unzip not found." >&2; return 1; fi
    if ! command -v tar &>/dev/null; then echo "❌ Error: tar not found." >&2; return 1; fi

    local home_directory; home_directory=$(pwd)
    local wp_home; wp_home=$( wp option get home --skip-themes --skip-plugins )
    if [[ "$wp_home" != "http"* ]]; then
        echo "❌ Error: WordPress not found in current directory. Migration cancelled." >&2
        return 1
    fi
    
    # --- Find Private Directory ---
    local private_dir=""
    if [ -d "_wpeprivate" ]; then private_dir="${home_directory}/_wpeprivate"; fi
    if [ -d "../private" ]; then private_dir=$(cd ../private && pwd); fi
    if [ -d "../tmp" ]; then private_dir=$(cd ../tmp && pwd); fi
    cd "$home_directory" #  Ensure we are back
    if [[ -z "$private_dir" ]]; then
        echo "❌ Error: Can't locate a private folder. Migration cancelled." >&2
        return 1
    fi
    
    # --- Download and Extract Backup ---
    local timedate; timedate=$(date +'%Y-%m-%d-%H%M%S')
    local restore_dir="${private_dir}/restore_${timedate}"
    mkdir -p "$restore_dir"
    cd "$restore_dir" || return 1
    
    local local_file_name; local_file_name=$(basename "$backup_url")

    #  Handle special URLs
    if [[ "$backup_url" == *"admin-ajax.php"* ]]; then
      echo "ℹ️ Backup Buddy URL found, transforming..."
      backup_url=${backup_url/wp-admin\/admin-ajax.php?action=pb_backupbuddy_backupbuddy&function=download_archive&backupbuddy_backup=/wp-content\/uploads\/backupbuddy_backups/}
    fi
    if [[ "$backup_url" == *"dropbox.com"* && "$backup_url" != *"dl=1" ]]; then
      echo "ℹ️ Dropbox URL found, adding dl=1..."
      backup_url=${backup_url/&dl=0/&dl=1}
    fi
    
    #  Download or use local file
    if [ ! -f "${private_dir}/${local_file_name}" ]; then
      echo "Downloading from $backup_url..."
      wget --no-check-certificate --progress=bar:force:noscroll -O "backup_file" "$backup_url"
      if [ $? -ne 0 ]; then echo "❌ Error: Download failed."; cd "$home_directory"; return 1; fi
    else
      echo "ℹ️ Local file '${local_file_name}' found. Using it."
      mv "${private_dir}/${local_file_name}" ./backup_file
    fi

    #  Extract based on extension
    echo "Extracting backup..."
    if [[ "$backup_url" == *".zip"* || "$local_file_name" == *".zip"* ]]; then
        unzip -q -o backup_file -x "__MACOSX/*" "cgi-bin/*"
    elif [[ "$backup_url" == *".tar.gz"* || "$local_file_name" == *".tar.gz"* ]]; then
        tar xzf backup_file
    elif [[ "$backup_url" == *".tar"* || "$local_file_name" == *".tar"* ]]; then
        tar xf backup_file
    else #  Assume zip if no extension matches
        echo "ℹ️ No clear extension, assuming .zip format."
        unzip -q -o backup_file -x "__MACOSX/*" "cgi-bin/*"
    fi
    rm -f backup_file

    # --- Migrate Files ---
    local wordpresspath; wordpresspath=$( find . -type d -name 'wp-content' -print -quit )
    if [[ -z "$wordpresspath" ]]; then
      echo "❌ Error: Can't find wp-content/ in backup. Migration cancelled."; cd "$home_directory"; return 1
    fi

    echo "Migrating files..."
    #  A safer way to migrate content is using rsync
    rsync -av --remove-source-files "${wordpresspath}/" "${home_directory}/wp-content/"
    
    #  Find and move non-default root files
    local backup_root_dir; backup_root_dir=$(dirname "$wordpresspath")
    cd "$backup_root_dir" || return 1
    local default_files=( index.php license.txt readme.html wp-activate.php wp-app.php wp-blog-header.php wp-comments-post.php wp-config-sample.php wp-cron.php wp-links-opml.php wp-load.php wp-login.php wp-mail.php wp-pass.php wp-register.php wp-settings.php wp-signup.php wp-trackback.php xmlrpc.php wp-admin wp-config.php wp-content wp-includes )
    for item in *; do
        is_default=false
        for default in "${default_files[@]}"; do
            if [[ "$item" == "$default" ]]; then is_default=true; break; fi
        done
        if ! $is_default; then
            echo "Moving root item: $item"
            mv -f "$item" "${home_directory}/"
        fi
    done
    cd "$home_directory"

    # --- Database Migration ---
    local database; database=$(find "$restore_dir" -type f -name '*.sql' -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
    if [[ -z "$database" || ! -f "$database" ]]; then
        echo "⚠️ Warning: No .sql file found in backup. Skipping database import.";
    else
        echo "Importing database from $database..."
        local search_privacy; search_privacy=$( wp option get blog_public --skip-plugins --skip-themes )
        wp db reset --yes --skip-plugins --skip-themes
        wp db import "$database" --skip-plugins --skip-themes
        wp cache flush --skip-plugins --skip-themes
        wp option update blog_public "$search_privacy" --skip-plugins --skip-themes

        #  URL updates
        local wp_home_imported; wp_home_imported=$( wp option get home --skip-plugins --skip-themes )
        if [[ "$update_urls_flag" == "true" && "$wp_home_imported" != "$wp_home" ]]; then
            echo "Updating URLs from $wp_home_imported to $wp_home..."
            wp search-replace "$wp_home_imported" "$wp_home" --all-tables --report-changed-only --skip-plugins --skip-themes
        fi
    fi

    # --- Cleanup & Final Steps ---
    echo "Performing cleanup and final optimizations..."
    local plugins_to_remove=( backupbuddy wordfence w3-total-cache wp-super-cache ewww-image-optimizer )
    for plugin in "${plugins_to_remove[@]}"; do
        if wp plugin is-installed "$plugin" --skip-plugins --skip-themes &>/dev/null; then
            echo "Removing plugin: $plugin"
            wp plugin delete "$plugin" --skip-plugins --skip-themes
        fi
    done
    
    #  Convert tables to InnoDB
    local alter_queries; alter_queries=$(wp db query "SELECT CONCAT('ALTER TABLE ', TABLE_SCHEMA,'.', TABLE_NAME, ' ENGINE=InnoDB;') FROM information_schema.TABLES WHERE ENGINE = 'MyISAM' AND TABLE_SCHEMA=DATABASE()" --skip-column-names --skip-plugins --skip-themes)
    if [[ -n "$alter_queries" ]]; then
        echo "Converting MyISAM tables to InnoDB..."
        echo "$alter_queries" | wp db query --skip-plugins --skip-themes
    fi

    wp rewrite flush --skip-plugins --skip-themes
    if wp plugin is-active woocommerce --skip-plugins --skip-themes &>/dev/null; then
        wp wc tool run regenerate_product_attributes_lookup_table --user=1 --skip-plugins --skip-themes
    fi
    
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    
    #  Clean up restore directory
    rm -rf "$restore_dir"
    
    echo "✅ Site migration complete!"
}
# --------------------------------------
#  Monitors server access logs in real-time.
# --------------------------------------
function monitor_traffic() {
    local limit_arg="$1"
    local process_from_now="$2"

    if ! setup_gum; then
        echo "Aborting monitor: gum setup failed." >&2
        return 1
    fi

    # --- Configuration ---
    local limit=${limit_arg:-25}
    local log="$HOME/logs/access.log"
    local initial_lines_to_process=500 # How many lines to look back initially (only used with --now)
    # --- End Configuration ---

    if [ ! -f "$log" ]; then
        echo "Error: Log file not found at $log" >&2
        exit 1
    fi

    # --- Initial Setup ---
    local start_line=1 # Default: start from the beginning

    if [ "$process_from_now" = true ]; then
        echo "Processing from near the end (--now specified)." >&2
        local initial_log_count; initial_log_count=$(wc -l < "$log")
        local calculated_start=$((initial_log_count - initial_lines_to_process + 1))
        
        if [ $calculated_start -gt 1 ]; then
            start_line=$calculated_start
        else
            start_line=1
        fi
    else
        echo "Processing from the beginning of the log (line 1)." >&2
    fi

    echo "Starting analysis from line: $start_line | Top hits limit: $limit" >&2
    # --- End Initial Setup ---

    trap "echo; echo 'Monitoring stopped.'; exit 0" INT
    sleep 2 # Give user time to read initial messages

    while true; do
        local current_log_count; current_log_count=$(wc -l < "$log")
        
        if [ "$current_log_count" -lt "$start_line" ]; then
            echo "Warning: Log file appears to have shrunk or rotated. Resetting start line to 1." >&2
            start_line=1
            sleep 1
            current_log_count=$(wc -l < "$log")
            if [ "$current_log_count" -lt 1 ]; then
                echo "Log file is empty or unreadable after reset. Waiting..." >&2
                sleep 5
                continue
            fi
        fi

        local actual_lines_processed=$((current_log_count - start_line + 1))
        if [ $actual_lines_processed -lt 0 ]; then
             actual_lines_processed=0
        fi

        local overview_header="PHP Workers,Log File,Processed,From Time,To Time\n"
        local overview_data=""
        local php_workers; php_workers=$(ps -eo pid,uname,comm,%cpu,%mem,time --sort=time --no-headers | grep '[p]hp-fpm' | grep -v 'root' | wc -l)

        local first_line_time; first_line_time=$(sed -n "${start_line}p" "$log" | awk -F'[][]' '{print $2}' | head -n 1)
        [ -z "$first_line_time" ] && first_line_time="N/A"

        local last_line_time; last_line_time=$(tail -n 1 "$log" | awk -F'[][]' '{print $2}' | head -n 1)
        [ -z "$last_line_time" ] && last_line_time="N/A"

        overview_data+="$php_workers,$log,$actual_lines_processed,$first_line_time,$last_line_time\n"
        local output_header="Hits,IP Address,Status Code,Last User Agent\n"
        local output_data=""

        local top_combinations; top_combinations=$(timeout 10s sed -n "$start_line,\$p" "$log" | \
                                  awk '{print $2 " " $8}' | \
                                  sort | \
                                  uniq -c | \
                                  sort -nr | \
                                  head -n "$limit")

        if [ -z "$top_combinations" ]; then
            output_data+="0,No new data,-,\"N/A\"\n"
        else
            while IFS= read -r line; do
                line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')
                local count ip status_code
                read -r count ip status_code <<< "$line"

                if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ -z "$ip" ]] || ! [[ "$status_code" =~ ^[0-9]+$ ]]; then
                    continue
                fi

                local ip_user_agent; ip_user_agent=$(timeout 2s sed -n "$start_line,\$p" "$log" | grep " $ip " | tail -n 1 | awk -F\" '{print $6}' | cut -c 1-100)
                ip_user_agent=${ip_user_agent//,/}
                ip_user_agent=${ip_user_agent//\"/}

                [ -z "$ip_user_agent" ] && ip_user_agent="-"

                output_data+="$count,$ip,$status_code,\"$ip_user_agent\"\n"
            done < <(echo -e "$top_combinations")
        fi

        clear
        echo "--- Overview (Lines $start_line - $current_log_count | Total: $actual_lines_processed) ---"
        echo -e "$overview_header$overview_data" | "$GUM_CMD" table --print
        echo
        echo "--- Top $limit IP/Status Hits (Lines $start_line - $current_log_count) ---"
        echo -e "$output_header$output_data" | "$GUM_CMD" table --print

        sleep 2
    done
}
# --------------------------------------
#  Resets file and folder permissions to common defaults (755 for dirs, 644 for files).
# --------------------------------------
function reset_permissions() {
    echo "Resetting file and folder permissions to defaults"
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    echo "✅ Permissions have been reset."
}
# --------------------------------------
#  Identifies plugins that may be slowing down WP-CLI command execution.
# --------------------------------------
function identify_slow_plugins() {
    _get_wp_execution_time() { local output; output=$(command wp "$@" --debug 2>&1); echo "$output" | perl -ne '/Debug \(bootstrap\): Running command: .+\(([^s]+s)/ && print $1'; }
    if ! command -v wp &>/dev/null; then echo "❌ Error: WP-CLI (wp command) not found." >&2; return 1; fi
    if ! command wp core is-installed --quiet; then echo "❌ Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo "🚀 WordPress Plugin Performance Test 🚀"
    echo "This script measures the execution time of 'wp plugin list --debug' under various conditions."
    echo ""
    echo "📋 Initial Baseline Measurements for 'wp plugin list --debug':"

    local time_no_theme_s; printf "  ⏳ Measuring time with NO themes loaded (--skip-themes)... "; time_no_theme_s=$(_get_wp_execution_time plugin list --skip-themes); echo "Time: $time_no_theme_s"
    local time_no_plugins_s; printf "  ⏳ Measuring time with NO plugins loaded (--skip-plugins)... "; time_no_plugins_s=$(_get_wp_execution_time plugin list --skip-plugins); echo "Time: $time_no_plugins_s"
    local base_time_s; printf "  ⏳ Measuring base time (ALL plugins & theme active)... "; base_time_s=$(_get_wp_execution_time plugin list)
    if [[ -z "$base_time_s" ]]; then echo "❌ Error: Could not measure base execution time." >&2; return 1; fi; echo "Base time: $base_time_s"
    echo ""

    local active_plugins=()
    while IFS= read -r line; do
        active_plugins+=("$line")
    done < <(command wp plugin list --field=name --status=active)

    if [[ ${#active_plugins[@]} -eq 0 ]]; then echo "ℹ️ No active plugins found to test."; return 0; fi

    echo "📊 Measuring impact of individual plugins (compared to '${base_time_s}' base time):"
    echo "A larger positive 'Impact' suggests the plugin contributes more to the load time of this specific WP-CLI command."

    echo "---------------------------------------------------------------------------------"; printf "%-40s | %-15s | %-15s\n" "Plugin Skipped" "Time w/ Skip" "Impact (Base-Skip)"; echo "---------------------------------------------------------------------------------"
    local results=(); for plugin in "${active_plugins[@]}"; do
        local time_with_skip_s; time_with_skip_s=$(_get_wp_execution_time plugin list --skip-plugins="$plugin")
        if [[ -n "$time_with_skip_s" ]]; then
            local diff_s; diff_s=$(awk -v base="${base_time_s%s}" -v skip="${time_with_skip_s%s}" 'BEGIN { printf "%.3f", base - skip }')
            local impact_sign=""
            if [[ $(awk -v diff="$diff_s" 'BEGIN { print (diff > 0) }') -eq 1 ]]; then
                impact_sign="+"
            fi
            results+=("$(printf "%.3f" "$diff_s")|$plugin|$time_with_skip_s|${impact_sign}${diff_s}s")
        else results+=("0.000|$plugin|Error|Error measuring"); fi
    done

    local sorted_results=()
    while IFS= read -r line; do
        sorted_results+=("$line")
    done < <(printf "%s\n" "${results[@]}" | sort -t'|' -k1,1nr)

    for result_line in "${sorted_results[@]}"; do
        local p_name; p_name=$(echo "$result_line" | cut -d'|' -f2); local t_skip; t_skip=$(echo "$result_line" | cut -d'|' -f3); local i_str; i_str=$(echo "$result_line" | cut -d'|' -f4)
        printf "%-40s | %-15s | %-15s\n" "$p_name" "$t_skip" "$i_str"
    done
    echo "---------------------------------------------------------------------------------"; echo ""; echo "✅ Test Complete"
    echo "💡 Note: This measures impact on a specific WP-CLI command. For front-end or"; echo "   admin profiling, consider using a plugin like Query Monitor or New Relic."; echo ""
}
# --------------------------------------
#  Deactivates a suspend message by removing the mu-plugin.
#  (Formerly site_activate)
# --------------------------------------
function suspend_deactivate() {
    local wp_content="$1"

    #  Set default wp-content if not provided
    if [[ -z "$wp_content" ]]; then
        wp_content="wp-content"
    fi

    local suspend_file="${wp_content}/mu-plugins/captaincore-suspended.php"

    if [ -f "$suspend_file" ]; then
        echo "Deactivating suspend message by removing ${suspend_file}..."
        rm "$suspend_file"
        echo "✅ Suspend message deactivated. Site is now live."
    else
        echo "Site appears to be already live (suspend file not found)."
    fi

    #  Clear Kinsta cache if environment is detected
    if [ -f "/etc/update-motd.d/00-kinsta-welcome" ]; then
        if command -v wp &> /dev/null && wp kinsta cache purge --all --skip-themes &> /dev/null; then
            echo "Kinsta cache purged."
        else
            echo "Warning: Could not purge Kinsta cache. Is the 'wp kinsta' command available?" >&2
        fi
    fi
}

# --------------------------------------
#  Activates a suspend message by adding an mu-plugin.
#  (Formerly site_deactivate)
# --------------------------------------
function suspend_activate() {
    local name="$1"
    local link="$2"
    local wp_content="$3"

    #  Set default wp-content if not provided
    if [[ -z "$wp_content" ]]; then
        wp_content="wp-content"
    fi

    #  Check for required arguments
    if [[ -z "$name" || -z "$link" ]]; then
        echo "Error: Missing required flags for 'suspend activate'." >&2
        show_command_help "suspend"
        return 1
    fi
    
    if [ ! -d "${wp_content}/mu-plugins" ]; then
        echo "Creating directory: ${wp_content}/mu-plugins"
        mkdir -p "${wp_content}/mu-plugins"
    fi

    #  Remove existing deactivation file if present
    if [ -f "${wp_content}/mu-plugins/captaincore-suspended.php" ]; then
        echo "Removing existing suspend file..."
        rm "${wp_content}/mu-plugins/captaincore-suspended.php"
    fi

    #  Create the deactivation mu-plugin
    local output_file="${wp_content}/mu-plugins/captaincore-suspended.php"
    echo "Generating suspend file at ${output_file}..."
    cat <<EOF > "$output_file"
<?php
/**
 * Plugin Name: Website Suspended
 * Description: Deactivates the front-end of the website.
 */
function captaincore_template_redirect() {
    //  Return if in WP Admin or CLI
    if ( is_admin() || ( defined( 'WP_CLI' ) && WP_CLI ) ) {
        return;
    }
?>
<html>
  <head>
    <meta charset="utf-8">
    <title>Website Suspended</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css?family=Roboto');
        body {
            text-align: center;
            margin: 10% auto;
            padding: 0 15px;
            font-family: 'Roboto', sans-serif;
            overflow: hidden;
            display: block;
            max-width: 550px;
            background: #eeeeee;
        }
        p {
            margin-top: 3%;
            line-height: 1.4em;
            display: block;
        }
        img {
            margin-top: 1%;
        }
        a {
            color:#27c3f3;
        }
    </style>
  </head>
  <body>
    <div class="row">
        <div class="col s12">
            <div class="card">
                <div class="card-content">
                    <span class="card-title">Website Suspended</span>
                    <p>This website is currently unavailable.</p>
                </div>
                <div class="card-content grey lighten-4">
                    <p>Site owners may contact <a href="${link}" target="_blank" rel="noopener noreferrer">${name}</a>.</p>
                </div>
            </div>
        </div>
    </div>
  </body>
</html>
<?php
    //  Stop WordPress from loading further
    die();
}
add_action( 'template_redirect', 'captaincore_template_redirect', 1 );
EOF

    echo "✅ Generated ${output_file}"

    #  Clear Kinsta cache if environment is detected
    if [ -f "/etc/update-motd.d/00-kinsta-welcome" ]; then
        if command -v wp &> /dev/null && wp kinsta cache purge --all --skip-themes &> /dev/null; then
            echo "Kinsta cache purged."
        else
            echo "Warning: Could not purge Kinsta cache. Is the 'wp kinsta' command available?" >&2
        fi
    fi
}
# --------------------------------------
#  Displays the version of the captaincore-do script.
# --------------------------------------
function show_version() {
    echo "captaincore-do version $CAPTAINCORE_DO_VERSION"
}
#  Pass all script arguments to the main function.
main "$@"
