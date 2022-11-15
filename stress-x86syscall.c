/*
 * Copyright (C) 2013-2021 Canonical, Ltd.
 * Copyright (C)      2022 Colin Ian King.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 */
#include "stress-ng.h"
#include "core-arch.h"
#include "core-cpu.h"

static const stress_help_t help[] = {
	{ NULL,	"x86syscall N",		"start N workers exercising functions using syscall" },
	{ NULL,	"x86syscall-func F",	"use just syscall function F" },
	{ NULL,	"x86syscall-ops N",	"stop after N syscall function calls" },
	{ NULL,	NULL,			NULL }
};

/*
 *  stress_set_x86syscall_func()
 *      set the default x86syscall function
 */
static int stress_set_x86syscall_func(const char *name)
{
	return stress_set_setting("x86syscall-func", TYPE_ID_STR, name);
}

static const stress_opt_set_func_t opt_set_funcs[] = {
	{ OPT_x86syscall_func,	stress_set_x86syscall_func },
	{ 0,			NULL }
};

#if defined(__linux__) &&		\
    !defined(__PCC__) &&		\
    defined(STRESS_ARCH_X86_64)

typedef int (*stress_wfunc_t)(void);

/*
 *  syscall symbol mapping name to address and wrapper function
 */
typedef struct stress_x86syscall {
	const stress_wfunc_t func;	/* Wrapper function */
	const char *name;	/* Function name */
	bool exercise;		/* True = exercise the syscall */
} stress_x86syscall_t;

/*
 *  stress_x86syscall_supported()
 *	check if tsc is supported
 */
static int stress_x86syscall_supported(const char *name)
{
	/* Intel CPU? */
	if (!stress_cpu_is_x86()) {
		pr_inf_skip("%s stressor will be skipped, "
			"not a recognised Intel CPU\n", name);
		return -1;
	}
	/* ..and supports syscall? */
	if (!stress_cpu_x86_has_syscall()) {
		pr_inf_skip("%s stressor will be skipped, CPU "
			"does not support the syscall instruction\n", name);
		return -1;
	}

#if defined(__NR_getcpu) ||		\
    defined(__NR_gettimeofday) ||	\
    defined(__NR_time)
	return 0;
#else
	pr_inf_skip("%s: stressor will be skipped, no definitions for __NR_getcpu, __NR_gettimeofday or __NR_time\n", name);
	return -1;
#endif
}

/*
 *  x86_64_syscall1()
 *	syscall 1 arg wrapper
 */
static inline long x86_64_syscall1(long number, long arg1)
{
	long ret;
	long tmp_arg1 = arg1;
	register long asm_arg1 __asm__("rdi") = tmp_arg1;

	__asm__ __volatile__("syscall\n\t"
			: "=a" (ret)
			: "0" (number), "r" (asm_arg1)
			: "memory", "cc", "r11", "cx");
	if (ret < 0) {
		errno = (int)ret;
		ret = -1;
	}
	return ret;
}

/*
 *  x86_64_syscall2()
 *	syscall 2 arg wrapper
 */
static inline long x86_64_syscall2(long number, long arg1, long arg2)
{
	long ret;
	long tmp_arg1 = arg1;
	long tmp_arg2 = arg2;
	register long asm_arg1 __asm__("rdi") = tmp_arg1;
	register long asm_arg2 __asm__("rsi") = tmp_arg2;

	__asm__ __volatile__("syscall\n\t"
			: "=a" (ret)
			: "0" (number), "r" (asm_arg1), "r" (asm_arg2)
			: "memory", "cc", "r11", "cx");
	if (ret < 0) {
		errno = (int)ret;
		ret = -1;
	}
	return ret;
}

/*
 *  x86_64_syscall3()
 *	syscall 3 arg wrapper
 */
static inline long x86_64_syscall3(long number, long arg1, long arg2, long arg3)
{
	long ret;
	long tmp_arg1 = arg1;
	long tmp_arg2 = arg2;
	long tmp_arg3 = arg3;
	register long asm_arg1 __asm__("rdi") = tmp_arg1;
	register long asm_arg2 __asm__("rsi") = tmp_arg2;
	register long asm_arg3 __asm__("rdx") = tmp_arg3;

	__asm__ __volatile__("syscall\n\t"
			: "=a" (ret)
			: "0" (number), "r" (asm_arg1), "r" (asm_arg2), "r" (asm_arg3)
			: "memory", "cc", "r11", "cx");
	if (ret < 0) {
		errno = (int)ret;
		ret = -1;
	}
	return ret;
}

#if defined(__NR_getcpu)
/*
 *  wrap_getcpu()
 *	invoke getcpu()
 */
static int wrap_getcpu(void)
{
	unsigned cpu, node;

	return (int)x86_64_syscall3(__NR_getcpu, (long)&cpu, (long)&node, (long)NULL);
}
#endif

#if defined(__NR_gettimeofday)
/*
 *  wrap_gettimeofday()
 *	invoke gettimeofday()
 */
static int wrap_gettimeofday(void)
{
	struct timeval tv;

	return (int)x86_64_syscall2(__NR_gettimeofday, (long)&tv, (long)NULL);
}
#endif

#if defined(__NR_time)
/*
 *  wrap_time()
 *	invoke time()
 */
