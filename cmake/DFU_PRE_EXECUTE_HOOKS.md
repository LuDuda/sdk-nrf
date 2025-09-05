# DFU Pre-Execute Hooks System

This document describes the pre-execute hooks system that allows applications to intercept and modify DFU package parameters just before the final package generation.

## Overview

The pre-execute hooks system provides a "last chance" interception point where applications can modify all prepared parameters for DFU packages (both multi-image and ZIP formats) right before the final `dfu_multi_image_package()` or `generate_dfu_zip()` calls.

This approach gives applications maximum flexibility to:
- Add custom images with specific IDs
- Modify existing parameters
- Change output filenames
- Add script parameters for ZIP generation
- Include external binaries or configuration files
- Implement conditional logic based on build configuration

## Key Features

- **Pre-Execute Interception**: Hooks are called with all prepared parameters
- **Full Parameter Access**: Applications can read and modify all package parameters
- **Multiple Hook Support**: Multiple hooks can be registered and will be executed in order
- **Helper Functions**: Convenient functions for common modifications
- **Type Safety**: Hooks receive variable names, ensuring proper scope handling
- **Debug Information**: Detailed logging of hook execution

## Hook Types

### Multi-Image Hooks

Called just before `dfu_multi_image_package()` execution.

**Function Signature:**
```cmake
function(my_multi_image_hook ids_var paths_var targets_var output_var)
    # ids_var: variable name containing list of image IDs
    # paths_var: variable name containing list of image paths  
    # targets_var: variable name containing list of CMake targets
    # output_var: variable name containing output file path
endfunction()
```

### ZIP Hooks

Called just before `generate_dfu_zip()` execution.

**Function Signature:**
```cmake
function(my_zip_hook bin_files_var zip_names_var signed_targets_var script_params_var output_var exclude_files_var include_files_var)
    # bin_files_var: variable name containing list of binary files
    # zip_names_var: variable name containing list of ZIP entry names
    # signed_targets_var: variable name containing list of CMake targets
    # script_params_var: variable name containing list of script parameters
    # output_var: variable name containing output ZIP file path
    # exclude_files_var: variable name containing files to exclude
    # include_files_var: variable name containing files to include
endfunction()
```

## API Reference

### Registration Functions

#### `dfu_register_pre_multi_image_hook(function_name)`

Registers a function to be called before multi-image package generation.

```cmake
dfu_register_pre_multi_image_hook(my_custom_multi_image_hook)
```

#### `dfu_register_pre_zip_hook(function_name)`

Registers a function to be called before ZIP package generation.

```cmake
dfu_register_pre_zip_hook(my_custom_zip_hook)
```

### Helper Functions for Hook Implementations

#### `dfu_hook_add_multi_image(ids_var paths_var targets_var image_id image_path target_name)`

Adds a custom image to multi-image package.

```cmake
dfu_hook_add_multi_image(${ids_var} ${paths_var} ${targets_var} 15 "/path/to/image.bin" my_target)
```

#### `dfu_hook_add_zip_file(bin_files_var zip_names_var signed_targets_var bin_path zip_name target_name)`

Adds a custom file to ZIP package.

```cmake
dfu_hook_add_zip_file(${bin_files_var} ${zip_names_var} ${signed_targets_var} "/path/to/file.bin" "file.bin" my_target)
```

#### `dfu_hook_add_script_param(script_params_var param_name param_value)`

Adds a script parameter for ZIP generation.

```cmake
dfu_hook_add_script_param(${script_params_var} "file.binload_address" "0x10000000")
```

#### `dfu_hook_set_output(output_var new_output)`

Changes the output file path.

```cmake
dfu_hook_set_output(${output_var} "${CMAKE_BINARY_DIR}/custom_output.zip")
```

### Utility Functions

#### `dfu_clear_all_hooks()`

Clears all registered hooks (useful for testing).

```cmake
dfu_clear_all_hooks()
```

## Usage Examples

### Example 1: Basic Multi-Image Hook

