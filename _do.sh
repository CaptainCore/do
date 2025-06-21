#!/bin/bash

# ----------------------------------------------------
#  Command: _do
#  Description: A collection of useful command-line utilities for managing WordPress sites.
#  Author: Austin Ginder
#  License: MIT
# ----------------------------------------------------

# --- Global Variables ---
CAPTAINCORE_DO_VERSION="1.1"
GUM_VERSION="0.14.4"
CWEBP_VERSION="1.5.0"
RCLONE_VERSION="1.69.3"
GIT_VERSION="2.50.0"
GUM_CMD=""
CWEBP_CMD=""
WP_CLI_CMD=""

# --- Helper Functions ---

# ----------------------------------------------------
#  Intelligently finds or creates a private directory.
#  Sets a global variable CAPTAINCORE_PRIVATE_DIR and echoes the path.
# ----------------------------------------------------
function _get_private_dir() {
    # Return immediately if already found
    if [[ -n "$CAPTAINCORE_PRIVATE_DIR" ]]; then
        echo "$CAPTAINCORE_PRIVATE_DIR"
        return 0
    fi

    # --- Tier 1: Preferred WP-CLI Method ---
    if setup_wp_cli; then
        local wp_config_path
        wp_config_path=$("$WP_CLI_CMD" config path --quiet 2>/dev/null)
        if [ -n "$wp_config_path" ] && [ -f "$wp_config_path" ]; then
            local wp_root
            wp_root=$(dirname "$wp_config_path")
            local parent_dir
            parent_dir=$(dirname "$wp_root")

            # Check for WP Engine's private directory first
            if [ -d "${parent_dir}/_wpeprivate" ]; then
                CAPTAINCORE_PRIVATE_DIR="${parent_dir}/_wpeprivate"
                echo "$CAPTAINCORE_PRIVATE_DIR"
                return 0
            fi
            # Check for a standard ../private directory
            if [ -d "${parent_dir}/private" ]; then
                CAPTAINCORE_PRIVATE_DIR="${parent_dir}/private"
                echo "$CAPTAINCORE_PRIVATE_DIR"
                return 0
            fi
            # Try to create a ../private directory
            if mkdir -p "${parent_dir}/private"; then
                CAPTAINCORE_PRIVATE_DIR="${parent_dir}/private"
                echo "$CAPTAINCORE_PRIVATE_DIR"
                return 0
            fi
            # Fallback to ../tmp if it exists
            if [ -d "${parent_dir}/tmp" ]; then
                CAPTAINCORE_PRIVATE_DIR="${parent_dir}/tmp"
                echo "$CAPTAINCORE_PRIVATE_DIR"
                return 0
            fi
        fi
    fi

    # --- Tier 2: Manual Fallback (if WP-CLI fails or not in a WP install) ---
    local current_dir
    current_dir=$(pwd)
    if [ -d "${current_dir}/_wpeprivate" ]; then # WPE check
        CAPTAINCORE_PRIVATE_DIR="${current_dir}/_wpeprivate"
        echo "$CAPTAINCORE_PRIVATE_DIR"
        return 0
    fi
    if [ -d "../private" ]; then # Relative private check
        CAPTAINCORE_PRIVATE_DIR=$(cd ../private && pwd)
        echo "$CAPTAINCORE_PRIVATE_DIR"
        return 0
    fi
    if mkdir -p "../private"; then # Attempt to create relative private
        CAPTAINCORE_PRIVATE_DIR=$(cd ../private && pwd)
        echo "$CAPTAINCORE_PRIVATE_DIR"
        return 0
    fi
    if [ -d "../tmp" ]; then # Relative tmp check
        CAPTAINCORE_PRIVATE_DIR=$(cd ../tmp && pwd)
        echo "$CAPTAINCORE_PRIVATE_DIR"
        return 0
    fi

    # --- Tier 3: Last Resort Fallback to Home Directory ---
    if mkdir -p "$HOME/private"; then # Home directory check
        CAPTAINCORE_PRIVATE_DIR="$HOME/private"
        echo "$CAPTAINCORE_PRIVATE_DIR"
        return 0
    fi

    echo "Error: Could not find or create a suitable private directory." >&2
    return 1
}

# ----------------------------------------------------
#  Checks for and installs 'gum' if not present. Sets GUM_CMD on success.
# ----------------------------------------------------
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
    echo "Required tool 'gum' not found. Installing..." >&2
    local private_dir
    if ! private_dir=$(_get_private_dir); then
        # Error message is handled by the helper function
        return 1
    fi
    cd "$private_dir" || { echo "Error: Could not enter private directory." >&2; return 1; }

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

# ----------------------------------------------------
#  Checks for and installs 'cwebp' if not present. Sets CWEBP_CMD on success.
# ----------------------------------------------------
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
    if [ -f "$cwebp_executable" ] && "$cwebp_executable" -version &> /dev/null; then
        echo "'cwebp' installed successfully." >&2
        CWEBP_CMD="$cwebp_executable"
    else
        echo "Error: cwebp installation failed." >&2
        cd - > /dev/null
        return 1
    fi
    cd - > /dev/null
}

# ----------------------------------------------------
#  Checks for and installs 'rclone' if not present. Sets RCLONE_CMD on success.
# ----------------------------------------------------
function setup_rclone() {
    #  Return if already found
    if [[ -n "$RCLONE_CMD" ]]; then return 0; fi

    #  If rclone is already in the PATH, we're good to go.
    if command -v rclone &> /dev/null; then
        RCLONE_CMD="rclone"
        return 0
    fi

    local rclone_dir="rclone-v${RCLONE_VERSION}-linux-amd64"
    local rclone_executable="$HOME/private/${rclone_dir}/rclone"

    #  Check for a local installation
    if [ -f "$rclone_executable" ] && "$rclone_executable" --version &> /dev/null; then
        RCLONE_CMD="$rclone_executable"
        return 0
    fi

    #  If not found or not working, download it
    echo "Required tool 'rclone' not found. Installing to ~/private..." >&2
    if ! command -v unzip &>/dev/null; then echo "Error: 'unzip' command is required for installation." >&2; return 1; fi
    mkdir -p "$HOME/private"
    cd "$HOME/private" || { echo "Error: Could not enter ~/private." >&2; return 1; }

    local rclone_zip="rclone-v${RCLONE_VERSION}-linux-amd64.zip"
    if ! wget --quiet "https://github.com/rclone/rclone/releases/download/v${RCLONE_VERSION}/${rclone_zip}" || ! unzip -q "${rclone_zip}"; then
        echo "Error: Failed to download or extract rclone." >&2
        cd - > /dev/null
        return 1
    fi
    rm -f "${rclone_zip}"

    #  Final check
    if [ -f "$rclone_executable" ] && "$rclone_executable" --version &> /dev/null; then
        echo "'rclone' installed successfully." >&2
        RCLONE_CMD="$rclone_executable"
    else
        echo "Error: rclone installation failed." >&2
        cd - > /dev/null
        return 1
    fi
    cd - > /dev/null
}

# ----------------------------------------------------
#  Checks for and installs 'git' if not present. Sets GIT_CMD on success.
# ----------------------------------------------------
function setup_git() {
    #  Return if already found
    if [[ -n "$GIT_CMD" ]]; then return 0; fi

    #  If git is already in the PATH, we're good to go.
    if command -v git &> /dev/null; then
        GIT_CMD="git"
        return 0
    fi

    # Since git is a more complex dependency, we'll just check for it
    # and error out if it's not installed. A proper sideload for git
    # is significantly more involved than for the other tools.
    echo "❌ Error: 'git' command not found. Please install Git to use checkpoint features." >&2
    return 1
}

# ----------------------------------------------------
#  Checks for and finds the 'wp' command. Sets WP_CLI_CMD on success.
# ----------------------------------------------------
function setup_wp_cli() {
    # Return if already found
    if [[ -n "$WP_CLI_CMD" ]]; then return 0; fi

    # 1. Check if 'wp' is already in the PATH (covers interactive shells)
    if command -v wp &> /dev/null; then
        WP_CLI_CMD="wp"
        return 0
    fi

    # 2. If not in PATH, check common absolute paths for cron environments
    local common_paths=(
        "/usr/local/bin/wp"
        "$HOME/bin/wp"
        "/opt/wp-cli/wp"
    )
    for path in "${common_paths[@]}"; do
        if [ -x "$path" ]; then
            WP_CLI_CMD="$path"
            return 0
        fi
    done

    # 3. If still not found, error out
    echo "❌ Error: 'wp' command not found. Please ensure WP-CLI is installed and in your PATH." >&2
    return 1
}

# ----------------------------------------------------
#  Displays detailed help for a specific command.
# ----------------------------------------------------
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
            echo "Usage: _do backup <folder>"
            ;;
        checkpoint)
            echo "Manages versioned checkpoints of a WordPress installation's manifest."
            echo
            echo "Usage: _do checkpoint <subcommand> [arguments]"
            echo
            echo "Subcommands:"
            echo "  create              Creates a new checkpoint of the current plugin/theme/core manifest."
            echo "  list                Lists available checkpoints from the generated list to inspect."
            echo "  list-generate       Generates a detailed list of all checkpoints for fast viewing."
            echo "  revert [<hash>]     Reverts the site to the specified checkpoint hash."
            echo "  show <hash>         Retrieves the details for a specific checkpoint hash."
            echo "  latest              Gets the hash of the most recent checkpoint."
            ;;
        clean)
            echo "Cleans up unused WordPress components or analyzes disk usage."
            echo
            echo "Usage: _do clean <subcommand>"
            echo
            echo "Subcommands:"
            echo "  themes    Deletes all inactive themes except for the latest default WordPress theme."
            echo "  disk      Provides an interactive disk usage analysis for the current directory."
            ;;
        cron)
            echo "Manages scheduled tasks (cron jobs) for this script."
            echo
            echo "Usage: _do cron <subcommand> [arguments]"
            echo
            echo "Subcommands:"
            echo "  enable                         Adds a job to the system crontab to run '_do cron run' every 10 minutes."
            echo "  list                           Lists all scheduled commands."
            echo "  run                            Executes any scheduled commands that are due."
            echo "  add \"<cmd>\" \"<time>\" \"<freq>\"  Adds a new command to the schedule."
            echo "  delete <id>                    Deletes a command from the schedule."
            echo
            echo "Arguments for 'add':"
            echo "  <cmd>     (Required) The _do command to run, in quotes (e.g., \"update all\")."
            echo "  <time>    (Required) The next run time, in quotes (e.g., \"4am\", \"tomorrow 2pm\", \"+2 hours\")."
            echo "  <freq>    (Required) The frequency, in quotes (e.g., \"1 day\", \"1 week\", \"12 hours\")."
            echo
            echo "Example:"
            echo "  _do cron add \"update all\" \"4am\" \"1 day\""
            ;;
        db)
            echo "Performs various database operations."
            echo
            echo "Usage: _do db <subcommand>"
            echo
            echo "Subcommands:"
            echo "  backup           Performs a DB-only backup to a secure private directory."
            echo "  check-autoload   Checks the size and top 25 largest autoloaded options in the DB."
            echo "  optimize         Converts tables to InnoDB, reports large tables, and cleans transients."
            ;;
        dump)
            echo "Dumps the content of files matching a pattern into a single text file."
            echo
            echo "Usage: _do dump \"<pattern>\" [-x <exclude_pattern_1>] [-x <exclude_pattern_2>]..."
            echo
            echo "Arguments:"
            echo "  <pattern>   (Required) The path and file pattern to search for, enclosed in quotes."
            echo
            echo "Flags:"
            echo "  -x <pattern>  (Optional) A file or directory pattern to exclude. Can be used multiple times."
            echo "                To exclude a directory, the pattern MUST end with a forward slash (e.g., 'my-dir/')."
            echo
            echo "Examples:"
            echo "  _do dump \"wp-content/plugins/my-plugin/**/*.php\""
            echo "  _do dump \"*\" -x \"*.log\" -x \"node_modules/\""
            ;;
        convert-to-webp)
            echo "Finds and converts large images (JPG, PNG) to WebP format."
            echo
            echo "Usage: _do convert-to-webp"
            ;;
        migrate)
            echo "Migrates a site from a backup snapshot."
            echo
            echo "Usage: _do migrate --url=<backup-url> [--update-urls]"
            echo
            echo "  --update-urls   Update urls to destination WordPress site. Default will keep source urls."
            ;;
        monitor)
            echo "Monitors server access logs or errors in real-time."
            echo
            echo "Usage: _do monitor <subcommand> [--flags]"
            echo
            echo "Subcommands:"
            echo "  traffic       Analyzes and monitors top hits from access logs." 
            echo "  errors        Monitors logs for HTTP 500 and PHP fatal errors." 
            echo "  access.log    Provides a real-time stream of the access log."
            echo "  error.log     Provides a real-time stream of the error log."
            echo
            echo "Flags for 'traffic':"
            echo "  --top=<number>   The number of top IP/Status combinations to show. Default is 25." 
            echo "  --now            Start processing from the end of the log file instead of the beginning." 
            ;;
        php-tags)
            echo "Finds outdated or invalid PHP opening tags in PHP files."
            echo
            echo "Usage: _do php-tags [directory]"
            echo
            echo "Arguments:"
            echo "  [directory]  (Optional) The directory to search in. Defaults to 'wp-content/'."
            ;;
        reset-wp)
            echo "Resets the WordPress installation to a default state."
            echo
            echo "Usage: _do reset-wp --admin_user=<username> [--admin_email=<email>]"
            echo
            echo "Flags:"
            echo "  --admin_user=<username>   (Required) The username for the new administrator."
            echo "  --admin_email=<email>     (Optional) The email for the new administrator."
            echo "                            Defaults to the current site's admin email."
            ;;
        reset-permissions)
            echo "Resets file and folder permissions to defaults (755 for dirs, 644 for files)."
            echo
            echo "Usage: _do reset-permissions"
            ;;
        slow-plugins)
            echo "Identifies plugins that may be slowing down WP-CLI."
            echo
            echo "Usage: _do slow-plugins"
            ;;
        suspend)
            echo "Activates or deactivates a suspend message shown to visitors."
            echo
            echo "Usage: _do suspend <subcommand> [flags]"
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
        update)
            echo "Handles WordPress core, theme, and plugin updates."
            echo
            echo "Usage: _do update <subcommand>"
            echo
            echo "Subcommands:"
            echo "  all                 Creates a 'before' checkpoint, runs all updates, creates an"
            echo "                      'after' checkpoint, and logs the changes."
            echo "  list                Shows a list of past updates to inspect from the generated list."
            echo "  list-generate       Generates a detailed list of all updates for fast viewing."
            ;;
        version)
            echo "Displays the current version of the _do script."
            echo
            echo "Usage: _do version"
            ;;
        wpcli)
            echo "Checks for and identifies sources of WP-CLI warnings."
            echo
            echo "Usage: _do wpcli <subcommand>"
            echo
            echo "Subcommands:"
            echo "  check     Runs a check to find themes or plugins causing WP-CLI warnings."
            ;;
        *)
            echo "Error: Unknown command '$cmd' for help." >&2
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# ----------------------------------------------------
#  Displays the main help and usage information.
# ----------------------------------------------------
function show_usage() {
    echo "CaptainCore _do (v$CAPTAINCORE_DO_VERSION)"
    echo "--------------------------"
    echo "A collection of useful command-line utilities for managing WordPress sites."
    echo ""
    echo "Usage:"
    echo "  _do <command> [arguments] [--flags]"
    echo ""
    echo "Available Commands:"
    echo "  backup              Creates a full backup (files + DB) of a WordPress site."
    echo "  checkpoint          Manages versioned checkpoints of the site's manifest."
    echo "  clean               Removes unused items like inactive themes or analyzes disk usage."
    echo "  convert-to-webp     Finds and converts large images (JPG, PNG) to WebP format."
    echo "  cron                Manages cron jobs and schedules tasks to run at specific times."
    echo "  db                  Performs various database operations (backup, check-autoload, optimize)."
    echo "  dump                Dumps the content of files matching a pattern into a single text file."
    echo "  migrate             Migrates a site from a backup URL or local file."
    echo "  monitor             Monitors server logs or errors in real-time."
    echo "  php-tags            Finds outdated or invalid PHP opening tags."
    echo "  reset-wp            Resets the WordPress installation to a default state."
    echo "  reset-permissions   Resets file and folder permissions to defaults."
    echo "  slow-plugins        Identifies plugins that may be slowing down WP-CLI."
    echo "  suspend             Activates or deactivates a suspend message shown to visitors."
    echo "  update              Runs WordPress updates and logs the changes."
    echo "  version             Displays the current version of the _do script."
    echo "  wpcli               Checks for and identifies sources of WP-CLI warnings."
    echo ""
    echo "Run '_do help <command>' for more information on a specific command."
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
    local admin_user_flag=""
    local admin_email_flag=""
    local path_flag=""
    local exclude_patterns=()
    local positional_args=()
    
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
        --admin_user=*)
          admin_user_flag="${1#*=}"
          shift
          ;;
        --admin_email=*)
          admin_email_flag="${1#*=}"
          shift
          ;;
        --path=*)
          path_flag="${1#*=}"
          shift
          ;;
        -x) # Exclude flag
          if [[ -n "$2" ]]; then
            exclude_patterns+=("$2")
            shift 2 # past flag and value
          else
            echo "Error: -x flag requires an argument." >&2
            exit 1
          fi
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

    # --- Global Path Handling ---
    # If a path is provided, change to that directory first.
    # This allows commands to be run from anywhere for a specific site.
    if [[ -n "$path_flag" ]]; then
        if [ -d "$path_flag" ]; then
            cd "$path_flag" || { echo "❌ Error: Could not change directory to '$path_flag'." >&2; exit 1; }
        else
            echo "❌ Error: Provided path '$path_flag' does not exist." >&2
            exit 1
        fi
    fi

    #  The first positional argument is the main command.
    local command="${positional_args[0]}"

    # --- Command Router ---
    #  This routes to the correct function based on the parsed command.
    case "$command" in
        backup)
            full_backup "${positional_args[1]}"
            ;;
        checkpoint)
            local subcommand="${positional_args[1]}"
            case "$subcommand" in
                create)
                    checkpoint_create
                    ;;
                list)
                    checkpoint_list
                    ;;
                list-generate)
                    checkpoint_list_generate
                    ;;
                revert)
                    local hash="${positional_args[2]}"
                    checkpoint_revert "$hash"
                    ;;
                show)
                    local hash="${positional_args[2]}"
                    checkpoint_show "$hash"
                    ;;
                latest)
                    checkpoint_latest
                    ;;
                *)
                    show_command_help "checkpoint"
                    exit 0
                    ;;
            esac
            ;;
        clean)
            local arg1="${positional_args[1]}"
            case "$arg1" in
                themes)
                    clean_themes
                    ;;
                disk)
                    clean_disk
                    ;;
                *)
                    show_command_help "clean"
                    exit 0
                    ;;
            esac
            ;;
        cron)
            local subcommand="${positional_args[1]}"
            case "$subcommand" in
                enable)
                    cron_enable
                    ;;
                list)
                    cron_list
                    ;;
                run)
                    cron_run
                    ;;
                add)
                    cron_add "${positional_args[2]}" "${positional_args[3]}" "${positional_args[4]}"
                    ;;
                delete)
                    cron_delete "${positional_args[2]}"
                    ;;
                *)
                    show_command_help "cron"
                    exit 0
                    ;;
            esac
            ;;
        db)
            local arg1="${positional_args[1]}"
            case "$arg1" in
                backup)
                    db_backup # Originally from backup-db command 
                    ;;
                check-autoload)
                    db_check_autoload # Originally from db-check-autoload command 
                    ;;
                optimize)
                    db_optimize # Originally from db-optimize command 
                    ;;
                *)
                    show_command_help "db"
                    exit 0
                    ;;
            esac
            ;;
        convert-to-webp)
            convert_to_webp
            ;;
        dump)
            # There should be exactly 2 positional args total: 'dump' and the pattern.
            if [ ${#positional_args[@]} -ne 2 ]; then
                echo -e "Error: Incorrect number of arguments for 'dump'. It's likely your pattern was expanded by the shell." >&2
                echo "Please wrap the input pattern in double quotes." >&2
                echo -e "\n  Usage: _do dump \"<pattern>\" [-x <exclude1>...]" >&2
                return 1
            fi
            run_dump "${positional_args[1]}" "${exclude_patterns[@]}"
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
            local arg1="${positional_args[1]}"
            case "$arg1" in
                traffic)
                    monitor_traffic "$top_flag" "$now_flag"
                    ;;
                errors)
                    monitor_errors
                    ;;
                access.log)
                    monitor_access_log
                    ;;
                error.log)
                    monitor_error_log
                    ;;
                *)
                    show_command_help "monitor"
                    exit 0
                    ;;
            esac
            ;;
        php-tags)
            find_outdated_php_tags "${positional_args[1]}"
            ;;
        reset-wp)
            if [[ -z "$admin_user_flag" ]]; then
                echo "Error: The 'reset-wp' command requires the --admin_user=<...> flag." >&2
                show_command_help "reset-wp"
                exit 1
            fi
            reset_site "$admin_user_flag" "$admin_email_flag"
            ;;
        reset-permissions)
            reset_permissions
            ;;
        slow-plugins)
            identify_slow_plugins
            ;;
        suspend)
            local arg1="${positional_args[1]}" 
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
        update)
            local subcommand="${positional_args[1]}"
            case "$subcommand" in
                all)
                    run_update_all
                    ;;
                list)
                    update_list
                    ;;
                list-generate)
                    update_list_generate
                    ;;
                *)
                    show_command_help "update"
                    exit 1
                    ;;
            esac
            ;;
        version|--version|-v)
            show_version
            ;;
        wpcli)
            local subcommand="${positional_args[1]}"
            case "$subcommand" in
                check)
                    wpcli_check
                    ;;
                *)
                    show_command_help "wpcli"
                    exit 0
                    ;;
            esac
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

