######################################################################################
# Library Build Type Options
######################################################################################

MACRO(OPTION_LIBRARY_BUILD_STATIC DEFAULT)
  OPTION(BUILD_STATIC "Build static libraries" ${DEFAULT})

  IF(BUILD_STATIC)
	LIST(APPEND BUILDSYS_LIB_TYPES STATIC)
	MESSAGE(STATUS "Building Static Libraries for ${CMAKE_PROJECT_NAME}")
  ELSE()
  	MESSAGE(STATUS "NOT Building Static Libraries for ${CMAKE_PROJECT_NAME}")
  ENDIF()
ENDMACRO()

MACRO(OPTION_USE_STATIC_SUFFIX DEFAULT)
  OPTION(USE_STATIC_SUFFIX "If building static libraries, suffix their name with _s. Handy on windows when building both." ${DEFAULT})

  IF(USE_STATIC_SUFFIX)
	MESSAGE(STATUS "Building Static Libraries with suffix '_s'")
  ELSE()
  	MESSAGE(STATUS "Building Static Libraries with same name as shared (may cause issues on windows)")
  ENDIF()
ENDMACRO()

MACRO(OPTION_LIBRARY_BUILD_SHARED DEFAULT)
  OPTION(BUILD_SHARED "Build shared libraries" ${DEFAULT})

  IF(BUILD_SHARED)
	LIST(APPEND BUILDSYS_LIB_TYPES SHARED)
	MESSAGE(STATUS "Building Shared Libraries for ${CMAKE_PROJECT_NAME}")
  ELSE()
  	MESSAGE(STATUS "NOT Building Shared Libraries for ${CMAKE_PROJECT_NAME}")
  ENDIF()
ENDMACRO()

MACRO(OPTION_LIBRARY_BUILD_FRAMEWORK DEFAULT)
  IF(APPLE)
    OPTION(BUILD_FRAMEWORK "Build OS X Frameworks" ${DEFAULT})

    IF(BUILD_FRAMEWORK)
	  LIST(APPEND BUILDSYS_LIB_TYPES FRAMEWORK)
	  MESSAGE(STATUS "Building Shared Libraries for ${CMAKE_PROJECT_NAME}")
    ELSE()
  	  MESSAGE(STATUS "NOT Building Shared Libraries for ${CMAKE_PROJECT_NAME}")
    ENDIF()
  ENDIF()
ENDMACRO()

######################################################################################
# RPATH Relink Options
######################################################################################

MACRO(OPTION_BUILD_RPATH DEFAULT)
  OPTION(SET_BUILD_RPATH "Set the build RPATH to local directories, relink to install directories at install time" ${DEFAULT})

  IF(SET_BUILD_RPATH)
  	MESSAGE(STATUS "Setting build RPATH for ${CMAKE_PROJECT_NAME}")
	# use, i.e. don't skip the full RPATH for the build tree
	SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
    
	# when building, don't use the install RPATH already
	# (but later on when installing)
	SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE) 
    
	# the RPATH to be used when installing
	SET(CMAKE_INSTALL_RPATH "${LIBRARY_INSTALL_DIR}")
    
	# add the automatically determined parts of the RPATH
	# which point to directories outside the build tree to the install RPATH
	SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
  ELSE()
    MESSAGE(STATUS "NOT Setting build RPATH for ${CMAKE_PROJECT_NAME}")
  ENDIF()
ENDMACRO()

######################################################################################
# Create software version code file
######################################################################################

MACRO(OPTION_CREATE_VERSION_FILE DEFAULT OUTPUT_FILES)
  OPTION(CREATE_VERSION_FILE "Creates a version.cc file using the setlocalversion script" ${DEFAULT})
  IF(CREATE_VERSION_FILE)
	MESSAGE(STATUS "Generating git information for ${CMAKE_PROJECT_NAME}")	
	FOREACH(VERSION_FILE ${OUTPUT_FILES})
	  MESSAGE(STATUS "- Generating to ${VERSION_FILE}")	
      SET(COMMAND_LIST "python" "${BUILDSYS_CMAKE_DIR}/../python/get_version.py" "-f" "${VERSION_FILE}" "-d" "${CMAKE_SOURCE_DIR}")
 	  EXECUTE_PROCESS(COMMAND ${COMMAND_LIST})
	ENDFOREACH(VERSION_FILE ${OUTPUT_FILES})
  ELSE()
	MESSAGE(STATUS "NOT generating git information for ${CMAKE_PROJECT_NAME}")	
  ENDIF()
ENDMACRO()

######################################################################################
# Turn on GProf based profiling 
######################################################################################

