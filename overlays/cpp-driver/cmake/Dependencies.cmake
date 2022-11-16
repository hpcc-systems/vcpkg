# ------------------------
# Windows libraries
# ------------------------

if(WIN32)
  # Assign additional library requirements for Windows
  set(CASS_LIBS ${CASS_LIBS} iphlpapi psapi wsock32 crypt32 ws2_32 userenv version)
endif()

# ------------------------
# Libuv
# ------------------------
find_package(libuv CONFIG REQUIRED)

# Assign libuv include and libraries
# set(CASS_INCLUDES ${CASS_INCLUDES} ${LIBUV_INCLUDE_DIRS})
set(CASS_LIBS ${CASS_LIBS} $<IF:$<TARGET_EXISTS:uv_a>,uv_a,uv>)

# libuv and gtests require thread library
if(NOT WIN32)
  set(CMAKE_THREAD_PREFER_PTHREAD 1)
  set(THREADS_PREFER_PTHREAD_FLAG 1)
endif()

find_package(Threads REQUIRED)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_THREAD_LIBS_INIT}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_THREAD_LIBS_INIT}")
if(NOT WIN32 AND ${CMAKE_VERSION} VERSION_LESS "3.1.0")
  # FindThreads in CMake versions < v3.1.0 do not have the THREADS_PREFER_PTHREAD_FLAG to prefer -pthread
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
endif()

#------------------------
# OpenSSL
#------------------------

if(CASS_USE_OPENSSL)
  if(NOT WIN32)
    set(_OPENSSL_ROOT_PATHS "${PROJECT_SOURCE_DIR}/lib/openssl/")
    set(_OPENSSL_ROOT_HINTS ${OPENSSL_ROOT_DIR} $ENV{OPENSSL_ROOT_DIR})
    set(_OPENSSL_ROOT_HINTS_AND_PATHS
        HINTS ${_OPENSSL_ROOT_HINTS}
        PATHS ${_OPENSSL_ROOT_PATHS})
  else()
    if(NOT DEFINED OPENSSL_ROOT_DIR)
      # FindOpenSSL overrides _OPENSSL_ROOT_HINTS and _OPENSSL_ROOT_PATHS on Windows
      # however it utilizes OPENSSL_ROOT_DIR when it sets these values
      set(OPENSSL_ROOT_DIR "${PROJECT_SOURCE_DIR}/lib/openssl/"
                           "${PROJECT_SOURCE_DIR}/build/libs/openssl/")
    endif()
  endif()

  # Discover OpenSSL and assign OpenSSL include and libraries
  if(WIN32 AND OPENSSL_VERSION) # Store the current version of OpenSSL to prevent corruption
    set(SAVED_OPENSSL_VERSION ${OPENSSL_VERSION})
  endif()
  find_package(OpenSSL)
  if(WIN32 AND NOT OPENSSL_FOUND)
    message(STATUS "Unable to Locate OpenSSL: Third party build step will be performed")
    if(SAVED_OPENSSL_VERSION)
      set(OPENSSL_VERSION ${SAVED_OPENSSL_VERSION})
    endif()
    include(ExternalProject-OpenSSL)
  elseif(NOT OPENSSL_FOUND)
    message(FATAL_ERROR "Unable to Locate OpenSSL: Ensure OpenSSL is installed in order to build the driver")
  else()
    set(openssl_name "OpenSSL")
    if(LIBRESSL_FOUND)
      set(openssl_name "LibreSSL")
    endif()
    message(STATUS "${openssl_name} version: v${OPENSSL_VERSION}")
  endif()
  set(CASS_INCLUDES ${CASS_INCLUDES} ${OPENSSL_INCLUDE_DIR})
  set(CASS_LIBS ${CASS_LIBS} ${OPENSSL_LIBRARY_DIR})
endif()

#------------------------
# ZLIB
#------------------------

find_package(ZLIB REQUIRED)

# Assign zlib properties
set(CASS_INCLUDES ${CASS_INCLUDES} ${ZLIB_INCLUDE_DIRS})
set(CASS_LIBS ${CASS_LIBS} ${ZLIB_LIBRARIES})

#------------------------
# Kerberos
#------------------------

if(CASS_USE_KERBEROS)
  # Discover Kerberos and assign Kerberos include and libraries
  find_package(Kerberos REQUIRED)
  set(CASS_INCLUDES ${CASS_INCLUDES} ${KERBEROS_INCLUDE_DIR})
  set(CASS_LIBS ${CASS_LIBS} ${KERBEROS_LIBRARIES})
endif()

#------------------------
# Boost
#------------------------

if(CASS_USE_BOOST_ATOMIC)
  # Allow for boost directory to be specified on the command line
  if(NOT DEFINED ENV{BOOST_ROOT})
    if(EXISTS "${PROJECT_SOURCE_DIR}/lib/boost/")
      set(ENV{BOOST_ROOT} "${PROJECT_SOURCE_DIR}/lib/boost/")
    elseif(EXISTS "${PROJECT_SOURCE_DIR}/build/libs/boost/")
      set(ENV{BOOST_ROOT} "${PROJECT_SOURCE_DIR}/build/libs/boost/")
    endif()
  endif()
  if(BOOST_ROOT_DIR)
    if(EXISTS ${BOOST_ROOT_DIR})
      set(ENV{BOOST_ROOT} ${BOOST_ROOT_DIR})
    endif()
  endif()

  # Ensure Boost auto linking is disabled (defaults to auto linking on Windows)
  if(WIN32)
    add_definitions(-DBOOST_ALL_NO_LIB)
  endif()

  # Check for general Boost availability
  find_package(Boost ${CASS_MINIMUM_BOOST_VERSION})
  if(CASS_USE_BOOST_ATOMIC)
    if(NOT Boost_INCLUDE_DIRS)
      message(FATAL_ERROR "Boost headers required to build driver because of -DCASS_USE_BOOST_ATOMIC=On")
    endif()

    # Assign Boost include for atomics
    set(CASS_INCLUDES ${CASS_INCLUDES} ${Boost_INCLUDE_DIRS})
  endif()

  # Determine if additional Boost definitions are required for driver/executables
  if(NOT WIN32)
    # Handle explicit initialization warning in atomic/details/casts
    add_definitions(-Wno-missing-field-initializers)
  endif()
endif()

