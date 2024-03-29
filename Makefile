#
# Copyright (C) 2013-2021 Canonical, Ltd.
# Copyright (C) 2021-2024 Colin Ian King
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

CURRENT_DIR := $(CURDIR)

SRC_INC_DIR := $(CURRENT_DIR)/src/include
SRC_CORE_DIR := $(CURRENT_DIR)/src/core
SRC_STRESS_DIR := $(CURRENT_DIR)/src/stress

VERSION=0.17.06

#
# Codename "scintillating scheduler smasher"
#

KERNEL=$(shell uname -s)
NODENAME=$(shell uname -n)

override CFLAGS += -Wall -Wextra -DVERSION='"$(VERSION)"' -std=gnu99 -I$(SRC_INC_DIR) -I$(CURRENT_DIR)

#
#  Building stress-vnni with less than -O2 causes breakage with
#  gcc-13.2, so remove then and ensure at least -O2 is used or
#  honour flags > -O2 if they are provided
#
VNNI_OFLAGS_REMOVE=-O0 -O1 -Og
VNNI_CFLAGS += $(filter-out $(VNNI_OFLAGS_REMOVE),$(CFLAGS))

#
# Default -O2 if optimization level not defined
#
ifeq "$(findstring -O,$(CFLAGS))" ""
	override CFLAGS += -O2
endif
ifeq "$(findstring -O,$(VNNI_CFLAGS))" ""
	override VNNI_CFLAGS += -O2
endif

#
# Debug flag
#
ifeq ($(DEBUG),1)
override CFLAGS += -g
endif

#
# Check if compiler supports flag set in $(flag)
#
cc_supports_flag = $(shell $(CC) -Werror $(flag) -E -xc /dev/null > /dev/null 2>&1 && echo $(flag))

#
# Pedantic flags
#
ifeq ($(PEDANTIC),1)

PEDANTIC_FLAGS := \
	-Wcast-qual -Wfloat-equal -Wmissing-declarations \
	-Wmissing-format-attribute -Wno-long-long -Wpacked \
	-Wredundant-decls -Wshadow -Wno-missing-field-initializers \
	-Wno-missing-braces -Wno-sign-compare -Wno-multichar \
	-DHAVE_PEDANTIC
override CFLAGS += $(foreach flag,$(PEDANTIC_FLAGS),$(cc_supports_flag))
endif

#
# Test for hardening flags and apply them if applicable
#
MACHINE = $(shell uname -m)
ifneq ($(PRESERVE_CFLAGS),1)
ifneq ($(MACHINE),$(filter $(MACHINE),alpha parisc ia64))
flag = -Wformat -fstack-protector-strong \
	-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 \
	-Werror=format-security
override CFLAGS += $(cc_supports_flag)
endif
endif

#
# Optimization flags
#
ifeq ($(findstring icc,$(CC)),)
override CFLAGS += $(foreach flag,-fipa-pta,$(cc_supports_flag))
endif
#
# Enable Link Time Optimization
#
ifeq ($(LTO),1)
override CFLAGS += $(foreach flag,-flto=auto,$(cc_supports_flag))
endif

#
# Expected build warnings
#
ifeq ($(UNEXPECTED),1)
override CFLAGS += -DCHECK_UNEXPECTED
endif

#
# Disable any user defined PREFV setting
#
ifneq ($(PRE_V),)
override undefine PRE_V
endif
#
# Verbosity prefixes
#
ifeq ($(VERBOSE),)
PRE_V=@
PRE_Q=@
else
PRE_V=
PRE_Q=@#
endif

ifneq ($(PRESERVE_CFLAGS),1)
ifeq ($(findstring icc,$(CC)),icc)
override CFLAGS += -no-inline-max-size -no-inline-max-total-size
override CFLAGS += -axAVX,CORE-AVX2,CORE-AVX-I,CORE-AVX512,SSE2,SSE3,SSSE3,SSE4.1,SSE4.2,SANDYBRIDGE,SKYLAKE,SKYLAKE-AVX512,TIGERLAKE,SAPPHIRERAPIDS
override CFLAGS += -ip -falign-loops -funroll-loops -ansi-alias -fma -qoverride-limits
endif
endif

#ifeq ($(findstring clang,$(CC)),clang)
#override CFLAGS += -Weverything
#endif

GREP = grep
#
# SunOS requires special grep for -e support
#
ifeq ($(KERNEL),SunOS)
ifneq ($(NODENAME),dilos)
GREP = /usr/xpg4/bin/grep
endif
endif

#
# Static flags, only to be used when using GCC
#
ifeq ($(STATIC),1)
override LDFLAGS += -static -z muldefs
override CFLAGS += -DBUILD_STATIC
endif

BINDIR=/usr/bin
MANDIR=/usr/share/man/man1
JOBDIR=/usr/share/stress-ng/example-jobs
BASHDIR=/usr/share/bash-completion/completions


