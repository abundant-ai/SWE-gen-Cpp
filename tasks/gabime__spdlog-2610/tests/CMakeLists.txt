cmake_minimum_required(VERSION 3.10)
project(spdlog_utests CXX)

if(NOT TARGET spdlog)
    # Stand-alone build
    find_package(spdlog REQUIRED)
endif()

include(../cmake/utils.cmake)

find_package(PkgConfig)
if(PkgConfig_FOUND)
    pkg_check_modules(systemd libsystemd)
endif()

set(SPDLOG_UTESTS_SOURCES
    test_custom_callbacks.cpp
    main.cpp)

enable_testing()

function(spdlog_prepare_test test_target spdlog_lib)
    add_executable(${test_target} ${SPDLOG_UTESTS_SOURCES})
    spdlog_enable_warnings(${test_target})
    target_link_libraries(${test_target} PRIVATE ${spdlog_lib})
    if(systemd_FOUND)
        target_link_libraries(${test_target} PRIVATE ${systemd_LIBRARIES})
    endif()
    if(SPDLOG_SANITIZE_ADDRESS)
        spdlog_enable_sanitizer(${test_target})
    endif()
    add_test(NAME ${test_target} COMMAND ${test_target})
    set_tests_properties(${test_target} PROPERTIES RUN_SERIAL ON)
endfunction()

# The compiled library tests
if(SPDLOG_BUILD_TESTS OR SPDLOG_BUILD_ALL)
    spdlog_prepare_test(spdlog-utests spdlog::spdlog)
endif()

# The header-only library version tests
if(SPDLOG_BUILD_TESTS_HO OR SPDLOG_BUILD_ALL)
    spdlog_prepare_test(spdlog-utests-ho spdlog::spdlog_header_only)
endif()