# ----------------------------------------------------
#  Creates a full backup of a WordPress site (files + database).
# ----------------------------------------------------
function full_backup() {
    local target_folder="$1"
    if [ -z "$target_folder" ]; then echo "Error: Please provide a folder path." >&2; echo "Usage: _do backup <folder>" >&2; return 1; fi
    if ! command -v realpath &> /dev/null; then echo "Error: 'realpath' command not found. Please install it." >&2; return 1; fi
    if [ ! -d "$target_folder" ]; then echo "Error: Folder '$target_folder' not found." >&2; return 1; fi

    #  Resolve the absolute path to handle cases like "."
    local full_target_path; full_target_path=$(realpath "$target_folder")
    local parent_dir; parent_dir=$(dirname "$full_target_path")
    local site_dir_name; site_dir_name=$(basename "$full_target_path")

    local today; today=$(date +"%Y-%m-%d"); local random; random=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 7); local backup_filename="${today}_${random}.zip"; local original_dir;
    original_dir=$(pwd)

    #  Change to the parent directory for consistent relative paths in the zip
    cd "$parent_dir" || return 1

    if ! setup_wp_cli; then echo "Error: wp-cli is not installed." >&2; cd "$original_dir"; return 1; fi
    local home_url; home_url=$("$WP_CLI_CMD" option get home --path="$site_dir_name" --skip-plugins --skip-themes); local name; name=$("$WP_CLI_CMD" option get blogname --path="$site_dir_name" --skip-plugins --skip-themes);
    local database_file="db_export.sql"

    echo "Exporting database for '$name'...";
    if ! "$WP_CLI_CMD" db export "$site_dir_name/$database_file" --path="$site_dir_name" --add-drop-table --default-character-set=utf8mb4; then
        echo "Error: Database export failed." >&2
        cd "$original_dir"
        return 1
    fi

    echo "Creating zip archive...";
    #  Create the zip in the parent directory, zipping the site directory
    if ! zip -r "$backup_filename" "$site_dir_name" -x "$site_dir_name/wp-content/updraft/*" > /dev/null; then
        echo "Error: Failed to zip files." >&2
        rm -f "$site_dir_name/$database_file"
        cd "$original_dir"
        return 1
    fi

    #  Add wp-config.php if it exists in the site directory
    if [ -f "$site_dir_name/wp-config.php" ]; then
        zip "$backup_filename" "$site_dir_name/wp-config.php" > /dev/null
    fi

    #  Cleanup and Final Steps
    local size; size=$(ls -lh "$backup_filename" | awk '{print $5}')
    rm -f "$site_dir_name/$database_file"
    mv "$backup_filename" "$site_dir_name/"

    local final_backup_location="$site_dir_name/$backup_filename"

    cd "$original_dir"

    echo "-----------------------------------------------------";
    echo "✅ Full site backup complete!";
    echo "   Name: $name";
    echo "   Location: $final_backup_location";
    echo "   Size: $size";
    echo "   URL: ${home_url}/${backup_filename}";
    echo "-----------------------------------------------------";
    echo "When done, remember to remove the backup file.";
    echo "rm -f \"$full_target_path/$backup_filename\""
}
# ----------------------------------------------------
#  Checkpoint Commands
#  Manages versioned checkpoints of the site's manifest.
# ----------------------------------------------------

# --- Checkpoint Base Directory ---
CHECKPOINT_BASE_DIR=""
CHECKPOINT_REPO_DIR=""
CHECKPOINT_LIST_FILE=""

# ----------------------------------------------------
#  (Helper) Reverts a specific item's files to a given checkpoint hash.
# ----------------------------------------------------
function _revert_item_to_hash() {
    local item_type="$1"      # "plugin" or "theme"
    local item_name="$2"      # e.g., "akismet"
    local target_hash="$3"    # The git hash to revert to
    local wp_content_dir="$4" # The live wp-content directory
    local repo_dir="$5"       # The path to the checkpoint git repo
    local current_hash="$6"   # The hash we are reverting FROM (for cleanup)

    # Define paths
    local item_path_in_repo="${item_type}s/${item_name}"
    local restored_source_path="${repo_dir}/${item_path_in_repo}/"
    local live_item_path="${wp_content_dir}/${item_type}s/${item_name}"

    echo "Reverting '$item_name' files to state from checkpoint ${target_hash:0:7}..."

    # Use git to restore the files *within the checkpoint repo*
    "$GIT_CMD" -C "$repo_dir" checkout "$target_hash" -- "$item_path_in_repo" &>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Error: git checkout failed. Could not restore files from checkpoint." >&2
        # Clean up by checking out the original state before we messed with it
        "$GIT_CMD" -C "$repo_dir" checkout "$current_hash" -- "$item_path_in_repo" &>/dev/null
        return 1
    fi

    # Sync the restored files from the repo back to the live site
    echo "Syncing restored files to the live site..."

    # If the path no longer exists in the reverted repo state, it should be deleted from the live site.
    if [ ! -e "${repo_dir}/${item_path_in_repo}" ]; then
        echo "   - Item did not exist in target checkpoint. Removing from live site..."
        if [ -e "$live_item_path" ]; then
            rm -rf "$live_item_path"
            echo "   ✅ Removed '$live_item_path'."
        else
            echo "   - Already absent from live site. No action needed."
        fi
    else
        # The item existed. Sync it to the live site. This handles both updates and re-additions.
        echo "   - Item existed in target checkpoint. Syncing files..."
        rsync -a --delete "$restored_source_path" "$live_item_path/"
        echo "   ✅ Synced files to '$live_item_path/'."
    fi

    # IMPORTANT: Revert the repo back to the original hash so it remains consistent.
    # This resets the state of the repo, leaving only the live files changed.
    "$GIT_CMD" -C "$repo_dir" checkout "$current_hash" -- "$item_path_in_repo" &>/dev/null

    echo "✅ Revert complete for '$item_name'."
    echo "💡 Note: This action reverts files only. Database or activation status changes are not affected."
}

# ----------------------------------------------------
#  Ensures checkpoint directories and lists exist.
# ----------------------------------------------------
function _ensure_checkpoint_setup() {
    # Exit if already initialized
    if [[ -n "$CHECKPOINT_BASE_DIR" ]]; then return 0; fi

    local private_dir
    if ! private_dir=$(_get_private_dir); then
        return 1
    fi

    CHECKPOINT_BASE_DIR="${private_dir}/checkpoints"
    CHECKPOINT_REPO_DIR="$CHECKPOINT_BASE_DIR/repo"
    CHECKPOINT_LIST_FILE="$CHECKPOINT_BASE_DIR/list.json"

    mkdir -p "$CHECKPOINT_REPO_DIR"
    if [ ! -f "$CHECKPOINT_LIST_FILE" ]; then
        echo "[]" > "$CHECKPOINT_LIST_FILE" 
    fi
}

# ----------------------------------------------------
#  Generates a JSON manifest of the current WP state and saves it to a file.
# ----------------------------------------------------
function _generate_manifest() {
    local output_file="$1"
    if [ -z "$output_file" ]; then
        echo "Error: No output file provided to _generate_manifest." >&2
        return 1
    fi

    local core_version; core_version=$("$WP_CLI_CMD" core version --skip-plugins --skip-themes)
    local plugins; plugins=$("$WP_CLI_CMD" plugin list --fields=name,title,status,version,auto_update --format=json --skip-plugins --skip-themes)
    local themes; themes=$("$WP_CLI_CMD" theme list --fields=name,title,status,version,auto_update --format=json --skip-plugins --skip-themes)

    # Manually create JSON to avoid extra dependencies
    cat <<EOF > "$output_file"
{
  "core": "$core_version",
  "plugins": $plugins,
  "themes": $themes
}
EOF
}

