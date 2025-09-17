#
# Copyright (c) 2025 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

#
# DFU Extra Image extension - Improved version using CMake properties
#
# This file provides functions for adding extra images which are not natively
# integrated to nRF Connect SDK to the DFU packages.
# It supports both multi-image binaries and ZIP packages, allowing applications 
# to extend the built-in DFU functionality with additional extra firmware images.
#


#
# Add a extra binary to DFU packages (both multi-image binary and ZIP)
#
# Usage:
#   dfu_add_extra_binary(
#     [MULTI_IMAGE_ID <id>]
#     [MCUBOOT_IMAGE_ID <id>]
#     BINARY_PATH <path>
#     [ZIP_NAME <name>]
#     [DEPENDS <target1> [<target2> ...]]
#   )
#
# Parameters:
#   MULTI_IMAGE_ID        - Numeric identifier for multi-image binary packaging (signed integer)
#                          Used in dfu_multi_image.bin. User must ensure the ID is unique
#                          and doesn't conflict with built-in IDs.
#   MCUBOOT_IMAGE_ID      - MCUboot image identifier for ZIP packages (non-negative integer)
#                          Used for MCUboot slot calculations and ZIP package metadata.
#                          User must ensure that the ID is supported by MCUmgr image management. 
#   BINARY_PATH           - Path to the binary file to include in the package.
#   ZIP_NAME              - Optional name for the binary in ZIP packages (defaults to basename of BINARY_PATH)
#   DEPENDS               - Optional list of CMake targets that must be built before
#                          this extra binary is available
#
# Note: At least one of MULTI_IMAGE_ID or MCUBOOT_IMAGE_ID must be provided.
#
function(dfu_add_extra_binary)
    cmake_parse_arguments(EXTRA "" "MULTI_IMAGE_ID;MCUBOOT_IMAGE_ID;BINARY_PATH;ZIP_NAME" "DEPENDS" ${ARGN})

    # Validate required parameters
    if(NOT DEFINED EXTRA_BINARY_PATH)
        message(FATAL_ERROR "dfu_add_extra_binary: BINARY_PATH is required")
    endif()

    if(NOT DEFINED EXTRA_MULTI_IMAGE_ID AND NOT DEFINED EXTRA_MCUBOOT_IMAGE_ID)
        message(FATAL_ERROR "dfu_add_extra_binary: Either MULTI_IMAGE_ID or MCUBOOT_IMAGE_ID (or both) must be provided")
    endif()

    # Multi-Image ID validation (can be negative)
    if(DEFINED EXTRA_MULTI_IMAGE_ID)
        if(NOT EXTRA_MULTI_IMAGE_ID MATCHES "^-?[0-9]+$")
            message(FATAL_ERROR "dfu_add_extra_binary: MULTI_IMAGE_ID must be a signed integer, got: ${EXTRA_MULTI_IMAGE_ID}")
        endif()
        # Warn about potential conflicts with built-in IDs
        if(EXTRA_MULTI_IMAGE_ID GREATER_EQUAL -2 AND EXTRA_MULTI_IMAGE_ID LESS_EQUAL 2)
            message(WARNING "dfu_add_extra_binary: MULTI_IMAGE_ID ${EXTRA_MULTI_IMAGE_ID} may conflict with built-in IDs (-2 to 2)")
        endif()
    endif()

    # MCUboot ID validation (must be non-negative for slot calculations)
    if(DEFINED EXTRA_MCUBOOT_IMAGE_ID)
        if(NOT EXTRA_MCUBOOT_IMAGE_ID MATCHES "^[0-9]+$")
            message(FATAL_ERROR "dfu_add_extra_binary: MCUBOOT_IMAGE_ID must be a non-negative integer, got: ${EXTRA_MCUBOOT_IMAGE_ID}")
        endif()
    endif()

    # Set defaults for optional parameters
    if(NOT DEFINED EXTRA_ZIP_NAME)
        get_filename_component(EXTRA_ZIP_NAME ${EXTRA_BINARY_PATH} NAME)
    endif()

    # Prepare target list for dependencies
    set(target_list "${EXTRA_DEPENDS}")

    # Calculate MCUboot slots if MCUboot ID is provided
    if(DEFINED EXTRA_MCUBOOT_IMAGE_ID)
        math(EXPR slot_primary "${EXTRA_MCUBOOT_IMAGE_ID} * 2 + 1")
        math(EXPR slot_secondary "${EXTRA_MCUBOOT_IMAGE_ID} * 2 + 2")
    endif()

    # Use CMake global properties instead of files for cross-phase communication
    # This solves all the file-based issues: no overwriting, no incremental build problems, no cleanup issues
    
    # Multi-image binary support
    if(DEFINED EXTRA_MULTI_IMAGE_ID)
        # Get current lists
        get_property(multi_ids GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_IDS)
        get_property(multi_paths GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_PATHS)  
        get_property(multi_targets GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_TARGETS)
        
        # Append new values
        list(APPEND multi_ids "${EXTRA_MULTI_IMAGE_ID}")
        list(APPEND multi_paths "${EXTRA_BINARY_PATH}")
        list(APPEND multi_targets "${target_list}")
        
        # Set back to global properties
        set_property(GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_IDS "${multi_ids}")
        set_property(GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_PATHS "${multi_paths}")
        set_property(GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_TARGETS "${multi_targets}")
    endif()

    # ZIP package support
    if(DEFINED EXTRA_MCUBOOT_IMAGE_ID)
        # Get current lists
        get_property(zip_paths GLOBAL PROPERTY DFU_EXTRA_ZIP_PATHS)
        get_property(zip_names GLOBAL PROPERTY DFU_EXTRA_ZIP_NAMES)
        get_property(zip_targets GLOBAL PROPERTY DFU_EXTRA_ZIP_TARGETS)
        get_property(zip_params GLOBAL PROPERTY DFU_EXTRA_ZIP_PARAMS)
        
        # Append new values
        list(APPEND zip_paths "${EXTRA_BINARY_PATH}")
        list(APPEND zip_names "${EXTRA_ZIP_NAME}")
        list(APPEND zip_targets "${target_list}")
        list(APPEND zip_params "${EXTRA_ZIP_NAME}image_index=${EXTRA_MCUBOOT_IMAGE_ID}")
        list(APPEND zip_params "${EXTRA_ZIP_NAME}slot_index_primary=${slot_primary}")
        list(APPEND zip_params "${EXTRA_ZIP_NAME}slot_index_secondary=${slot_secondary}")
        
        # Set back to global properties
        set_property(GLOBAL PROPERTY DFU_EXTRA_ZIP_PATHS "${zip_paths}")
        set_property(GLOBAL PROPERTY DFU_EXTRA_ZIP_NAMES "${zip_names}")
        set_property(GLOBAL PROPERTY DFU_EXTRA_ZIP_TARGETS "${zip_targets}")
        set_property(GLOBAL PROPERTY DFU_EXTRA_ZIP_PARAMS "${zip_params}")
    endif()

    message(STATUS "DFU: Added extra binary to DFU package(s): ${EXTRA_BINARY_PATH}")
