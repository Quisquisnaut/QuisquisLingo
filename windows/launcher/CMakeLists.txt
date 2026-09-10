cmake_minimum_required(VERSION 3.15)
project(qql_bootstrap_launcher LANGUAGES CXX)

if(NOT WIN32 OR NOT MSVC)
  message(FATAL_ERROR "The QuisquisLingo bootstrap launcher requires MSVC on Windows.")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
  message(FATAL_ERROR "The QuisquisLingo bootstrap launcher is x64-only.")
endif()

set(QQL_LAUNCHER_LOGIC_SOURCES
  "launcher_logic.cpp"
  "launcher_logic.h"
)

add_executable(qql_bootstrap_launcher WIN32
  "launcher_main.cpp"
  ${QQL_LAUNCHER_LOGIC_SOURCES}
  "Launcher.rc"
  "launcher.exe.manifest"
)

set_target_properties(qql_bootstrap_launcher PROPERTIES
  OUTPUT_NAME "QuisquisLingo"
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)
target_compile_features(qql_bootstrap_launcher PRIVATE cxx_std_17)
target_compile_options(qql_bootstrap_launcher PRIVATE
  /W4
  /WX
  /permissive-
  /EHsc
  "$<$<CONFIG:Debug>:/MTd>"
  "$<$<NOT:$<CONFIG:Debug>>:/MT>"
)
target_compile_definitions(qql_bootstrap_launcher PRIVATE
  UNICODE
  _UNICODE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
  _WIN32_WINNT=0x0601
)
target_link_libraries(qql_bootstrap_launcher PRIVATE
  comctl32.lib
  shell32.lib
  user32.lib
)

install(TARGETS qql_bootstrap_launcher
  RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime
)

# Native launcher tests are deliberately excluded from normal Flutter builds
# and packaged output. The packaging script builds and runs them explicitly.
add_executable(qql_bootstrap_launcher_tests EXCLUDE_FROM_ALL
  "launcher_tests.cpp"
  ${QQL_LAUNCHER_LOGIC_SOURCES}
)
set_target_properties(qql_bootstrap_launcher_tests PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)
target_compile_features(qql_bootstrap_launcher_tests PRIVATE cxx_std_17)
target_compile_options(qql_bootstrap_launcher_tests PRIVATE
  /W4
  /WX
  /permissive-
  /EHsc
  "$<$<CONFIG:Debug>:/MTd>"
  "$<$<NOT:$<CONFIG:Debug>>:/MT>"
)
target_compile_definitions(qql_bootstrap_launcher_tests PRIVATE
  UNICODE
  _UNICODE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
  _WIN32_WINNT=0x0601
)
target_link_libraries(qql_bootstrap_launcher_tests PRIVATE shell32.lib)

add_executable(qql_bootstrap_child_probe EXCLUDE_FROM_ALL
  "launcher_child_probe.cpp"
)
set_target_properties(qql_bootstrap_child_probe PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)
target_compile_features(qql_bootstrap_child_probe PRIVATE cxx_std_17)
target_compile_options(qql_bootstrap_child_probe PRIVATE
  /W4
  /WX
  /permissive-
  /EHsc
  "$<$<CONFIG:Debug>:/MTd>"
  "$<$<NOT:$<CONFIG:Debug>>:/MT>"
)
target_compile_definitions(qql_bootstrap_child_probe PRIVATE
  UNICODE
  _UNICODE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
  _WIN32_WINNT=0x0601
)

add_executable(qql_bootstrap_package_tests EXCLUDE_FROM_ALL
  "launcher_package_tests.cpp"
  ${QQL_LAUNCHER_LOGIC_SOURCES}
)
set_target_properties(qql_bootstrap_package_tests PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)
target_compile_features(qql_bootstrap_package_tests PRIVATE cxx_std_17)
target_compile_options(qql_bootstrap_package_tests PRIVATE
  /W4
  /WX
  /permissive-
  /EHsc
  "$<$<CONFIG:Debug>:/MTd>"
  "$<$<NOT:$<CONFIG:Debug>>:/MT>"
)
target_compile_definitions(qql_bootstrap_package_tests PRIVATE
  UNICODE
  _UNICODE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
  _WIN32_WINNT=0x0601
)
target_link_libraries(qql_bootstrap_package_tests PRIVATE user32.lib)

add_dependencies(qql_bootstrap_package_tests
  qql_bootstrap_launcher
  qql_bootstrap_child_probe
)

enable_testing()
add_test(NAME qql_bootstrap_launcher_unit_tests
  COMMAND $<TARGET_FILE:qql_bootstrap_launcher_tests>
)
