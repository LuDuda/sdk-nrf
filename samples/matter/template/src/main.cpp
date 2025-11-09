/*
 * Copyright (c) 2021 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include "app_task.h"

#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(app, CONFIG_CHIP_APP_LOG_LEVEL);


#include <zephyr/kernel.h>
#include <zephyr/storage/flash_map.h>
#include <pm_config.h>
#include <bootutil/bootutil_public.h>
#include <bootutil/image.h>

static void print_image_content(const char *name, uint32_t img_id,
				uint32_t img_address, uint32_t slot_size)
{
	uint8_t buffer[16];
	const struct flash_area *fa;
	struct image_header hdr;
	uint32_t img_size;
	int ret;

	printk("\n=== %s ===\n", name);
	printk("Slot: 0x%08x (%u bytes)\n", img_address, slot_size);

	ret = flash_area_open(img_id, &fa);
	if (ret != 0) {
		printk("Failed to open flash area\n");
		return;
	}

	ret = boot_image_load_header(fa, &hdr);
	if (ret != 0) {
		printk("No valid MCUboot image found\n");
		flash_area_close(fa);
		return;
	}

	if (hdr.ih_magic != IMAGE_MAGIC) {
		printk("Invalid image magic: 0x%08x\n", hdr.ih_magic);
		flash_area_close(fa);
		return;
	}

	img_size = hdr.ih_img_size;
	printk("Version: %u.%u.%u+%u\n",
	       hdr.ih_ver.iv_major, hdr.ih_ver.iv_minor,
	       hdr.ih_ver.iv_revision, hdr.ih_ver.iv_build_num);
	printk("Image size: %u bytes\n", img_size);
	printk("\nContent (first 512B and last 512B):\n");

	uint32_t bytes_to_show = 512;
	uint32_t offset = hdr.ih_hdr_size;

	if (img_size <= 1024) {
		bytes_to_show = img_size;
	}

	uint32_t sections = (img_size <= 1024) ? 1 : 2;

	for (uint32_t s = 0; s < sections; s++) {
		uint32_t start_offset = offset;
		if (s == 1) {
			start_offset = hdr.ih_hdr_size + img_size - bytes_to_show;
			printk("\n... (skipped middle part) ...\n\n");
		}

		uint32_t bytes_read = 0;

		while (bytes_read < bytes_to_show) {
			uint32_t chunk_size = (bytes_to_show - bytes_read) < sizeof(buffer)
					      ? (bytes_to_show - bytes_read) : sizeof(buffer);

			memset(buffer, 0, sizeof(buffer));
			ret = flash_area_read(fa, start_offset + bytes_read, buffer, chunk_size);
			if (ret != 0) {
				printk("Failed to read flash at 0x%08x\n", start_offset + bytes_read);
				break;
			}

			printk("%06x: ", (start_offset - hdr.ih_hdr_size) + bytes_read);

			for (uint32_t i = 0; i < chunk_size; i++) {
				printk("%02x ", buffer[i]);
			}

			for (uint32_t i = chunk_size; i < 16; i++) {
				printk("   ");
			}

			printk(" |");
			for (uint32_t i = 0; i < chunk_size; i++) {
				char c = buffer[i];
				printk("%c", (c >= 32 && c <= 126) ? c : '.');
			}
			printk("|\n");

			bytes_read += chunk_size;
		}
	}

	flash_area_close(fa);
}

int main(void)
{
	printk("\n*** DFU Extra Images Test ***\n");

	print_image_content("Extra Image primary",
			    PM_MCUBOOT_PRIMARY_2_ID,
			    PM_MCUBOOT_PRIMARY_2_ADDRESS,
			    PM_MCUBOOT_PRIMARY_2_SIZE);

	print_image_content("Extra Image 1 secondary",
			    PM_MCUBOOT_SECONDARY_2_ID,
			    PM_MCUBOOT_SECONDARY_2_ADDRESS,
			    PM_MCUBOOT_SECONDARY_2_SIZE);

	CHIP_ERROR err = AppTask::Instance().StartApp();

	LOG_ERR("Exited with code %" CHIP_ERROR_FORMAT, err.Format());
	return err == CHIP_NO_ERROR ? EXIT_SUCCESS : EXIT_FAILURE;
}