MACRO(OPTION_GPROF DEFAULT)
  IF(CMAKE_COMPILER_IS_GNUCXX)
	OPTION(ENABLE_GPROF "Compile using -g -pg for gprof output" ${DEFAULT})
	IF(ENABLE_GPROF)
	  MESSAGE(STATUS "Using gprof output for ${CMAKE_PROJECT_NAME}")
	  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -pg")
	  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -pg")
	  SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -g -pg")
	  SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -g -pg")
	ELSE()
	  MESSAGE(STATUS "NOT using gprof output for ${CMAKE_PROJECT_NAME}")
	ENDIF()
  ELSE()
	MESSAGE(STATUS "gprof generation NOT AVAILABLE - Not a GNU compiler")
  ENDIF()
ENDMACRO()

######################################################################################
# Turn on "extra" compiler warnings (SPAMMY WITH BOOST)
######################################################################################

MACRO(OPTION_EXTRA_COMPILER_WARNINGS DEFAULT)
  IF(CMAKE_COMPILER_IS_GNUCXX)
	OPTION(EXTRA_COMPILER_WARNINGS "Turn on -Wextra for gcc" ${DEFAULT})
	IF(EXTRA_COMPILER_WARNINGS)
	  MESSAGE(STATUS "Turning on extra c/c++ warnings for ${CMAKE_PROJECT_NAME}")
	  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wextra")
	  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra")
	ELSE()
	  MESSAGE(STATUS "NOT turning on extra c/c++ warnings for ${CMAKE_PROJECT_NAME}")
	ENDIF()
  ELSE()
	MESSAGE(STATUS "Extra compiler warnings NOT AVAILABLE - Not a GNU compiler")
  ENDIF()
ENDMACRO()

######################################################################################
# Turn on effective C++ compiler warnings
######################################################################################

MACRO(OPTION_EFFCXX_COMPILER_WARNINGS DEFAULT)
  IF(CMAKE_COMPILER_IS_GNUCXX)
	OPTION(EFFCXX_COMPILER_WARNINGS "Turn on -Weffc++ (effective c++ warnings) for gcc" ${DEFAULT})
	IF(EFFCXX_COMPILER_WARNINGS)
	  MESSAGE(STATUS "Turning on Effective c++ warnings for ${CMAKE_PROJECT_NAME}")
	  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Weffc++")
	ELSE()
	  MESSAGE(STATUS "NOT turning on Effective c++ warnings for ${CMAKE_PROJECT_NAME}")
	ENDIF()
  ELSE()
	MESSAGE(STATUS "Effective C++ compiler warnings NOT AVAILABLE - Not a GNU compiler")
  ENDIF()
ENDMACRO()

######################################################################################
# Return type compiler warnings
######################################################################################

MACRO(OPTION_RETURN_TYPE_COMPILER_WARNINGS DEFAULT)
  IF(CMAKE_COMPILER_IS_GNUCXX)
	OPTION(RETURN_TYPE_COMPILER_WARNINGS "Turn on -Wreturn-type for gcc" ${DEFAULT})
	IF(RETURN_TYPE_COMPILER_WARNINGS)
	  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wreturn-type")
	  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wreturn-type")
	  MESSAGE(STATUS "Turning on return type warnings for ${CMAKE_PROJECT_NAME}")
	ELSE()
	  MESSAGE(STATUS "NOT turning on return type warnings for ${CMAKE_PROJECT_NAME}")
	ENDIF()
  ELSE()
	MESSAGE(STATUS "Return type warnings NOT AVAILABLE - Not a GNU compiler")
  ENDIF()
ENDMACRO()

######################################################################################
# Force 32-bit, regardless of the platform we're on
######################################################################################

MACRO(OPTION_FORCE_32_BIT DEFAULT)
  IF(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
	IF(CMAKE_COMPILER_IS_GNUCXX)
	  OPTION(FORCE_32_BIT "Force compiler to use -m32 when compiling" ${DEFAULT})
	  IF(FORCE_32_BIT)
		MESSAGE(STATUS "Forcing 32-bit on 64-bit platform (using -m32)")
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
		SET(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -m32")
		SET(CMAKE_LINK_FLAGS "${CMAKE_CXX_FLAGS} -m32")
	  ELSE()
		MESSAGE(STATUS "Not forcing 32-bit on 64-bit platform")
	  ENDIF()
	ELSE()
	  MESSAGE(STATUS "Force 32 bit NOT AVAILABLE - Not using gnu compiler")
	ENDIF()
  ELSE({CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
	MESSAGE(STATUS "Force 32 bit NOT AVAILABLE - Already on a 32 bit platform")
  ENDIF()
ENDMACRO()
