#
# Copyright (c) 2025 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

if(SB_CONFIG_MCUBOOT_EXTRA_IMAGES)
  include(${ZEPHYR_NRF_MODULE_DIR}/cmake/dfu_extra.cmake)

  set(ext_img1_path "${CMAKE_BINARY_DIR}/ext_img1.bin")

  # Generate exactly 512 KB (524288 bytes) of sequential uint32_t values
  math(EXPR total_bytes "512 * 1024")
  math(EXPR total_words "${total_bytes} / 4")

  # Use Python to generate the file (since CMake itself can't easily write binary)
  file(WRITE ${CMAKE_BINARY_DIR}/gen_ext_img1.py
        "with open(r'${ext_img1_path}', 'wb') as f:
            for i in range(${total_words}):
                f.write((i*2).to_bytes(4, 'big'))  # big-endian
      ")

  execute_process(
    COMMAND ${CMAKE_COMMAND} -E env python3 ${CMAKE_BINARY_DIR}/gen_ext_img1.py
    RESULT_VARIABLE gen_result
  )
  if(NOT gen_result EQUAL 0)
    message(FATAL_ERROR \"Failed to generate ${ext_img1_path}\")
  endif()

  dfu_extra_add_binary(
    BINARY_PATH ${ext_img1_path}
    NAME "extimg_fw"
    VERSION "1.2.3"
  )
endif()