#
# Header files
#
HEADERS = \
	$(SRC_INC_DIR)/core-arch.h \
	$(SRC_INC_DIR)/core-affinity.h \
	$(SRC_INC_DIR)/core-asm-arm.h \
	$(SRC_INC_DIR)/core-asm-generic.h \
	$(SRC_INC_DIR)/core-asm-loong64.h \
	$(SRC_INC_DIR)/core-asm-ppc64.h \
	$(SRC_INC_DIR)/core-asm-riscv.h \
	$(SRC_INC_DIR)/core-asm-s390.h \
	$(SRC_INC_DIR)/core-asm-sparc.h \
	$(SRC_INC_DIR)/core-asm-x86.h \
	$(SRC_INC_DIR)/core-asm-ret.h \
	$(SRC_INC_DIR)/core-attribute.h \
	$(SRC_INC_DIR)/core-bitops.h \
	$(SRC_INC_DIR)/core-builtin.h \
	$(SRC_INC_DIR)/core-capabilities.h \
	$(SRC_INC_DIR)/core-clocksource.h \
	$(SRC_INC_DIR)/core-config-check.h \
	$(SRC_INC_DIR)/core-cpu.h \
	$(SRC_INC_DIR)/core-cpu-cache.h \
	$(SRC_INC_DIR)/core-cpuidle.h \
	$(SRC_INC_DIR)/core-ftrace.h \
	$(SRC_INC_DIR)/core-hash.h \
	$(SRC_INC_DIR)/core-ignite-cpu.h \
	$(SRC_INC_DIR)/core-interrupts.h \
	$(SRC_INC_DIR)/core-io-priority.h \
	$(SRC_INC_DIR)/core-job.h \
	$(SRC_INC_DIR)/core-helper.h \
	$(SRC_INC_DIR)/core-killpid.h \
	$(SRC_INC_DIR)/core-klog.h \
	$(SRC_INC_DIR)/core-limit.h \
	$(SRC_INC_DIR)/core-lock.h \
	$(SRC_INC_DIR)/core-log.h \
	$(SRC_INC_DIR)/core-madvise.h \
	$(SRC_INC_DIR)/core-mlock.h \
	$(SRC_INC_DIR)/core-mmap.h \
	$(SRC_INC_DIR)/core-mincore.h \
	$(SRC_INC_DIR)/core-module.h \
	$(SRC_INC_DIR)/core-mounts.h \
	$(SRC_INC_DIR)/core-mwc.h \
	$(SRC_INC_DIR)/core-nt-load.h \
	$(SRC_INC_DIR)/core-nt-store.h \
	$(SRC_INC_DIR)/core-net.h \
	$(SRC_INC_DIR)/core-numa.h \
	$(SRC_INC_DIR)/core-opts.h \
	$(SRC_INC_DIR)/core-out-of-memory.h \
	$(SRC_INC_DIR)/core-parse-opts.h \
	$(SRC_INC_DIR)/core-perf.h \
	$(SRC_INC_DIR)/core-pragma.h \
	$(SRC_INC_DIR)/core-processes.h \
	$(SRC_INC_DIR)/core-pthread.h \
	$(SRC_INC_DIR)/core-put.h \
	$(SRC_INC_DIR)/core-resources.h \
	$(SRC_INC_DIR)/core-sched.h \
	$(SRC_INC_DIR)/core-setting.h \
	$(SRC_INC_DIR)/core-shared-heap.h \
	$(SRC_INC_DIR)/core-shim.h \
	$(SRC_INC_DIR)/core-smart.h \
	$(SRC_INC_DIR)/core-sort.h \
	$(SRC_INC_DIR)/core-stressors.h \
	$(SRC_INC_DIR)/core-syslog.h \
	$(SRC_INC_DIR)/core-target-clones.h \
	$(SRC_INC_DIR)/core-thermal-zone.h \
	$(SRC_INC_DIR)/core-thrash.h \
	$(SRC_INC_DIR)/core-time.h \
	$(SRC_INC_DIR)/core-try-open.h \
	$(SRC_INC_DIR)/core-vecmath.h \
	$(SRC_INC_DIR)/core-version.h \
	$(SRC_INC_DIR)/core-vmstat.h \
	$(SRC_INC_DIR)/stress-af-alg-defconfigs.h \
	$(SRC_INC_DIR)/stress-eigen-ops.h \
	$(SRC_INC_DIR)/stress-ng.h

#
#  Build time generated header files
#
HEADERS_GEN = \
	config.h \
	git-commit-id.h \
	io-uring.h \
	personality.h

