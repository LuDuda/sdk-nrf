#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

# DFU Pre-Execute Hooks System
# This system allows applications to intercept and modify DFU package parameters
# just before the final package generation (multi-image or ZIP)

# Global properties to store registered hooks
set_property(GLOBAL PROPERTY DFU_PRE_MULTI_IMAGE_HOOKS "")
set_property(GLOBAL PROPERTY DFU_PRE_ZIP_HOOKS "")

# Function to register a pre-execute hook for multi-image packages
# Usage: dfu_register_pre_multi_image_hook(<function_name>)
# The function will be called with parameters:
#   - ids_var: variable name containing image IDs list
#   - paths_var: variable name containing image paths list  
#   - targets_var: variable name containing targets list
#   - output_var: variable name containing output path
function(dfu_register_pre_multi_image_hook hook_function)
  if(NOT COMMAND ${hook_function})
    message(FATAL_ERROR "dfu_register_pre_multi_image_hook: Function '${hook_function}' does not exist")
  endif()
  
  get_property(existing_hooks GLOBAL PROPERTY DFU_PRE_MULTI_IMAGE_HOOKS)
  if(${hook_function} IN_LIST existing_hooks)
    message(WARNING "dfu_register_pre_multi_image_hook: Hook '${hook_function}' already registered")
    return()
  endif()
  
  set_property(GLOBAL APPEND PROPERTY DFU_PRE_MULTI_IMAGE_HOOKS ${hook_function})
  message(STATUS "Registered pre-multi-image hook: ${hook_function}")
endfunction()

# Function to register a pre-execute hook for ZIP packages
# Usage: dfu_register_pre_zip_hook(<function_name>)
# The function will be called with parameters:
#   - bin_files_var: variable name containing binary files list
#   - zip_names_var: variable name containing ZIP names list
#   - signed_targets_var: variable name containing signed targets list
#   - script_params_var: variable name containing script parameters list
#   - output_var: variable name containing output path
#   - exclude_files_var: variable name containing exclude files list
#   - include_files_var: variable name containing include files list
function(dfu_register_pre_zip_hook hook_function)
  if(NOT COMMAND ${hook_function})
    message(FATAL_ERROR "dfu_register_pre_zip_hook: Function '${hook_function}' does not exist")
  endif()
  
  get_property(existing_hooks GLOBAL PROPERTY DFU_PRE_ZIP_HOOKS)
  if(${hook_function} IN_LIST existing_hooks)
    message(WARNING "dfu_register_pre_zip_hook: Hook '${hook_function}' already registered")
    return()
  endif()
  
  set_property(GLOBAL APPEND PROPERTY DFU_PRE_ZIP_HOOKS ${hook_function})
  message(STATUS "Registered pre-ZIP hook: ${hook_function}")
endfunction()

# Internal function to execute all registered multi-image hooks
# Called by packaging.cmake before dfu_multi_image_package()
function(dfu_execute_pre_multi_image_hooks ids_var paths_var targets_var output_var)
  get_property(hooks GLOBAL PROPERTY DFU_PRE_MULTI_IMAGE_HOOKS)
  
  if(hooks)
    list(LENGTH hooks hook_count)
    message(STATUS "Executing ${hook_count} pre-multi-image hooks...")
    
    foreach(hook_function ${hooks})
      message(STATUS "  Calling hook: ${hook_function}")
      cmake_language(CALL ${hook_function} ${ids_var} ${paths_var} ${targets_var} ${output_var})
    endforeach()
  endif()
endfunction()

# Internal function to execute all registered ZIP hooks
# Called by zip.cmake before generate_dfu_zip()
function(dfu_execute_pre_zip_hooks bin_files_var zip_names_var signed_targets_var script_params_var output_var exclude_files_var include_files_var)
  get_property(hooks GLOBAL PROPERTY DFU_PRE_ZIP_HOOKS)
  
  if(hooks)
    list(LENGTH hooks hook_count)
    message(STATUS "Executing ${hook_count} pre-ZIP hooks...")
    
    foreach(hook_function ${hooks})
      message(STATUS "  Calling hook: ${hook_function}")
      cmake_language(CALL ${hook_function} ${bin_files_var} ${zip_names_var} ${signed_targets_var} ${script_params_var} ${output_var} ${exclude_files_var} ${include_files_var})
    endforeach()
  endif()
endfunction()

# Utility function to clear all hooks (useful for testing)
function(dfu_clear_all_hooks)
  set_property(GLOBAL PROPERTY DFU_PRE_MULTI_IMAGE_HOOKS "")
  set_property(GLOBAL PROPERTY DFU_PRE_ZIP_HOOKS "")
  message(STATUS "Cleared all DFU hooks")
endfunction()

# Utility functions for hook implementations to add custom content

# Helper to add custom image to multi-image package
function(dfu_hook_add_multi_image ids_var paths_var targets_var image_id image_path target_name)
  # Get current values
  set(current_ids ${${ids_var}})
  set(current_paths ${${paths_var}})
  set(current_targets ${${targets_var}})
  
  # Validate ID is not already used
  if(${image_id} IN_LIST current_ids)
    message(FATAL_ERROR "dfu_hook_add_multi_image: Image ID ${image_id} already exists")
  endif()
  
  # Add new image
  list(APPEND current_ids ${image_id})
  list(APPEND current_paths ${image_path})
  list(APPEND current_targets ${target_name})
  
  # Update parent scope
  set(${ids_var} ${current_ids} PARENT_SCOPE)
  set(${paths_var} ${current_paths} PARENT_SCOPE)
  set(${targets_var} ${current_targets} PARENT_SCOPE)
  
  message(STATUS "  Added custom multi-image: ID=${image_id}, PATH=${image_path}")
endfunction()

# Helper to add custom file to ZIP package
function(dfu_hook_add_zip_file bin_files_var zip_names_var signed_targets_var bin_path zip_name target_name)
  # Get current values
  set(current_bins ${${bin_files_var}})
  set(current_names ${${zip_names_var}})
  set(current_targets ${${signed_targets_var}})
  
  # Add new file
  list(APPEND current_bins ${bin_path})
  list(APPEND current_names ${zip_name})
  list(APPEND current_targets ${target_name})
  
  # Update parent scope
  set(${bin_files_var} ${current_bins} PARENT_SCOPE)
  set(${zip_names_var} ${current_names} PARENT_SCOPE)
  set(${signed_targets_var} ${current_targets} PARENT_SCOPE)
  
  message(STATUS "  Added custom ZIP file: ${zip_name} -> ${bin_path}")
endfunction()

# Helper to add script parameter to ZIP package
function(dfu_hook_add_script_param script_params_var param_name param_value)
  # Get current values
  set(current_params ${${script_params_var}})
  
  # Add new parameter
  list(APPEND current_params "${param_name}=${param_value}")
  
  # Update parent scope
  set(${script_params_var} ${current_params} PARENT_SCOPE)
  
  message(STATUS "  Added script parameter: ${param_name}=${param_value}")
endfunction()

# Helper to modify output path
function(dfu_hook_set_output output_var new_output)
  set(${output_var} ${new_output} PARENT_SCOPE)
  message(STATUS "  Changed output path to: ${new_output}")
endfunction()