# ----------------------------------------------------
#  Creates a new checkpoint.
# ----------------------------------------------------
function checkpoint_create() {
    if ! setup_git; then return 1; fi
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! command -v rsync &>/dev/null; then echo "❌ Error: rsync command not found." >&2; return 1; fi

    _ensure_checkpoint_setup

    echo "🚀 Creating new checkpoint..."

    # Get wp-content path
    local wp_content_dir
    wp_content_dir=$("$WP_CLI_CMD" eval "echo rtrim(WP_CONTENT_DIR, '/');" --skip-plugins --skip-themes 2>/dev/null)
    if [ -z "$wp_content_dir" ] || [ ! -d "$wp_content_dir" ]; then
        echo "❌ Error: Could not determine wp-content directory." >&2
        return 1
    fi
    echo "   - Found wp-content at: $wp_content_dir"

    # Sync files
    echo "   - Syncing themes, plugins, and mu-plugins..."
    mkdir -p "$CHECKPOINT_REPO_DIR/themes" "$CHECKPOINT_REPO_DIR/plugins" "$CHECKPOINT_REPO_DIR/mu-plugins"

    # Use rsync to copy directories. The trailing slashes are important.
    rsync -a --delete --exclude='*.zip' --exclude='logs/' --exclude='.git/' "$wp_content_dir/themes/" "$CHECKPOINT_REPO_DIR/themes/"
    rsync -a --delete --exclude='*.zip' --exclude='logs/' --exclude='.git/' "$wp_content_dir/plugins/" "$CHECKPOINT_REPO_DIR/plugins/"
    if [ -d "$wp_content_dir/mu-plugins" ]; then
      rsync -a --delete --exclude='*.zip' --exclude='logs/' --exclude='.git/' "$wp_content_dir/mu-plugins/" "$CHECKPOINT_REPO_DIR/mu-plugins/"
    fi

    local manifest_file="$CHECKPOINT_REPO_DIR/manifest.json"

    echo "   - Generating manifest..."
    if ! _generate_manifest "$manifest_file"; then
        echo "❌ Error: Failed to generate manifest file." >&2
        return 1
    fi

    # Initialize git repo if it doesn't exist
    if [ ! -d "$CHECKPOINT_REPO_DIR/.git" ]; then
        echo "   - Initializing checkpoint repository..."
        "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" init -b main > /dev/null
    fi

    echo "   - Committing changes to repository..."
    # Add all changes (manifest + files)
    "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" add .
    # Check if there are changes to commit
    if "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff --staged --quiet; then
        echo "✅ No changes detected. Checkpoint is up-to-date."
        local latest_hash; latest_hash=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" rev-parse HEAD 2>/dev/null)
        if [ -n "$latest_hash" ]; then
            echo "   Latest Hash: $latest_hash"
        fi
        return 0
    fi
    
    # Set a default author identity for the commit to prevent errors on remote systems
    # where git might not be configured. This is a local config for this repo only.
    "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" config user.email "script@captaincore.io"
    "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" config user.name "_do Script"

    local timestamp; timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" commit -m "Checkpoint $timestamp" > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to commit checkpoint changes." >&2
        return 1
    fi
    
    local commit_hash; commit_hash=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" rev-parse HEAD)
    if [ -z "$commit_hash" ]; then
        echo "❌ Error: Could not retrieve commit hash after creating checkpoint." >&2
        return 1
    fi

    local checkpoint_file="$CHECKPOINT_BASE_DIR/$commit_hash.json"

    echo "   - Saving checkpoint details..."
    printf '{\n  "hash": "%s",\n  "timestamp": "%s"\n}\n' "$commit_hash" "$timestamp" > "$checkpoint_file"

    # Safely update the JSON list file using a PHP script
    local php_code_template='
<?php
$list_file = "%s";
$hash = "%s";
$timestamp = "%s";
$list = file_exists($list_file) ? json_decode(file_get_contents($list_file), true) : [];
if (!is_array($list)) { $list = []; }
$new_entry = ["hash" => $hash, "timestamp" => $timestamp];
array_unshift($list, $new_entry);
echo json_encode($list, JSON_PRETTY_PRINT);
'
    local php_script; php_script=$(printf "$php_code_template" "$CHECKPOINT_LIST_FILE" "$commit_hash" "$timestamp")
    
    local temp_list_file; temp_list_file=$(mktemp)
    if echo "$php_script" | "$WP_CLI_CMD" eval-file - > "$temp_list_file"; then
        mv "$temp_list_file" "$CHECKPOINT_LIST_FILE"
    else
        echo "❌ Error: Failed to update checkpoint list." >&2
        rm "$temp_list_file"
    fi
    
    echo "✅ Checkpoint created successfully."
    echo "   Hash: $commit_hash"
    
    # Automatically regenerate the detailed checkpoint list
    echo "   - Regenerating detailed checkpoint list..."
    checkpoint_list_generate > /dev/null
}

# ----------------------------------------------------
#  Generates a detailed list of checkpoints for faster access.
# ----------------------------------------------------
function checkpoint_list_generate() {
    if ! setup_gum || ! setup_git; then return 1; fi
    if ! setup_wp_cli; then return 1; fi
    _ensure_checkpoint_setup

    # Read the potentially simple list created by `checkpoint create`
    local php_script_read_list='
<?php
$list_file = "%s";
if (!file_exists($list_file)) { return; }
$list = json_decode(file_get_contents($list_file), true);
if (!is_array($list) || empty($list)) { return; }
foreach($list as $item) {
    if (isset($item["timestamp"]) && isset($item["hash"])) {
        echo $item["timestamp"] . "|" . $item["hash"] . "\n";
    }
}
'
    local php_script; php_script=$(printf "$php_script_read_list" "$CHECKPOINT_LIST_FILE")
    local checkpoint_entries; checkpoint_entries=$(echo "$php_script" | "$WP_CLI_CMD" eval-file -)

    if [ -z "$checkpoint_entries" ]; then
        echo "ℹ️  No checkpoints found to generate a list from."
        return 0
    fi
    
    echo "🔎 Generating detailed checkpoint list... (This may take a moment)"
    local detailed_items=()

    while IFS='|' read -r timestamp hash; do
        hash=$(echo "$hash" | tr -d '[:space:]')
        if [ -z "$hash" ]; then continue; fi

        local parent_hash=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" log -n 1 --pretty=format:%P "$hash" 2>/dev/null)
        local manifest_current; manifest_current=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" show "$hash:manifest.json" 2>/dev/null)
        if [ -z "$manifest_current" ]; then continue; fi

        local php_get_counts='
<?php
$manifest_json = <<<'EOT'
%s
EOT;
$data = json_decode($manifest_json, true);
$theme_count = isset($data["themes"]) && is_array($data["themes"]) ? count($data["themes"]) : 0;
$plugin_count = isset($data["plugins"]) && is_array($data["plugins"]) ? count($data["plugins"]) : 0;
echo "$theme_count Themes, $plugin_count Plugins";
'
        local counts_script; counts_script=$(printf "$php_get_counts" "$manifest_current")
        local counts_str; counts_str=$(echo "$counts_script" | "$WP_CLI_CMD" eval-file -)
        
        local diff_stats="Initial checkpoint"
        if [ -n "$parent_hash" ]; then
            diff_stats=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff --shortstat "$parent_hash" "$hash" -- 'plugins/' 'themes/' 'mu-plugins/' | sed 's/^[ \t]*//')
            if [ -z "$diff_stats" ]; then diff_stats="No file changes"; fi
        fi

        local formatted_timestamp
        if [[ "$(uname)" == "Darwin" ]]; then
            formatted_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" -u "$timestamp" "+%a, %b %d, %Y, %-I:%M %p")
        else
            formatted_timestamp=$(date -d "$timestamp" "+%a, %b %d, %Y, %-I:%M %p")
        fi

        # Create a JSON object for this item
        local json_item
        json_item=$(printf '{"hash": "%s", "timestamp": "%s", "formatted_timestamp": "%s", "counts_str": "%s", "diff_stats": "%s"}' \
            "$hash" "$timestamp" "$formatted_timestamp" "$counts_str" "$diff_stats")
        
        detailed_items+=("$json_item")

    done <<< "$checkpoint_entries"
    
    # Write the detailed list back to the file
    local full_json="["
    full_json+=$(IFS=,; echo "${detailed_items[*]}")
    full_json+="]"

    # Use PHP to pretty-print the JSON to the file
    local php_write_script='
<?php
$list_file = "%s";
$json_data = <<<'EOT'
%s
EOT;
$data = json_decode($json_data, true);
file_put_contents($list_file, json_encode($data, JSON_PRETTY_PRINT));
'
    local write_script; write_script=$(printf "$php_write_script" "$CHECKPOINT_LIST_FILE" "$full_json")
    if echo "$write_script" | "$WP_CLI_CMD" eval-file -; then
        echo "✅ Detailed checkpoint list saved to $CHECKPOINT_LIST_FILE"
    else
        echo "❌ Error: Failed to write detailed list."
    fi
}

