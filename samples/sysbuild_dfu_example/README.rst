.. _sysbuild_dfu_example:

Sysbuild DFU auto-detection example
###################################

.. contents::
   :local:
   :depth: 2

This sample demonstrates the **generic sysbuild DFU integration** that automatically detects and includes sysbuild images in DFU packages without hardcoded configuration.

Overview
********

This example shows how the new **automatic sysbuild image detection** eliminates the need for manual DFU image registration. Instead of hardcoding image paths and IDs, the system:

1. **Scans all registered sysbuild images** using the existing ``sysbuild_images`` global property
2. **Auto-detects DFU configuration** from image ``prj.conf`` files
3. **Automatically determines binary paths** including MCUboot signing support
4. **Includes images in both multi-image and ZIP packages** automatically

Key Benefits
************

* **No hardcoded image lists** - works with any sysbuild image
* **Automatic MCUboot signing detection** - chooses signed/unsigned binaries intelligently  
* **Unified for both multi-image and ZIP** - single configuration works for all DFU mechanisms
* **Leverages existing sysbuild infrastructure** - no separate image registry needed
* **Kconfig-driven inclusion** - easy to enable/disable images for DFU

How it Works
************

Auto-detection Logic
===================

The system automatically includes sysbuild images in DFU packages if they have:

1. **``CONFIG_DFU_IMAGE_ID``** defined in their ``prj.conf``
2. **``CONFIG_MCUBOOT_IMAGE_NUMBER``** defined in their ``prj.conf``
3. **``SB_CONFIG_DFU_INCLUDE_<image_name>``** explicitly enabled in sysbuild

MCUboot Signing Support
=======================

The system automatically chooses the correct binary format:

* **Signed binaries** (``*.signed.bin``) when ``SB_CONFIG_DFU_USE_SIGNED_IMAGES=y``
* **Unsigned binaries** (``*.bin``) when ``SB_CONFIG_DFU_USE_SIGNED_IMAGES=n``
* **Per-image override** using ``SB_CONFIG_DFU_SIGNED_<image_name>``

Sample Structure
****************

This sample includes:

**Main Application**
   The primary application that will be included in DFU packages.

**Sensor Controller Image**
   A custom sysbuild image (``sensor_controller``) with:
   
   * ``CONFIG_DFU_IMAGE_ID=20``
   * ``CONFIG_MCUBOOT_IMAGE_NUMBER=20``
   * Automatically detected and included

**External MCU Image**
   Another custom sysbuild image (``external_mcu``) with:
   
   * ``CONFIG_DFU_IMAGE_ID=21``  
   * ``CONFIG_MCUBOOT_IMAGE_NUMBER=21``
   * Automatically detected and included

Configuration Files
*******************

sysbuild.conf
=============

.. code-block:: kconfig

   # Enable automatic sysbuild image detection (key feature!)
   SB_CONFIG_DFU_MULTI_IMAGE_PACKAGE_SYSBUILD_IMAGES=y
   
   # Use signed images for security
   SB_CONFIG_DFU_USE_SIGNED_IMAGES=y
   
   # Enable our custom images  
   SB_CONFIG_SENSOR_CONTROLLER_IMAGE=y
   SB_CONFIG_EXTERNAL_MCU_IMAGE=y

sensor_controller/prj.conf
===========================

.. code-block:: kconfig

   # Enable DFU support with a specific image ID
   CONFIG_DFU_IMAGE_ID=20
   CONFIG_MCUBOOT_IMAGE_NUMBER=20

external_mcu/prj.conf  
======================

.. code-block:: kconfig

   # Enable DFU support with a specific image ID
   CONFIG_DFU_IMAGE_ID=21
   CONFIG_MCUBOOT_IMAGE_NUMBER=21

Building and Running
********************

1. Build the sample with sysbuild:

   .. code-block:: console

      west build -b nrf5340dk_nrf5340_cpuapp samples/sysbuild_dfu_example --sysbuild

2. Check the build output:

   .. code-block:: console

      # Multi-image binary with auto-detected images
      ls build/dfu_multi_image.bin
      
      # ZIP package with auto-detected images  
      ls build/dfu_application.zip

3. Observe the automatic detection in build logs:

   .. code-block:: console

      -- DFU Auto-detect: Scanning 4 sysbuild images...
      -- DFU Auto-detect: sensor_controller - auto-detected via DFU config
      -- DFU Auto-detect: external_mcu - auto-detected via DFU config
      -- DFU Auto-detect: Found 2 sysbuild images for DFU inclusion

Expected Output
***************

During build, you should see messages like:

.. code-block:: console

   -- DFU Auto-detect: Scanning N sysbuild images...
   -- DFU Auto-detect: sensor_controller - auto-detected via DFU config
   -- DFU Auto-detect: Added sensor_controller -> ID 20, Path: .../sensor_controller.signed.bin
   -- DFU Auto-detect: external_mcu - auto-detected via DFU config
   -- DFU Auto-detect: Added external_mcu -> ID 21, Path: .../external_mcu.signed.bin
   -- DFU Auto-detect: Found 2 sysbuild images for DFU inclusion

When running the applications:

.. code-block:: console

   [00:00:00.000,000] <inf> sysbuild_dfu_example: Sysbuild DFU Example
   [00:00:00.000,000] <inf> sysbuild_dfu_example: This demonstrates automatic detection of sysbuild images for DFU
   [00:00:00.000,000] <inf> sensor_controller: Sensor Controller Image (DFU ID: 20)
   [00:00:00.000,000] <inf> external_mcu: External MCU Image (DFU ID: 21)

Adding Your Own Images
**********************

To add your own sysbuild images to DFU packages:

1. **Create a sysbuild image** in ``sysbuild.cmake``:

   .. code-block:: cmake

      ExternalZephyrProject_Add(
          APPLICATION my_custom_image
          SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/my_custom_image
          BOARD ${BOARD}
      )

2. **Configure DFU support** in the image's ``prj.conf``:

   .. code-block:: kconfig

      CONFIG_DFU_IMAGE_ID=25
      CONFIG_MCUBOOT_IMAGE_NUMBER=25

3. **Enable the image** in ``sysbuild.conf``:

   .. code-block:: kconfig

      SB_CONFIG_MY_CUSTOM_IMAGE=y

4. **Enable auto-detection**:

   .. code-block:: kconfig

      SB_CONFIG_DFU_MULTI_IMAGE_PACKAGE_SYSBUILD_IMAGES=y

That's it! The image will be automatically detected and included in DFU packages.

Comparison with Previous Approach
*********************************

**Before (Hardcoded)**:

.. code-block:: cmake

   # Manual registration required
   dfu_multi_image_add_custom(
     IMAGE_ID 20
     IMAGE_PATH "${CMAKE_BINARY_DIR}/sensor_controller.bin"
     DEPENDS sensor_controller_target
   )

**Now (Automatic)**:

.. code-block:: kconfig

   # In image prj.conf - that's it!
   CONFIG_DFU_IMAGE_ID=20

The new system automatically:

* Detects the image from sysbuild registry
* Determines the correct binary path  
* Handles MCUboot signing
* Includes in both multi-image and ZIP packages
* Manages build dependencies

Dependencies
************

* Sysbuild system
* MCUboot (for signed images)
* DFU multi-image library

See Also
********

* :ref:`ug_sysbuild` - Sysbuild user guide
* :ref:`lib_dfu_multi_image` - DFU multi-image library
* :ref:`ug_multi_image` - Multi-image builds guide