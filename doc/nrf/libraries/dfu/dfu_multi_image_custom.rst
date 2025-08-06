.. _lib_dfu_multi_image_custom:

DFU unified custom extensions
#############################

.. contents::
   :local:
   :depth: 2

The DFU unified custom extensions provide a flexible mechanism for adding custom firmware images to both DFU multi-image packages and DFU ZIP packages. This allows applications and NCS Add-Ons to extend the built-in DFU functionality with additional custom firmware images beyond the standard application, network core, MCUboot, and Wi-Fi firmware patch images.

The unified system ensures that custom images are automatically included in all DFU delivery mechanisms:

* **DFU multi-image binary** - For direct flashing and SUIT updates
* **DFU ZIP packages** - For Device Firmware Update over Bluetooth Low Energy (BLE)

Overview
********

The standard DFU packages in NCS support a fixed set of predefined images:

* Application image (ID 0)
* Network core image (ID 1) 
* MCUboot images (IDs -2, -1)
* Wi-Fi firmware patch (ID 1 or 2)

With the unified custom extensions, you can add any number of additional images with custom IDs and binary paths to **both** multi-image and ZIP packages simultaneously. This is useful for:

* Custom bootloaders or secondary processors
* External MCU firmware updates
* FPGA bitstreams or configuration data
* Cryptographic key updates
* Application-specific data images

Configuration
*************

To enable custom image support, set the following Kconfig options:

.. code-block:: kconfig

   CONFIG_DFU_MULTI_IMAGE_PACKAGE_BUILD=y
   CONFIG_DFU_MULTI_IMAGE_PACKAGE_CUSTOM=y

Usage
*****

Adding custom images from application
======================================

In your application's ``CMakeLists.txt`` or sysbuild configuration, use the ``dfu_add_custom_image()`` function:

.. code-block:: cmake

   # Add a custom firmware image with ID 10 (will be included in both multi-image and ZIP)
   dfu_add_custom_image(
     IMAGE_ID 10
     IMAGE_PATH "${CMAKE_BINARY_DIR}/my_custom_firmware.bin"
     ZIP_NAME "custom_fw.bin"
     MCUBOOT_IMAGE_NUMBER 10
     DEPENDS my_custom_target
   )

   # Add multiple custom images with different configurations
   dfu_add_custom_image(
     IMAGE_ID 11
     IMAGE_PATH "${CMAKE_BINARY_DIR}/external_mcu_fw.bin"
     ZIP_NAME "ext_mcu.bin"
     DEPENDS external_mcu_target
   )

   dfu_add_custom_image(
     IMAGE_ID 20
     IMAGE_PATH "${CMAKE_BINARY_DIR}/crypto_keys.bin"
     ZIP_NAME "keys.bin"
   )

Adding custom images from NCS Add-On
====================================

Create a sysbuild extension file in your NCS Add-On:

.. code-block:: cmake

   # File: my_addon/cmake/sysbuild_my_addon.cmake
   
   if(SB_CONFIG_DFU_MULTI_IMAGE_PACKAGE_CUSTOM AND SB_CONFIG_MY_ADDON_DFU)
     # Add custom bootloader image to both multi-image and ZIP packages
     dfu_add_custom_image(
       IMAGE_ID 15
       IMAGE_PATH "${CMAKE_BINARY_DIR}/my_addon_bootloader.bin"
       ZIP_NAME "addon_bootloader.bin"
       MCUBOOT_IMAGE_NUMBER 15
       DEPENDS my_addon_bootloader_target
     )
   endif()

Then include this file in your Add-On's CMake configuration.

Function reference
******************

dfu_add_custom_image()
======================

Adds a custom image to both DFU multi-image and ZIP packages.

**Syntax:**

.. code-block:: cmake

   dfu_add_custom_image(
     IMAGE_ID <id>
     IMAGE_PATH <path>
     [ZIP_NAME <name>]
     [MCUBOOT_IMAGE_NUMBER <number>]
     [DEPENDS <target1> [<target2> ...]]
   )

**Parameters:**

