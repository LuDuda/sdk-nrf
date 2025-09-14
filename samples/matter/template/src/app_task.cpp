/*
 * Copyright (c) 2021 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include "app_task.h"

#include "app/matter_init.h"
#include "app/task_executor.h"
#include "board/board.h"
#include "lib/core/CHIPError.h"
#include "lib/support/CodeUtils.h"

#include <setup_payload/OnboardingCodesUtil.h>

#include <zephyr/logging/log.h>

#include <zephyr/storage/flash_map.h>
#include <zephyr/drivers/flash.h>

LOG_MODULE_DECLARE(app, CONFIG_CHIP_APP_LOG_LEVEL);

using namespace ::chip;
using namespace ::chip::app;
using namespace ::chip::DeviceLayer;

static void PrintExternalImageData()
{
	const struct flash_area *fa;
	int ret = flash_area_open(FLASH_AREA_ID(ext_img), &fa);
	if (ret != 0) {
		LOG_ERR("Failed to open external image partition: %d", ret);
		return;
	}

	uint8_t buffer[512];
	ret = flash_area_read(fa, 0, buffer, sizeof(buffer));
	if (ret != 0) {
		LOG_ERR("Failed to read external image partition: %d", ret);
		flash_area_close(fa);
		return;
	}

	LOG_INF("External image data (first 512 bytes):");
	for (int i = 0; i < 512; i += 16) {
		LOG_INF("%04x: %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x",
			i,
			buffer[i], buffer[i+1], buffer[i+2], buffer[i+3],
			buffer[i+4], buffer[i+5], buffer[i+6], buffer[i+7],
			buffer[i+8], buffer[i+9], buffer[i+10], buffer[i+11],
			buffer[i+12], buffer[i+13], buffer[i+14], buffer[i+15]);
	}

	flash_area_close(fa);
}

CHIP_ERROR AppTask::Init()
{
	/* Initialize Matter stack */
	ReturnErrorOnFailure(Nrf::Matter::PrepareServer());

	if (!Nrf::GetBoard().Init()) {
		LOG_ERR("User interface initialization failed.");
		return CHIP_ERROR_INCORRECT_STATE;
	}

	/* Print external image data on boot */
	PrintExternalImageData();

	/* Register Matter event handler that controls the connectivity status LED based on the captured Matter network
	 * state. */
	ReturnErrorOnFailure(Nrf::Matter::RegisterEventHandler(Nrf::Board::DefaultMatterEventHandler, 0));

	return Nrf::Matter::StartServer();
}

CHIP_ERROR AppTask::StartApp()
{
	ReturnErrorOnFailure(Init());

	while (true) {
		Nrf::DispatchNextTask();
	}

	return CHIP_NO_ERROR;
}
