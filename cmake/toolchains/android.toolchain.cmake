# ------------------------------------------------------------------------------
#  Android CMake toolchain file, for use with the Android NDK r9d.
#  Requires cmake 2.8.3 or newer.
#
#  This toolchain was designed to be used by the SFML project but you can reuse
#  it for your own project.
#
#  This toolchain doesn't support compiling with a standalone toolchain or
#  with clang compilers.
#
#  This toolchain doesn't support "release minsize" and "release with debug
#  info" build as well as the creation of module or executable. Only static and
#  shared build in either release or debug mode are allowed.
#
#  Usage Windows:
#   > set ANDROID_NDK="C:\absolute\path\to\android-ndk
#   > mkdir build && cd build
#   > cmake -G "MinGW Makefiels" -DCMAKE_TOOLCHAIN_FILE=path\to\the\android.toolchain.cmake ..
#   > mingw32-make -j8
#
#  Usage Linux & Mac:
#   $ export ANDROID_NDK=/absolute/path/to/the/android-ndk
#   $ mkdir build && cd build
#   $ cmake -DCMAKE_TOOLCHAIN_FILE=path/to/the/android.toolchain.cmake ..
#   $ make -j8
#
#  Options (can be set as cmake parameters: -D<option_name>=<value>):
#
#    ANDROID_NDK=/absolute/path/to/android-ndk - Path to the NDK directory.
#
#      Can be set as environment variable. Can be set only at first cmake run.
#
#    ANDROID_ABI=armeabi-v7a - Specifies the target architecture
#
#      Possible targets are:
#        "armeabi"     - Compile for ARM architecture
#        "armeabi-v7a" - Compile for ARM architecture v7-a
#        "x86"         - Compile for x86 architecture
#        "mips"        - Compile for MIPS architecture
#
#    ANDROID_STL="system" - Specifies the STL version to link against.
#
#      Possible values are:
#        "system"  - Use the minimal system C++ runtime library
#        "gabi++"  - Use the GAbi++ runtime
#        "stlport" - Use the STLport runtime
#        "gnustl"  - Use the GNU STL
#        "c++"     - Use the LLVM libc++ (default)
#
#    ANDROID_API_LEVEL="9" - Specifies the level of the Android API to use.
#
#      Possible values are:
#        "3"  - Correspond to Android 1.5 system images
#        "4"  - Correspond to Android 1.6 system images
#        "5"  - Correspond to Android 2.0 system images
#        "6"  - Correspond to Android 2.0.1 system images
#        "7"  - Correspond to Android 2.1 system images
#        "8"  - Correspond to Android 2.2 system images
#        "9"  - Correspond to Android 2.3 system images
#        "14" - Correspond to Android 4.0 system images
#        "18" - Correspond to Android 4.3 system images
#
#    ANDROID_COMPILER_VERSION="4.8" - Specifies compiler version
#
#      Possible values are:
#        "4.6" - Use version 4.6 of GNU toolchains
#        "4.8" - Use version 4.8 of GNU toolchain (default)
#
#

cmake_minimum_required(VERSION 2.8.3)

