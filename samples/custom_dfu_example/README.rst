.. _custom_dfu_example:

Custom DFU multi-image example
##############################

.. contents::
   :local:
   :depth: 2

This sample demonstrates how to extend the DFU multi-image package with custom firmware images using the NCS custom DFU extensions.

Overview
********

The sample shows how to:

* Enable custom DFU image support in sysbuild configuration
* Add custom firmware images to the DFU multi-image package using CMake
* Build a DFU package that includes both standard and custom images

Requirements
************

* One of the following development kits:

  * |nRF5340DK|
  * |nRF52840DK|
  * Any board supporting MCUboot and DFU

* |VSC| with the |nRFVSC|

Building and running
********************

This application can be built and programmed to the target board as follows:

1. Build the application:

   .. code-block:: console

      west build -b nrf5340dk_nrf5340_cpuapp samples/custom_dfu_example --sysbuild

2. Check the build output for custom images:

   .. code-block:: console

      ls build/dfu_multi_image*

   You should see ``dfu_multi_image.bin`` containing your custom images.

3. Program the application:

   .. code-block:: console

      west flash

Sample output
*************

When building, you should see output similar to:

.. code-block:: console

   -- Adding custom images to DFU multi-image package
   -- Custom DFU images configured:
   --   - Sensor firmware: ID 20
   --   - External MCU firmware: ID 21
   -- DFU Multi-Image: Added custom image ID 20 -> .../custom_sensor_fw.bin
   -- DFU Multi-Image: Added custom image ID 21 -> .../external_mcu_fw.bin
   -- DFU Multi-Image: Added 2 custom images to package

When running, the application outputs:

.. code-block:: console

   [00:00:00.000,000] <inf> custom_dfu_example: Custom DFU Multi-Image Example
   [00:00:00.000,000] <inf> custom_dfu_example: This application demonstrates adding custom images to DFU packages
   [00:00:00.000,000] <inf> custom_dfu_example: Check the build output for dfu_multi_image.bin with custom images
   [00:00:05.000,000] <inf> custom_dfu_example: Application running...

Customization
*************

To add your own custom images:

1. Replace the dummy firmware generation in ``CMakeLists.txt`` with your actual firmware build steps.

2. Modify the image IDs and paths to match your requirements:

   .. code-block:: cmake

      dfu_multi_image_add_custom(
        IMAGE_ID 25                                    # Your custom ID
        IMAGE_PATH "${CMAKE_BINARY_DIR}/your_fw.bin"   # Your firmware path
        DEPENDS your_fw_build_target                   # Your build target
      )

3. Update ``sysbuild.conf`` to enable/disable other DFU image types as needed.

Dependencies
************

This sample depends on the following NCS components:

* DFU multi-image library (:kconfig:option:`CONFIG_DFU_MULTI_IMAGE`)
* Custom DFU extensions (``SB_CONFIG_DFU_MULTI_IMAGE_PACKAGE_CUSTOM``)
* MCUboot bootloader (``SB_CONFIG_BOOTLOADER_MCUBOOT``)

References
**********

* :ref:`lib_dfu_multi_image_custom` - Custom DFU extensions documentation
* :ref:`lib_dfu_multi_image` - Base DFU multi-image library
* :ref:`ug_multi_image` - Multi-image builds guide