# ----------------------------------------------------
#  (Helper) Lets the user select a checkpoint hash from the list.
# ----------------------------------------------------
function _select_checkpoint_hash() {
    _ensure_checkpoint_setup
    if ! setup_wp_cli; then return 1; fi

    if [ ! -s "$CHECKPOINT_LIST_FILE" ]; then
        echo "ℹ️ No checkpoints found. Run '_do checkpoint create' to make one." >&2
        exit 1
    fi
    
    # Use PHP to read the detailed list and check if it's in the new format
    local php_script_read_list='
<?php
$list_file = "%s";
$list = json_decode(file_get_contents($list_file), true);

if (!is_array($list) || empty($list)) {
    echo "EMPTY";
    return;
}

// Check if the first item has the detailed format.
if (!isset($list[0]["formatted_timestamp"])) {
    echo "NEEDS_GENERATE";
    return;
}

foreach($list as $item) {
    if (isset($item["formatted_timestamp"]) && isset($item["hash"]) && isset($item["counts_str"]) && isset($item["diff_stats"])) {
        // Output format: formatted_timestamp|hash|counts_str|diff_stats
        echo $item["formatted_timestamp"] . "|" . $item["hash"] . "|" . $item["counts_str"] . "|" . $item["diff_stats"] . "\n";
    }
}
'
    local php_script; php_script=$(printf "$php_script_read_list" "$CHECKPOINT_LIST_FILE")
    local checkpoint_entries; checkpoint_entries=$(echo "$php_script" | "$WP_CLI_CMD" eval-file -)

    if [[ "$checkpoint_entries" == "EMPTY" ]]; then
        echo "ℹ️  No checkpoints available to select." >&2
        exit 1 # Use exit 1 to guarantee a non-zero exit code from the subshell
    elif [[ "$checkpoint_entries" == "NEEDS_GENERATE" ]]; then
        echo "⚠️ The checkpoint list needs to be generated for faster display." >&2
        echo "Please run: _do checkpoint list-generate" >&2
        exit 1 # Use exit 1
    fi

    local display_items=()
    local data_items=()

    # Get terminal width for dynamic padding
    local term_width; term_width=$(tput cols)
    local hash_col_width=9 # "xxxxxxx |"
    local counts_col_width=20 # "xx Themes, xx Plugins |"
    
    # Calculate available width for the timestamp column
    local timestamp_col_width=$((term_width - hash_col_width - counts_col_width - 5)) # 5 for buffers
    # Set a reasonable minimum and maximum
    if [ "$timestamp_col_width" -lt 20 ]; then timestamp_col_width=20; fi
    if [ "$timestamp_col_width" -gt 30 ]; then timestamp_col_width=30; fi

    while IFS='|' read -r formatted_timestamp hash counts_str diff_stats; do
        hash=$(echo "$hash" | tr -d '[:space:]')
        if [ -z "$hash" ]; then continue; fi

        # Use the new dynamic width for the timestamp
        local display_string
        display_string=$(printf "%-${timestamp_col_width}s | %s | %-18s | %s" \
            "$formatted_timestamp" "${hash:0:7}" "$counts_str" "$diff_stats")
        
        display_items+=("$display_string")
        data_items+=("$hash")
    done <<< "$checkpoint_entries"
    
    if [ ${#display_items[@]} -eq 0 ]; then
      echo "❌ No valid checkpoints to display." >&2
      exit 1
    fi

    local prompt_text="${1:-Select a checkpoint to inspect}"
    local selected_display
    selected_display=$(printf "%s\n" "${display_items[@]}" | "$GUM_CMD" filter --height=20 --prompt="👇 $prompt_text" --indicator="→" --placeholder="")

    if [ -z "$selected_display" ]; then
        echo "" # Return empty for cancellation
        return 0
    fi

    local selected_index=-1
    for i in "${!display_items[@]}"; do
       if [[ "${display_items[$i]}" == "$selected_display" ]]; then
           selected_index=$i
           break
       fi
    done

    if [ "$selected_index" -ne -1 ]; then
        echo "${data_items[$selected_index]}"
        return 0
    else
        echo "❌ Error: Could not find selected checkpoint." >&2
        exit 1
    fi
}

# ----------------------------------------------------
#  Lists all checkpoints from the pre-generated list and allows selection.
# ----------------------------------------------------
function checkpoint_list() {
    if ! setup_gum || ! setup_git; then return 1; fi
    
    local selected_hash
    selected_hash=$(_select_checkpoint_hash "Select a checkpoint to inspect")
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        return 1
    fi

    if [ -z "$selected_hash" ]; then
        echo "No checkpoint selected."
        return 0
    fi

    checkpoint_show "$selected_hash"
}

# ----------------------------------------------------
#  Reverts all files to a specific checkpoint hash.
# ----------------------------------------------------
function checkpoint_revert() {
    local target_hash="$1"

    if ! setup_gum || ! setup_git; then return 1; fi
    if ! setup_wp_cli; then return 1; fi

    # If no hash is provided, let the user pick one from a detailed list.
    if [ -z "$target_hash" ]; then
        target_hash=$(_select_checkpoint_hash "Select a checkpoint to revert to")
        
        if [ -z "$target_hash" ]; then
            echo "Revert cancelled."
            return 0
        fi
        # Check the exit code of the helper
        if [ $? -ne 0 ]; then
            return 1 # Error was already printed by the helper
        fi
    fi
    
    _ensure_checkpoint_setup

    # Validate the hash to ensure it exists in the repo before proceeding
    if ! "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" cat-file -e "${target_hash}^{commit}" &>/dev/null; then
        echo "❌ Error: Checkpoint hash '$target_hash' not found." >&2
        return 1
    fi

    # Final confirmation before the revert
    echo "🚨 You are about to revert ALL themes, plugins, and mu-plugins to the state from checkpoint ${target_hash:0:7}."
    echo "This will overwrite any changes made since that checkpoint was created."
    "$GUM_CMD" confirm "Are you sure you want to proceed?" || { echo "Revert cancelled."; return 0; }

    # Get wp-content path for rsync destination
    local wp_content_dir
    wp_content_dir=$("$WP_CLI_CMD" eval "echo rtrim(WP_CONTENT_DIR, '/');" --skip-plugins --skip-themes 2>/dev/null)
    if [ -z "$wp_content_dir" ] || [ ! -d "$wp_content_dir" ]; then
        echo "❌ Error: Could not determine wp-content directory." >&2
        return 1
    fi
    
    local current_hash=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" rev-parse HEAD)

    # Revert all three directories within the git repo
    echo "Reverting all tracked files to checkpoint ${target_hash:0:7}..."
    "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" checkout "$target_hash" -- 'plugins/' 'themes/' 'mu-plugins/' &>/dev/null
    
    # Sync the reverted files from the repo to the live site directories
    echo "Syncing restored files to the live site..."
    rsync -a --delete "$CHECKPOINT_REPO_DIR/plugins/" "$wp_content_dir/plugins/"
    rsync -a --delete "$CHECKPOINT_REPO_DIR/themes/" "$wp_content_dir/themes/"
    rsync -a --delete "$CHECKPOINT_REPO_DIR/mu-plugins/" "$wp_content_dir/mu-plugins/"

    # IMPORTANT: Reset the repo's state back to the original `HEAD`
    "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" checkout "$current_hash" -- 'plugins/' 'themes/' 'mu-plugins/' &>/dev/null

    echo "✅ Full file revert to checkpoint ${target_hash:0:7} is complete."
    echo "💡 Note: This action reverts files only. Database changes, plugin/theme activation status, and WordPress core version are not affected."
}

# ----------------------------------------------------
#  Shows the diff between two checkpoints or one checkpoint and its parent.
# ----------------------------------------------------
function checkpoint_show() {
    local hash_after="$1"
    local hash_before="$2"

    if [ -z "$hash_after" ]; then
        echo "❌ Error: No hash provided." >&2
        show_command_help "checkpoint"
        return 1
    fi

    if ! setup_gum || ! setup_git; then return 1; fi
    if ! setup_wp_cli; then return 1; fi
    _ensure_checkpoint_setup

    # If 'before' hash is not provided, find the parent of the 'after' hash.
    if [ -z "$hash_before" ]; then
        hash_before=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" log -n 1 --pretty=format:%P "$hash_after" 2>/dev/null)
    fi

    local manifest_after
    manifest_after=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" show "$hash_after:manifest.json" 2>/dev/null)
    if [ -z "$manifest_after" ]; then
        echo "❌ Error: Could not find manifest for 'after' hash '$hash_after'." >&2
        return 1
    fi

    local manifest_before="{}"
    if [ -n "$hash_before" ]; then
        manifest_before=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" show "$hash_before:manifest.json" 2>/dev/null)
        if [ -z "$manifest_before" ]; then
            echo "⚠️ Warning: Could not find manifest for 'before' hash '$hash_before'. Comparing against an empty state." >&2
            manifest_before="{}"
        fi
    fi

    # Get a list of themes and plugins that have actual file changes.
    local changed_files_list
    if [ -z "$hash_before" ]; then
        # This is the initial commit, compare against the empty tree.
        changed_files_list=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff-tree --no-commit-id --name-only -r "$hash_after" -- 'plugins/' 'themes/' 'mu-plugins/')
    else
        changed_files_list=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff --name-only "$hash_before" "$hash_after" -- 'plugins/' 'themes/' 'mu-plugins/')
    fi

    local items_with_file_changes=()
    while IFS= read -r file_path; do
        if [[ -n "$file_path" ]]; then
            local item_name
            item_name=$(echo "$file_path" | cut -d'/' -f2)
            items_with_file_changes+=("$item_name")
        fi
    done <<< "$changed_files_list"
    local changed_items_str
    changed_items_str=$(printf "%s\n" "${items_with_file_changes[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')

    # --- 1. Generate list of ALL items from PHP ---
    export MANIFEST_AFTER_JSON="$manifest_after"
    export MANIFEST_BEFORE_JSON="$manifest_before"
    export CHANGED_ITEMS_STR="$changed_items_str"

    local php_script
    read -r -d '' php_script <<'PHP'
<?php
// This PHP script compares two manifest files and outputs pipe-delimited data for shell processing.

$manifest_after_json = getenv('MANIFEST_AFTER_JSON');
$manifest_before_json = getenv('MANIFEST_BEFORE_JSON');
$changed_items_str = getenv('CHANGED_ITEMS_STR');

$after_data = json_decode($manifest_after_json, true);
$before_data = json_decode($manifest_before_json, true);
$items_with_file_changes = !empty($changed_items_str) ? explode(',', $changed_items_str) : [];

function process_item_diff($item_type, $after_items, $before_items, $items_with_file_changes) {
    $after_map = [];
    if (is_array($after_items)) { foreach ($after_items as $item) { if(isset($item["name"])) $after_map[$item["name"]] = $item; } }

    $before_map = [];
    if (is_array($before_items)) { foreach ($before_items as $item) { if(isset($item["name"])) $before_map[$item["name"]] = $item; } }

    $all_names = array_unique(array_merge(array_keys($after_map), array_keys($before_map)));
    sort($all_names);
    
    $output_lines = [];

    foreach ($all_names as $name) {
        if(empty($name)) continue;

        $has_changed = false;
        $change_parts = [];
        $after_item = $after_map[$name] ?? null;
        $before_item = $before_map[$name] ?? null;

        if ($after_item && $before_item) {
            // Check for status changes first for correct ordering
            if (($after_item["status"] ?? null) !== ($before_item["status"] ?? null)) {
                $change_parts[] = "status " . ($before_item["status"] ?? 'N/A') . " -> " . ($after_item["status"] ?? 'N/A');
                $has_changed = true;
            }
            if (($after_item["version"] ?? null) !== ($before_item["version"] ?? null)) {
                $change_parts[] = "version " . ($before_item["version"] ?? 'N/A') . " -> " . ($after_item["version"] ?? 'N/A');
                $has_changed = true;
            }
            if (in_array($name, $items_with_file_changes, true)) {
                $change_parts[] = "files changed";
                $has_changed = true;
            }
        } elseif ($after_item) {
            $change_parts[] = "installed";
            if(isset($after_item["version"])) $change_parts[] = "v" . $after_item["version"];
            $has_changed = true;
        } else {
            $change_parts[] = "deleted";
            $has_changed = true;
        }

        $item_for_details = $after_item ?: $before_item;
        $title = $item_for_details["title"] ?? $name;
        
        if ($has_changed) {
            $details_string = implode(", ", array_unique($change_parts));
        } else {
            $version = $item_for_details["version"] ?? 'N/A';
            $status = $item_for_details["status"] ?? 'N/A';
            // Format with status first, then version
            $details_string = "$status, v$version";
        }
        
        $output_lines[] = [
            'has_changed' => $has_changed,
            'type'        => $item_type,
            'slug'        => $name,
            'title'       => $title,
            'details'     => $details_string,
        ];
    }

    // Sort to show changed items first
    usort($output_lines, function ($a, $b) {
        if ($a['has_changed'] !== $b['has_changed']) {
            return $b['has_changed'] <=> $a['has_changed'];
        }
        return strcmp($a['slug'], $b['slug']);
    });

    // Output as pipe-delimited data
    foreach ($output_lines as $line) {
        echo implode("|", [
            $line['has_changed'] ? 'true' : 'false',
            $line['type'],
            $line['slug'],
            $line['title'],
            $line['details']
        ]) . "\n";
    }
}

process_item_diff('Theme', $after_data['themes'] ?? [], $before_data['themes'] ?? [], $items_with_file_changes);
process_item_diff('Plugin', $after_data['plugins'] ?? [], $before_data['plugins'] ?? [], $items_with_file_changes);
PHP

    local php_output
    php_output=$(echo "$php_script" | "$WP_CLI_CMD" eval-file - 2>/dev/null)

    # Unset the environment variables
    unset MANIFEST_AFTER_JSON
    unset MANIFEST_BEFORE_JSON
    unset CHANGED_ITEMS_STR

    if [ -z "$php_output" ]; then
        echo "✅  No manifest changes found between checkpoints ${hash_before:0:7} and ${hash_after:0:7}."
        return 0
    fi
    
    local display_items=()
    local data_items=()

    # Use fixed-width columns for consistent alignment
    local slug_width=30
    local title_width=42

    # Read the pipe-delimited output from PHP and format it for display
    while IFS='|' read -r has_changed item_type slug title details; do
        local icon
        if [[ "$has_changed" == "true" ]];
        then
            icon="+"
        else
            icon=$(printf '\xE2\xA0\x80\xE2\xA0\x80')
        fi

        # Use "%-2s" to create a 2-character wide column for the icon.
        # This ensures consistent padding for both the "+" and " " cases.
        # Note the space between "%-2s" and "%-8s" is preserved.
        local display_line
        display_line=$(printf "%-2s%-8s %-*.*s %-*.*s %s" "$icon" "$item_type" "$slug_width" "$slug_width" "$slug" "$title_width" "$title_width" "$title" "$details")

        display_items+=("$display_line")
        data_items+=("$item_type|$slug")
    done <<< "$php_output"

    # Start a loop to allow returning to the item selection.
    while true; do
        # --- 2. Interactive Item Selection ---
        local selected_display_text
        selected_display_text=$(printf "%s\n" "${display_items[@]}" | "$GUM_CMD" filter --prompt="? Select item to inspect (checkpoints ${hash_before:0:7} -> ${hash_after:0:7}). Press Esc to exit." --height=20 --indicator="→" --placeholder="")

        if [ -z "$selected_display_text" ]; then
            # User pressed Esc, so break the loop and exit the function.
            break
        fi

        local selected_index=-1
        for i in "${!display_items[@]}"; do
           if [[ "${display_items[$i]}" == "$selected_display_text" ]]; then
               selected_index=$i
               break
           fi
        done

        if [ "$selected_index" -eq -1 ]; then
            # Should not happen, but as a safeguard
            continue
        fi

        local item_data="${data_items[$selected_index]}"
        local item_type; item_type=$(echo "$item_data" | cut -d'|' -f1)
        local item_name; item_name=$(echo "$item_data" | cut -d'|' -f2)

        # --- 3. Get wp-content Path ---
        local wp_content_dir
        wp_content_dir=$("$WP_CLI_CMD" eval "echo rtrim(WP_CONTENT_DIR, '/');" --skip-plugins --skip-themes 2>/dev/null)
        if [ -z "$wp_content_dir" ] || [ ! -d "$wp_content_dir" ]; then
            echo "❌ Error: Could not determine wp-content directory." >&2
            return 1
        fi

        # --- 4. Interactive Action Selection ---
        local choices=("Show File Changes" "Revert Files to 'After' State (${hash_after:0:7})")
        if [ -n "$hash_before" ]; then
            choices+=("Revert Files to 'Before' State (${hash_before:0:7})")
        fi
        choices+=("Back to item list")
        
        local action; action=$("$GUM_CMD" choose "${choices[@]}")

        # --- 5. Execute Action ---
        case "$action" in
            "Show File Changes")
                local item_path_in_repo
                case "$item_type" in
                    "Theme")
                        item_path_in_repo="themes/${item_name}"
                        ;;
                    "Plugin")
                        item_path_in_repo="plugins/${item_name}"
                        ;;
                esac
                
                # Get the list of files that have changed for the selected item.
                local changed_files
                if [ -z "$hash_before" ]; then
                    changed_files=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff-tree --no-commit-id --name-only -r "$hash_after" -- "$item_path_in_repo")
                else
                    changed_files=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff --name-only "$hash_before" "$hash_after" -- "$item_path_in_repo")
                fi

                if [ -z "$changed_files" ]; then
                    "$GUM_CMD" spin --spinner dot --title "No file changes found for '$item_name'." -- sleep 3
                else
                    echo "Showing file changes for '$item_name' between ${hash_before:0:7} and ${hash_after:0:7}."

                    # Loop to allow viewing multiple diffs
                    while true; do
                        local selected_file
                        selected_file=$(echo "$changed_files" | "$GUM_CMD" filter --prompt="? Select a file to view its diff (Press Esc to exit)" --height=20 --indicator="→" --placeholder="")

                        if [ -z "$selected_file" ]; then
                            break
                        fi
                        
                        # Show the diff for the selected file, piped to `less`.
                        if [ -z "$hash_before" ]; then
                             # For the initial commit, just show the file content as it was added.
                            "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" --no-pager show --color=always "$hash_after" -- "$selected_file" | less -RX
                        else
                            "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" --no-pager diff --color=always "$hash_before" "$hash_after" -- "$selected_file" | less -RX
                        fi
                    done
                fi
                ;;
            "Revert Files to 'After' State ("*)
                _revert_item_to_hash "$item_type" "$item_name" "$hash_after" "$wp_content_dir" "$CHECKPOINT_REPO_DIR" "$hash_after"
                ;;
            "Revert Files to 'Before' State ("*)
                 if [ -z "$hash_before" ]; then
                    echo "❌ Cannot revert: 'Before' state does not exist (likely the first checkpoint)." >&2
                    return 1
                 fi
                _revert_item_to_hash "$item_type" "$item_name" "$hash_before" "$wp_content_dir" "$CHECKPOINT_REPO_DIR" "$hash_after"
                ;;
            "Back to item list"|*)
                # Do nothing, the loop will continue to the next iteration.
                continue
                ;;
        esac
    done
}

# ----------------------------------------------------
#  Gets the latest checkpoint hash.
# ----------------------------------------------------
function checkpoint_latest() {
    _ensure_checkpoint_setup
    if ! setup_wp_cli; then return 1; fi
    if [ ! -s "$CHECKPOINT_LIST_FILE" ]; then
        echo "ℹ️ No checkpoints found."
        return
    fi
    
    local php_code_template='
<?php
$list_file = "%s";
if (!file_exists($list_file)) { return; }
$list = json_decode(file_get_contents($list_file));
if (!empty($list) && isset($list[0]->hash)) {
    echo $list[0]->hash;
}
'
    local php_script; php_script=$(printf "$php_code_template" "$CHECKPOINT_LIST_FILE")
    local latest_hash
    latest_hash=$(echo "$php_script" | "$WP_CLI_CMD" eval-file -)

    if [ -z "$latest_hash" ]; then
        echo "ℹ️ No checkpoints found."
    else
        echo "$latest_hash"
    fi
}