#
#  Stressors
#
STRESS_SRC = \
	$(SRC_STRESS_DIR)/stress-access.c \
	$(SRC_STRESS_DIR)/stress-acl.c \
	$(SRC_STRESS_DIR)/stress-affinity.c \
	$(SRC_STRESS_DIR)/stress-af-alg.c \
	$(SRC_STRESS_DIR)/stress-aio.c \
	$(SRC_STRESS_DIR)/stress-aiol.c \
	$(SRC_STRESS_DIR)/stress-alarm.c \
	$(SRC_STRESS_DIR)/stress-apparmor.c \
	$(SRC_STRESS_DIR)/stress-atomic.c \
	$(SRC_STRESS_DIR)/stress-bad-altstack.c \
	$(SRC_STRESS_DIR)/stress-bad-ioctl.c \
	$(SRC_STRESS_DIR)/stress-bigheap.c \
	$(SRC_STRESS_DIR)/stress-bind-mount.c \
	$(SRC_STRESS_DIR)/stress-binderfs.c \
	$(SRC_STRESS_DIR)/stress-bitonicsort.c \
	$(SRC_STRESS_DIR)/stress-branch.c \
	$(SRC_STRESS_DIR)/stress-brk.c \
	$(SRC_STRESS_DIR)/stress-bsearch.c \
	$(SRC_STRESS_DIR)/stress-cache.c \
	$(SRC_STRESS_DIR)/stress-cacheline.c \
	$(SRC_STRESS_DIR)/stress-cap.c \
	$(SRC_STRESS_DIR)/stress-cgroup.c \
	$(SRC_STRESS_DIR)/stress-chattr.c \
	$(SRC_STRESS_DIR)/stress-chdir.c \
	$(SRC_STRESS_DIR)/stress-chmod.c \
	$(SRC_STRESS_DIR)/stress-chown.c \
	$(SRC_STRESS_DIR)/stress-chroot.c \
	$(SRC_STRESS_DIR)/stress-clock.c \
	$(SRC_STRESS_DIR)/stress-clone.c \
	$(SRC_STRESS_DIR)/stress-close.c \
	$(SRC_STRESS_DIR)/stress-context.c \
	$(SRC_STRESS_DIR)/stress-copy-file.c \
	$(SRC_STRESS_DIR)/stress-cpu.c \
	$(SRC_STRESS_DIR)/stress-cpu-online.c \
	$(SRC_STRESS_DIR)/stress-crypt.c \
	$(SRC_STRESS_DIR)/stress-cyclic.c \
	$(SRC_STRESS_DIR)/stress-daemon.c \
	$(SRC_STRESS_DIR)/stress-dccp.c \
	$(SRC_STRESS_DIR)/stress-dekker.c \
	$(SRC_STRESS_DIR)/stress-dentry.c \
	$(SRC_STRESS_DIR)/stress-dev.c \
	$(SRC_STRESS_DIR)/stress-dev-shm.c \
	$(SRC_STRESS_DIR)/stress-dir.c \
	$(SRC_STRESS_DIR)/stress-dirdeep.c \
	$(SRC_STRESS_DIR)/stress-dirmany.c \
	$(SRC_STRESS_DIR)/stress-dnotify.c \
	$(SRC_STRESS_DIR)/stress-dup.c \
	$(SRC_STRESS_DIR)/stress-dynlib.c \
	$(SRC_STRESS_DIR)/stress-eigen.c \
	$(SRC_STRESS_DIR)/stress-efivar.c \
	$(SRC_STRESS_DIR)/stress-enosys.c \
	$(SRC_STRESS_DIR)/stress-env.c \
	$(SRC_STRESS_DIR)/stress-epoll.c \
	$(SRC_STRESS_DIR)/stress-eventfd.c \
	$(SRC_STRESS_DIR)/stress-exec.c \
	$(SRC_STRESS_DIR)/stress-exit-group.c \
	$(SRC_STRESS_DIR)/stress-expmath.c \
	$(SRC_STRESS_DIR)/stress-factor.c \
	$(SRC_STRESS_DIR)/stress-fallocate.c \
	$(SRC_STRESS_DIR)/stress-fanotify.c \
	$(SRC_STRESS_DIR)/stress-far-branch.c \
	$(SRC_STRESS_DIR)/stress-fault.c \
	$(SRC_STRESS_DIR)/stress-fcntl.c \
	$(SRC_STRESS_DIR)/stress-fd-fork.c \
	$(SRC_STRESS_DIR)/stress-file-ioctl.c \
	$(SRC_STRESS_DIR)/stress-fiemap.c \
	$(SRC_STRESS_DIR)/stress-fifo.c \
	$(SRC_STRESS_DIR)/stress-filename.c \
	$(SRC_STRESS_DIR)/stress-flock.c \
	$(SRC_STRESS_DIR)/stress-flushcache.c \
	$(SRC_STRESS_DIR)/stress-fma.c \
	$(SRC_STRESS_DIR)/stress-fork.c \
	$(SRC_STRESS_DIR)/stress-forkheavy.c \
	$(SRC_STRESS_DIR)/stress-fp.c \
	$(SRC_STRESS_DIR)/stress-fp-error.c \
	$(SRC_STRESS_DIR)/stress-fpunch.c \
	$(SRC_STRESS_DIR)/stress-fsize.c \
	$(SRC_STRESS_DIR)/stress-fstat.c \
	$(SRC_STRESS_DIR)/stress-full.c \
	$(SRC_STRESS_DIR)/stress-funccall.c \
	$(SRC_STRESS_DIR)/stress-funcret.c \
	$(SRC_STRESS_DIR)/stress-futex.c \
	$(SRC_STRESS_DIR)/stress-get.c \
	$(SRC_STRESS_DIR)/stress-getrandom.c \
	$(SRC_STRESS_DIR)/stress-getdent.c \
	$(SRC_STRESS_DIR)/stress-goto.c \
	$(SRC_STRESS_DIR)/stress-gpu.c \
	$(SRC_STRESS_DIR)/stress-handle.c \
	$(SRC_STRESS_DIR)/stress-hash.c \
	$(SRC_STRESS_DIR)/stress-hdd.c \
	$(SRC_STRESS_DIR)/stress-heapsort.c \
	$(SRC_STRESS_DIR)/stress-hrtimers.c \
	$(SRC_STRESS_DIR)/stress-hsearch.c \
	$(SRC_STRESS_DIR)/stress-icache.c \
	$(SRC_STRESS_DIR)/stress-icmp-flood.c \
	$(SRC_STRESS_DIR)/stress-idle-page.c \
	$(SRC_STRESS_DIR)/stress-inode-flags.c \
	$(SRC_STRESS_DIR)/stress-inotify.c \
	$(SRC_STRESS_DIR)/stress-io.c \
	$(SRC_STRESS_DIR)/stress-iomix.c \
	$(SRC_STRESS_DIR)/stress-ioport.c \
	$(SRC_STRESS_DIR)/stress-ioprio.c \
	$(SRC_STRESS_DIR)/stress-io-uring.c \
	$(SRC_STRESS_DIR)/stress-ipsec-mb.c \
	$(SRC_STRESS_DIR)/stress-itimer.c \
	$(SRC_STRESS_DIR)/stress-jpeg.c \
	$(SRC_STRESS_DIR)/stress-judy.c \
	$(SRC_STRESS_DIR)/stress-kcmp.c \
	$(SRC_STRESS_DIR)/stress-key.c \
	$(SRC_STRESS_DIR)/stress-kill.c \
	$(SRC_STRESS_DIR)/stress-klog.c \
	$(SRC_STRESS_DIR)/stress-kvm.c \
	$(SRC_STRESS_DIR)/stress-l1cache.c \
	$(SRC_STRESS_DIR)/stress-landlock.c \
	$(SRC_STRESS_DIR)/stress-lease.c \
	$(SRC_STRESS_DIR)/stress-led.c \
	$(SRC_STRESS_DIR)/stress-link.c \
	$(SRC_STRESS_DIR)/stress-list.c \
	$(SRC_STRESS_DIR)/stress-llc-affinity.c \
	$(SRC_STRESS_DIR)/stress-loadavg.c \
	$(SRC_STRESS_DIR)/stress-lockbus.c \
	$(SRC_STRESS_DIR)/stress-locka.c \
	$(SRC_STRESS_DIR)/stress-lockf.c \
	$(SRC_STRESS_DIR)/stress-lockofd.c \
	$(SRC_STRESS_DIR)/stress-logmath.c \
	$(SRC_STRESS_DIR)/stress-longjmp.c \
	$(SRC_STRESS_DIR)/stress-loop.c \
	$(SRC_STRESS_DIR)/stress-lsearch.c \
	$(SRC_STRESS_DIR)/stress-lsm.c \
	$(SRC_STRESS_DIR)/stress-madvise.c \
	$(SRC_STRESS_DIR)/stress-malloc.c \
	$(SRC_STRESS_DIR)/stress-matrix.c \
	$(SRC_STRESS_DIR)/stress-matrix-3d.c \
	$(SRC_STRESS_DIR)/stress-mcontend.c \
	$(SRC_STRESS_DIR)/stress-membarrier.c \
	$(SRC_STRESS_DIR)/stress-memcpy.c \
	$(SRC_STRESS_DIR)/stress-memfd.c \
	$(SRC_STRESS_DIR)/stress-memhotplug.c \
	$(SRC_STRESS_DIR)/stress-memrate.c \
	$(SRC_STRESS_DIR)/stress-memthrash.c \
	$(SRC_STRESS_DIR)/stress-mergesort.c \
	$(SRC_STRESS_DIR)/stress-metamix.c \
	$(SRC_STRESS_DIR)/stress-mincore.c \
	$(SRC_STRESS_DIR)/stress-misaligned.c \
	$(SRC_STRESS_DIR)/stress-mknod.c \
	$(SRC_STRESS_DIR)/stress-mlock.c \
	$(SRC_STRESS_DIR)/stress-mlockmany.c \
	$(SRC_STRESS_DIR)/stress-mmap.c \
	$(SRC_STRESS_DIR)/stress-mmapaddr.c \
	$(SRC_STRESS_DIR)/stress-mmapfiles.c \
	$(SRC_STRESS_DIR)/stress-mmapfixed.c \
	$(SRC_STRESS_DIR)/stress-mmapfork.c \
	$(SRC_STRESS_DIR)/stress-mmaphuge.c \
	$(SRC_STRESS_DIR)/stress-mmapmany.c \
	$(SRC_STRESS_DIR)/stress-module.c \
	$(SRC_STRESS_DIR)/stress-monte-carlo.c \
	$(SRC_STRESS_DIR)/stress-mprotect.c \
	$(SRC_STRESS_DIR)/stress-mpfr.c \
	$(SRC_STRESS_DIR)/stress-mq.c \
	$(SRC_STRESS_DIR)/stress-mremap.c \
	$(SRC_STRESS_DIR)/stress-msg.c \
	$(SRC_STRESS_DIR)/stress-msync.c \
	$(SRC_STRESS_DIR)/stress-msyncmany.c \
	$(SRC_STRESS_DIR)/stress-munmap.c \
	$(SRC_STRESS_DIR)/stress-mutex.c \
	$(SRC_STRESS_DIR)/stress-nanosleep.c \
	$(SRC_STRESS_DIR)/stress-netdev.c \
	$(SRC_STRESS_DIR)/stress-netlink-proc.c \
	$(SRC_STRESS_DIR)/stress-netlink-task.c \
	$(SRC_STRESS_DIR)/stress-nice.c \
	$(SRC_STRESS_DIR)/stress-nop.c \
	$(SRC_STRESS_DIR)/stress-null.c \
	$(SRC_STRESS_DIR)/stress-numa.c \
	$(SRC_STRESS_DIR)/stress-oom-pipe.c \
	$(SRC_STRESS_DIR)/stress-opcode.c \
	$(SRC_STRESS_DIR)/stress-open.c \
	$(SRC_STRESS_DIR)/stress-pagemove.c \
	$(SRC_STRESS_DIR)/stress-pageswap.c \
	$(SRC_STRESS_DIR)/stress-pci.c \
	$(SRC_STRESS_DIR)/stress-personality.c \
	$(SRC_STRESS_DIR)/stress-peterson.c \
	$(SRC_STRESS_DIR)/stress-physpage.c \
	$(SRC_STRESS_DIR)/stress-pidfd.c \
	$(SRC_STRESS_DIR)/stress-ping-sock.c \
	$(SRC_STRESS_DIR)/stress-pipe.c \
	$(SRC_STRESS_DIR)/stress-pipeherd.c \
	$(SRC_STRESS_DIR)/stress-pkey.c \
	$(SRC_STRESS_DIR)/stress-plugin.c \
	$(SRC_STRESS_DIR)/stress-poll.c \
	$(SRC_STRESS_DIR)/stress-powmath.c \
	$(SRC_STRESS_DIR)/stress-prctl.c \
	$(SRC_STRESS_DIR)/stress-prefetch.c \
	$(SRC_STRESS_DIR)/stress-prio-inv.c \
	$(SRC_STRESS_DIR)/stress-priv-instr.c \
	$(SRC_STRESS_DIR)/stress-procfs.c \
	$(SRC_STRESS_DIR)/stress-pthread.c \
	$(SRC_STRESS_DIR)/stress-ptrace.c \
	$(SRC_STRESS_DIR)/stress-pty.c \
	$(SRC_STRESS_DIR)/stress-quota.c \
	$(SRC_STRESS_DIR)/stress-qsort.c \
	$(SRC_STRESS_DIR)/stress-race-sched.c \
	$(SRC_STRESS_DIR)/stress-radixsort.c \
	$(SRC_STRESS_DIR)/stress-randlist.c \
	$(SRC_STRESS_DIR)/stress-ramfs.c \
	$(SRC_STRESS_DIR)/stress-rawdev.c \
	$(SRC_STRESS_DIR)/stress-rawpkt.c \
	$(SRC_STRESS_DIR)/stress-rawsock.c \
	$(SRC_STRESS_DIR)/stress-rawudp.c \
	$(SRC_STRESS_DIR)/stress-rdrand.c \
	$(SRC_STRESS_DIR)/stress-readahead.c \
	$(SRC_STRESS_DIR)/stress-reboot.c \
	$(SRC_STRESS_DIR)/stress-regs.c \
	$(SRC_STRESS_DIR)/stress-remap.c \
	$(SRC_STRESS_DIR)/stress-rename.c \
	$(SRC_STRESS_DIR)/stress-resched.c \
	$(SRC_STRESS_DIR)/stress-resources.c \
	$(SRC_STRESS_DIR)/stress-revio.c \
	$(SRC_STRESS_DIR)/stress-ring-pipe.c \
	$(SRC_STRESS_DIR)/stress-rlimit.c \
	$(SRC_STRESS_DIR)/stress-rmap.c \
	$(SRC_STRESS_DIR)/stress-rotate.c \
	$(SRC_STRESS_DIR)/stress-rseq.c \
	$(SRC_STRESS_DIR)/stress-rtc.c \
	$(SRC_STRESS_DIR)/stress-sctp.c \
	$(SRC_STRESS_DIR)/stress-schedmix.c \
	$(SRC_STRESS_DIR)/stress-schedpolicy.c \
	$(SRC_STRESS_DIR)/stress-seal.c \
	$(SRC_STRESS_DIR)/stress-seccomp.c \
	$(SRC_STRESS_DIR)/stress-secretmem.c \
	$(SRC_STRESS_DIR)/stress-seek.c \
	$(SRC_STRESS_DIR)/stress-sem.c \
	$(SRC_STRESS_DIR)/stress-sem-sysv.c \
	$(SRC_STRESS_DIR)/stress-sendfile.c \
	$(SRC_STRESS_DIR)/stress-session.c \
	$(SRC_STRESS_DIR)/stress-set.c \
	$(SRC_STRESS_DIR)/stress-shellsort.c \
	$(SRC_STRESS_DIR)/stress-shm.c \
	$(SRC_STRESS_DIR)/stress-shm-sysv.c \
	$(SRC_STRESS_DIR)/stress-sigabrt.c \
	$(SRC_STRESS_DIR)/stress-sigbus.c \
	$(SRC_STRESS_DIR)/stress-sigchld.c \
	$(SRC_STRESS_DIR)/stress-sigfd.c \
	$(SRC_STRESS_DIR)/stress-sigfpe.c \
	$(SRC_STRESS_DIR)/stress-sigio.c \
	$(SRC_STRESS_DIR)/stress-signal.c \
	$(SRC_STRESS_DIR)/stress-signest.c \
	$(SRC_STRESS_DIR)/stress-sigpending.c \
	$(SRC_STRESS_DIR)/stress-sigpipe.c \
	$(SRC_STRESS_DIR)/stress-sigq.c \
	$(SRC_STRESS_DIR)/stress-sigrt.c \
	$(SRC_STRESS_DIR)/stress-sigsegv.c \
	$(SRC_STRESS_DIR)/stress-sigsuspend.c \
	$(SRC_STRESS_DIR)/stress-sigtrap.c \
	$(SRC_STRESS_DIR)/stress-sigxcpu.c \
	$(SRC_STRESS_DIR)/stress-sigxfsz.c \
	$(SRC_STRESS_DIR)/stress-skiplist.c \
	$(SRC_STRESS_DIR)/stress-sleep.c \
	$(SRC_STRESS_DIR)/stress-smi.c \
	$(SRC_STRESS_DIR)/stress-sock.c \
	$(SRC_STRESS_DIR)/stress-sockabuse.c \
	$(SRC_STRESS_DIR)/stress-sockdiag.c \
	$(SRC_STRESS_DIR)/stress-sockfd.c \
	$(SRC_STRESS_DIR)/stress-sockpair.c \
	$(SRC_STRESS_DIR)/stress-sockmany.c \
	$(SRC_STRESS_DIR)/stress-softlockup.c \
	$(SRC_STRESS_DIR)/stress-spawn.c \
	$(SRC_STRESS_DIR)/stress-sparsematrix.c \
	$(SRC_STRESS_DIR)/stress-splice.c \
	$(SRC_STRESS_DIR)/stress-stack.c \
	$(SRC_STRESS_DIR)/stress-stackmmap.c \
	$(SRC_STRESS_DIR)/stress-statmount.c \
	$(SRC_STRESS_DIR)/stress-str.c \
	$(SRC_STRESS_DIR)/stress-stream.c \
	$(SRC_STRESS_DIR)/stress-swap.c \
	$(SRC_STRESS_DIR)/stress-switch.c \
	$(SRC_STRESS_DIR)/stress-sync-file.c \
	$(SRC_STRESS_DIR)/stress-syncload.c \
	$(SRC_STRESS_DIR)/stress-sysbadaddr.c \
	$(SRC_STRESS_DIR)/stress-syscall.c \
	$(SRC_STRESS_DIR)/stress-sysinfo.c \
	$(SRC_STRESS_DIR)/stress-sysinval.c \
	$(SRC_STRESS_DIR)/stress-sysfs.c \
	$(SRC_STRESS_DIR)/stress-tee.c \
	$(SRC_STRESS_DIR)/stress-timer.c \
	$(SRC_STRESS_DIR)/stress-timerfd.c \
	$(SRC_STRESS_DIR)/stress-time-warp.c \
	$(SRC_STRESS_DIR)/stress-tlb-shootdown.c \
	$(SRC_STRESS_DIR)/stress-tmpfs.c \
	$(SRC_STRESS_DIR)/stress-touch.c \
	$(SRC_STRESS_DIR)/stress-tree.c \
	$(SRC_STRESS_DIR)/stress-trig.c \
	$(SRC_STRESS_DIR)/stress-tsc.c \
	$(SRC_STRESS_DIR)/stress-tsearch.c \
	$(SRC_STRESS_DIR)/stress-tun.c \
	$(SRC_STRESS_DIR)/stress-udp.c \
	$(SRC_STRESS_DIR)/stress-udp-flood.c \
	$(SRC_STRESS_DIR)/stress-umount.c \
	$(SRC_STRESS_DIR)/stress-unshare.c \
	$(SRC_STRESS_DIR)/stress-uprobe.c \
	$(SRC_STRESS_DIR)/stress-urandom.c \
	$(SRC_STRESS_DIR)/stress-userfaultfd.c \
	$(SRC_STRESS_DIR)/stress-usersyscall.c \
	$(SRC_STRESS_DIR)/stress-utime.c \
	$(SRC_STRESS_DIR)/stress-vdso.c \
	$(SRC_STRESS_DIR)/stress-vecfp.c \
	$(SRC_STRESS_DIR)/stress-vecmath.c \
	$(SRC_STRESS_DIR)/stress-vecshuf.c \
	$(SRC_STRESS_DIR)/stress-vecwide.c \
	$(SRC_STRESS_DIR)/stress-verity.c \
	$(SRC_STRESS_DIR)/stress-vforkmany.c \
	$(SRC_STRESS_DIR)/stress-vm.c \
	$(SRC_STRESS_DIR)/stress-vm-addr.c \
	$(SRC_STRESS_DIR)/stress-vm-rw.c \
	$(SRC_STRESS_DIR)/stress-vm-segv.c \
	$(SRC_STRESS_DIR)/stress-vm-splice.c \
	$(SRC_STRESS_DIR)/stress-vma.c \
	$(SRC_STRESS_DIR)/stress-vnni.c \
	$(SRC_STRESS_DIR)/stress-wait.c \
	$(SRC_STRESS_DIR)/stress-waitcpu.c \
	$(SRC_STRESS_DIR)/stress-watchdog.c \
	$(SRC_STRESS_DIR)/stress-wcs.c \
	$(SRC_STRESS_DIR)/stress-workload.c \
	$(SRC_STRESS_DIR)/stress-x86cpuid.c \
	$(SRC_STRESS_DIR)/stress-x86syscall.c \
	$(SRC_STRESS_DIR)/stress-xattr.c \
	$(SRC_STRESS_DIR)/stress-yield.c \
	$(SRC_STRESS_DIR)/stress-zero.c \
	$(SRC_STRESS_DIR)/stress-zlib.c \
	$(SRC_STRESS_DIR)/stress-zombie.c \


