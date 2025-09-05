#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

# Custom DFU image registration system
# This file provides hooks for applications to register additional images
# for inclusion in DFU packages (both multi-image and ZIP formats)

# Global variables to store custom image information
set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_IDS "")
set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_PATHS "")
set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_TARGETS "")
set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_ZIP_NAMES "")
set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_METADATA "")

# Function to register a custom image for DFU packages
# Usage: dfu_register_custom_image(
#   IMAGE_ID <id>           # Optional: specific ID, if not provided auto-assigned
#   IMAGE_PATH <path>       # Path to the binary file
#   ZIP_NAME <name>         # Name in ZIP package
#   TARGET <target>         # CMake target that produces the binary
#   METADATA <key=value>... # Optional metadata for ZIP generation
# )
function(dfu_register_custom_image)
  cmake_parse_arguments(CUSTOM
    ""
    "IMAGE_ID;IMAGE_PATH;ZIP_NAME;TARGET"
    "METADATA"
    ${ARGN}
  )

  if(NOT CUSTOM_IMAGE_PATH)
    message(FATAL_ERROR "dfu_register_custom_image: IMAGE_PATH is required")
  endif()

  if(NOT CUSTOM_ZIP_NAME)
    message(FATAL_ERROR "dfu_register_custom_image: ZIP_NAME is required")
  endif()

  if(NOT CUSTOM_TARGET)
    message(FATAL_ERROR "dfu_register_custom_image: TARGET is required")
  endif()

  # Auto-assign ID if not provided
  if(NOT CUSTOM_IMAGE_ID)
    get_property(existing_ids GLOBAL PROPERTY DFU_CUSTOM_IMAGES_IDS)
    
    # Find next available ID starting from 10 (to avoid conflicts with standard images)
    set(next_id 10)
    while(${next_id} IN_LIST existing_ids)
      math(EXPR next_id "${next_id} + 1")
    endwhile()
    set(CUSTOM_IMAGE_ID ${next_id})
  endif()

  # Validate that ID is not already used
  get_property(existing_ids GLOBAL PROPERTY DFU_CUSTOM_IMAGES_IDS)
  if(${CUSTOM_IMAGE_ID} IN_LIST existing_ids)
    message(FATAL_ERROR "dfu_register_custom_image: IMAGE_ID ${CUSTOM_IMAGE_ID} is already registered")
  endif()

  # Store the custom image information
  set_property(GLOBAL APPEND PROPERTY DFU_CUSTOM_IMAGES_IDS ${CUSTOM_IMAGE_ID})
  set_property(GLOBAL APPEND PROPERTY DFU_CUSTOM_IMAGES_PATHS ${CUSTOM_IMAGE_PATH})
  set_property(GLOBAL APPEND PROPERTY DFU_CUSTOM_IMAGES_TARGETS ${CUSTOM_TARGET})
  set_property(GLOBAL APPEND PROPERTY DFU_CUSTOM_IMAGES_ZIP_NAMES ${CUSTOM_ZIP_NAME})
  
  # Store metadata as a single string
  if(CUSTOM_METADATA)
    string(JOIN ";" metadata_string ${CUSTOM_METADATA})
    set_property(GLOBAL APPEND PROPERTY DFU_CUSTOM_IMAGES_METADATA ${metadata_string})
  else()
    set_property(GLOBAL APPEND PROPERTY DFU_CUSTOM_IMAGES_METADATA "")
  endif()

  message(STATUS "Registered custom DFU image: ID=${CUSTOM_IMAGE_ID}, PATH=${CUSTOM_IMAGE_PATH}, ZIP_NAME=${CUSTOM_ZIP_NAME}")
endfunction()

# Function to get all registered custom images
# Usage: dfu_get_custom_images(<ids_var> <paths_var> <targets_var> [<zip_names_var>] [<metadata_var>])
function(dfu_get_custom_images ids_var paths_var targets_var)
  set(zip_names_var "")
  set(metadata_var "")
  
  # Parse optional arguments
  if(${ARGC} GREATER 3)
    set(zip_names_var ${ARGV3})
  endif()
  if(${ARGC} GREATER 4)
    set(metadata_var ${ARGV4})
  endif()

  get_property(custom_ids GLOBAL PROPERTY DFU_CUSTOM_IMAGES_IDS)
  get_property(custom_paths GLOBAL PROPERTY DFU_CUSTOM_IMAGES_PATHS)
  get_property(custom_targets GLOBAL PROPERTY DFU_CUSTOM_IMAGES_TARGETS)

  set(${ids_var} ${custom_ids} PARENT_SCOPE)
  set(${paths_var} ${custom_paths} PARENT_SCOPE)
  set(${targets_var} ${custom_targets} PARENT_SCOPE)

  if(zip_names_var)
    get_property(custom_zip_names GLOBAL PROPERTY DFU_CUSTOM_IMAGES_ZIP_NAMES)
    set(${zip_names_var} ${custom_zip_names} PARENT_SCOPE)
  endif()

  if(metadata_var)
    get_property(custom_metadata GLOBAL PROPERTY DFU_CUSTOM_IMAGES_METADATA)
    set(${metadata_var} ${custom_metadata} PARENT_SCOPE)
  endif()
endfunction()

# Convenience function for multi-image packages (backward compatibility)
function(dfu_multi_image_get_custom ids_var paths_var targets_var)
  dfu_get_custom_images(${ids_var} ${paths_var} ${targets_var})
endfunction()

# Function to clear all registered custom images (useful for testing)
function(dfu_clear_custom_images)
  set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_IDS "")
  set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_PATHS "")
  set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_TARGETS "")
  set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_ZIP_NAMES "")
  set_property(GLOBAL PROPERTY DFU_CUSTOM_IMAGES_METADATA "")
endfunction()

# Function to register external binary (not built by this project)
# Usage: dfu_register_external_binary(
#   BINARY_PATH <path>      # Path to external binary file
#   ZIP_NAME <name>         # Name in ZIP package
#   IMAGE_ID <id>           # Optional: specific ID
#   METADATA <key=value>... # Optional metadata
# )
function(dfu_register_external_binary)
  cmake_parse_arguments(EXT
    ""
    "BINARY_PATH;ZIP_NAME;IMAGE_ID"
    "METADATA"
    ${ARGN}
  )

  if(NOT EXT_BINARY_PATH)
    message(FATAL_ERROR "dfu_register_external_binary: BINARY_PATH is required")
  endif()

  if(NOT EXISTS ${EXT_BINARY_PATH})
    message(WARNING "dfu_register_external_binary: Binary file ${EXT_BINARY_PATH} does not exist")
  endif()

  # Create a custom target that depends on the external binary
  get_filename_component(binary_name ${EXT_BINARY_PATH} NAME_WE)
  set(target_name "external_${binary_name}_target")
  
  add_custom_target(${target_name}
    DEPENDS ${EXT_BINARY_PATH}
    COMMENT "External binary dependency: ${EXT_BINARY_PATH}"
  )

  # Register using the main function
  if(EXT_IMAGE_ID)
    dfu_register_custom_image(
      IMAGE_ID ${EXT_IMAGE_ID}
      IMAGE_PATH ${EXT_BINARY_PATH}
      ZIP_NAME ${EXT_ZIP_NAME}
      TARGET ${target_name}
      METADATA ${EXT_METADATA}
    )
  else()
    dfu_register_custom_image(
      IMAGE_PATH ${EXT_BINARY_PATH}
      ZIP_NAME ${EXT_ZIP_NAME}
      TARGET ${target_name}
      METADATA ${EXT_METADATA}
    )
  endif()
endfunction()
