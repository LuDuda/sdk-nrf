#
# Copyright (c) 2025 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

if(SB_CONFIG_MCUBOOT_EXTRA_IMAGES)
  include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_extra.cmake)

  set(ext_img1_unsigned "${CMAKE_BINARY_DIR}/ext_img1.bin")
  set(ext_img2_unsigned "${CMAKE_BINARY_DIR}/ext_img2.bin")
  set(ext_img1_path "${CMAKE_BINARY_DIR}/ext_img1_signed.bin")
  set(ext_img2_path "${CMAKE_BINARY_DIR}/ext_img2_signed.bin")

  file(WRITE ${ext_img1_unsigned} "EXTRA_IMAGE_1_CONTENT_FOR_TESTING")
  file(WRITE ${ext_img2_unsigned} "EXTRA_IMAGE_2_CONTENT_FOR_TESTING")

  find_program(IMGTOOL_PY imgtool.py PATHS ${ZEPHYR_MCUBOOT_MODULE_DIR}/scripts NO_DEFAULT_PATH)
  if(NOT IMGTOOL_PY)
    set(IMGTOOL_PY ${ZEPHYR_MCUBOOT_MODULE_DIR}/scripts/imgtool.py)
  endif()

  set(MCUBOOT_KEY_FILE "${ZEPHYR_MCUBOOT_MODULE_DIR}/root-ec-p256.pem")

  add_custom_command(
    OUTPUT ${ext_img1_path}
    COMMAND ${PYTHON_EXECUTABLE} ${IMGTOOL_PY} sign
      --key ${MCUBOOT_KEY_FILE}
      --header-size ${SB_CONFIG_PM_MCUBOOT_PAD}
      --pad-header
      --align 4
      --version 1.0.0
      --slot-size $<TARGET_PROPERTY:partition_manager,PM_EXT_IMG1_SIZE>
      ${ext_img1_unsigned}
      ${ext_img1_path}
    DEPENDS ${ext_img1_unsigned}
    COMMENT "Signing ext_img1"
  )

  add_custom_command(
    OUTPUT ${ext_img2_path}
    COMMAND ${PYTHON_EXECUTABLE} ${IMGTOOL_PY} sign
      --key ${MCUBOOT_KEY_FILE}
      --header-size ${SB_CONFIG_PM_MCUBOOT_PAD}
      --pad-header
      --align 4
      --version 1.0.0
      --slot-size $<TARGET_PROPERTY:partition_manager,PM_EXT_IMG2_SIZE>
      ${ext_img2_unsigned}
      ${ext_img2_path}
    DEPENDS ${ext_img2_unsigned}
    COMMENT "Signing ext_img2"
  )

  add_custom_target(ext_img1_target DEPENDS ${ext_img1_path})
  add_custom_target(ext_img2_target DEPENDS ${ext_img2_path})

  dfu_extra_add_binary(
    BINARY_PATH ${ext_img1_path}
    IMAGE_NAME ext_img1_signed.bin
    DEPENDS ext_img1_target
  )

  dfu_extra_add_binary(
    BINARY_PATH ${ext_img2_path}
    IMAGE_NAME ext_img2_signed.bin
    DEPENDS ext_img2_target
  )

  set(ext_img1_hex "${CMAKE_BINARY_DIR}/ext_img1_signed.hex")
  set(ext_img2_hex "${CMAKE_BINARY_DIR}/ext_img2_signed.hex")

  add_custom_command(
    OUTPUT ${ext_img1_hex}
    COMMAND ${PYTHON_EXECUTABLE}
      -c "import sys, intelhex; intelhex.bin2hex(sys.argv[1], sys.argv[2], int(sys.argv[3], 0))"
      ${ext_img1_path}
      ${ext_img1_hex}
      $<TARGET_PROPERTY:partition_manager,PM_EXT_IMG1_PAD_ADDRESS>
    DEPENDS ${ext_img1_path}
    VERBATIM
  )

  add_custom_command(
    OUTPUT ${ext_img2_hex}
    COMMAND ${PYTHON_EXECUTABLE}
      -c "import sys, intelhex; intelhex.bin2hex(sys.argv[1], sys.argv[2], int(sys.argv[3], 0))"
      ${ext_img2_path}
      ${ext_img2_hex}
      $<TARGET_PROPERTY:partition_manager,PM_EXT_IMG2_PAD_ADDRESS>
    DEPENDS ${ext_img2_path}
    VERBATIM
  )

  add_custom_target(ext_img1_hex_target DEPENDS ${ext_img1_hex})
  add_custom_target(ext_img2_hex_target DEPENDS ${ext_img2_hex})

  set_property(GLOBAL PROPERTY ext_img1_PM_HEX_FILE ${ext_img1_hex})
  set_property(GLOBAL PROPERTY ext_img1_PM_TARGET ext_img1_hex_target)
  set_property(GLOBAL PROPERTY ext_img2_PM_HEX_FILE ${ext_img2_hex})
  set_property(GLOBAL PROPERTY ext_img2_PM_TARGET ext_img2_hex_target)

  set(dfu_multi_image "${CMAKE_BINARY_DIR}/dfu_multi_image.bin")
  set(dfu_zip "${CMAKE_BINARY_DIR}/dfu_application.zip")

  add_custom_target(verify_dfu_packages ALL
    COMMAND sh -c "\
      echo '=== DFU Package Verification ===' && \
      test -f ${CMAKE_BINARY_DIR}/dfu_application.zip || (echo 'ERROR: Missing ZIP' && exit 1) && \
      test -f ${CMAKE_BINARY_DIR}/dfu_multi_image.bin || (echo 'ERROR: Missing BIN' && exit 1) && \
      grep -q '\"image_index\": \"0\"' ${CMAKE_BINARY_DIR}/dfu_application.zip_manifest.json || (echo 'ERROR: Missing image 0' && exit 1) && \
      grep -q '\"image_index\": \"1\"' ${CMAKE_BINARY_DIR}/dfu_application.zip_manifest.json || (echo 'ERROR: Missing image 1' && exit 1) && \
      grep -q '\"image_index\": \"2\"' ${CMAKE_BINARY_DIR}/dfu_application.zip_manifest.json || (echo 'ERROR: Missing image 2' && exit 1) && \
      grep -q '\"file\": \"ext_img1_signed.bin\"' ${CMAKE_BINARY_DIR}/dfu_application.zip_manifest.json || (echo 'ERROR: Missing ext_img1_signed.bin in manifest' && exit 1) && \
      grep -q '\"file\": \"ext_img2_signed.bin\"' ${CMAKE_BINARY_DIR}/dfu_application.zip_manifest.json || (echo 'ERROR: Missing ext_img2_signed.bin in manifest' && exit 1) && \
      test $(grep -c -- '--image' ${CMAKE_BINARY_DIR}/dfu_multi_image.bin.args) -eq 3 || (echo 'ERROR: Expected 3 images in args' && exit 1) && \
      grep -q 'ext_img1_signed.bin' ${CMAKE_BINARY_DIR}/dfu_multi_image.bin.args || (echo 'ERROR: Missing ext_img1_signed.bin path in args' && exit 1) && \
      grep -q 'ext_img2_signed.bin' ${CMAKE_BINARY_DIR}/dfu_multi_image.bin.args || (echo 'ERROR: Missing ext_img2_signed.bin path in args' && exit 1) && \
      echo 'Result: PASS'"
    DEPENDS ${dfu_multi_image} ${dfu_zip}
    COMMENT "Verifying DFU packages"
    VERBATIM
  )
endif()