#
#  Build time core source files
#
CORE_SRC_GEN = \
	core-config.c

#
# Stress core
#
CORE_SRC = \
	$(SRC_CORE_DIR)/core-affinity.c \
	$(SRC_CORE_DIR)/core-asm-ret.c \
	$(SRC_CORE_DIR)/core-cpu.c \
	$(SRC_CORE_DIR)/core-cpu-cache.c \
	$(SRC_CORE_DIR)/core-cpuidle.c \
	$(SRC_CORE_DIR)/core-clocksource.c \
	$(SRC_CORE_DIR)/core-config-check.c \
	$(SRC_CORE_DIR)/core-hash.c \
	$(SRC_CORE_DIR)/core-helper.c \
	$(SRC_CORE_DIR)/core-ignite-cpu.c \
	$(SRC_CORE_DIR)/core-interrupts.c \
	$(SRC_CORE_DIR)/core-io-uring.c \
	$(SRC_CORE_DIR)/core-io-priority.c \
	$(SRC_CORE_DIR)/core-job.c \
	$(SRC_CORE_DIR)/core-killpid.c \
	$(SRC_CORE_DIR)/core-klog.c \
	$(SRC_CORE_DIR)/core-limit.c \
	$(SRC_CORE_DIR)/core-lock.c \
	$(SRC_CORE_DIR)/core-log.c \
	$(SRC_CORE_DIR)/core-madvise.c \
	$(SRC_CORE_DIR)/core-mincore.c \
	$(SRC_CORE_DIR)/core-mlock.c \
	$(SRC_CORE_DIR)/core-mmap.c \
	$(SRC_CORE_DIR)/core-module.c \
	$(SRC_CORE_DIR)/core-mounts.c \
	$(SRC_CORE_DIR)/core-mwc.c \
	$(SRC_CORE_DIR)/core-net.c \
	$(SRC_CORE_DIR)/core-numa.c \
	$(SRC_CORE_DIR)/core-opts.c \
	$(SRC_CORE_DIR)/core-out-of-memory.c \
	$(SRC_CORE_DIR)/core-parse-opts.c \
	$(SRC_CORE_DIR)/core-perf.c \
	$(SRC_CORE_DIR)/core-processes.c \
	$(SRC_CORE_DIR)/core-resources.c \
	$(SRC_CORE_DIR)/core-sched.c \
	$(SRC_CORE_DIR)/core-setting.c \
	$(SRC_CORE_DIR)/core-shared-heap.c \
	$(SRC_CORE_DIR)/core-shim.c \
	$(SRC_CORE_DIR)/core-smart.c \
	$(SRC_CORE_DIR)/core-sort.c \
	$(SRC_CORE_DIR)/core-thermal-zone.c \
	$(SRC_CORE_DIR)/core-time.c \
	$(SRC_CORE_DIR)/core-thrash.c \
	$(SRC_CORE_DIR)/core-ftrace.c \
	$(SRC_CORE_DIR)/core-try-open.c \
	$(SRC_CORE_DIR)/core-vmstat.c \
	$(SRC_STRESS_DIR)/stress-ng.c

