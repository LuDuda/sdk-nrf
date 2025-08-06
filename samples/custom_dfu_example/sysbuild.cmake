#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

# Sysbuild configuration for custom DFU example
# This file demonstrates how to use dfu_add_custom_binary() to add custom images

message(STATUS "=== APPLICATION SYSBUILD.CMAKE STARTED ===")
message(STATUS "APP_DIR = ${APP_DIR}")
message(STATUS "CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}")

# Enable MCUboot as bootloader
set(SB_CONFIG_BOOTLOADER_MCUBOOT TRUE)

# Enable custom DFU binaries support
set(SB_CONFIG_DFU_CUSTOM_BINARIES TRUE)
set(SB_CONFIG_DFU_CUSTOM_MULTI_IMAGE TRUE)
set(SB_CONFIG_DFU_CUSTOM_ZIP TRUE)

# Configure MCUboot settings for multi-image support
set(SB_CONFIG_MCUBOOT_SIGNATURE_KEY_FILE "${ZEPHYR_NRF_MODULE_DIR}/modules/mcuboot/root-rsa-2048.pem")

# Enable image signing for DFU
ExternalZephyrProject_Add(
    APPLICATION mcuboot
    SOURCE_DIR ${ZEPHYR_MCUBOOT_MODULE_DIR}/boot/zephyr
    BOARD ${SB_CONFIG_BOARD}
)

# Configure the main application image
set_config_bool(${DEFAULT_IMAGE} CONFIG_BOOTLOADER_MCUBOOT y)
set_config_bool(${DEFAULT_IMAGE} CONFIG_MCUBOOT_SIGNATURE_KEY_FILE "${ZEPHYR_NRF_MODULE_DIR}/modules/mcuboot/root-rsa-2048.pem")

# Enable DFU support in the application
set_config_bool(${DEFAULT_IMAGE} CONFIG_IMG_MANAGER y)
set_config_bool(${DEFAULT_IMAGE} CONFIG_MCUBOOT_IMG_MANAGER y)
set_config_bool(${DEFAULT_IMAGE} CONFIG_IMG_ENABLE_IMAGE_CHECK y)

# Configure logging for better debugging
set_config_bool(${DEFAULT_IMAGE} CONFIG_LOG y)
set_config_bool(${DEFAULT_IMAGE} CONFIG_LOG_DEFAULT_LEVEL 3)

# Example 1: Add external MCU firmware if it exists
set(external_mcu_fw "${CMAKE_SOURCE_DIR}/external_binaries/mcu_firmware.bin")
if(EXISTS ${external_mcu_fw})
    # Create a dummy target for the external binary (it already exists)
    add_custom_target(external_mcu_target
        DEPENDS ${external_mcu_fw}
        COMMENT "External MCU firmware dependency"
    )
    
    dfu_add_custom_binary(
        BINARY_ID 15
        BINARY_PATH ${external_mcu_fw}
        ZIP_NAME "external_mcu.bin"
        ZIP_SLOT_ID 3
        DEPENDS external_mcu_target
    )
    message(STATUS "Added external MCU firmware to DFU packages")
endif()

# Example 2: Create and add a custom sensor firmware
set(sensor_fw_dir "${CMAKE_BINARY_DIR}/sensor_firmware")
set(sensor_fw_bin "${sensor_fw_dir}/sensor_fw.bin")

# Create directory for sensor firmware
file(MAKE_DIRECTORY ${sensor_fw_dir})

# Create a custom command to build sensor firmware (simulate with copy)
add_custom_command(
    OUTPUT ${sensor_fw_bin}
    COMMAND ${CMAKE_COMMAND} -E echo "Building sensor firmware..."
    COMMAND ${CMAKE_COMMAND} -E copy 
        $<TARGET_FILE_DIR:${DEFAULT_IMAGE}>/zephyr/zephyr.bin 
        ${sensor_fw_bin}
    COMMENT "Creating sensor firmware binary"
    DEPENDS ${DEFAULT_IMAGE}
)

add_custom_target(sensor_firmware_target
    DEPENDS ${sensor_fw_bin}
)

dfu_add_custom_binary(
    BINARY_ID 20
    BINARY_PATH ${sensor_fw_bin}
    ZIP_NAME "sensor_fw.bin"
    ZIP_SLOT_ID 1
    DEPENDS sensor_firmware_target
)

# Example 3: Add configuration file as custom binary
set(config_file "${CMAKE_SOURCE_DIR}/device_config.json")
if(EXISTS ${config_file})
    add_custom_target(config_target
        DEPENDS ${config_file}
        COMMENT "Device configuration file"
    )
    
    dfu_add_custom_binary(
        BINARY_ID 25
        BINARY_PATH ${config_file}
        ZIP_NAME "device_config.json"
        ZIP_SLOT_ID 2
        DEPENDS config_target
    )
endif()

# Post-build information display
function(show_dfu_info)
    message(STATUS "=== DFU Package Information ===")
    message(STATUS "Multi-image output: ${CMAKE_BINARY_DIR}/dfu_multi_image.bin")
    message(STATUS "ZIP output: ${CMAKE_BINARY_DIR}/dfu_application.zip")
    message(STATUS "Custom binaries will be included if SB_CONFIG_DFU_CUSTOM_* options are enabled")
    message(STATUS "Use dfu_add_custom_binary() to add more custom images")
endfunction()

# Show info after build
cmake_language(DEFER CALL show_dfu_info)

message(STATUS "=== APPLICATION SYSBUILD.CMAKE FINISHED ===")
message(STATUS "APP: Registered custom binaries during application sysbuild processing")