# ----------------------------------------------------
#  Cleans up inactive themes.
# ----------------------------------------------------
function clean_themes() {
    # --- Pre-flight checks ---
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo "🔎 Finding the latest default WordPress theme to preserve..."
    latest_default_theme=$("$WP_CLI_CMD" theme search twenty --field=slug --per-page=1 --quiet --skip-plugins --skip-themes)

    if [ $? -ne 0 ] || [ -z "$latest_default_theme" ]; then
      echo "❌ Error: Could not determine the latest default theme. Aborting." >&2
      return 1
    fi
    echo "✅ The latest default theme is '$latest_default_theme'. This will be preserved."
    inactive_themes=($("$WP_CLI_CMD" theme list --status=inactive --field=name --skip-plugins --skip-themes))
    if [ ${#inactive_themes[@]} -eq 0 ]; then
      echo "👍 No inactive themes found to process. All done!"
      return 0
    fi

    echo "🚀 Processing ${#inactive_themes[@]} inactive themes..."
    for theme in "${inactive_themes[@]}"; do
      # Check if the current inactive theme is the one we want to keep
      if [[ "$theme" == "$latest_default_theme" ]]; then
        echo "⚪️ Keeping inactive default theme: $theme"
      else
        echo "❌ Deleting inactive theme: $theme"
        "$WP_CLI_CMD" theme delete "$theme"
      fi
    done

    echo "✨ Cleanup complete."
}

# ----------------------------------------------------
#  Analyzes disk usage using rclone.
# ----------------------------------------------------
function clean_disk() {
    echo "🚀 Launching interactive disk usage analysis..."
    if ! setup_rclone; then
        echo "Aborting analysis: rclone setup failed." >&2
        return 1
    fi
    "$RCLONE_CMD" ncdu .
}
# ----------------------------------------------------
#  Finds large images and converts them to the WebP format.
# ----------------------------------------------------
function convert_to_webp() {
    echo "🚀 Starting WebP Conversion Process 🚀"
    if ! setup_cwebp; then 
        echo "Aborting conversion: cwebp setup failed." >&2 
        return 1
    fi
    if ! command -v identify &> /dev/null; then echo "❌ Error: 'identify' command not found. Please install ImageMagick." >&2; return 1; fi 
    local uploads_dir="wp-content/uploads"; if [ ! -d "$uploads_dir" ]; then echo "❌ Error: Cannot find '$uploads_dir' directory." >&2; return 1; fi 
    local before_size; before_size="$(du -sh "$uploads_dir" | awk '{print $1}')"; 
    echo "Current uploads size: $before_size" 
    local files;
    files=$(find "$uploads_dir" -type f -size +1M \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \)) 
    if [[ -z "$files" ]]; then 
        echo "✅ No images larger than 1MB found to convert."; return 0; 
    fi
    local count;
    count=$(echo "$files" | wc -l); echo "Found $count image(s) over 1MB to process..."; 
    echo "" 
    echo "$files" | while IFS= read -r file; do 
        if [[ "$(identify -format "%m" "$file")" == "WEBP" ]]; then 
            echo "Skipping (already WebP): $file"; continue; 
        fi
        local temp_file="${file}.temp.webp"; local before_file_size; 
        before_file_size=$(ls -lh "$file" | awk '{print $5}')
        "$CWEBP_CMD" -q 80 "$file" -o "$temp_file" > /dev/null 2>&1 
        if [ -s "$temp_file" ]; then 
            mv "$temp_file" "$file"; local after_file_size; 
            after_file_size=$(ls -lh "$file" | awk '{print $5}')
            echo "✅ Converted ($before_file_size -> $after_file_size): $file"
        else
            rm -f "$temp_file"; 
            echo "❌ Failed conversion: $file" 
        fi
    done
    echo ""; 
    local after_size; after_size="$(du -sh "$uploads_dir" | awk '{print $1}')" 
    echo "✅ Bulk conversion complete!"; 
    echo "-----------------------------------------------------"; 
    echo "   Uploads folder size reduced from $before_size to $after_size."; 
    echo "-----------------------------------------------------" 
}
# ----------------------------------------------------
#  Cron Commands
#  Manages scheduled tasks for the _do script.
# ----------------------------------------------------

# ----------------------------------------------------
#  (Helper) PHP script to manage cron events.
# ----------------------------------------------------
function _get_cron_manager_php_script() {
    read -r -d '' php_script <<'PHP'
<?php

$argv = WP_CLI::get_runner()->arguments;
array_shift( $argv );
// This script is a self-contained manager for cron events stored in a WP option.
// It is designed to be called with specific actions and arguments.

// Prevent direct execution.
if (empty($argv) || !isset($argv[1])) {
    return;
}

$action = $argv[1] ?? null;
// The main function for this script is to get the option, unserialize it,
// perform an action, then serialize and save the result.
function get_events() {
    // get_option will return the value of the option, already unserialized.
    // The second argument is the default value if the option does not exist.
    $events = get_option("captaincore_do_cron", []);
    return is_array($events) ? $events : [];
}

function save_events($events) {
    // update_option will create the option if it does not exist.
    // The third argument 'no' sets autoload to false.
    update_option( "captaincore_do_cron", $events, 'no');
}

// --- Action Router ---

if ($action === 'list_all') {
    $events = get_events();
    if (empty($events)) {
        return;
    }
    // Sort events by the next_run timestamp to show the soonest first.
    usort($events, function($a, $b) {
        return ($a['next_run'] ?? 0) <=> ($b['next_run'] ?? 0);
    });

    // MODIFICATION: Get the WordPress timezone once before the loop.
    $wp_timezone = wp_timezone();

    foreach ($events as $event) {
        
        // MODIFICATION: Convert the stored UTC timestamp to the WP timezone for display.
        $next_run_formatted = 'N/A';
        if (isset($event['next_run'])) {
            // Create a DateTime object from the UTC timestamp
            $next_run_dt = new DateTime("@" . $event['next_run']);
            // Set the object's timezone to the WordPress configured timezone
            $next_run_dt->setTimezone($wp_timezone);
            // Format for output
            $next_run_formatted = $next_run_dt->format('Y-m-d H:i:s T');
        }
        
        // Output in CSV format for gum table
        echo implode(',', [
            $event['id'] ?? 'N/A',
            '"' . ($event['command'] ?? 'N/A') . '"', // Quote command in case it has spaces
            $next_run_formatted,
            $event['frequency'] ?? 'N/A'
        ]) . "\n";
    }
}

elseif ($action === 'list_due') {
    $now = time();
    $due_events = [];
    foreach (get_events() as $event) {
        if (isset($event['next_run']) && $event['next_run'] <= $now) {
            $due_events[] = $event;
        }
    }
    echo json_encode($due_events);
}

elseif ($action === 'add') {
    $id = uniqid('event_');
    $command = $argv[2] ?? null; 
    $next_run_str = $argv[3] ?? null;
    $frequency = $argv[4] ?? null; 

    if (!$command || !$next_run_str || !$frequency) {
        error_log('Error: Missing arguments for add action.');
        return;
    }

    // --- Frequency Translation ---
    $freq_lower = strtolower($frequency); 
    if ($freq_lower === 'weekly') {
        $frequency = '1 week';
    } elseif ($freq_lower === 'daily') {
        $frequency = '1 day';
    } elseif ($freq_lower === 'monthly') {
        $frequency = '1 month';
    } elseif ($freq_lower === 'hourly') {
        $frequency = '1 hour';
    }
    // --- End Translation ---

    try {
        // Use the WordPress configured timezone for parsing the date string.
        $wp_timezone = wp_timezone();
        $next_run_dt = new DateTime($next_run_str, $wp_timezone);
        $next_run_timestamp = $next_run_dt->getTimestamp();
    } catch (Exception $e) {
        error_log('Error: Invalid date/time string for next_run: ' . $e->getMessage());
        return;
    }
    
    $events = get_events();
    $events[] = [ 
        'id'        => $id,
        'command'   => $command,
        'next_run'  => $next_run_timestamp,
        'frequency' => $frequency,
    ];
    save_events($events);
    echo "✅ Event '$id' added. Input '{$next_run_str}' interpreted using WordPress timezone ({$wp_timezone->getName()}). Next run: " . date('Y-m-d H:i:s T', $next_run_timestamp) . "\n";
}

elseif ($action === 'delete') {
    $id_to_delete = $argv[2] ?? null;
    if (!$id_to_delete) {
        error_log('Error: No ID provided for delete action.');
        return;
    }

    $events = get_events();
    $updated_events = [];
    $found = false;
    foreach ($events as $event) {
        if (isset($event['id']) && $event['id'] === $id_to_delete) {
            $found = true;
        } else {
            $updated_events[] = $event;
        }
    }

    if ($found) {
        save_events($updated_events);
        echo "✅ Event '$id_to_delete' deleted successfully.\n";
    } else {
        echo "❌ Error: Event with ID '$id_to_delete' not found.\n";
    }
}

elseif ($action === 'update_next_run') {
    $id = $argv[2] ?? null;
    if (!$id) {
        error_log('Error: No ID provided to update_next_run.'); 
        return;
    }

    $events = get_events(); 
    $found = false;
    foreach ($events as &$event) {
        if (isset($event['id']) && $event['id'] === $id) {
            try {
                $last_run_ts = $event['next_run'] ??
                    time();
                $next_run_dt = new DateTime("@{$last_run_ts}", new DateTimeZone('UTC'));
                
                do {
                    $next_run_dt->modify('+ ' . $event['frequency']);
                } while ($next_run_dt->getTimestamp() <= time());

                $event['next_run'] = $next_run_dt->getTimestamp(); 
                $found = true;
                break;
            } catch (Exception $e) {
                 error_log('Error: Invalid frequency string "' . ($event['frequency'] ?? '') . '": ' . $e->getMessage());
                 return;
            }
        }
    }

    if ($found) {
        save_events($events);
    }
}
PHP
    echo "$php_script"
}

# ----------------------------------------------------
#  Configures the global cron runner by installing the latest script.
# ----------------------------------------------------
function cron_enable() {
    echo "Attempting to configure cron runner..."

    if ! setup_wp_cli || ! "$WP_CLI_CMD" core is-installed --quiet; then
        echo "❌ Error: This command must be run from within a WordPress directory." >&2
        return 1
    fi
    if ! command -v realpath &> /dev/null || ! command -v md5sum &> /dev/null; then
        echo "❌ Error: 'realpath' and 'md5sum' commands are required." >&2
        return 1
    fi

    # Determine the absolute path of the WordPress installation
    local wp_path
    wp_path=$(realpath ".")
    if [[ ! -f "$wp_path/wp-load.php" ]]; then
        echo "❌ Error: Could not confirm WordPress root at '$wp_path'." >&2
        return 1
    fi

    local private_dir
    if ! private_dir=$(_get_private_dir); then return 1; fi
    local script_path="$private_dir/_do.sh"

    echo "ℹ️  Downloading the latest version of the _do script..."
    if ! command -v curl &> /dev/null; then
         echo "❌ Error: 'curl' is required to download the script." >&2; return 1;
    fi
    if ! curl -sL "https://captaincore.io/do" -o "$script_path"; then
        echo "❌ Error: Failed to download the _do script." >&2; return 1;
    fi
    chmod +x "$script_path"
    echo "✅ Script installed/updated at: $script_path"

    # Make the marker unique to the path to allow multiple cron jobs
    local path_hash
    path_hash=$(echo "$wp_path" | md5sum | cut -d' ' -f1)
    local cron_marker="#_DO_CRON_RUNNER_$path_hash"
    local cron_command="bash \"$script_path\" cron run --path=\"$wp_path\""
    local cron_job="*/10 * * * * $cron_command $cron_marker"

    # Atomically update the crontab
    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null | grep -v "$cron_marker")
    (echo "$current_crontab"; echo "$cron_job") | crontab -

    if [ $? -eq 0 ]; then
        local site_url
        site_url=$("$WP_CLI_CMD" option get home --skip-plugins --skip-themes 2>/dev/null)
        echo "✅ Cron runner enabled for site: $site_url ($wp_path)"
    else
        echo "❌ Error: Could not modify crontab. Please check your permissions." >&2
        return 1
    fi

    echo "Current crontab:"
    crontab -l
}

# ----------------------------------------------------
#  Runs the cron process, executing any due events.
# ----------------------------------------------------
function cron_run() {
    # If a path is provided, change to that directory first.
    if [[ -n "$path_flag" ]]; then
        if [ -d "$path_flag" ]; then
            cd "$path_flag" || { echo "[$(date)] Cron Error: Could not change directory to '$path_flag'." >> /tmp/_do_cron.log; return 1; }
        else
            echo "[$(date)] Cron Error: Provided path '$path_flag' does not exist." >> /tmp/_do_cron.log;
            return 1
        fi
    fi

    # Call the setup function to ensure the wp command path is known.
    if ! setup_wp_cli; then
        echo "[$(date)] Cron Error: WP-CLI setup failed." >> /tmp/_do_cron.log
        return 1
    fi

    # Check if this is a WordPress installation using the full command path.
    if ! "$WP_CLI_CMD" core is-installed --quiet; then
        return 1
    fi

    local php_script;
    php_script=$(_get_cron_manager_php_script)

    local due_events_json;
    # Use the full command path for all wp-cli calls.
    due_events_json=$(echo "$php_script" | "$WP_CLI_CMD" eval-file - 'list_due' 2>&1)
    if [ $? -ne 0 ];
    then
        echo "[$(date)] Cron run failed: $due_events_json" >> /tmp/_do_cron.log
        return 1
    fi

    if [ -z "$due_events_json" ] || [[ "$due_events_json" == "[]" ]];
    then
        return 0
    fi

    local php_parser='
$json = file_get_contents("php://stdin");
$events = json_decode($json, true);
if (is_array($events)) {
    foreach($events as $event) {
        echo $event["id"] . "|" . $event["command"] . "\n";
    }
}
'
    local due_events_list;
    due_events_list=$(echo "$due_events_json" | php -r "$php_parser")

    if [ -z "$due_events_list" ];
    then
        return 0
    fi

    echo "Found due events, processing..."
    while IFS='|' read -r id command; do
        if [ -z "$id" ] || [ -z "$command" ]; then
            continue
        fi
        echo "-> Running event '$id': _do $command"
        local script_path
        script_path=$(realpath "$0")
        bash "$script_path" $command
        echo "-> Updating next run time for event '$id'"
        # Use the full command path here as well.
        echo "$php_script" | "$WP_CLI_CMD" eval-file - 'update_next_run' "$id"
    done <<< "$due_events_list"
    echo "Cron run complete."
}

# ----------------------------------------------------
#  Adds a new command to the cron schedule.
# ----------------------------------------------------
function cron_add() {
    local command="$1"
    local next_run="$2"
    local frequency="$3"

    if [ -z "$command" ] || [ -z "$next_run" ] || [ -z "$frequency" ]; then
        echo "❌ Error: Missing arguments." >&2
        show_command_help "cron"
        return 1
    fi

    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: Not in a WordPress installation." >&2; return 1; fi

    echo "Adding new cron event..."
    local php_script; php_script=$(_get_cron_manager_php_script)

    # Capture both stdout and stderr to a variable
    local output; output=$(echo "$php_script" | "$WP_CLI_CMD" eval-file - "add" "$command" "$next_run" "$frequency" 2>&1)

    # Check the exit code of the wp-cli command
    if [ $? -ne 0 ]; then
        echo "❌ Error: The wp-cli command failed to execute."
        echo "   Output:"
        # Indent the output for readability
        echo "$output" | sed 's/^/   /'
    else
        # Print the success message from the PHP script
        echo "$output"
    fi
}

# ----------------------------------------------------
#  Deletes a scheduled cron event by its ID.
# ----------------------------------------------------
function cron_delete() {
    local event_id="$1"

    if [ -z "$event_id" ]; then
        echo "❌ Error: No event ID provided." >&2
        show_command_help "cron"
        return 1
    fi

    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: Not in a WordPress installation." >&2; return 1; fi

    echo "Attempting to delete event '$event_id'..."
    local php_script
    php_script=$(_get_cron_manager_php_script)

    # Capture and display output from the PHP script
    local output
    output=$(echo "$php_script" | "$WP_CLI_CMD" eval-file - "delete" "$event_id" 2>&1)

    # The PHP script now prints success or error, so just display it.
    echo "$output"
}

# ----------------------------------------------------
#  Lists all scheduled cron events in a table.
# ----------------------------------------------------
function cron_list() {
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: Not in a WordPress installation." >&2; return 1; fi
    if ! setup_gum; then return 1; fi

    echo "🔎 Fetching scheduled events..."

    local php_script; php_script=$(_get_cron_manager_php_script)

    # Capture stdout and stderr
    local events_csv; events_csv=$(echo "$php_script" | "$WP_CLI_CMD" eval-file - 'list_all' 2>&1)

    # Check exit code
    if [ $? -ne 0 ]; then
        echo "❌ Error: The wp-cli command failed while listing events."
        echo "   Output:"
        echo "$events_csv" | sed 's/^/   /'
        return 1
    fi

    if [ -z "$events_csv" ]; then
        echo "ℹ️ No scheduled cron events found."
        return 0
    fi

    local table_header="ID,Command,Next Run,Frequency"

    # Prepend the header and pipe to gum table for a formatted view
    (echo "$table_header"; echo "$events_csv") | "$GUM_CMD" table --print --separator ","
}
# ----------------------------------------------------
#  Performs a WordPress database-only backup to a secure, private directory.
# ----------------------------------------------------
function db_backup() {
    echo "Starting database-only backup..."
    local home_directory; home_directory=$(pwd);
    local private_directory
    if ! private_directory=$(_get_private_dir); then
        return 1
    fi
    if ! setup_wp_cli; then echo "Error: wp-cli is not installed." >&2; return 1; fi
    local database_name; database_name=$("$WP_CLI_CMD" config get DB_NAME --skip-plugins --skip-themes --quiet); local database_username; database_username=$("$WP_CLI_CMD" config get DB_USER --skip-plugins --skip-themes --quiet); local database_password; database_password=$("$WP_CLI_CMD" config get DB_PASSWORD --skip-plugins --skip-themes --quiet);
    local dump_command; if command -v mariadb-dump &> /dev/null; then dump_command="mariadb-dump"; elif command -v mysqldump &> /dev/null; then dump_command="mysqldump"; else echo "Error: Neither mariadb-dump nor mysqldump could be found." >&2; return 1; fi
    echo "Using ${dump_command} for the backup."
    local backup_file="${private_directory}/database-backup-$(date +"%Y-%m-%d").sql"
    if ! "${dump_command}" -u"${database_username}" -p"${database_password}" --max_allowed_packet=512M --default-character-set=utf8mb4 --add-drop-table --single-transaction --quick --lock-tables=false "${database_name}" > "${backup_file}"; then echo "Error: Database dump failed." >&2; rm -f "${backup_file}"; return 1; fi
    chmod 600 "${backup_file}"; echo "✅ Database backup complete!"; echo "   Backup file located at: ${backup_file}"
}