SRC = $(CORE_SRC) $(CORE_SRC_GEN) $(STRESS_SRC)
OBJS = apparmor-data.o
OBJS += stress-eigen-ops.o
OBJS += $(SRC:.c=.o)

APPARMOR_PARSER=/sbin/apparmor_parser

all: config.h stress-ng

.SUFFIXES: .cpp .c .o

.o: Makefile

%.o: %.c $(HEADERS) $(HEADERS_GEN)
	$(PRE_Q)echo "CC $<"
	$(PRE_V)$(CC) $(CFLAGS) -c -o $@ $<

stress-vnni.o: stress-vnni.c $(HEADERS) $(HEADERS_GEN)
	$(PRE_Q)echo "CC $<"
	$(PRE_V)$(CC) $(VNNI_CFLAGS) -c -o $@ $<

#
#  Use CC for linking if eigen is not being used, otherwise use CXX
#
stress-ng: config.h $(OBJS)
	$(PRE_Q)echo "LD $@"
	$(eval LINK_TOOL := $(shell if [ -n "$(shell grep '^#define HAVE_EIGEN' config.h)" ]; then echo $(CXX); else echo $(CC); fi))
	$(eval LDFLAGS_EXTRA := $(shell grep CONFIG_LDFLAGS config | sed 's/CONFIG_LDFLAGS +=//' | tr '\n' ' '))
	$(PRE_V)$(LINK_TOOL) $(OBJS) -lm $(LDFLAGS) $(LDFLAGS_EXTRA) -o $@