# on some platforms (OSX) this may not be defined, so search for it
if(NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
    find_program(CMAKE_INSTALL_NAME_TOOL install_name_tool)
endif()

# subsequent toolchain loading is not really needed
if(DEFINED CMAKE_CROSSCOMPILING)
    return()
endif()

# locate the android ndk and make sure it points to an existing directory
if(NOT DEFINED ANDROID_NDK)
    set(ANDROID_NDK $ENV{ANDROID_NDK})
endif()
if(NOT IS_DIRECTORY ${ANDROID_NDK})
    message(FATAL_ERROR "The ANDROID_NDK variable points to an unexisting directory.")
endif()

# set default option value
if(NOT DEFINED ANDROID_ABI)
    set(ANDROID_ABI "armeabi-v7a")
endif()
if(NOT DEFINED ANDROID_API_LEVEL)
    set(ANDROID_API_LEVEL 9)
endif()
if(NOT DEFINED ANDROID_COMPILER_VERSION)
    set(ANDROID_COMPILER_VERSION "4.8")
endif()
if(NOT DEFINED ANDROID_STL)
    set(ANDROID_STL "c++")
endif()

# compiling for x86 and mips arches are only supported since API level 9
if(ANDROID_API_LEVEL LESS 9)
    if(ANDROID_ABI STREQUAL "x86" OR ANDROID_ABI STREQUAL "mips")
        message(FATAL_ERROR "Compiling for x86 and mips arches are only supported since API level 9")
    endif()
endif()

# we want to add the ".exe" suffix if we are on windows
set(EXE_SUFFIX "")
if(CMAKE_HOST_WIN32)
    set(EXE_SUFFIX ".exe")
endif()

# define the compiler name and codename
if(ANDROID_ABI STREQUAL "armeabi" OR ANDROID_ABI STREQUAL "armeabi-v7a")
    set(COMPILER_NAME     "arm-linux-androideabi")
    set(COMPILER_CODENAME "arm-linux-androideabi")
elseif(ANDROID_ABI STREQUAL "x86")
    set(COMPILER_NAME     "i686-linux-android")
    set(COMPILER_CODENAME "x86")
elseif(ANDROID_ABI STREQUAL "mips")
    set(COMPILER_NAME     "mipsel-linux-android")
    set(COMPILER_CODENAME "mipsel-linux-android")
endif()

# define the architecture name
if(ANDROID_ABI STREQUAL "armeabi" OR ANDROID_ABI STREQUAL "armeabi-v7a")
    set(ARCHITECTURE_NAME "arm")
elseif(ANDROID_ABI STREQUAL "x86")
    set(ARCHITECTURE_NAME "x86")
elseif(ANDROID_ABI STREQUAL "mips")
    set(ARCHITECTURE_NAME "mips")
endif()

# define the STL codename
if(ANDROID_STL STREQUAL "system")
    set(STL_CODENAME "system")
elseif(ANDROID_STL STREQUAL "gabi++")
    set(STL_CODENAME "gabi++")
elseif(ANDROID_STL STREQUAL "stlport")
    set(STL_CODENAME "stlport")
elseif(ANDROID_STL STREQUAL "gnustl")
    set(STL_CODENAME "gnu-libstdc++")
elseif(ANDROID_STL STREQUAL "c++")
    set(STL_CODENAME "llvm-libc++")
endif()

# define the platform codename (according the host OS)
if(CMAKE_HOST_WIN32)
    set(PLATFORM_CODENAME "windows")
    if(NOT EXISTS "${ANDROID_NDK}/toolchains/${COMPILER_CODENAME}-${ANDROID_COMPILER_VERSION}/prebuilt/${PLATFORM_CODENAME}")
        set(PLATFORM_CODENAME "windows-x86_64")
    endif()
elseif(CMAKE_HOST_APPLE)
    set(PLATFORM_CODENAME "darwin-x86")
    if(NOT EXISTS "${ANDROID_NDK}/toolchains/${COMPILER_CODENAME}-${ANDROID_COMPILER_VERSION}/prebuilt/${PLATFORM_CODENAME}")
        set(PLATFORM_CODENAME "darwin-x86_64")
    endif()
elseif(CMAKE_HOST_UNIX)
    set(PLATFORM_CODENAME "linux-x86")
    if(NOT EXISTS "${ANDROID_NDK}/toolchains/${COMPILER_CODENAME}-${ANDROID_COMPILER_VERSION}/prebuilt/${PLATFORM_CODENAME}")
        set(PLATFORM_CODENAME "linux-x86_64")
    endif()
else()
    message(FATAL_ERROR "Cross-compilation on your platform is not supported by this cmake toolchain")
endif()

# define the compiler, sysroot and stl path
set(COMPILER_PATH "${ANDROID_NDK}/toolchains/${COMPILER_CODENAME}-${ANDROID_COMPILER_VERSION}/prebuilt/${PLATFORM_CODENAME}/bin")
set(SYSROOT_PATH  "${ANDROID_NDK}/platforms/android-${ANDROID_API_LEVEL}/arch-${ARCHITECTURE_NAME}")
set(STL_PATH      "${ANDROID_NDK}/sources/cxx-stl/${STL_CODENAME}")

# set up the compiler to find and link against the chosen STL library
if(ANDROID_STL STREQUAL "system")
    include_directories("${STL_PATH}/include")
elseif(ANDROID_STL STREQUAL "gabi++")
    include_directories("${STL_PATH}/include")
    link_directories("${STL_PATH}/libs/${ANDROID_ABI}")
    set(STL_STATIC_LIBRARY "-lgabi++_static")
    set(STL_SHARED_LIBRARY "-lgabi++_shared")
elseif(ANDROID_STL STREQUAL "stlport")
    include_directories("${STL_PATH}/stlport")
    link_directories("${STL_PATH}/libs/${ANDROID_ABI}")
    set(STL_STATIC_LIBRARY "-lstlport_static")
    set(STL_SHARED_LIBRARY "-lstlport_shared")
elseif(ANDROID_STL STREQUAL "gnustl")
    include_directories("${STL_PATH}/${ANDROID_COMPILER_VERSION}/include")
    include_directories("${STL_PATH}/${ANDROID_COMPILER_VERSION}/libs/${ANDROID_ABI}/include")
    link_directories("${STL_PATH}/${ANDROID_COMPILER_VERSION}/libs/${ANDROID_ABI}")
    set(STL_STATIC_LIBRARY "-lgnustl_static")
    set(STL_SHARED_LIBRARY "-lgnustl_shared")
elseif(ANDROID_STL STREQUAL "c++")
    include_directories("${STL_PATH}/libcxx/include")
    include_directories("${ANDROID_NDK}/sources/android/support/include")
    link_directories("${STL_PATH}/libs/${ANDROID_ABI}")
    set(STL_STATIC_LIBRARY "-lc++_static")
    set(STL_SHARED_LIBRARY "-lc++_shared")
endif()

# additional android flags (see document ndk/docs/STANDALONE-TOOLCHAIN.html)
set(ANDROID_EXTRA_FLAGS "")
if(ANDROID_ABI STREQUAL "armeabi")
    set(ANDROID_EXTRA_COMPILE_FLAGS "-mthumb")
    set(ANDROID_EXTRA_COMPILE_FLAGS "${ANDROID_EXTRA_COMPILE_FLAGS} -fPIC -Wno-psabi -frtti -fno-exceptions -mthumb -O3 -fomit-frame-pointer -DNDEBUG")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    #set(ANDROID_EXTRA_COMPILE_FLAGS "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16")
    #set(ANDROID_EXTRA_COMPILE_FLAGS "${ANDROID_EXTRA_COMPILE_FLAGS} -fPIC -Wno-psabi -frtti -fno-exceptions -mthumb -O3 -fomit-frame-pointer -DNDEBUG")
    set(ANDROID_EXTRA_COMPILE_FLAGS "-fsigned-char -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fdata-sections -ffunction-sections -fPIC -Wno-psabi -frtti -fno-exceptions -mthumb -O3 -fomit-frame-pointer ")
    #set(ANDROID_EXTRA_LINK_FLAGS "-fsigned-char -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fdata-sections -ffunction-sections -fPIC -Wno-psabi -frtti -fno-exceptions -mthumb -O3 -fomit-frame-pointer ")
    set(ANDROID_EXTRA_LINK_FLAGS "-Wl,--fix-cortex-a8 -Wl,--gc-sections -Wl,--no-undefined")
endif()
#set(ANDROID_EXTRA_LINK_FLAGS "-Wl,-z,nocopyreloc")

# set up the cross compiler
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_C_COMPILER     "${COMPILER_PATH}/${COMPILER_NAME}-gcc${EXE_SUFFIX}" CACHE PATH "C compiler.")
set(CMAKE_CXX_COMPILER   "${COMPILER_PATH}/${COMPILER_NAME}-g++${EXE_SUFFIX}" CACHE PATH "CXX compiler.")
set(CMAKE_FIND_ROOT_PATH "${SYSROOT_PATH}")

