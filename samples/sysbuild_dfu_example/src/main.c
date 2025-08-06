/*
 * Copyright (c) 2024 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(sysbuild_dfu_example, LOG_LEVEL_INF);

int main(void)
{
	LOG_INF("Sysbuild DFU Example");
	LOG_INF("This demonstrates automatic detection of sysbuild images for DFU");
	LOG_INF("Check build output for dfu_multi_image.bin and dfu_application.zip");
	LOG_INF("with automatically detected custom images");

	while (1) {
		LOG_INF("Main application running...");
		k_sleep(K_SECONDS(10));
	}

	return 0;
}