# ----------------------------------------------------
#  Checks the size and contents of autoloaded options in the WordPress database.
# ----------------------------------------------------
function db_check_autoload() {
    echo "Checking autoloaded options in the database..."
    # Ensure the 'gum' utility is available for formatting
    if ! setup_gum; then
        echo "Aborting check: gum setup failed." >&2
        return 1
    fi
    if ! setup_wp_cli; then echo "Error: wp-cli is not installed." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo
    echo "--- Total Autoloaded Size ---"
    "$WP_CLI_CMD" db query "SELECT ROUND(SUM(LENGTH(option_value))/1024/1024, 2) as 'Autoload MB', COUNT(*) as 'Count' FROM $($WP_CLI_CMD db prefix)options WHERE autoload='yes';" | "$GUM_CMD" table --print --separator $'\t'
    echo
    echo "--- Top 25 Autoloaded Options & Totals ---"
    "$WP_CLI_CMD" db query "SELECT option_name, round(length(option_value) / 1024 / 1024, 2) as 'Size (MB)' FROM $($WP_CLI_CMD db prefix)options WHERE autoload='yes' ORDER BY length(option_value) DESC LIMIT 25" | "$GUM_CMD" table --print --separator $'\t'
    echo
    echo "✅ Autoload check complete."
}

