# DFU Custom Image Hooks System

This document describes the custom image hooks system that allows applications to inject additional images into DFU packages (both multi-image and ZIP formats) from the sysbuild level.

## Overview

The DFU custom hooks system provides a way for applications to register additional binary images that should be included in DFU packages without modifying the core packaging scripts. This is useful for:

- External MCU firmware updates
- Sensor firmware updates  
- Custom application modules
- Third-party binary components
- Any additional images not part of the standard MCUboot flow

## Key Features

- **Automatic ID Assignment**: System automatically assigns unique IDs starting from 10
- **Manual ID Control**: Option to specify custom IDs to avoid conflicts
- **Multi-format Support**: Works with both dfu_ multi-image packages and ZIP packages
- **Metadata Support**: Rich metadata support for ZIP generation scripts
- **External Binary Support**: Can include pre-built binaries from outside the project
- **Build Integration**: Seamless integration with CMake build targets

## API Reference

### Core Functions

#### `dfu_register_custom_image()`

Registers a custom image for inclusion in DFU packages.

```cmake
dfu_register_custom_image(
    [IMAGE_ID <id>]           # Optional: specific ID (auto-assigned if not provided)
    IMAGE_PATH <path>         # Required: path to binary file
    ZIP_NAME <name>           # Required: name in ZIP package
    TARGET <target>           # Required: CMake target that produces the binary
    [METADATA <key=value>...] # Optional: metadata for ZIP generation
)
```

**Parameters:**
- `IMAGE_ID`: Specific ID for the image (optional, auto-assigned starting from 10)
- `IMAGE_PATH`: Path to the binary file (required)
- `ZIP_NAME`: Name of the file in the ZIP package (required)
- `TARGET`: CMake target that produces the binary (required)
- `METADATA`: Key-value pairs for ZIP script generation (optional)

#### `dfu_register_external_binary()`

Convenience function for registering external (pre-built) binaries.

```cmake
dfu_register_external_binary(
    BINARY_PATH <path>        # Required: path to external binary
    ZIP_NAME <name>           # Required: name in ZIP package
    [IMAGE_ID <id>]           # Optional: specific ID
    [METADATA <key=value>...] # Optional: metadata
)
```

#### `dfu_get_custom_images()`

Retrieves all registered custom images.

```cmake
dfu_get_custom_images(<ids_var> <paths_var> <targets_var> [<zip_names_var>] [<metadata_var>])
```

### Utility Functions

#### `dfu_clear_custom_images()`

Clears all registered custom images (useful for testing).

```cmake
dfu_clear_custom_images()
```

## Usage Examples

### Example 1: External MCU Firmware

```cmake
# Include the custom DFU system
include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_custom.cmake)

# Register external MCU firmware
dfu_register_external_binary(
    BINARY_PATH "${CMAKE_SOURCE_DIR}/external_binaries/mcu_firmware.bin"
    ZIP_NAME "external_mcu.bin"
    IMAGE_ID 15  # Specific ID to avoid conflicts
    METADATA 
        "load_address=0x20000000"
        "version=1.2.3"
        "board=custom_mcu"
)
```

### Example 2: Custom Built Image

```cmake
# Create custom target
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/sensor_firmware.bin
    COMMAND build_sensor_firmware.sh
    COMMENT "Building sensor firmware"
)

add_custom_target(sensor_firmware_target
    DEPENDS ${CMAKE_BINARY_DIR}/sensor_firmware.bin
)

# Register for DFU packages
dfu_register_custom_image(
    IMAGE_PATH ${CMAKE_BINARY_DIR}/sensor_firmware.bin
    ZIP_NAME "sensor_fw.bin"
    TARGET sensor_firmware_target
    METADATA 
        "load_address=0x10000000"
        "image_index=20"
        "version=2.1.0"
        "type=sensor"
)
```

### Example 3: Multiple Images with Auto-Assignment

```cmake
# Register multiple images (IDs auto-assigned: 10, 11, 12...)
dfu_register_custom_image(
    IMAGE_PATH ${CMAKE_BINARY_DIR}/module1.bin
    ZIP_NAME "module1.bin"
    TARGET module1_target
)

dfu_register_custom_image(
    IMAGE_PATH ${CMAKE_BINARY_DIR}/module2.bin
    ZIP_NAME "module2.bin"
    TARGET module2_target
)
```

## Integration Points

### Multi-Image Packages (packaging.cmake)

The system automatically integrates with `packaging.cmake`:

```cmake
# Hook automatically adds custom images
dfu_get_custom_images(custom_ids custom_paths custom_targets)
if(custom_ids)
    list(APPEND dfu_multi_image_ids ${custom_ids})
    list(APPEND dfu_multi_image_paths ${custom_paths})
    list(APPEND dfu_multi_image_targets ${custom_targets})
endif()
```

### ZIP Packages (zip.cmake)

The system automatically integrates with `zip.cmake`:

```cmake
# Hook automatically adds custom images to ZIP
dfu_get_custom_images(custom_ids custom_paths custom_targets custom_zip_names custom_metadata)
if(custom_ids)
    list(APPEND bin_files ${custom_paths})
    list(APPEND zip_names ${custom_zip_names})
    list(APPEND signed_targets ${custom_targets})
    # Process metadata for script parameters...
endif()
```

## Metadata Format

Metadata is used to generate script parameters for ZIP packages. Format:

```cmake
METADATA 
    "key1=value1"
    "key2=value2"
    "load_address=0x10000000"
    "version=1.2.3"
```

This generates script parameters like:
```
filename.binkey1=value1
filename.binkey2=value2
filename.binload_address=0x10000000
filename.binversion=1.2.3
```

## ID Assignment Strategy

- **Standard Images**: Use IDs 0-9 (reserved for MCUboot, app, network core, etc.)
- **Custom Images**: Auto-assigned starting from ID 10
- **Manual Assignment**: Use specific IDs > 10 to avoid conflicts
- **Special IDs**: Negative IDs (-1, -2) reserved for MCUboot components

## File Structure

```
nrf/cmake/
├── dfu_custom.cmake           # Main custom DFU system
├── sysbuild/
│   └── zip.cmake             # Modified with hooks
└── subsys/bootloader/cmake/
    └── packaging.cmake       # Modified with hooks

nrf/samples/
└── custom_dfu_example/
    └── sysbuild.cmake        # Example usage
```

## Best Practices

1. **Always include the custom system**: Add `include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_custom.cmake)` to your sysbuild.cmake
2. **Use specific IDs for critical images**: Avoid auto-assignment for images that must have consistent IDs
3. **Validate external binaries**: Check if external files exist before registering
4. **Provide meaningful metadata**: Include version, load address, and type information
5. **Use descriptive ZIP names**: Make ZIP contents self-documenting

## Troubleshooting

### Common Issues

1. **ID Conflicts**: Use `dfu_clear_custom_images()` and re-register with specific IDs
2. **Missing Binaries**: Check that TARGET dependencies are correct
3. **Metadata Not Applied**: Ensure metadata format is "key=value" strings
4. **Build Order**: Use `cmake_language(DEFER CALL ...)` for post-configuration setup

### Debug Information

The system provides status messages:
```
-- Registered custom DFU image: ID=10, PATH=..., ZIP_NAME=...
-- Added 2 custom images to dfu_ multi-image package
-- Added 2 custom images to DFU ZIP package
```

## Compatibility

- **NCS Version**: 2.9.0+
- **MCUboot**: All supported versions
- **Zephyr**: Compatible with sysbuild system
- **Platforms**: All Nordic platforms supporting DFU
