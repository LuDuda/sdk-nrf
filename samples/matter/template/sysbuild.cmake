#
# Copyright (c) 2024 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

# Only apply extra image configuration when enabled via sysbuild config
if(SB_CONFIG_DFU_EXTRA_BINARIES)
    # Include the extra DFU system
    include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_extra.cmake)

    # Create a simple 512B external image
    set(ext_img_path "${CMAKE_BINARY_DIR}/ext_img.bin")
    set(ext_img_signed_path "${CMAKE_BINARY_DIR}/ext_img.signed.bin")
    set(ext_img_signed_hex_path "${CMAKE_BINARY_DIR}/ext_img.signed.hex")

    # Generate test binary file directly using file(WRITE)
    set(pattern "abcd")
    set(content "")
    foreach(i RANGE 127)
        string(APPEND content "${pattern}")
    endforeach()
    file(WRITE ${ext_img_path} "${content}")
    
    add_custom_command(
        OUTPUT ${ext_img_path}
        COMMAND ${CMAKE_COMMAND} -E touch ${ext_img_path}
    )
    
    # Create build target for the external binary
    add_custom_target(ext_img_target
        DEPENDS ${ext_img_path}
    )

    # Find imgtool for signing
    find_program(IMGTOOL imgtool.py HINTS ${ZEPHYR_MCUBOOT_MODULE_DIR}/scripts/ NAMES imgtool NAMES_PER_DIR)
    if(NOT IMGTOOL)
        message(FATAL_ERROR "Cannot find imgtool for signing external image")
    endif()

    # Create signed version of the external image using imgtool
    add_custom_command(
        OUTPUT ${ext_img_signed_path}
        COMMAND ${PYTHON_EXECUTABLE} ${IMGTOOL} sign
            --version "1.0.1"
            --align 4
            --header-size ${SB_CONFIG_PM_MCUBOOT_PAD}
            --slot-size $<TARGET_PROPERTY:partition_manager,PM_EXT_IMG_SIZE>
            --pad-header
            -k ${SB_CONFIG_BOOT_SIGNATURE_KEY_FILE}
            ${ext_img_path} ${ext_img_signed_path}
        DEPENDS ${ext_img_path}
        COMMENT "Signing external image (generate ${ext_img_signed_path})"
    )
    
    add_custom_target(ext_img_signed_target
        DEPENDS ${ext_img_signed_path}
        COMMENT "Signed external image target"
    )
    
    # Add extra binary to both multi-image and ZIP packages
    dfu_add_extra_binary(
        MULTI_IMAGE_ID 10          # For dfu_multi_image.bin
        MCUBOOT_IMAGE_ID 2         # For ZIP packages and MCUboot slots
        BINARY_PATH ${ext_img_signed_path}
        ZIP_NAME "ext_img.bin"
        DEPENDS ext_img_signed_target
    )

    set(qspi_xip_address 0x10000000)

    add_custom_command(
        OUTPUT ${ext_img_signed_hex_path}
        COMMAND ${PYTHON_EXECUTABLE}
            -c "import sys; import intelhex; intelhex.bin2hex(sys.argv[1], sys.argv[2], int(sys.argv[3], 16) + int(sys.argv[4], 16))"
            ${ext_img_signed_path}
            ${ext_img_signed_hex_path}
            $<TARGET_PROPERTY:partition_manager,PM_EXT_IMG_OFFSET>
            ${qspi_xip_address}
        DEPENDS ${ext_img_signed_path}
        VERBATIM
        COMMENT "Converting signed binary to HEX (${ext_img_signed_hex_path})"
        )

    add_custom_target(ext_img_signed_hex_target ALL
        DEPENDS ${ext_img_signed_hex_path}
        COMMENT "Generate ${ext_img_signed_hex_path}"
    )

    # Merge external firmware hex
    set_property(GLOBAL PROPERTY ext_img_PM_HEX_FILE ${ext_img_signed_hex_path})
    set_property(GLOBAL PROPERTY ext_img_PM_TARGET ext_img_signed_hex_target)
endif()