```cmake
# Include the hooks system
include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_hooks.cmake)

# Define hook function
function(my_multi_image_hook ids_var paths_var targets_var output_var)
    message(STATUS "Current IDs: ${${ids_var}}")
    
    # Add external firmware
    set(external_fw "${CMAKE_SOURCE_DIR}/external.bin")
    if(EXISTS ${external_fw})
        add_custom_target(external_target DEPENDS ${external_fw})
        dfu_hook_add_multi_image(${ids_var} ${paths_var} ${targets_var} 
                               15 ${external_fw} external_target)
    endif()
    
    # Change output filename
    dfu_hook_set_output(${output_var} "${CMAKE_BINARY_DIR}/custom_multi.bin")
endfunction()

# Register the hook
dfu_register_pre_multi_image_hook(my_multi_image_hook)
```

### Example 2: Advanced ZIP Hook

```cmake
function(my_zip_hook bin_files_var zip_names_var signed_targets_var script_params_var output_var exclude_files_var include_files_var)
    # Add configuration file
    set(config_file "${CMAKE_SOURCE_DIR}/config.json")
    if(EXISTS ${config_file})
        add_custom_target(config_target DEPENDS ${config_file})
        dfu_hook_add_zip_file(${bin_files_var} ${zip_names_var} ${signed_targets_var}
                             ${config_file} "device_config.json" config_target)
    endif()
    
    # Add custom binary with metadata
    set(custom_bin "${CMAKE_BINARY_DIR}/module.bin")
    add_custom_command(OUTPUT ${custom_bin}
        COMMAND create_module.sh ${custom_bin}
        DEPENDS ${DEFAULT_IMAGE}
    )
    add_custom_target(module_target DEPENDS ${custom_bin})
    
    dfu_hook_add_zip_file(${bin_files_var} ${zip_names_var} ${signed_targets_var}
                         ${custom_bin} "custom_module.bin" module_target)
    
    # Add metadata for the custom module
    dfu_hook_add_script_param(${script_params_var} "custom_module.binload_address" "0x30000000")
    dfu_hook_add_script_param(${script_params_var} "custom_module.binversion" "2.1.0")
    
    # Custom output name
    dfu_hook_set_output(${output_var} "${CMAKE_BINARY_DIR}/enhanced_dfu.zip")
endfunction()

dfu_register_pre_zip_hook(my_zip_hook)
```

### Example 3: Conditional Hook

```cmake
function(conditional_hook ids_var paths_var targets_var output_var)
    # Only add images if specific configuration is enabled
    if(SB_CONFIG_CUSTOM_EXTERNAL_IMAGES)
        message(STATUS "Adding external images...")
        
        # Add multiple external images
        foreach(img_id RANGE 20 25)
            set(img_path "${CMAKE_SOURCE_DIR}/images/image_${img_id}.bin")
            if(EXISTS ${img_path})
                add_custom_target(img_${img_id}_target DEPENDS ${img_path})
                dfu_hook_add_multi_image(${ids_var} ${paths_var} ${targets_var}
                                       ${img_id} ${img_path} img_${img_id}_target)
            endif()
        endforeach()
    endif()
    
    # Add timestamp to output filename
    string(TIMESTAMP build_time "%Y%m%d_%H%M%S")
    dfu_hook_set_output(${output_var} "${CMAKE_BINARY_DIR}/dfu_${build_time}.bin")
endfunction()

dfu_register_pre_multi_image_hook(conditional_hook)
```

### Example 4: Parameter Inspection and Modification

```cmake
function(debug_and_modify_hook bin_files_var zip_names_var signed_targets_var script_params_var output_var exclude_files_var include_files_var)
    # Debug: Print all current parameters
    message(STATUS "=== ZIP Hook Debug Info ===")
    message(STATUS "Binary files: ${${bin_files_var}}")
    message(STATUS "ZIP names: ${${zip_names_var}}")
    message(STATUS "Targets: ${${signed_targets_var}}")
    message(STATUS "Script params: ${${script_params_var}}")
    message(STATUS "Output: ${${output_var}}")
    
    # Modify existing script parameters
    set(current_params ${${script_params_var}})
    list(APPEND current_params "global_build_timestamp=${build_time}")
    list(APPEND current_params "global_build_config=${CMAKE_BUILD_TYPE}")
    set(${script_params_var} ${current_params} PARENT_SCOPE)
    
    # Add version info file
    set(version_file "${CMAKE_BINARY_DIR}/version_info.txt")
    file(WRITE ${version_file} "Build: ${build_time}\nConfig: ${CMAKE_BUILD_TYPE}\n")
    
    add_custom_target(version_target DEPENDS ${version_file})
    dfu_hook_add_zip_file(${bin_files_var} ${zip_names_var} ${signed_targets_var}
                         ${version_file} "build_info.txt" version_target)
endfunction()

dfu_register_pre_zip_hook(debug_and_modify_hook)
```

