/*
 * Copyright (c) 2024 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(external_mcu, LOG_LEVEL_INF);

int main(void)
{
	LOG_INF("External MCU Image (DFU ID: 21)");
	LOG_INF("This image will be automatically detected and included in DFU packages");

	while (1) {
		LOG_INF("External MCU running...");
		k_sleep(K_SECONDS(7));
	}

	return 0;
}