stress-eigen-ops.o: config.h
	@if grep -q '^#define HAVE_EIGEN' config.h; then \
		echo "CXX stress-eigen-ops.cpp";	\
		$(CXX) -c -o stress-eigen-ops.o $(SRC_STRESS_DIR)/stress-eigen-ops.cpp; \
	else \
		echo "CC stress-eigen-ops.c";	\
		$(CC) -c -o stress-eigen-ops.o $(SRC_STRESS_DIR)/stress-eigen-ops.c; \
	fi

config.h config:
	$(PRE_Q)echo "Generating config.."
	$(MAKE) CC="$(CC)" CXX="$(CXX)" STATIC=$(STATIC) -f Makefile.config
	$(PRE_Q)rm -f core-config.c

makeconfig: config.h

#
#  generate apparmor data using minimal core utils tools from apparmor
#  parser output
#
apparmor-data.o: usr.bin.pulseaudio.eg config.h
	$(PRE_Q)rm -f apparmor-data.bin
	$(PRE_V)if [ -n "$(shell grep '^#define HAVE_APPARMOR' config.h)" ]; then \
		echo "Generating AppArmor profile from usr.bin.pulseaudio.eg"; \
		$(APPARMOR_PARSER) -Q usr.bin.pulseaudio.eg  -o apparmor-data.bin >/dev/null 2>&1 ; \
	else \
		echo "Generating empty AppArmor profile"; \
		touch apparmor-data.bin; \
	fi
	$(PRE_V)echo "#include <stddef.h>" > apparmor-data.c
	$(PRE_V)echo "char g_apparmor_data[]= { " >> apparmor-data.c
	$(PRE_V)od -tx1 -An -v < apparmor-data.bin | \
		sed 's/[0-9a-f][0-9a-f]/0x&,/g' | \
		sed '$$ s/.$$//' >> apparmor-data.c
	$(PRE_V)echo "};" >> apparmor-data.c
	$(PRE_V)rm -f apparmor-data.bin
	$(PRE_V)echo "const size_t g_apparmor_data_len = sizeof(g_apparmor_data);" >> apparmor-data.c
	$(PRE_Q)echo "CC apparmor-data.c"
	$(PRE_V)$(CC) $(CFLAGS) -c apparmor-data.c -o apparmor-data.o
	$(PRE_V)rm -f apparmor-data.c