# define unneeded stuff for cmake to be happy
set(CMAKE_STRIP   "${COMPILER_PATH}/${COMPILER_NAME}-strip${EXE_SUFFIX}"   CACHE PATH "Path to a program.")
set(CMAKE_AR      "${COMPILER_PATH}/${COMPILER_NAME}-ar${EXE_SUFFIX}"      CACHE PATH "Path to a program.")
set(CMAKE_LINKER  "${COMPILER_PATH}/${COMPILER_NAME}-ld${EXE_SUFFIX}"      CACHE PATH "Path to a program.")
set(CMAKE_NM      "${COMPILER_PATH}/${COMPILER_NAME}-nm${EXE_SUFFIX}"      CACHE PATH "Path to a program.")
set(CMAKE_OBJCOPY "${COMPILER_PATH}/${COMPILER_NAME}-objcopy${EXE_SUFFIX}" CACHE PATH "Path to a program.")
set(CMAKE_OBJDUMP "${COMPILER_PATH}/${COMPILER_NAME}-objdump${EXE_SUFFIX}" CACHE PATH "Path to a program.")
set(CMAKE_RANLIB  "${COMPILER_PATH}/${COMPILER_NAME}-ranlib${EXE_SUFFIX}"  CACHE PATH "Path to a program.")

