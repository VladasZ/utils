cmake_minimum_required(VERSION 3.9.2 FATAL_ERROR)

cmake_policy(SET CMP0049 OLD)

set(DEPS_ROOT $ENV{HOME}/.deps)

include(${DEPS_ROOT}/build_tools/deps.cmake)

set(CMAKE_CXX_STANDARD 17)

set_property(GLOBAL PROPERTY USE_FOLDERS TRUE)

function(prepend var prefix)
  set(listVar "")
  foreach(f ${ARGN})
    list(APPEND listVar "${prefix}/${f}")
  endforeach(f)
  set(${var} "${listVar}" PARENT_SCOPE)
endfunction(prepend)

function(get_subdirs out dir)
  file(GLOB children RELATIVE ${dir} ${dir}/*)
  foreach(child ${children})
    if (IS_DIRECTORY ${dir}/${child})
      list(APPEND out ${child})
    endif()
  endforeach()
  set(${out} ${${out}} PARENT_SCOPE)
endfunction()

function(get_files out dir)
  file(GLOB children RELATIVE ${dir} ${dir}/*)
  foreach(child ${children})
    if (NOT IS_DIRECTORY ${child})
      list(APPEND out ${child})
    endif()
  endforeach()
  set(${out} ${${out}} PARENT_SCOPE)
endfunction()

function(add_catalog_recursive catalog group_catalog source_files)
  file(GLOB children RELATIVE ${catalog} ${catalog}/*)
  foreach(child ${children})
    if(IS_DIRECTORY ${catalog}/${child})
      add_catalog_recursive(${catalog}/${child} ${group_catalog}/${child} ${source_files})
    else()
      get_filename_component(extension ${child} EXT)
      if (NOT extension STREQUAL "")
        if (USING_OBJC)
          string(REGEX MATCHALL "^.*.[h|m|mm|cpp]" out ${extension})
        else()
          string(REGEX MATCHALL "^.*.[h|cpp]" out ${extension})
        endif()
        if (NOT out STREQUAL "")
          if(MSVC)
            string(REPLACE "/" "\\" group_catalog_name ${group_catalog})
          else()
            set(group_catalog_name ${group_catalog})
          endif()
          set(filename ${catalog}/${child})
          source_group(${group_catalog_name} FILES ${filename})
          include_directories(${catalog})
          set(${source_files} ${${source_files}} ${filename})
        endif()
      endif()
    endif()
  endforeach()
  set(${source_files} ${${source_files}} PARENT_SCOPE)
endfunction(add_catalog_recursive)

macro(include_recursive catalog)
  include_directories(${catalog})
  file(GLOB children RELATIVE ${catalog} ${catalog}/*)
  foreach(child ${children})
    if(IS_DIRECTORY ${catalog}/${child})
      include_directories(${catalog}/${child})
      include_recursive(${catalog}/${child})
    endif()
  endforeach()
endmacro(include_recursive)

macro(link_project project)
  include_recursive(${PROJECT_SOURCE_DIR}/../${project})
  link_from(${project})
  target_link_libraries(${PROJECT_NAME} ${project})
endmacro(link_project)

macro(link_project_at_path linked_project_name path)
  include_recursive(${path})
  target_link_libraries(${PROJECT_NAME} ${linked_project_name})
endmacro(link_project_at_path)

macro(setup_conan_if_needed)
  if(NEEDS_CONAN)
    conan_basic_setup()
  endif()
endmacro()

macro(link_conan_if_needed)
  if(NEEDS_CONAN)
    conan_target_link_libraries(${PROJECT_NAME})
  endif()
endmacro()

macro(set_folder folder)
  set_target_properties(${PROJECT_NAME} PROPERTIES FOLDER "${folder}")
endmacro()

macro(setup_lib lib)
  project(${lib})
  add_catalog_recursive(${PROJECT_SOURCE_DIR} / ${lib}_SOURCE)
  add_library(${PROJECT_NAME} ${${lib}_SOURCE})
  link_conan_if_needed()
  link_and_include_deps(${lib})
  if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
  endif()
endmacro()

macro(setup_shared_lib lib)
  project(${lib})
  add_catalog_recursive(${PROJECT_SOURCE_DIR} / ${lib}_SOURCE)
  add_library(${PROJECT_NAME} SHARED ${${lib}_SOURCE})
  link_conan_if_needed()
  link_and_include_deps(${lib})
  set_folder(libs)
  if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
  endif()
endmacro()

macro(link_from project)
  link_conan_if_needed()
  link_and_include_deps(${project})
endmacro()

macro(_internal_setup_exe exe)
  project(${exe})
  add_catalog_recursive(${PROJECT_SOURCE_DIR} / ${exe}_SOURCE)
  add_executable(${PROJECT_NAME} ${${exe}_SOURCE})
  link_conan_if_needed()
  include_deps(${exe})
  set_folder(tests)
  if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
  endif()
endmacro()

macro(add_deps project)
  foreach(var ${${project}_PROJECTS_TO_ADD})
    add_subdirectory(${var} "${var}/dep_build")
  endforeach()
endmacro()

macro(include_deps project)
  foreach(var ${${project}_PATHS_TO_INCLUDE})
    include_recursive(${var})
  endforeach()
endmacro()

macro(link_deps project)
  foreach(var ${${project}_LIBS_TO_LINK})
    target_link_libraries(${PROJECT_NAME} ${var})
  endforeach()
endmacro()

macro(link lib)
  target_link_libraries(${PROJECT_NAME} ${lib})
endmacro()

macro(link_and_include_deps project)
  link_deps(${project})
  include_deps(${project})
endmacro()

macro(setup_project project)
  project(${project})
  setup_conan_if_needed()
  add_deps(${project})
  add_subdirectory(source/${project})
  if(DESKTOP_BUILD)
    add_subdirectory(source/${project}_test)
  elseif(IOS_BUILD)
    if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
      if(NEEDS_IOS_EXE)
        add_subdirectory(source/${project}_test)
      endif()
    endif()
  endif()
endmacro()

include("~/.deps/build_tools/ios.cmake")

macro(setup_exe exe)
  if(IOS_BUILD)
    _setup_ios_exe(${exe})
  else()
    _internal_setup_exe(${exe})
  endif()
endmacro()

macro(exclude list regex)
  list(FILTER ${list} EXCLUDE REGEX ${regex})
endmacro()
