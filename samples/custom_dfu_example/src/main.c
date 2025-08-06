/*
 * Copyright (c) 2024 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(custom_dfu_example, LOG_LEVEL_INF);

int main(void)
{
	LOG_INF("Custom DFU Multi-Image Example");
	LOG_INF("This application demonstrates adding custom images to DFU packages");
	LOG_INF("Check the build output for dfu_multi_image.bin with custom images");

	while (1) {
		LOG_INF("Application running...");
		k_sleep(K_SECONDS(5));
	}

	return 0;
}