#
#  extract the PER_* personality enums
#
personality.h: config.h
	$(PRE_V)$(CPP) $(CFLAGS) $(SRC_CORE_DIR)/core-personality.c | $(GREP) -e "PER_[A-Z0-9]* =.*," | cut -d "=" -f 1 \
	| sed "s/.$$/,/" > personality.h
	$(PRE_Q)echo "MK personality.h"

$(SRC_STRESS_DIR)/stress-personality.c: personality.h

#
#  extract IORING_OP enums and #define HAVE_ prefixed values
#  so we can check if these enums exist
#
io-uring.h: config.h
	$(PRE_V)$(CPP) $(CFLAGS) $(SRC_CORE_DIR)/core-io-uring.c  | $(GREP) IORING_OP | sed 's/,//' | \
	sed 's/.*\(IORING_OP_.*\)/#define HAVE_\1/' > io-uring.h
	$(PRE_Q)echo "MK io-uring.h"

$(SRC_STRESS_DIR)/stress-io-uring.c: io-uring.h

$(SRC_CORE_DIR)/core-perf.o: $(SRC_CORE_DIR)/core-perf.c $(SRC_CORE_DIR)/core-perf-event.c config.h
	$(PRE_V)$(CC) $(CFLAGS) -E $(SRC_CORE_DIR)/core-perf-event.c | $(GREP) "PERF_COUNT" | \
	sed 's/,/ /' | sed s/'^ *//' | \
	awk {'print "#define STRESS_" $$1 " (1)"'} > core-perf-event.h
	$(PRE_Q)echo CC $<
	$(PRE_V)$(CC) $(CFLAGS) -c -o $@ $<

