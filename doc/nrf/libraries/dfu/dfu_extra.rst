.. _lib_dfu_extra:

DFU extra image extensions
##########################

.. contents::
   :local:
   :depth: 2

The DFU extra image extensions provide a flexible mechanism for adding extra firmware images to DFU packages. This allows applications to extend the built-in DFU functionality with additional extra firmware images beyond the standard application, network core, MCUboot, and Wi-Fi firmware patch images.

The system supports both DFU delivery mechanisms:

* **Multi-image binary** (``dfu_multi_image.bin``)
* **ZIP packages** (``dfu_application.zip``) - For Device Firmware Update over SMP

Configuration
*************

To enable extra image support, set the following Kconfig options in your ``sysbuild.conf``:

.. code-block:: kconfig

   # Enable DFU multi-image package build
   SB_CONFIG_DFU_MULTI_IMAGE_PACKAGE_BUILD=y
   
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
   
   # Enable extra DFU binaries
   set(SB_CONFIG_DFU_EXTRA_BINARIES TRUE)
   set(SB_CONFIG_DFU_EXTRA_MULTI_IMAGE TRUE)
   set(SB_CONFIG_DFU_EXTRA_ZIP TRUE)
   
   # Define path to external SoC firmware
   set(ext_soc_fw "${APP_DIR}/ext_soc_fw.bin")
   
   # Create build target for the external binary
   add_custom_target(ext_soc_fw_target
       DEPENDS ${ext_soc_fw}
       COMMENT "External SoC firmware dependency"
   )
   
   # Add extra binary to DFU packages
   dfu_add_extra_binary(
       BINARY_ID 10
       BINARY_PATH ${ext_soc_fw}
       ZIP_NAME "ext_soc_fw.bin"
       ZIP_SLOT_ID 3
       DEPENDS ext_soc_fw_target
   )


Function reference
******************

dfu_add_extra_binary()
========================

Adds a extra binary to both DFU multi-image binary and ZIP packages.

**Syntax:**

.. code-block:: cmake

   dfu_add_extra_binary(
     BINARY_ID <id>
     BINARY_PATH <path>
     [ZIP_NAME <name>]
     [ZIP_SLOT_ID <number>]
     [DEPENDS <target1> [<target2> ...]]
   )

**Parameters:**

* ``BINARY_ID`` - Numeric identifier for the extra binary (signed integer). Used in multi-image packages. Must be unique.

* ``BINARY_PATH`` - Path to the binary file to include in the package. The path can be absolute or relative to the build directory.

* ``ZIP_NAME`` - Optional name for the binary file in ZIP packages. Defaults to the basename of BINARY_PATH if not specified.

* ``ZIP_SLOT_ID`` - Optional slot ID for ZIP packages. Defaults to BINARY_ID if not specified.

* ``DEPENDS`` - Optional list of CMake targets that must be built before this extra binary is available. This ensures proper build ordering.

Understanding ID types
**********************

For nRF7002, the typical image assignments are:

* ``0``: Application core
* ``1``: Network core  
* ``2``: Wi-Fi patch


See also
********

* :ref:`lib_dfu_multi_image` - Base DFU multi-image library
* :ref:`ug_multi_image` - Multi-image builds guide
* :ref:`ug_sysbuild` - Sysbuild user guide