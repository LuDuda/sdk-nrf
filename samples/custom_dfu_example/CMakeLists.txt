#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(custom_dfu_example)

target_sources(app PRIVATE src/main.c)

# Example: Add custom images to DFU multi-image package
# This demonstrates how applications can extend the DFU package with custom firmware

# Create a dummy custom firmware binary for demonstration
# In a real application, this would be your actual custom firmware build
add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/custom_sensor_fw.bin
  COMMAND ${CMAKE_COMMAND} -E echo "Custom sensor firmware placeholder" > ${CMAKE_BINARY_DIR}/custom_sensor_fw.txt
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/custom_sensor_fw.txt ${CMAKE_BINARY_DIR}/custom_sensor_fw.bin
  COMMENT "Generating custom sensor firmware (placeholder)"
)

add_custom_target(custom_sensor_fw_target
  DEPENDS ${CMAKE_BINARY_DIR}/custom_sensor_fw.bin
)

# Create another dummy custom firmware for external MCU
add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/external_mcu_fw.bin
  COMMAND ${CMAKE_COMMAND} -E echo "External MCU firmware placeholder" > ${CMAKE_BINARY_DIR}/external_mcu_fw.txt
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/external_mcu_fw.txt ${CMAKE_BINARY_DIR}/external_mcu_fw.bin
  COMMENT "Generating external MCU firmware (placeholder)"
)

add_custom_target(external_mcu_fw_target
  DEPENDS ${CMAKE_BINARY_DIR}/external_mcu_fw.bin
)

# Add custom images to DFU packages (both multi-image and ZIP)
# Note: This will only work if SB_CONFIG_DFU_MULTI_IMAGE_PACKAGE_CUSTOM is enabled

if(CONFIG_DFU_MULTI_IMAGE)
  message(STATUS "Adding custom images to DFU packages (multi-image and ZIP)")
  
  # Add custom sensor firmware with ID 20
  dfu_add_custom_image(
    IMAGE_ID 20
    IMAGE_PATH "${CMAKE_BINARY_DIR}/custom_sensor_fw.bin"
    ZIP_NAME "sensor_fw.bin"
    MCUBOOT_IMAGE_NUMBER 20
    DEPENDS custom_sensor_fw_target
  )

  # Add external MCU firmware with ID 21  
  dfu_add_custom_image(
    IMAGE_ID 21
    IMAGE_PATH "${CMAKE_BINARY_DIR}/external_mcu_fw.bin"
    ZIP_NAME "external_mcu.bin"
    MCUBOOT_IMAGE_NUMBER 21
    DEPENDS external_mcu_fw_target
  )

  message(STATUS "Custom DFU images configured:")
  message(STATUS "  - Sensor firmware: ID 20 -> sensor_fw.bin")
  message(STATUS "  - External MCU firmware: ID 21 -> external_mcu.bin")
  message(STATUS "  - Images will be included in both multi-image binary and ZIP packages")
endif()