# add android preprocessor definitions
add_definitions(-DANDROID)

# global compilation flags
set(CMAKE_C_FLAGS   "${ANDROID_EXTRA_FLAGS} --sysroot=\"${SYSROOT_PATH}\"")
set(CMAKE_CXX_FLAGS "${ANDROID_EXTRA_FLAGS} --sysroot=\"${SYSROOT_PATH}\"")

# release and debug compilation flags
set(CMAKE_C_FLAGS_RELEASE   "")
set(CMAKE_C_FLAGS_DEBUG     "")
set(CMAKE_CXX_FLAGS_RELEASE "${ANDROID_EXTRA_COMPILE_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG   "")

# release and debug linker flags
set(CMAKE_STATIC_LINKER_FLAGS         "")
set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "")
set(CMAKE_STATIC_LINKER_FLAGS_DEBUG   "")
set(CMAKE_SHARED_LINKER_FLAGS         "${STL_SHARED_LIBRARY} ${ANDROID_EXTRA_LINK_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG   "")

# cache flags
set(CMAKE_C_FLAGS           "${CMAKE_C_FLAGS}"           CACHE STRING "Flags used by the compiler during all build types.")
set(CMAKE_C_FLAGS_RELEASE   "${CMAKE_C_FLAGS_RELEASE}"   CACHE STRING "Flags used by the compiler during release builds.")
set(CMAKE_C_FLAGS_DEBUG     "${CMAKE_C_FLAGS_DEBUG}"     CACHE STRING "Flags used by the compiler during debug builds.")

set(CMAKE_CXX_FLAGS         "${CMAKE_CXX_FLAGS}"         CACHE STRING "Flags used by the compiler during all build types." )
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" CACHE STRING "Flags used by the compiler during release builds.")
set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG}"   CACHE STRING "Flags used by the compiler during debug builds.")

set(CMAKE_STATIC_LINKER_FLAGS         "${CMAKE_STATIC_LINKER_FLAGS}"         CACHE STRING "Flags used by the linker during the creation of static libraries.")
set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "${CMAKE_STATIC_LINKER_FLAGS_RELEASE}" CACHE STRING "Flags used by the linker during release builds.")
set(CMAKE_STATIC_LINKER_FLAGS_DEBUG   "${CMAKE_STATIC_LINKER_FLAGS_DEBUG}"   CACHE STRING "Flags used by the linker during debug builds.")

set(CMAKE_SHARED_LINKER_FLAGS         "${CMAKE_SHARED_LINKER_FLAGS}"         CACHE STRING "Flags used by the linker during the creation of shared libraries.")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}" CACHE STRING "Flags used by the linker during release builds.")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG   "${CMAKE_SHARED_LINKER_FLAGS_DEBUG}"   CACHE STRING "Flags used by the linker during debug builds.")

# macro to find packages on the host OS
macro(find_host_package)
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)

    if(CMAKE_HOST_WIN32)
        set(WIN32)
        set(UNIX)
    elseif(CMAKE_HOST_APPLE)
        set(APPLE)
        set(UNIX)
    endif()

    find_package(${ARGN})

    set(WIN32)
    set(APPLE)
    set(UNIX)

    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endmacro()

# global flag for cmake client scripts to change behavior
set(ANDROID 1)