core-config.c: config.h
	$(PRE_V)echo "const char stress_config[] = " > core-config.c
	$(PRE_V)sed 's/.*/"&\\n"/' config.h >> core-config.c
	$(PRE_V)echo ";" >> core-config.c

$(SRC_STRESS_DIR)/stress-vecmath.o: $(SRC_STRESS_DIR)/stress-vecmath.c config.h
	$(PRE_Q)echo CC $<
	$(PRE_V)$(CC) $(CFLAGS) -fno-builtin -c -o $@ $<

#
#  define STRESS_GIT_COMMIT_ID
#
git-commit-id.h:
	$(PRE_Q)echo "MK $@"
	@if [ -e .git/HEAD -a -e .git/index ]; then \
		echo "#define STRESS_GIT_COMMIT_ID \"$(shell git rev-parse HEAD)\"" > $@ ; \
	else \
		echo "#define STRESS_GIT_COMMIT_ID \"\"" > $@ ; \
	fi

$(OBJS): $(SRC_INC_DIR)/stress-ng.h Makefile Makefile.config

stress-ng.1.gz: stress-ng.1
	$(PRE_V)gzip -n -c $< > $@

.PHONY: dist
dist:
	rm -rf stress-ng-$(VERSION)
	mkdir stress-ng-$(VERSION)
	cp -rp Makefile Makefile.config $(CORE_SRC) $(STRESS_SRC) $(HEADERS) \
		stress-ng.1 COPYING syscalls.txt mascot README.md Dockerfile \
		README.Android test presentations .github TODO \
		$(SRC_CORE_DIR)/core-perf-event.c usr.bin.pulseaudio.eg $(SRC_STRESS_DIR)/stress-eigen-ops.c \
		$(SRC_STRESS_DIR)/stress-eigen-ops.cpp $(SRC_CORE_DIR)/core-personality.c bash-completion \
		example-jobs .travis.yml kernel-coverage.sh \
		code-of-conduct.txt stress-ng-$(VERSION)
	tar -Jcf stress-ng-$(VERSION).tar.xz stress-ng-$(VERSION)
	rm -rf stress-ng-$(VERSION)

.PHONY: pdf
pdf:
	man -t ./stress-ng.1 | ps2pdf - > stress-ng.pdf

.PHONY: cleanconfig
cleanconfig:
	$(PRE_V)rm -f config config.h core-config.c
	$(PRE_V)rm -rf configs

.PHONY: cleanobj
cleanobj:
	$(PRE_V)rm -f core-config.c
	$(PRE_V)rm -f io-uring.h
	$(PRE_V)rm -f git-commit-id.h
	$(PRE_V)rm -f core-perf-event.h
	$(PRE_V)rm -f personality.h
	$(PRE_V)rm -f apparmor-data.bin
	$(PRE_V)rm -f *.o

.PHONY: clean
clean: cleanconfig cleanobj
	$(PRE_V)rm -f stress-ng $(OBJS) stress-ng.1.gz stress-ng.pdf
	$(PRE_V)rm -f stress-ng-$(VERSION).tar.xz
	$(PRE_V)rm -f tags

.PHONY: fast-test-all
fast-test-all: all
	STRESS_NG=./stress-ng debian/tests/fast-test-all

.PHONY: lite-test
lite-test: all
	STRESS_NG=./stress-ng debian/tests/lite-test

.PHONY: slow-test-all
slow-test-all: all
	./stress-ng --seq 0 -t 15 --pathological --times --tz --metrics --klog-check --progress --cache-enable-all || true

.PHONY: verify-test-all
verify-test-all: all
	./stress-ng --seq 0 -t 5 --pathological --times --tz --metrics --verify --progress --cache-enable-all || true

.PHONY: tags
tags:
	ctags -R --extra=+f --c-kinds=+p *

.PHONY: install
install: stress-ng stress-ng.1.gz
	mkdir -p ${DESTDIR}${BINDIR}
	cp stress-ng ${DESTDIR}${BINDIR}
	mkdir -p ${DESTDIR}${MANDIR}
ifneq ($(MAN_COMPRESS),0)
	cp stress-ng.1.gz ${DESTDIR}${MANDIR}
else
	cp stress-ng.1 ${DESTDIR}${MANDIR}
endif
	mkdir -p ${DESTDIR}${JOBDIR}
	cp -r example-jobs/*.job ${DESTDIR}${JOBDIR}
	mkdir -p ${DESTDIR}${BASHDIR}
	cp bash-completion/stress-ng ${DESTDIR}${BASHDIR}

.PHONY: uninstall
uninstall:
	rm -f ${DESTDIR}${BINDIR}/stress-ng
	rm -f ${DESTDIR}${MANDIR}/stress-ng.1.gz
	rm -f ${DESTDIR}${MANDIR}/stress-ng.1
	rm -f ${DESTDIR}${JOBDIR}/*.job
	rm -f ${DESTDIR}${BASHDIR}/stress-ng

