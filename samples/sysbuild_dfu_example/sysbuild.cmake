#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

# Example: Add custom sysbuild images that will be automatically detected for DFU

# Add a custom sensor controller image
if(SB_CONFIG_SENSOR_CONTROLLER_IMAGE)
    ExternalZephyrProject_Add(
        APPLICATION sensor_controller
        SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/sensor_controller
        BOARD ${BOARD}
    )
endif()

# Add a custom external MCU image  
if(SB_CONFIG_EXTERNAL_MCU_IMAGE)
    ExternalZephyrProject_Add(
        APPLICATION external_mcu
        SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/external_mcu
        BOARD ${BOARD}
    )
endif()