endfunction()

#
# Get all extra binary information for use in multi-image packaging
#
# This function is used internally by the packaging system to retrieve
# all registered extra binaries.
#
function(dfu_multi_image_get_extra out_ids out_paths out_targets)
    # Get from global properties
    get_property(extra_ids GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_IDS)
    get_property(extra_paths GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_PATHS)
    get_property(extra_targets GLOBAL PROPERTY DFU_EXTRA_MULTI_IMAGE_TARGETS)
    
    # Handle empty properties (convert to empty lists)
    if(NOT extra_ids)
        set(extra_ids "")
    endif()
    if(NOT extra_paths)
        set(extra_paths "")
    endif()
    if(NOT extra_targets)
        set(extra_targets "")
    endif()
    
    list(LENGTH extra_ids count)
    if(count GREATER 0)
        message(STATUS "DFU: Found ${count} extra binaries for multi-image package")
    endif()

    set(${out_ids} "${extra_ids}" PARENT_SCOPE)
    set(${out_paths} "${extra_paths}" PARENT_SCOPE)
    set(${out_targets} "${extra_targets}" PARENT_SCOPE)
endfunction()

#
# Get all extra binary information for use in ZIP packaging
#
# This function is used internally by the ZIP packaging system to retrieve
# all registered extra binaries.
#
function(dfu_zip_get_extra out_bin_files out_zip_names out_targets out_script_params)
    # Get from global properties
    get_property(extra_bin_files GLOBAL PROPERTY DFU_EXTRA_ZIP_PATHS)
    get_property(extra_zip_names GLOBAL PROPERTY DFU_EXTRA_ZIP_NAMES)
    get_property(extra_targets GLOBAL PROPERTY DFU_EXTRA_ZIP_TARGETS)
    get_property(extra_script_params GLOBAL PROPERTY DFU_EXTRA_ZIP_PARAMS)
    
    # Handle empty properties (convert to empty lists)
    if(NOT extra_bin_files)
        set(extra_bin_files "")
    endif()
    if(NOT extra_zip_names)
        set(extra_zip_names "")
    endif()
    if(NOT extra_targets)
        set(extra_targets "")
    endif()
    if(NOT extra_script_params)
        set(extra_script_params "")
    endif()
    
    list(LENGTH extra_bin_files count)
    if(count GREATER 0)
        message(STATUS "DFU: Found ${count} extra binaries for ZIP package")
    endif()

    set(${out_bin_files} "${extra_bin_files}" PARENT_SCOPE)
    set(${out_zip_names} "${extra_zip_names}" PARENT_SCOPE)
    set(${out_targets} "${extra_targets}" PARENT_SCOPE)
    set(${out_script_params} "${extra_script_params}" PARENT_SCOPE)
endfunction()
