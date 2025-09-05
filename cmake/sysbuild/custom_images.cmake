# Copyright (c) 2024 Nordic Semiconductor ASA
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause

# Custom external images integration for sysbuild DFU packages
# This file provides integration hooks for custom external images in ZIP and multi-image DFU packages

# Function to get custom image information for ZIP packaging
function(dfu_zip_get_custom_sysbuild result_bin_files result_zip_names result_targets result_script_params)
  set(bin_files)
  set(zip_names)
  set(targets)
  set(script_params)

  # Get list of registered custom images
  get_property(custom_images GLOBAL PROPERTY SYSBUILD_CUSTOM_IMAGES)
  
  if(custom_images)
    foreach(image_name ${custom_images})
      get_property(target_name GLOBAL PROPERTY ${image_name}_TARGET)
      get_property(signed_bin GLOBAL PROPERTY ${image_name}_SIGNED_BIN)
      get_property(image_index GLOBAL PROPERTY ${image_name}_IMAGE_INDEX)
      get_property(display_name GLOBAL PROPERTY ${image_name}_NAME)
      
      if(target_name AND signed_bin AND DEFINED image_index)
        # Calculate slot indices (primary and secondary)
        math(EXPR slot_primary "${image_index} * 2")
        math(EXPR slot_secondary "${image_index} * 2 + 1")
        
        # Add 1 to match mcumgr slot numbering (mcumgr uses 1-based indexing)
        math(EXPR slot_primary_mcumgr "${slot_primary} + 1")
        math(EXPR slot_secondary_mcumgr "${slot_secondary} + 1")
        
        list(APPEND bin_files ${signed_bin})
        list(APPEND zip_names "${display_name}.bin")
        list(APPEND targets ${target_name})
        
        # Add script parameters for manifest generation
        list(APPEND script_params
          "${display_name}.binimage_index=${image_index}"
          "${display_name}.binslot_index_primary=${slot_primary_mcumgr}"
          "${display_name}.binslot_index_secondary=${slot_secondary_mcumgr}"
        )
        
        message(STATUS "Custom sysbuild image '${display_name}' added to ZIP package:")
        message(STATUS "  Image index: ${image_index}")
        message(STATUS "  Primary slot: ${slot_primary_mcumgr}")
        message(STATUS "  Secondary slot: ${slot_secondary_mcumgr}")
      endif()
    endforeach()
  endif()

  set(${result_bin_files} ${bin_files} PARENT_SCOPE)
  set(${result_zip_names} ${zip_names} PARENT_SCOPE)
  set(${result_targets} ${targets} PARENT_SCOPE)
  set(${result_script_params} ${script_params} PARENT_SCOPE)
endfunction()

# Function to get custom image information for multi-image packaging
function(dfu_multi_image_get_custom_sysbuild result_bin_files result_targets)
  set(bin_files)
  set(targets)

  # Get list of registered custom images
  get_property(custom_images GLOBAL PROPERTY SYSBUILD_CUSTOM_IMAGES)
  
  if(custom_images)
    foreach(image_name ${custom_images})
      get_property(target_name GLOBAL PROPERTY ${image_name}_TARGET)
      get_property(signed_bin GLOBAL PROPERTY ${image_name}_SIGNED_BIN)
      get_property(display_name GLOBAL PROPERTY ${image_name}_NAME)
      
      if(target_name AND signed_bin)
        list(APPEND bin_files ${signed_bin})
        list(APPEND targets ${target_name})
        
        message(STATUS "Custom sysbuild image '${display_name}' added to multi-image package")
      endif()
    endforeach()
  endif()

  set(${result_bin_files} ${bin_files} PARENT_SCOPE)
  set(${result_targets} ${targets} PARENT_SCOPE)
endfunction()

# Function to add custom images to partition manager configuration
function(add_custom_images_to_pm)
  get_property(custom_images GLOBAL PROPERTY SYSBUILD_CUSTOM_IMAGES)
  
  if(custom_images)
    foreach(image_name ${custom_images})
      get_property(image_index GLOBAL PROPERTY ${image_name}_IMAGE_INDEX)
      get_property(display_name GLOBAL PROPERTY ${image_name}_NAME)
      
      if(DEFINED image_index)
        # Add partition manager configuration for this image
        # This creates mcuboot_primary_N and mcuboot_secondary_N partitions
        set_property(GLOBAL APPEND PROPERTY PM_CUSTOM_IMAGES ${image_index})
        set_property(GLOBAL PROPERTY PM_CUSTOM_IMAGE_${image_index}_NAME ${display_name})
        
        message(STATUS "Added custom image '${display_name}' to partition manager with index ${image_index}")
      endif()
    endforeach()
  endif()
endfunction()

# Function to validate custom image configuration
function(validate_custom_images)
  get_property(custom_images GLOBAL PROPERTY SYSBUILD_CUSTOM_IMAGES)
  
  if(custom_images)
    set(used_indices)
    
    foreach(image_name ${custom_images})
      get_property(image_index GLOBAL PROPERTY ${image_name}_IMAGE_INDEX)
      get_property(display_name GLOBAL PROPERTY ${image_name}_NAME)
      
      if(DEFINED image_index)
        # Check for duplicate indices
        if(${image_index} IN_LIST used_indices)
          message(FATAL_ERROR "Duplicate image index ${image_index} for custom image '${display_name}'")
        endif()
        
        list(APPEND used_indices ${image_index})
        
        # Validate image index is not conflicting with system images
        if(image_index EQUAL 0)
          message(FATAL_ERROR "Custom image '${display_name}' cannot use image index 0 (reserved for application)")
        endif()
        
        if(SB_CONFIG_SUPPORT_NETCORE AND NOT SB_CONFIG_NETCORE_NONE AND image_index EQUAL 1)
          message(FATAL_ERROR "Custom image '${display_name}' cannot use image index 1 (reserved for network core)")
        endif()
      endif()
    endforeach()
    
    message(STATUS "Custom image validation passed. Used indices: ${used_indices}")
  endif()
endfunction()
