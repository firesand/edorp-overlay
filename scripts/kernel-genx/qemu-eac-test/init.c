/* Minimal init for the GenX EAC boot test: mounts proc/sys/securityfs,
 * prints the state Easy Anti-Cheat v2 cares about, tries to load an
 * unsigned and a signed copy of the same module, then powers off. */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/utsname.h>
#include <unistd.h>
#include <dirent.h>

static void show(const char *path) {
	char buf[4096]; int fd = open(path, O_RDONLY); ssize_t n;
	printf("EAC-TEST %s: ", path);
	if (fd < 0) { printf("(open failed: %s)\n", strerror(errno)); return; }
	n = read(fd, buf, sizeof buf - 1); close(fd);
	if (n < 0) { printf("(read failed: %s)\n", strerror(errno)); return; }
	buf[n] = 0; while (n > 0 && buf[n-1] == '\n') buf[--n] = 0;
	printf("%s\n", buf);
}
static void try_module(const char *path, const char *label) {
	int fd = open(path, O_RDONLY); struct stat st; char *buf; long rc;
	if (fd < 0) { printf("EAC-TEST insmod %s: missing (%s)\n", label, strerror(errno)); return; }
	fstat(fd, &st); buf = malloc(st.st_size);
	if (read(fd, buf, st.st_size) != st.st_size) { printf("EAC-TEST insmod %s: short read\n", label); return; }
	close(fd);
	rc = syscall(SYS_init_module, buf, (unsigned long)st.st_size, "");
	printf("EAC-TEST insmod %s: %s\n", label, rc == 0 ? "LOADED" : strerror(errno));
	free(buf);
}
int main(void) {
	struct utsname u;
	mount("proc", "/proc", "proc", 0, NULL);
	mount("sysfs", "/sys", "sysfs", 0, NULL);
	mount("securityfs", "/sys/kernel/security", "securityfs", 0, NULL);
	if (uname(&u) == 0) printf("EAC-TEST booted: %s %s %s\n", u.sysname, u.release, u.version);
	show("/proc/cmdline");
	show("/sys/kernel/security/lockdown");
	show("/sys/kernel/security/lsm");
	show("/proc/sys/kernel/kexec_load_disabled");
	show("/sys/module/module/parameters/sig_enforce");
	show("/sys/kernel/iommu_groups/0/type");
	{ DIR *d = opendir("/sys/kernel/iommu_groups"); int n = 0; struct dirent *e;
	  if (d) { while ((e = readdir(d))) if (e->d_name[0] != '.') n++; closedir(d); }
	  printf("EAC-TEST iommu groups: %d\n", n); }
	show("/sys/class/tpm/tpm0/tpm_version_major");
	show("/sys/devices/system/cpu/vulnerabilities/spectre_v2");
	try_module("/test/unsigned.ko", "unsigned");
	try_module("/test/signed.ko", "signed");
	/* lockdown integrity must refuse raw MSR / port access */
	{ int fd = open("/dev/port", O_WRONLY); printf("EAC-TEST open /dev/port for write: %s\n", fd < 0 ? strerror(errno) : "ALLOWED"); if (fd >= 0) close(fd); }
	printf("EAC-TEST done\n");
	fflush(stdout); sync();
	reboot(RB_POWER_OFF);
	return 0;
}