## Integration Points

### packaging.cmake Integration

```cmake
if(DEFINED dfu_multi_image_targets)
    # Set default output path
    set(dfu_multi_image_output "${CMAKE_BINARY_DIR}/dfu_multi_image.bin")
    
    # Execute pre-execute hooks - applications can modify parameters here
    dfu_execute_pre_multi_image_hooks(dfu_multi_image_ids dfu_multi_image_paths dfu_multi_image_targets dfu_multi_image_output)
    
    # Create the multi-image package with potentially modified parameters
    dfu_multi_image_package(dfu_multi_image_pkg
        IMAGE_IDS ${dfu_multi_image_ids}
        IMAGE_PATHS ${dfu_multi_image_paths}
        OUTPUT ${dfu_multi_image_output}
        DEPENDS ${dfu_multi_image_targets}
    )
endif()
```

### zip.cmake Integration

```cmake
if(bin_files)
    # Set default output path
    set(dfu_zip_output "${CMAKE_BINARY_DIR}/dfu_application.zip")
    
    # Execute pre-execute hooks - applications can modify parameters here
    dfu_execute_pre_zip_hooks(bin_files zip_names signed_targets generate_script_app_params dfu_zip_output exclude_files include_files)

    generate_dfu_zip(
        OUTPUT ${dfu_zip_output}
        BIN_FILES ${bin_files}
        ZIP_NAMES ${zip_names}
        TYPE application
        IMAGE ${DEFAULT_IMAGE}
        SCRIPT_PARAMS ${generate_script_app_params}
        DEPENDS ${signed_targets}
        ${exclude_files}
        ${include_files}
    )
endif()
```

## Hook Execution Flow

```
1. Standard DFU preparation (packaging.cmake/zip.cmake)
   ↓
2. All parameters prepared (IDs, paths, targets, etc.)
   ↓
3. dfu_execute_pre_*_hooks() called
   ↓
4. Each registered hook function executed in order
   ↓
5. Hook functions can modify parameters using helper functions
   ↓
6. Final dfu_multi_image_package() or generate_dfu_zip() called
   ↓
7. DFU package created with modified parameters
```

## Best Practices

1. **Always validate inputs**: Check if files exist before adding them
2. **Use descriptive hook names**: Make it clear what each hook does
3. **Add debug messages**: Help with troubleshooting build issues
4. **Handle errors gracefully**: Don't fail the build for optional additions
5. **Use helper functions**: They provide validation and consistent behavior
6. **Document your hooks**: Explain what modifications they make

## Troubleshooting

### Common Issues

1. **Hook not called**: Ensure the hook function is defined before registration
2. **Parameter not modified**: Use PARENT_SCOPE or helper functions correctly
3. **Build failures**: Validate all paths and targets before adding them
4. **ID conflicts**: Check existing IDs before adding new ones

### Debug Information

The system provides detailed logging:
```
-- Registered pre-multi-image hook: my_custom_hook
-- Executing 2 pre-multi-image hooks...
--   Calling hook: my_custom_hook
--   Added custom multi-image: ID=15, PATH=/path/to/image.bin
--   Changed output path to: /custom/output.bin
```

## Compatibility

- **NCS Version**: 2.9.0+
- **Build System**: Sysbuild required
- **CMake Version**: 3.20+ (for cmake_language support)
- **Platforms**: All Nordic platforms supporting DFU

## File Structure

```
nrf/cmake/
├── dfu_hooks.cmake              # Main hooks system
├── sysbuild/
│   └── zip.cmake               # Modified with pre-execute hooks
└── subsys/bootloader/cmake/
    └── packaging.cmake         # Modified with pre-execute hooks

nrf/samples/
└── custom_dfu_example/
    └── sysbuild.cmake          # Example hook implementations
```