static int wrap_time(void)
{
	time_t t;

	return (int)x86_64_syscall1(__NR_time, (long)&t);
}
#endif

/*
 *  wrap_dummy()
 *	dummy empty function for baseline
 */
static int wrap_dummy(void)
{
	int ret = -1;

	return ret;
}

/*
 *  mapping of wrappers to function symbol name
 */
static stress_x86syscall_t x86syscalls[] = {
#if defined(__NR_getcpu)
	{ wrap_getcpu,		"getcpu",		true },
#endif
#if defined(__NR_gettimeofday)
	{ wrap_gettimeofday,	"gettimeofday",		true },
#endif
#if defined(__NR_time)
	{ wrap_time,		"time",			true },
#endif
	/* Null entry is ignored */
	{ NULL,			NULL,			false },
};

/*
 *  mapping of wrappers for instrumentation measurement,
 *  MUST NOT be static to avoid optimizer from removing the
 *  indirect calls
 */
stress_x86syscall_t dummy_x86syscalls[] = {
	{ wrap_dummy,		"dummy",		true },
};

/*
 *  x86syscall_list_str()
 *	gather symbol names into a string
 */
static char *x86syscall_list_str(void)
{
	char *str = NULL;
	size_t i, len = 0;

	for (i = 0; x86syscalls[i].name; i++) {
		if (x86syscalls[i].exercise) {
			char *tmp;

			len += (strlen(x86syscalls[i].name) + 2);
			tmp = realloc(str, len);
			if (!tmp) {
				free(str);
				return NULL;
			}
			if (!str) {
				*tmp = '\0';
			} else {
				(void)strcat(tmp, " ");
			}
			(void)strcat(tmp, x86syscalls[i].name);
			str = tmp;
		}
	}
	return str;
}

/*
 *  x86syscall_check_x86syscall_func()
 *	if a x86syscall-func has been specified, locate it and
 *	mark it to be exercised.
 */
static int x86syscall_check_x86syscall_func(void)
{
	char *name;
	size_t i;
	bool exercise = false;

	if (!stress_get_setting("x86syscall-func", &name))
		return 0;

	for (i = 0; x86syscalls[i].name; i++) {
		const bool match = !strcmp(x86syscalls[i].name, name);

		exercise |= match;
		x86syscalls[i].exercise = match;
	}

	if (!exercise) {
		(void)fprintf(stderr, "invalid x86syscall-func '%s', must be one of:", name);
		for (i = 0; x86syscalls[i].name; i++)
			(void)fprintf(stderr, " %s", x86syscalls[i].name);
		(void)fprintf(stderr, "\n");
		return -1;
	}
	return 0;
}

/*
 *  stress_x86syscall()
 *	stress x86 syscall instruction
 */
static int stress_x86syscall(const stress_args_t *args)
{
	double t1, t2, t3, dt, overhead_ns;
	uint64_t counter;

	if (x86syscall_check_x86syscall_func() < 0)
		return EXIT_FAILURE;

	if (args->instance == 0) {
		char *str = x86syscall_list_str();

		if (str) {
			pr_inf("%s: exercising syscall on: %s\n",
				args->name, str);
			free(str);
		}
	}

	stress_set_proc_state(args->name, STRESS_STATE_RUN);

	t1 = stress_time_now();
	do {
		register size_t i;

		for (i = 0; x86syscalls[i].name; i++) {
			if (x86syscalls[i].exercise) {
				x86syscalls[i].func();
				inc_counter(args);
			}
		}
	} while (keep_stressing(args));
	t2 = stress_time_now();

	/*
	 *  And spend 1/10th of a second measuring overhead of
	 *  the test framework
	 */
	counter = get_counter(args);
	do {
		register int j;

		for (j = 0; j < 1000000; j++) {
			if (dummy_x86syscalls[0].exercise) {
				dummy_x86syscalls[0].func();
				inc_counter(args);
			}
		}
		t3 = stress_time_now();
	} while (t3 - t2 < 0.1);

	overhead_ns = (double)STRESS_NANOSECOND * ((t3 - t2) / (double)(get_counter(args) - counter));
	set_counter(args, counter);

	dt = t2 - t1;
	if (dt > 0.0) {
		const uint64_t c = get_counter(args);
		const double ns = ((dt * (double)STRESS_NANOSECOND) / (double)c) - overhead_ns;

		pr_inf("%s: %.2f nanosecs per call (excluding %.2f nanosecs test overhead)\n",
			args->name, ns, overhead_ns);
		stress_misc_stats_set(args->misc_stats, 0, "nanosecs per call", ns);
	}

	stress_set_proc_state(args->name, STRESS_STATE_DEINIT);

	return EXIT_SUCCESS;
}

stressor_info_t stress_x86syscall_info = {
	.stressor = stress_x86syscall,
	.class = CLASS_OS,
	.supported = stress_x86syscall_supported,
	.opt_set_funcs = opt_set_funcs,
	.help = help
};
#else
stressor_info_t stress_x86syscall_info = {
	.stressor = stress_not_implemented,
	.class = CLASS_OS,
	.opt_set_funcs = opt_set_funcs,
	.help = help,
	.unimplemented_reason = "only supported on Linux x86-64 and non-PCC compilers"
};
#endif
