#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

#
# Generic DFU Sysbuild Image Integration
#
# This file provides automatic detection and inclusion of sysbuild images in DFU packages.
# It leverages the existing sysbuild image system instead of creating a separate registry.
# Images are automatically detected based on Kconfig settings and their properties.
#

#
# Automatically detect and configure sysbuild images for DFU inclusion
#
# This function scans all registered sysbuild images and determines which ones
# should be included in DFU packages based on their configuration and Kconfig settings.
#
function(dfu_sysbuild_auto_detect_images out_ids out_paths out_targets)
    set(detected_ids)
    set(detected_paths)
    set(detected_targets)

    # Get all images from sysbuild
    get_property(all_images GLOBAL PROPERTY sysbuild_images)
    list(LENGTH all_images total_images)
    
    message(STATUS "DFU Auto-detect: Scanning ${total_images} sysbuild images...")
    
    foreach(image ${all_images})
        # Skip built-in images that are already handled explicitly
        if(image STREQUAL "${DEFAULT_IMAGE}" OR 
           image STREQUAL "mcuboot" OR 
           image STREQUAL "s1_image" OR
           image MATCHES ".*_ns$")
            continue()
        endif()

        # Check if this image should be included in DFU based on Kconfig
        set(include_in_dfu FALSE)
        
        # Check for image-specific DFU inclusion config
        if(DEFINED SB_CONFIG_DFU_INCLUDE_${image})
            if(SB_CONFIG_DFU_INCLUDE_${image})
                set(include_in_dfu TRUE)
                message(STATUS "DFU Auto-detect: ${image} - explicitly enabled via SB_CONFIG_DFU_INCLUDE_${image}")
            endif()
        else()
            # Auto-detect based on image properties and common patterns
            sysbuild_get(${image}_DFU_IMAGE_ID IMAGE ${image} VAR CONFIG_DFU_IMAGE_ID KCONFIG)
            sysbuild_get(${image}_MCUBOOT_IMAGE_NUMBER IMAGE ${image} VAR CONFIG_MCUBOOT_IMAGE_NUMBER KCONFIG)
            
            # Include if image has DFU configuration
            if(DEFINED ${image}_DFU_IMAGE_ID OR DEFINED ${image}_MCUBOOT_IMAGE_NUMBER)
                set(include_in_dfu TRUE)
                message(STATUS "DFU Auto-detect: ${image} - auto-detected via DFU config")
            endif()
        endif()

        if(include_in_dfu)
            # Determine image ID (prefer explicit DFU_IMAGE_ID, fallback to MCUBOOT_IMAGE_NUMBER)
            if(DEFINED ${image}_DFU_IMAGE_ID)
                set(image_id ${${image}_DFU_IMAGE_ID})
            elseif(DEFINED ${image}_MCUBOOT_IMAGE_NUMBER)
                set(image_id ${${image}_MCUBOOT_IMAGE_NUMBER})
            else()
                # Auto-assign ID based on position in image list
                list(LENGTH detected_ids current_count)
                math(EXPR image_id "10 + ${current_count}")
                message(STATUS "DFU Auto-detect: ${image} - auto-assigned ID ${image_id}")
            endif()

            # Determine binary path
            set(image_path)
            dfu_sysbuild_get_image_binary(${image} image_path)
            
            if(image_path)
                list(APPEND detected_ids ${image_id})
                list(APPEND detected_paths ${image_path})
                list(APPEND detected_targets ${image}_extra_byproducts)
                
                message(STATUS "DFU Auto-detect: Added ${image} -> ID ${image_id}, Path: ${image_path}")
            else()
                message(WARNING "DFU Auto-detect: ${image} - could not determine binary path, skipping")
            endif()
        endif()
    endforeach()

    # Count and report
    list(LENGTH detected_ids total_count)
    if(total_count GREATER 0)
        message(STATUS "DFU Auto-detect: Found ${total_count} sysbuild images for DFU inclusion")
    else()
        message(STATUS "DFU Auto-detect: No additional sysbuild images found for DFU")
    endif()

    set(${out_ids} "${detected_ids}" PARENT_SCOPE)
    set(${out_paths} "${detected_paths}" PARENT_SCOPE)
    set(${out_targets} "${detected_targets}" PARENT_SCOPE)
endfunction()

#
# Determine the correct binary path for a sysbuild image
#
# This function handles different image types and MCUboot signing scenarios
#
function(dfu_sysbuild_get_image_binary image_name out_path)
    # Get image properties
    sysbuild_get(${image_name}_binary_dir IMAGE ${image_name} VAR ZEPHYR_BINARY_DIR CACHE)
    sysbuild_get(${image_name}_kernel_name IMAGE ${image_name} VAR CONFIG_KERNEL_BIN_NAME KCONFIG)
    sysbuild_get(${image_name}_mcuboot_enabled IMAGE ${image_name} VAR CONFIG_BOOTLOADER_MCUBOOT KCONFIG)
    
    set(binary_path)
    
    if(${image_name}_mcuboot_enabled)
        # Check if image should use signed binary
        if(SB_CONFIG_DFU_USE_SIGNED_IMAGES OR 
           DEFINED SB_CONFIG_DFU_SIGNED_${image_name} AND SB_CONFIG_DFU_SIGNED_${image_name})
            # Use MCUboot signed binary
            set(binary_path "${CMAKE_BINARY_DIR}/signed_by_mcuboot_and_b0_${image_name}.bin")
            
            # Fallback to standard signed path if main path doesn't exist
            if(NOT EXISTS ${binary_path})
                set(binary_path "${${image_name}_binary_dir}/zephyr/${${image_name}_kernel_name}.signed.bin")
            endif()
        else()
            # Use unsigned binary
            set(binary_path "${${image_name}_binary_dir}/zephyr/${${image_name}_kernel_name}.bin")
        endif()
    else()
        # Non-MCUboot image, use standard binary
        set(binary_path "${${image_name}_binary_dir}/zephyr/${${image_name}_kernel_name}.bin")
    endif()

    # Validate path exists (at configure time this might not exist yet, which is fine)
    if(EXISTS ${binary_path})
        message(STATUS "DFU Binary: ${image_name} -> ${binary_path} (verified)")
    else()
        message(STATUS "DFU Binary: ${image_name} -> ${binary_path} (will be generated)")
    endif()
    
    set(${out_path} "${binary_path}" PARENT_SCOPE)
endfunction()

#
# Generate ZIP-specific information for detected sysbuild images
#
function(dfu_sysbuild_auto_detect_zip_images out_bin_files out_zip_names out_targets out_script_params)
    # First get the basic image information
    dfu_sysbuild_auto_detect_images(image_ids image_paths image_targets)
    
    set(zip_bin_files)
    set(zip_names)
    set(zip_targets)
    set(zip_script_params)
    
    # Convert multi-image info to ZIP format
    foreach(id path target IN ZIP_LISTS image_ids image_paths image_targets)
        # Generate ZIP name from path
        get_filename_component(zip_name ${path} NAME)
        
        list(APPEND zip_bin_files ${path})
        list(APPEND zip_names ${zip_name})
        list(APPEND zip_targets ${target})
        
        # Generate basic script parameters
        list(APPEND zip_script_params "${zip_name}image_index=${id}")
    endforeach()
    
    set(${out_bin_files} "${zip_bin_files}" PARENT_SCOPE)
    set(${out_zip_names} "${zip_names}" PARENT_SCOPE)
    set(${out_targets} "${zip_targets}" PARENT_SCOPE)
    set(${out_script_params} "${zip_script_params}" PARENT_SCOPE)
endfunction()