# ----------------------------------------------------
#  Optimizes the database by converting tables to InnoDB, reporting large tables, and cleaning transients.
# ----------------------------------------------------
function db_optimize() {
    # --- Pre-flight checks ---
    if ! setup_gum; then
        echo "Aborting optimization: gum setup failed." >&2
        return 1
    fi
    if ! setup_wp_cli; then echo "Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo "🚀 Starting database optimization..."
    echo ""

    # --- Step 1: Convert MyISAM to InnoDB ---
    echo "--- Step 1: Checking for MyISAM tables to convert to InnoDB ---"
    local myisam_tables
    myisam_tables=$("$WP_CLI_CMD" db query "SELECT TABLE_NAME FROM information_schema.TABLES WHERE ENGINE = 'MyISAM' AND TABLE_SCHEMA = DATABASE()" --skip-column-names)

    if [[ -z "$myisam_tables" ]]; then
        echo "✅ All tables are already using the InnoDB engine. No conversion needed."
    else
        echo "Found the following MyISAM tables to convert:"
        # Use gum to format the list of tables
        "$WP_CLI_CMD" db query "SELECT TABLE_NAME AS 'MyISAM Tables' FROM information_schema.TABLES WHERE ENGINE = 'MyISAM' AND TABLE_SCHEMA = DATABASE()" | "$GUM_CMD" table --print --separator $'\t'

        echo "Converting tables to InnoDB..."
        "$WP_CLI_CMD" db query "SELECT CONCAT('ALTER TABLE \`', TABLE_NAME, '\` ENGINE=InnoDB;') FROM information_schema.TABLES WHERE ENGINE = 'MyISAM' AND TABLE_SCHEMA = DATABASE()" --skip-column-names | "$WP_CLI_CMD" db query

        if [ $? -eq 0 ]; then
            echo "✅ Successfully converted tables to InnoDB."
        else
            echo "❌ An error occurred during the conversion."
            return 1
        fi
    fi

    # --- Step 2: List Top 10 Largest Tables ---
    echo ""
    echo "--- Step 2: Top 10 Tables Larger Than 1MB ---"
    # Use gum to format the table of large tables
    "$WP_CLI_CMD" db query "
      SELECT
        TABLE_NAME,
        CASE
          WHEN (data_length + index_length) >= 1073741824 THEN CONCAT(ROUND((data_length + index_length) / 1073741824, 2), ' GB')
          WHEN (data_length + index_length) >= 1048576 THEN CONCAT(ROUND((data_length + index_length) / 1048576, 2), ' MB')
          WHEN (data_length + index_length) >= 1024 THEN CONCAT(ROUND((data_length + index_length) / 1024, 2), ' KB')
          ELSE CONCAT((data_length + index_length), ' B')
        END AS Size
      FROM
        information_schema.TABLES
     WHERE
        TABLE_SCHEMA = DATABASE() AND (data_length + index_length) > 1048576
      ORDER BY
        (data_length + index_length) DESC
      LIMIT 10;
    " | "$GUM_CMD" table --print --separator $'\t'

    # --- Step 3: Delete Expired Transients ---
    echo ""
    echo "--- Step 3: Deleting Expired Transients ---"
    "$WP_CLI_CMD" transient delete --expired

    echo ""
    echo "✅ Database optimization complete."
}
# ----------------------------------------------------
#  Dumps the content of files matching a pattern into a single text file.
# ----------------------------------------------------
function run_dump() {
    # --- 1. Validate Input ---
    local INPUT_PATTERN="$1"
    shift
    local exclude_patterns=("$@")

    if [ -z "$INPUT_PATTERN" ];
    then
        echo "Error: No input pattern provided." >&2
        echo "Usage: _do dump \"<path/to/folder/*.extension>\" [-x <exclude_pattern>]..." >&2
        return 1
    fi

    # --- 2. Determine Paths and Names ---
    local SEARCH_DIR
    SEARCH_DIR=$(dirname "$INPUT_PATTERN")
    local FILE_PATTERN
    FILE_PATTERN=$(basename "$INPUT_PATTERN")

    local OUTPUT_BASENAME
    OUTPUT_BASENAME=$(basename "$SEARCH_DIR")
    if [ "$OUTPUT_BASENAME" == "." ]; then
        OUTPUT_BASENAME="dump"
    fi
    local OUTPUT_FILE="${OUTPUT_BASENAME}.txt"

    # --- 3. Process Files ---
    > "$OUTPUT_FILE"

    echo "Searching in '$SEARCH_DIR' for files matching '$FILE_PATTERN'..."
    if [ ${#exclude_patterns[@]} -gt 0 ]; then
        echo "Excluding user-defined patterns: ${exclude_patterns[*]}"
    fi
    echo "Automatically excluding: .git directory contents"

    # Dynamically build the find command
    local find_cmd=("find" "$SEARCH_DIR" "-type" "f" "-name" "$FILE_PATTERN")

    # Add user-defined exclusions
    for pattern in "${exclude_patterns[@]}"; do
        if [[ "$pattern" == */ ]]; then
            # For directories (pattern ends with /), use -path
            local dir_pattern=${pattern%/} # remove trailing slash
            find_cmd+=("-not" "-path" "*/$dir_pattern/*")
        else
            # For files, use -name
            find_cmd+=("-not" "-name" "$pattern")
        fi
    done

    # Add automatic exclusions for the output file and .git directory
    find_cmd+=("-not" "-name" "$OUTPUT_FILE")
    find_cmd+=("-not" "-path" "*/.git/*")

    # Execute the find command
    "${find_cmd[@]}" -print0 | while IFS= read -r -d '' file; do
        echo "--- File: $file ---" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
        echo -e "\n" >> "$OUTPUT_FILE"
    done

    # --- 4. Final Report ---
    if [ ! -s "$OUTPUT_FILE" ]; then
        echo "Warning: No files found matching the pattern. No dump file created."
        rm "$OUTPUT_FILE"
        return 0
    fi

    local FILE_SIZE
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1 | xargs)

    echo "Generated $OUTPUT_FILE ($FILE_SIZE)"
}
# ----------------------------------------------------
#  Migrates a site from a backup URL or local file.
#  Arguments:
#    $1 - The URL/path for the backup file.
#    $2 - A flag indicating whether to update URLs.
# ----------------------------------------------------
function migrate_site() {
    local backup_url="$1"
    local update_urls_flag="$2"

    echo "🚀 Starting Site Migration 🚀"

    # --- Pre-flight Checks ---
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! command -v wget &>/dev/null; then echo "❌ Error: wget not found." >&2; return 1; fi
    if ! command -v unzip &>/dev/null; then echo "❌ Error: unzip not found." >&2; return 1; fi
    if ! command -v tar &>/dev/null; then echo "❌ Error: tar not found." >&2; return 1; fi

    local home_directory; home_directory=$(pwd)
    local wp_home; wp_home=$( "$WP_CLI_CMD" option get home --skip-themes --skip-plugins )
    if [[ "$wp_home" != "http"* ]]; then
        echo "❌ Error: WordPress not found in current directory. Migration cancelled." >&2
        return 1
    fi
    
    # --- Find Private Directory ---
    local private_dir
    if ! private_dir=$(_get_private_dir); then
        # Error message is handled by the helper function.
        echo "❌ Error: Can't locate a suitable private folder. Migration cancelled." >&2 
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
      wget -q --show-progress --no-check-certificate --progress=bar:force:noscroll -O "backup_file" "$backup_url"
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
    # Migrate mu-plugins if found
    if [ -d "$wordpresspath/wp-content/mu-plugins" ]; then
        echo "Moving: mu-plugins"
        cd "$wordpresspath/wp-content/mu-plugins"
        for working in *; do
            echo "$working"
            if [ -f "$home_directory/wp-content/mu-plugins/$working" ]; then
            rm "$home_directory/wp-content/mu-plugins/$working"
            fi
            if [ -d "$home_directory/wp-content/mu-plugins/$working" ]; then
            rm -rf "$home_directory/wp-content/mu-plugins/$working"
            fi
            mv "$working" "$home_directory/wp-content/mu-plugins/"
        done
        cd "${private}/restore_${timedate}"
    fi

    # Migrate blogs.dir if found
    if [ -d "$wordpresspath/blogs.dir" ]; then
        echo "Moving: blogs.dir"
        rm -rf "$home_directory/wp-content/blogs.dir"
        mv "$wordpresspath/blogs.dir" "$home_directory/wp-content/"
    fi

    # Migrate gallery if found
    if [ -d "$wordpresspath/gallery" ]; then
        echo "Moving: gallery"
        rm -rf "$home_directory/wp-content/gallery"
        mv "$wordpresspath/gallery" "$home_directory/wp-content/"
    fi

    # Migrate ngg if found
    if [ -d "$wordpresspath/ngg" ]; then
        echo "Moving: ngg"
        rm -rf "$home_directory/wp-content/ngg"
        mv "$wordpresspath/ngg" "$home_directory/wp-content/"
    fi

    # Migrate uploads if found
    if [ -d "$wordpresspath/uploads" ]; then
        echo "Moving: uploads"
        rm -rf "$home_directory/wp-content/uploads"
        mv "$wordpresspath/uploads" "$home_directory/wp-content/"
    fi

    # Migrate themes if found
    for d in $wordpresspath/themes/*/; do
        echo "Moving: themes/$( basename "$d" )"
        rm -rf "$home_directory/wp-content/themes/$( basename "$d" )"
        mv "$d" "$home_directory/wp-content/themes/"
    done

    # Migrate plugins if found
    for d in $wordpresspath/plugins/*/; do
        echo "Moving: plugins/$( basename "$d" )"
        rm -rf "$home_directory/wp-content/plugins/$( basename "$d" )"
        mv "$d" "$home_directory/wp-content/plugins/"
    done
    
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
        local search_privacy; search_privacy=$( "$WP_CLI_CMD" option get blog_public --skip-plugins --skip-themes )
        "$WP_CLI_CMD" db reset --yes --skip-plugins --skip-themes
        "$WP_CLI_CMD" db import "$database" --skip-plugins --skip-themes
        "$WP_CLI_CMD" cache flush --skip-plugins --skip-themes
        "$WP_CLI_CMD" option update blog_public "$search_privacy" --skip-plugins --skip-themes

        #  URL updates
        local wp_home_imported; wp_home_imported=$( "$WP_CLI_CMD" option get home --skip-plugins --skip-themes )
        if [[ "$update_urls_flag" == "true" && "$wp_home_imported" != "$wp_home" ]]; then
            echo "Updating URLs from $wp_home_imported to $wp_home..."
            "$WP_CLI_CMD" search-replace "$wp_home_imported" "$wp_home" --all-tables --report-changed-only --skip-plugins --skip-themes
        fi
    fi

    # --- Cleanup & Final Steps ---
    echo "Performing cleanup and final optimizations..."
    local plugins_to_remove=( backupbuddy wordfence w3-total-cache wp-super-cache ewww-image-optimizer )
    for plugin in "${plugins_to_remove[@]}"; do
        if "$WP_CLI_CMD" plugin is-installed "$plugin" --skip-plugins --skip-themes &>/dev/null; then
            echo "Removing plugin: $plugin"
            "$WP_CLI_CMD" plugin delete "$plugin" --skip-plugins --skip-themes
        fi
    done

    #  Convert tables to InnoDB
    local alter_queries; alter_queries=$("$WP_CLI_CMD" db query "SELECT CONCAT('ALTER TABLE ', TABLE_SCHEMA,'.', TABLE_NAME, ' ENGINE=InnoDB;') FROM information_schema.TABLES WHERE ENGINE = 'MyISAM' AND TABLE_SCHEMA=DATABASE()" --skip-column-names --skip-plugins --skip-themes)
    if [[ -n "$alter_queries" ]]; then
        echo "Converting MyISAM tables to InnoDB..."
        echo "$alter_queries" | "$WP_CLI_CMD" db query --skip-plugins --skip-themes
    fi

    "$WP_CLI_CMD" rewrite flush --skip-plugins --skip-themes
    if "$WP_CLI_CMD" plugin is-active woocommerce --skip-plugins --skip-themes &>/dev/null; then
        "$WP_CLI_CMD" wc tool run regenerate_product_attributes_lookup_table --user=1 --skip-plugins --skip-themes
    fi
    
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    
    #  Clean up restore directory
    rm -rf "$restore_dir"
    
    echo "✅ Site migration complete!"
}
# ----------------------------------------------------
#  Monitors server access logs in real-time.
# ----------------------------------------------------
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
    local initial_lines_to_process=1 # How many lines to look back initially (only used with --now)
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

# ----------------------------------------------------
#  Monitors access and error logs for HTTP 500 and PHP fatal errors.
# ----------------------------------------------------
function monitor_errors() {
    if ! setup_gum; then
        echo "Aborting monitor: gum setup failed." >&2
        return 1
    fi

    # --- Find Log Files ---
    local access_log_path=""
    if [ -f "$HOME/logs/access.log" ]; then
        access_log_path="$HOME/logs/access.log"
    elif [ -f "logs/access.log" ]; then
        access_log_path="logs/access.log"
    elif [ -f "../logs/access.log" ]; then
        access_log_path="../logs/access.log"
    fi

    local error_log_path=""
    if [ -f "$HOME/logs/error.log" ]; then
        error_log_path="$HOME/logs/error.log"
    elif [ -f "logs/error.log" ]; then
        error_log_path="logs/error.log"
    elif [ -f "../logs/error.log" ]; then
        error_log_path="../logs/error.log"
    fi
    
    local files_to_monitor=()
    if [ -n "$access_log_path" ]; then
        echo "Checking for 500 errors in: $access_log_path" >&2
        files_to_monitor+=("$access_log_path")
    fi
    if [ -n "$error_log_path" ]; then
        echo "Checking for Fatal errors in: $error_log_path" >&2
        files_to_monitor+=("$error_log_path")
    fi

    if [ ${#files_to_monitor[@]} -eq 0 ]; then
        echo "No log files found in standard locations (~/logs/, logs/, ../logs/)" >&2
        return 1
    fi
    
    echo "Streaming errors from specified logs..." >&2
    echo "(Press Ctrl+C to stop)" >&2

    # --- Real-time Stream using `tail -F` ---
    tail -q -n 0 -F "${files_to_monitor[@]}" | while read -r line; do
        # Skip empty lines that might come from the pipe
        if [ -z "$line" ]; then
            continue
        fi

        # Check for the most specific term first ("Fatal") before less specific terms.
        if [[ "$line" == *"Fatal"* ]]; then
            "$GUM_CMD" log --level error "$line"
        elif [[ "$line" == *" 500 "* ]]; then
            "$GUM_CMD" log --level error "$line"
        fi
    done
}

# ----------------------------------------------------
#  Tails the access log for a clean, real-time view.
# ----------------------------------------------------
function monitor_access_log() {
    if ! setup_gum; then
        echo "Aborting monitor: gum setup failed." >&2
        return 1
    fi

    # --- Find Log File ---
    local access_log_path=""
    if [ -f "$HOME/logs/access.log" ]; then
        access_log_path="$HOME/logs/access.log"
    elif [ -f "logs/access.log" ]; then
        access_log_path="logs/access.log"
    elif [ -f "../logs/access.log" ]; then
        access_log_path="../logs/access.log"
    fi

    if [ -z "$access_log_path" ]; then
        echo "No access.log file found in standard locations (~/logs/, logs/, ../logs/)" >&2
        return 1
    fi

    echo "Streaming log: $access_log_path" >&2
    echo "(Press Ctrl+C to stop)" >&2

    # --- Real-time Stream using `tail -F` ---
    tail -n 50 -F "$access_log_path" | while read -r line; do
        # Skip empty lines
        if [ -z "$line" ]; then
            continue
        fi
        "$GUM_CMD" log --level info "$line"
    done
}

# ----------------------------------------------------
#  Tails the error log for a clean, real-time view.
# ----------------------------------------------------
function monitor_error_log() {
    if ! setup_gum; then
        echo "Aborting monitor: gum setup failed." >&2
        return 1
    fi

    # --- Find Log File ---
    local error_log_path=""
    if [ -f "$HOME/logs/error.log" ]; then
        error_log_path="$HOME/logs/error.log"
    elif [ -f "logs/error.log" ]; then
        error_log_path="logs/error.log"
    elif [ -f "../logs/error.log" ]; then
        error_log_path="../logs/error.log"
    fi

    if [ -z "$error_log_path" ]; then
        echo "No error.log file found in standard locations (~/logs/, logs/, ../logs/)" >&2
        return 1
    fi

    echo "Streaming log: $error_log_path" >&2
    echo "(Press Ctrl+C to stop)" >&2

    # --- Real-time Stream using `tail -F` ---
    tail -n 50 -F "$error_log_path" | while read -r line; do
        # Skip empty lines
        if [ -z "$line" ]; then
            continue
        fi
        "$GUM_CMD" log --level error "$line"
    done
}
# ----------------------------------------------------
#  Finds outdated or invalid PHP opening tags in PHP files.
# ----------------------------------------------------
function find_outdated_php_tags() {
    local search_dir="${1:-wp-content/}"

    #  Ensure the search directory ends with a slash for consistency
    if [[ "${search_dir: -1}" != "/" ]]; then
        search_dir+="/"
    fi

    if [ ! -d "$search_dir" ]; then
        echo "❌ Error: Directory '$search_dir' not found." >&2
        return 1
    fi

    echo "🚀 Searching for outdated PHP tags in '${search_dir}'..."
    echo "This can take a moment for large directories."
    echo

    #  Use a more precise regex to find '<?' that is NOT followed by 'php', 'xml', or '='.
    #  This avoids false positives for XML declarations and valid short echo tags.
    #  The '-i' flag makes the 'php' and 'xml' check case-insensitive.
    #  The '-P' flag enables Perl-compatible regular expressions (PCRE) for the negative lookahead.
    local initial_results
    initial_results=$(grep --include="*.php" --line-number --recursive -iP '<\?(?!php|xml|=)' "$search_dir" 2>/dev/null)

    # Filter out common false positives from comments and string functions.
    # This is not a perfect solution, but it significantly reduces noise.
    # It removes lines starting with *, lines containing // or # comments,
    # and lines where '<?' is found inside quotes or in common string functions.
    local found_tags
    found_tags=$(echo "$initial_results" \
        | grep -v -F -e "strpos(" -e "str_replace(" \
        | grep -v -E "^\s*\*|\s*//|\s*#|'\<\?'|\"\<\?\"" \
    )

    if [ -z "$found_tags" ]; then
        echo "✅ No outdated PHP tags were found (after filtering common false positives)."
    else
        echo "⚠️ Found potentially outdated PHP tags in the following files:"
        echo "-----------------------------------------------------"
        #  The output from grep is already well-formatted.
        echo "$found_tags"
        echo "-----------------------------------------------------"
        #  Use single quotes instead of backticks to prevent command execution.
        echo "Recommendation: Replace all short tags like '<?' with the full '<?php' tag."
    fi
}
# ----------------------------------------------------
#  Resets file and folder permissions to common defaults (755 for dirs, 644 for files).
# ----------------------------------------------------
function reset_permissions() {
    echo "Resetting file and folder permissions to defaults"
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    echo "✅ Permissions have been reset."
}
# ----------------------------------------------------
#  Resets the WordPress installation to a clean, default state.
# ----------------------------------------------------
function reset_site() {
    local admin_user="$1"
    local admin_email="$2"

    # --- Pre-flight Checks ---
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: This does not appear to be a WordPress installation." >&2; return 1; fi
    if ! command -v wget &>/dev/null; then echo "❌ Error: wget not found." >&2; return 1; fi
    if ! command -v unzip &>/dev/null; then echo "❌ Error: unzip not found." >&2; return 1; fi
    if ! command -v curl &>/dev/null; then echo "❌ Error: curl not found." >&2; return 1; fi

    echo "🚀 Starting WordPress Site Reset 🚀"
    echo "This is a destructive operation."
    # A 3-second countdown to allow the user to abort (Ctrl+C)
    for i in {3..1}; do echo -n "Continuing in $i... "; sleep 1; done; echo

    # --- Gather Info Before Reset ---
    local url; url=$( "$WP_CLI_CMD" option get home --skip-plugins --skip-themes )
    local title; title=$( "$WP_CLI_CMD" option get blogname --skip-plugins --skip-themes )

    # If admin_email is not supplied, get it from the current installation
    if [ -z "$admin_email" ]; then
        admin_email=$("$WP_CLI_CMD" option get admin_email --skip-plugins --skip-themes)
        echo "ℹ️ Admin email not provided. Using existing email: $admin_email"
    fi

    # --- Perform Reset ---
    echo "Step 1/9: Resetting the database..."
    "$WP_CLI_CMD" db reset --yes --skip-plugins --skip-themes

    echo "Step 2/9: Downloading latest WordPress core..."
    "$WP_CLI_CMD" core download --force --skip-plugins --skip-themes

    echo "Step 3/9: Installing WordPress core..."
    "$WP_CLI_CMD" core install --url="$url" --title="$title" --admin_user="$admin_user" --admin_email="$admin_email" --skip-plugins --skip-themes

    echo "Step 4/9: Deleting all other themes..."
    "$WP_CLI_CMD" theme delete --all --force --skip-plugins --skip-themes

    echo "Step 5/9: Deleting all plugins..."
    "$WP_CLI_CMD" plugin delete --all --skip-plugins --skip-themes

     echo "Step 6/9: Finding the latest default WordPress theme..."
    latest_default_theme=$("$WP_CLI_CMD" theme search twenty --field=slug --per-page=1 --quiet --skip-plugins --skip-themes)

    if [ $? -ne 0 ] || [ -z "$latest_default_theme" ]; then
      echo "❌ Error: Could not determine the latest default theme. Aborting reset." >&2
      return 1
    fi
    echo "✅ Latest default theme is '$latest_default_theme'."
    echo "Step 7/9: Installing and activating '$latest_default_theme'..."
    "$WP_CLI_CMD" theme install "$latest_default_theme" --force --activate --skip-plugins --skip-themes

    echo "Step 8/9: Cleaning up directories (mu-plugins, uploads)..."
    rm -rf wp-content/mu-plugins/
    mkdir -p wp-content/mu-plugins/
    rm -rf wp-content/uploads/
    mkdir -p wp-content/uploads/

    echo "Step 9/9: Installing helper plugins (Kinsta MU, CaptainCore Helper)..."
    if wget -q https://kinsta.com/kinsta-tools/kinsta-mu-plugins.zip; then
        unzip -q kinsta-mu-plugins.zip -d wp-content/mu-plugins/
        rm kinsta-mu-plugins.zip
        echo "✅ Kinsta MU plugin installed."
    else
        echo "⚠️ Warning: Could not download Kinsta MU plugin."
    fi

    if curl -sSL https://run.captaincore.io/deploy-helper | bash -s; then
        echo "✅ CaptainCore Helper deployed."
    else
        echo "⚠️ Warning: Could not deploy CaptainCore Helper."
    fi

    echo ""
    echo "✅ WordPress reset complete!"
    echo "   URL: $url"
    echo "   Admin User: $admin_user"
}
# ----------------------------------------------------
#  Identifies plugins that may be slowing down WP-CLI command execution.
# ----------------------------------------------------
function identify_slow_plugins() {
    _get_wp_execution_time() { local output; output=$("$WP_CLI_CMD" "$@" --debug 2>&1); echo "$output" | perl -ne '/Debug \(bootstrap\): Running command: .+\(([^s]+s)/ && print $1'; }
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI (wp command) not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo "🚀 WordPress Plugin Performance Test 🚀"
    echo "This script measures the execution time of 'wp plugin list --debug' under various conditions."
    echo ""
    echo "📋 Initial Baseline Measurements for 'wp plugin list --debug':"

    local time_no_theme_s; printf "  ⏳ Measuring time with NO themes loaded (--skip-themes)... "; time_no_theme_s=$(_get_wp_execution_time plugin list --skip-themes); echo "Time: $time_no_theme_s"
    local time_no_plugins_s; printf "  ⏳ Measuring time with NO plugins loaded (--skip-plugins)... "; time_no_plugins_s=$(_get_wp_execution_time plugin list --skip-plugins); echo "Time: $time_no_plugins_s"
    local base_time_s; printf "  ⏳ Measuring base time (ALL plugins & theme active)... "; base_time_s=$(_get_wp_execution_time plugin list)
    if [[ -z "$base_time_s" ]]; then echo "❌ Error: Could not measure base execution time." >&2; return 1; fi;
    echo "Base time: $base_time_s"
    echo ""

    local active_plugins=()
    while IFS= read -r line; do
        active_plugins+=("$line")
    done < <("$WP_CLI_CMD" plugin list --field=name --status=active)

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
# ----------------------------------------------------
#  Deactivates a suspend message by removing the mu-plugin.
# ----------------------------------------------------
function suspend_deactivate() {
    local wp_content="$1"

    #  Set default wp-content if not provided
    if [[ -z "$wp_content" ]]; then
        wp_content="wp-content"
    fi

    local suspend_file="${wp_content}/mu-plugins/do-suspend.php"

    if [ -f "$suspend_file" ]; then
        echo "Deactivating suspend message by removing ${suspend_file}..."
        rm "$suspend_file"
        echo "✅ Suspend message deactivated. Site is now live."
    else
        echo "Site appears to be already live (suspend file not found)."
    fi

    #  Clear Kinsta cache if environment is detected
    if [ -f "/etc/update-motd.d/00-kinsta-welcome" ]; then
        if setup_wp_cli && "$WP_CLI_CMD" kinsta cache purge --all --skip-themes &> /dev/null; then
            echo "Kinsta cache purged."
        else
            echo "Warning: Could not purge Kinsta cache. Is the 'wp kinsta' command available?" >&2
        fi
    fi
}

# ----------------------------------------------------
#  Activates a suspend message by adding an mu-plugin.
# ----------------------------------------------------
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
    if [ -f "${wp_content}/mu-plugins/do-suspend.php" ]; then
        echo "Removing existing suspend file..."
        rm "${wp_content}/mu-plugins/do-suspend.php"
    fi

    #  Create the deactivation mu-plugin
    local output_file="${wp_content}/mu-plugins/do-suspend.php"
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
        if setup_wp_cli && "$WP_CLI_CMD" kinsta cache purge --all --skip-themes &> /dev/null; then
            echo "Kinsta cache purged."
        else
            echo "Warning: Could not purge Kinsta cache. Is the 'wp kinsta' command available?" >&2
        fi
    fi
}
# ----------------------------------------------------
#  Update Commands
#  Handles WordPress core, theme, and plugin updates.
# ----------------------------------------------------

UPDATE_LOGS_DIR=""
UPDATE_LOGS_LIST_FILE=""

# ----------------------------------------------------
#  Ensures update directories and lists exist.
# ----------------------------------------------------
function _ensure_update_setup() {
    # Exit if already initialized
    if [[ -n "$UPDATE_LOGS_DIR" ]]; then return 0; fi

    local private_dir
    if ! private_dir=$(_get_private_dir); then
        return 1
    fi

    # Using the checkpoint base for consistency as updates are linked to checkpoints
    local checkpoint_base_dir="${private_dir}/checkpoints"
    UPDATE_LOGS_DIR="${checkpoint_base_dir}/updates"
    UPDATE_LOGS_LIST_FILE="$UPDATE_LOGS_DIR/list.json"

    mkdir -p "$UPDATE_LOGS_DIR"
    if [ ! -f "$UPDATE_LOGS_LIST_FILE" ]; then
        echo "[]" > "$UPDATE_LOGS_LIST_FILE"
    fi
}

# ----------------------------------------------------
#  (Helper) Lets the user select an update log from the list.
# ----------------------------------------------------
function _select_update_log() {
    _ensure_update_setup
    if ! setup_wp_cli; then return 1; fi

    if [ ! -s "$UPDATE_LOGS_LIST_FILE" ]; then
        echo "ℹ️ No update logs found. Run '_do update all' to create one." >&2
        return 1
    fi

    # Use PHP to read the detailed list and check format
    local php_script_read_list='
<?php
$list_file = "%s";
$list = json_decode(file_get_contents($list_file), true);

if (!is_array($list) || empty($list)) {
    echo "EMPTY";
    return;
}

// Check if the first item has the new detailed format.
if (!isset($list[0]["formatted_timestamp"])) {
    echo "NEEDS_GENERATE";
    return;
}

foreach($list as $item) {
    if (isset($item["formatted_timestamp"]) && isset($item["hash_before"]) && isset($item["hash_after"]) && isset($item["counts_str"]) && isset($item["diff_stats"])) {
        // Output format: formatted_timestamp|hash_before|hash_after|counts_str|diff_stats
        echo $item["formatted_timestamp"] . "|" . $item["hash_before"] . "|" . $item["hash_after"] . "|" . $item["counts_str"] . "|" . $item["diff_stats"] . "\n";
    }
}
'
    local php_script; php_script=$(printf "$php_script_read_list" "$UPDATE_LOGS_LIST_FILE")
    local update_entries; update_entries=$(echo "$php_script" | "$WP_CLI_CMD" eval-file -)

    if [[ "$update_entries" == "EMPTY" ]]; then
        echo "ℹ️ No update logs available to select." >&2; return 1;
    elif [[ "$update_entries" == "NEEDS_GENERATE" ]]; then
        echo "⚠️ The update log list needs to be generated for faster display." >&2
        echo "Please run: _do update list-generate" >&2
        return 1
    fi

    local display_items=()
    local data_items=()

    while IFS='|' read -r formatted_timestamp hash_before hash_after counts_str diff_stats; do
        hash_before=$(echo "$hash_before" | tr -d '[:space:]')
        hash_after=$(echo "$hash_after" | tr -d '[:space:]')
        if [ -z "$hash_before" ] || [ -z "$hash_after" ]; then continue; fi

        local display_string
        display_string=$(printf "%-28s | %s -> %s | %-18s | %s" \
            "$formatted_timestamp" "${hash_before:0:7}" "${hash_after:0:7}" "$counts_str" "$diff_stats")
        
        display_items+=("$display_string")
        data_items+=("$hash_before|$hash_after")
    done <<< "$update_entries"
    
    if [ ${#display_items[@]} -eq 0 ]; then
      echo "❌ No valid update entries to display." >&2
      return 1
    fi

    local prompt_text="${1:-Select an update to inspect}"
    local selected_display
    selected_display=$(printf "%s\n" "${display_items[@]}" | "$GUM_CMD" filter --height=20 --prompt="👇 $prompt_text" --indicator="→" --placeholder="")

    if [ -z "$selected_display" ]; then
        echo "" # Return empty for cancellation
        return 0
    fi

    local selected_index=-1
    for i in "${!display_items[@]}"; do
       if [[ "${display_items[$i]}" == "$selected_display" ]]; then
           selected_index=$i
           break
       fi
    done

    if [ "$selected_index" -ne -1 ]; then
        echo "${data_items[$selected_index]}"
        return 0
    else
        echo "❌ Error: Could not find selected update." >&2
        return 1
    fi
}


# ----------------------------------------------------
#  Generates a detailed list of updates for faster access.
# ----------------------------------------------------
function update_list_generate() {
    if ! setup_gum || ! setup_git; then return 1; fi
    if ! setup_wp_cli; then return 1; fi
    _ensure_checkpoint_setup # This sets up repo path as well
    _ensure_update_setup

    local php_script_read_list='
<?php
$list_file = "%s";
if (!file_exists($list_file)) { return; }
$list = json_decode(file_get_contents($list_file), true);
if (!is_array($list) || empty($list)) { return; }
foreach($list as $item) {
    // Read from both simple and potentially detailed formats
    $timestamp = $item["timestamp"] ?? "N/A";
    $hash_before = $item["before"] ?? $item["hash_before"] ?? null;
    $hash_after = $item["after"] ?? $item["hash_after"] ?? null;

    if ($timestamp && $hash_before && $hash_after) {
        echo "$timestamp|$hash_before|$hash_after\n";
    }
}
'
    local php_script; php_script=$(printf "$php_script_read_list" "$UPDATE_LOGS_LIST_FILE")
    local update_entries; update_entries=$(echo "$php_script" | "$WP_CLI_CMD" eval-file -)

    if [ -z "$update_entries" ]; then
        echo "ℹ️ No update logs found to generate a list from."
        return 0
    fi
    
    echo "🔎 Generating detailed update list... (This may take a moment)"
    local detailed_items=()

    while IFS='|' read -r timestamp hash_before hash_after; do
        hash_before=$(echo "$hash_before" | tr -d '[:space:]')
        hash_after=$(echo "$hash_after" | tr -d '[:space:]')
        if [ -z "$hash_before" ] || [ -z "$hash_after" ]; then continue; fi

        # Validate that both commits exist before proceeding
        if ! "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" cat-file -e "${hash_before}^{commit}" &>/dev/null; then
            echo "⚠️ Warning: Could not find 'before' commit '$hash_before'. Skipping entry." >&2
            continue
        fi
        if ! "$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" cat-file -e "${hash_after}^{commit}" &>/dev/null; then
            echo "⚠️ Warning: Could not find 'after' commit '$hash_after'. Skipping entry." >&2
            continue
        fi

        local manifest_after; manifest_after=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" show "$hash_after:manifest.json" 2>/dev/null)
        if [ -z "$manifest_after" ]; then
            echo "⚠️ Warning: Could not find manifest for 'after' hash '$hash_after'. Skipping entry." >&2
            continue
        fi

        local php_get_counts='
<?php
$manifest_json = <<<'EOT'
%s
EOT;
$data = json_decode($manifest_json, true);
$theme_count = isset($data["themes"]) && is_array($data["themes"]) ? count($data["themes"]) : 0;
$plugin_count = isset($data["plugins"]) && is_array($data["plugins"]) ? count($data["plugins"]) : 0;
echo "$theme_count Themes, $plugin_count Plugins";
'
        local counts_script; counts_script=$(printf "$php_get_counts" "$manifest_after")
        local counts_str; counts_str=$(echo "$counts_script" | "$WP_CLI_CMD" eval-file -)
        
        local diff_stats
        diff_stats=$("$GIT_CMD" -C "$CHECKPOINT_REPO_DIR" diff --shortstat "$hash_before" "$hash_after" -- 'plugins/' 'themes/' 'mu-plugins/' | sed 's/^[ \t]*//')
        if [ -z "$diff_stats" ]; then diff_stats="No file changes"; fi

        local formatted_timestamp
        if [[ "$(uname)" == "Darwin" ]]; then
            formatted_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" -u "$timestamp" "+%a, %b %d, %Y, %-I:%M %p")
        else
            formatted_timestamp=$(date -d "$timestamp" "+%a, %b %d, %Y, %-I:%M %p")
        fi

        local json_item
        json_item=$(printf '{"hash_before": "%s", "hash_after": "%s", "timestamp": "%s", "formatted_timestamp": "%s", "counts_str": "%s", "diff_stats": "%s"}' \
            "$hash_before" "$hash_after" "$timestamp" "$formatted_timestamp" "$counts_str" "$diff_stats")
        
        detailed_items+=("$json_item")

    done <<< "$update_entries"
    
    local full_json="["
    full_json+=$(IFS=,; echo "${detailed_items[*]}")
    full_json+="]"

    local php_write_script='
<?php
$list_file = "%s";
$json_data = <<<'EOT'
%s
EOT;
$data = json_decode($json_data, true);
file_put_contents($list_file, json_encode($data, JSON_PRETTY_PRINT));
'
    local write_script; write_script=$(printf "$php_write_script" "$UPDATE_LOGS_LIST_FILE" "$full_json")
    if echo "$write_script" | "$WP_CLI_CMD" eval-file -; then
        echo "✅ Detailed update list saved to $UPDATE_LOGS_LIST_FILE"
    else
        echo "❌ Error: Failed to write detailed update list."
    fi
}

# ----------------------------------------------------
#  Lists all past updates from the pre-generated list.
# ----------------------------------------------------
function update_list() {
    if ! setup_gum || ! setup_git; then return 1; fi
    if ! setup_wp_cli; then return 1; fi
    _ensure_checkpoint_setup # Ensures repo path is set
    
    local selected_hashes
    selected_hashes=$(_select_update_log "Select an update to inspect")

    if [ -z "$selected_hashes" ]; then
        echo "No update selected."
        return 0
    fi
    if [ $? -ne 0 ]; then
        return 1 # Error already printed by helper
    fi

    local selected_hash_before; selected_hash_before=$(echo "$selected_hashes" | cut -d'|' -f1)
    local selected_hash_after; selected_hash_after=$(echo "$selected_hashes" | cut -d'|' -f2)

    checkpoint_show "$selected_hash_after" "$selected_hash_before"
}

# ----------------------------------------------------
#  Runs the full update process.
# ----------------------------------------------------
function run_update_all() {
    if ! setup_git; then return 1; fi
    if ! command -v wp &>/dev/null; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi

    _ensure_checkpoint_setup
    _ensure_update_setup

    echo "🚀 Starting full WordPress update process..."

    echo "   - Step 1/5: Creating 'before' checkpoint..."
    checkpoint_create > /dev/null
    local hash_before; hash_before=$(checkpoint_latest)
    if [ -z "$hash_before" ]; then
        echo "❌ Error: Could not create 'before' checkpoint." >&2
        return 1
    fi
    echo "     Before Hash: $hash_before"

    echo "   - Step 2/5: Running WordPress updates..."
    echo "     - Updating core..."
    "$WP_CLI_CMD" core update --skip-plugins --skip-themes
    echo "     - Updating themes..."
    "$WP_CLI_CMD" theme update --all --skip-plugins --skip-themes
    echo "     - Updating plugins..."
    "$WP_CLI_CMD" plugin update --all --skip-plugins --skip-themes

    echo "   - Step 3/5: Creating 'after' checkpoint..."
    checkpoint_create > /dev/null
    local hash_after; hash_after=$(checkpoint_latest)
    if [ -z "$hash_after" ]; then
        echo "❌ Error: Could not create 'after' checkpoint." >&2
        return 1
    fi
    echo "     After Hash: $hash_after"
    
    if [ "$hash_before" == "$hash_after" ]; then
        echo "✅ No updates were available. Site is up-to-date."
        return 0
    fi
    
    echo "   - Step 4/5: Generating update log entry..."
    local timestamp; timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # This creates a simple entry. `update list-generate` will enrich it later.
    local php_list_template='
<?php
$list_file = "%s";
$before = "%s";
$after = "%s";
$timestamp = "%s";
$list = file_exists($list_file) ? json_decode(file_get_contents($list_file), true) : [];
if (!is_array($list)) { $list = []; }
$new_entry = ["before" => $before, "after" => $after, "timestamp" => $timestamp];
// To keep it simple, we just read the simple format and add to it.
// The list-generate command is responsible for creating the detailed format.
$simple_list = [];
foreach($list as $item) {
    $simple_list[] = [
        "before" => $item["before"] ?? $item["hash_before"] ?? null,
        "after" => $item["after"] ?? $item["hash_after"] ?? null,
        "timestamp" => $item["timestamp"] ?? null
    ];
}
array_unshift($simple_list, $new_entry);
echo json_encode($simple_list, JSON_PRETTY_PRINT);
'
    local php_list_script; php_list_script=$(printf "$php_list_template" "$UPDATE_LOGS_LIST_FILE" "$hash_before" "$hash_after" "$timestamp")
    
    local temp_list_file; temp_list_file=$(mktemp)
    if echo "$php_list_script" | "$WP_CLI_CMD" eval-file - > "$temp_list_file"; then
        mv "$temp_list_file" "$UPDATE_LOGS_LIST_FILE"
    else
        echo "❌ Error: Failed to update master update list." >&2
        rm "$temp_list_file"
    fi

    echo "   - Step 5/5: Regenerating detailed update list..."
    update_list_generate > /dev/null

    echo "✅ Update process complete."
}

# ----------------------------------------------------
#  Displays the version of the _do script.
# ----------------------------------------------------
function show_version() {
    echo "_do version $CAPTAINCORE_DO_VERSION"
}
# ----------------------------------------------------
#  Checks for and identifies sources of WP-CLI warnings.
# ----------------------------------------------------
function wpcli_check() {
    if ! setup_wp_cli; then echo "❌ Error: WP-CLI not found." >&2; return 1; fi
    if ! "$WP_CLI_CMD" core is-installed --quiet; then echo "❌ Error: This does not appear to be a WordPress installation." >&2; return 1; fi

    echo "🚀 Checking for WP-CLI warnings..."

    # 1. Run with everything skipped to check for core issues.
    local base_warnings
    base_warnings=$("$WP_CLI_CMD" plugin list --skip-themes --skip-plugins 2>&1 >/dev/null)

    if [[ -n "$base_warnings" ]]; then
        echo "⚠️ Found warnings even with all plugins and themes skipped. This might be a WP-CLI core or WordPress core issue."
        echo "--- Warnings ---"
        echo "$base_warnings"
        echo "----------------"
        return 1
    fi

    # 2. Run with everything active to get a baseline.
    local initial_warnings
    initial_warnings=$("$WP_CLI_CMD" plugin list 2>&1 >/dev/null)

    if [[ -z "$initial_warnings" ]]; then
        echo "✅ WP-CLI is running smoothly. No warnings detected."
        return 0
    fi

    echo "⚠️ WP-CLI produced warnings. Investigating the source..."
    echo
    echo "--- Initial Warnings Found ---"
    echo "$initial_warnings"
    echo "----------------------------"
    echo

    local culprit_found=false

    # 3. Check theme impact
    echo "Testing for theme conflicts..."
    local warnings_without_theme
    warnings_without_theme=$("$WP_CLI_CMD" plugin list --skip-themes 2>&1 >/dev/null)
    if [[ -z "$warnings_without_theme" ]]; then
        local active_theme
        active_theme=$("$WP_CLI_CMD" theme list --status=active --field=name)
        echo "✅ Problem resolved by skipping themes. The active theme '$active_theme' is the likely source of the warnings."
        culprit_found=true
    else
        echo "No warnings seem to originate from the theme."
    fi

    # 4. Check plugin impact
    echo "Testing for plugin conflicts..."
    local active_plugins=()
    while IFS= read -r line; do
        active_plugins+=("$line")
    done < <("$WP_CLI_CMD" plugin list --field=name --status=active)

    if [[ ${#active_plugins[@]} -eq 0 ]]; then
        echo "ℹ️ No active plugins found to test."
    else
        echo "Comparing output when skipping each of the ${#active_plugins[@]} active plugins..."
        for plugin in "${active_plugins[@]}"; do
            printf "  - Testing by skipping '%s'... " "$plugin"
            local warnings_without_plugin
            warnings_without_plugin=$("$WP_CLI_CMD" plugin list --skip-plugins="$plugin" 2>&1 >/dev/null)

            if [[ -z "$warnings_without_plugin" ]]; then
                printf "FOUND CULPRIT\n"
                echo "  ✅ Warnings disappeared when skipping '$plugin'. This plugin is a likely source of the warnings."
                culprit_found=true
            else
                 printf "no change\n"
            fi
        done
    fi
    echo
    if ! $culprit_found; then
        echo "ℹ️ Could not isolate a single plugin or theme as the source. The issue might be from a combination of plugins or WordPress core itself."
    fi
    echo "✅ Check complete."
}

#  Pass all script arguments to the main function.
main "$@"
