.. _lib_dfu_extra:

DFU extra image extensions
##########################

.. contents::
   :local:
   :depth: 2

The DFU extra image module provides a flexible mechanism for including extra firmware images in the DFU packages.
This allows applications to extend the built-in DFU functionality with additional extra firmware images beyond ones supported natively in the nRF Connect SDK.

This CMAke extension supports the following DFU delivery mechanisms:

* **Multi-image binary** (``dfu_multi_image.bin``)
* **ZIP packages** (``dfu_application.zip``) - For Device Firmware Update over SMP

Configuration
*************

To enable extra image support, set the following Kconfig options in your ``sysbuild.conf``:

.. code-block:: kconfig

   # Enable extra DFU binaries support
   SB_CONFIG_DFU_EXTRA_BINARIES=y
   
   # Include extra binaries in multi-image binary (optional)
   SB_CONFIG_DFU_EXTRA_MULTI_IMAGE=y
   
   # Include extra binaries in ZIP packages (optional)
   SB_CONFIG_DFU_EXTRA_ZIP=y

Usage Examples
**************

Add extra binaries in your application's **sysbuild.cmake** file:

.. code-block:: cmake

   # File: sysbuild.cmake
   
   # Include the extra DFU system
   include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_extra.cmake)
   
   # Define path to external firmware
   set(ext_fw "${APP_DIR}/ext_fw.signed.bin")
   
   # Create build target for the external binary
   add_custom_target(ext_fw_target
       DEPENDS ${ext_fw}
       COMMENT "External firmware dependency"
   )

   # Add extra binary to both multi-image and ZIP packages
   dfu_add_extra_binary(
       MULTI_IMAGE_ID 10          # For dfu_multi_image.bin
       MCUBOOT_IMAGE_ID 3         # For ZIP packages and MCUboot slots
       BINARY_PATH ${ext_fw}
       ZIP_NAME "ext_fw.bin"
       DEPENDS ext_fw_target
   )

Function reference
******************

dfu_add_extra_binary()
========================

Adds a extra binary to DFU multi-image binary and/or ZIP packages.

**Syntax:**

.. code-block:: cmake

   dfu_add_extra_binary(
     [MULTI_IMAGE_ID <id>]
     [MCUBOOT_IMAGE_ID <id>]
     BINARY_PATH <path>
     [ZIP_NAME <name>]
     [DEPENDS <target1> [<target2> ...]]
   )

**Parameters:**

* ``MULTI_IMAGE_ID`` - Numeric identifier for multi-image binary packaging (signed integer). Used in ``dfu_multi_image.bin``. Must be unique and should not conflict with built-in IDs, see :ref:`lib_dfu_multi_image`. Optional - only required if the binary should be included in multi-image packages.

* ``MCUBOOT_IMAGE_ID`` - MCUboot image identifier for ZIP packages (non-negative integer). Used for MCUboot slot calculations and ZIP package metadata, see :ref:`sysbuild_assigned_images_ids`. Optional - only required if the binary should be included in ZIP packages.

* ``BINARY_PATH`` - Path to the binary file to include in the package. The path can be absolute or relative to the build directory. Can be signed (``*.signed.bin``) or unsigned (``*.bin``) binary.

* ``ZIP_NAME`` - Optional name for the binary file in ZIP packages. Defaults to the basename of ``BINARY_PATH`` if not specified.

* ``DEPENDS`` - Optional list of CMake targets that must be built before this extra binary is available. This ensures proper build ordering.

**Important Notes:**

* At least one of ``MULTI_IMAGE_ID`` or ``MCUBOOT_IMAGE_ID`` must be provided.
* ``MULTI_IMAGE_ID`` and ``MCUBOOT_IMAGE_ID`` serve different purposes and can have different values.
* ``MULTI_IMAGE_ID`` is used for packaging multiple binaries into a single ``dfu_multi_image.bin`` file.
* ``MCUBOOT_IMAGE_ID`` is used by MCUboot for slot management and by mcumgr for device firmware updates over SMP.

See also
********

* :ref:`lib_dfu_multi_image` - Base DFU multi-image library
* :ref:`ug_multi_image` - Multi-image builds guide
* :ref:`sysbuild_assigned_images_ids` - Sysbuild-assigned image IDs
