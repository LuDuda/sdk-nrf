/*
 * Copyright (c) 2026 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

/*
 * On-hardware functional test for the RAM power-down library.
 *
 * The test runs across a software reset:
 *  - On the initial boot it powers unused RAM down and back up, keeps using RAM
 *    in between, then reboots while unused RAM is powered down.
 *  - On the boot that follows the reboot it verifies that the device came back
 *    up (i.e. RAM was restored on reboot) and that RAM is still usable.
 *
 * A console harness checks the printed sequence, so the test also fails if the
 * device crashes (bus fault on powered-down RAM) or fails to boot after reset.
 */

#include <zephyr/kernel.h>
#include <zephyr/sys/reboot.h>
#include <zephyr/sys/util.h>

#include <ram_pwrdn.h>

#define REBOOT_MARKER 0x5A11EDA7u

/* Lives inside the application image, so it is always powered. */
static volatile uint32_t work_buf[256];

/* Uninitialized RAM that keeps its value across a software reset (warm reset
 * does not clear RAM), used to detect the boot following our reboot.
 */
static __noinit uint32_t reboot_marker;

static void exercise_ram(void)
{
	uint32_t sum = 0;

	for (size_t i = 0; i < ARRAY_SIZE(work_buf); ++i) {
		work_buf[i] = (uint32_t)(i * 7u + 1u);
	}

	for (size_t i = 0; i < ARRAY_SIZE(work_buf); ++i) {
		sum += work_buf[i];
	}

	printk("ram_pwrdn: RAM check sum=%u\n", sum);
}

int main(void)
{
	if (reboot_marker == REBOOT_MARKER) {
		reboot_marker = 0;
		printk("ram_pwrdn: boot after reboot\n");
		exercise_ram();
		printk("ram_pwrdn: RAM access after reboot OK\n");
		printk("ram_pwrdn: TEST PASS\n");
		return 0;
	}

	printk("ram_pwrdn: initial boot\n");
	exercise_ram();

	power_down_unused_ram();
	printk("ram_pwrdn: powered down unused RAM\n");
	exercise_ram();
	printk("ram_pwrdn: RAM access after power-down OK\n");

	power_up_unused_ram();
	printk("ram_pwrdn: powered up unused RAM\n");
	exercise_ram();
	printk("ram_pwrdn: RAM access after power-up OK\n");

	/* Reboot while unused RAM is powered down to verify that it is
	 * restored automatically before the reset takes effect.
	 */
	reboot_marker = REBOOT_MARKER;
	power_down_unused_ram();
	printk("ram_pwrdn: rebooting with RAM powered down\n");
	k_msleep(100);
	sys_reboot(SYS_REBOOT_COLD);

	return 0;
}