* ``IMAGE_ID`` - Numeric identifier for the custom image (signed integer). Must be unique and should not conflict with built-in image IDs. Built-in IDs are: -2, -1 (MCUboot), 0 (app), 1 (net), 2 (wifi_fw). Recommended range for custom IDs: 10-255.

* ``IMAGE_PATH`` - Path to the binary image file to include in the package. Can be an absolute path or relative to the build directory.

* ``ZIP_NAME`` - Optional name for the image file in ZIP packages. Defaults to the basename of IMAGE_PATH if not specified.

* ``MCUBOOT_IMAGE_NUMBER`` - Optional MCUboot image number for ZIP package generation. Defaults to IMAGE_ID if not specified.

* ``DEPENDS`` - Optional list of CMake targets that must be built before this custom image is available.

**Example:**

.. code-block:: cmake

   # Simple custom image (will appear in both multi-image and ZIP)
   dfu_add_custom_image(
     IMAGE_ID 12
     IMAGE_PATH "${CMAKE_BINARY_DIR}/sensor_fw.bin"
     ZIP_NAME "sensor.bin"
   )

   # Custom image with dependencies and specific MCUboot configuration
   dfu_add_custom_image(
     IMAGE_ID 13
     IMAGE_PATH "${CMAKE_BINARY_DIR}/signed_external_fw.bin"
     ZIP_NAME "external.bin"
     MCUBOOT_IMAGE_NUMBER 13
     DEPENDS external_fw_sign_target external_fw_build_target
   )

Image ID recommendations
***********************

To avoid conflicts, follow these guidelines for IMAGE_ID selection:

* **Reserved IDs (do not use):**
  
  * ``-2``, ``-1``: MCUboot images
  * ``0``: Application image
  * ``1``: Network core image or Wi-Fi firmware patch (if no network core)
  * ``2``: Wi-Fi firmware patch (if network core is present)

* **Recommended custom ID ranges:**
  
  * ``10-19``: Application-specific custom images
  * ``20-29``: Hardware-specific firmware (external MCUs, sensors, etc.)
  * ``30-39``: Security-related images (keys, certificates)
  * ``40-99``: NCS Add-On images
  * ``100-255``: Vendor-specific or experimental images

Best practices
**************

1. **Use descriptive comments** when adding custom images:

   .. code-block:: cmake

      # Add firmware for external sensor MCU
      dfu_multi_image_add_custom(
        IMAGE_ID 21
        IMAGE_PATH "${CMAKE_BINARY_DIR}/sensor_mcu_fw.bin"
        DEPENDS sensor_mcu_build_target
      )

2. **Validate image files exist** before adding them:

   .. code-block:: cmake

      if(EXISTS "${CMAKE_BINARY_DIR}/my_custom_fw.bin")
        dfu_multi_image_add_custom(
          IMAGE_ID 15
          IMAGE_PATH "${CMAKE_BINARY_DIR}/my_custom_fw.bin"
        )
      else()
        message(WARNING "Custom firmware not found, skipping DFU inclusion")
      endif()

3. **Use consistent ID numbering** across your project to avoid conflicts.

4. **Document your custom image IDs** in your project's documentation.

Troubleshooting
***************

Common issues and solutions:

**Error: "IMAGE_ID X conflicts with built-in image IDs"**
  Choose a different IMAGE_ID outside the reserved range (see recommendations above).

**Error: "IMAGE_ID X is already used by another custom image"**
  Each custom image must have a unique IMAGE_ID. Check for duplicates in your CMake files.

**Error: "IMAGE_PATH is required"**
  Ensure you specify the IMAGE_PATH parameter with a valid file path.

**Warning: "Custom firmware not found"**
  The specified IMAGE_PATH does not exist at build time. Ensure the file is generated before the DFU packaging step, or add appropriate DEPENDS targets.

See also
********

* :ref:`lib_dfu_multi_image` - Base DFU multi-image library
* :ref:`ug_multi_image` - Multi-image builds guide
* :ref:`ug_sysbuild` - Sysbuild user guide