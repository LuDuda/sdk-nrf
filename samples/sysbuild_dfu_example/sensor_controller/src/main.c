/*
 * Copyright (c) 2024 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(sensor_controller, LOG_LEVEL_INF);

int main(void)
{
	LOG_INF("Sensor Controller Image (DFU ID: 20)");
	LOG_INF("This image will be automatically detected and included in DFU packages");

	while (1) {
		LOG_INF("Sensor controller running...");
		k_sleep(K_SECONDS(5));
	}

	return 0;
}