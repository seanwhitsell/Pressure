######################################################################################
# Parse Arguments Macro (for named argument building)
######################################################################################

#taken from http://www.cmake.org/Wiki/CMakeMacroParseArguments

MACRO(PARSE_ARGUMENTS prefix arg_names option_names)
  SET(DEFAULT_ARGS)
  FOREACH(arg_name ${arg_names})    
    SET(${prefix}_${arg_name})
  ENDFOREACH(arg_name)
  FOREACH(option ${option_names})
    SET(${prefix}_${option} FALSE)
  ENDFOREACH(option)

  SET(current_arg_name DEFAULT_ARGS)
  SET(current_arg_list)
  FOREACH(arg ${ARGN})            
    SET(larg_names ${arg_names})    
    LIST(FIND larg_names "${arg}" is_arg_name)                   
    IF (is_arg_name GREATER -1)
      SET(${prefix}_${current_arg_name} ${current_arg_list})
      SET(current_arg_name ${arg})
      SET(current_arg_list)
    ELSE (is_arg_name GREATER -1)
      SET(loption_names ${option_names})    
      LIST(FIND loption_names "${arg}" is_option)            
      IF (is_option GREATER -1)
		SET(${prefix}_${arg} TRUE)
      ELSE (is_option GREATER -1)
		LIST(APPEND current_arg_list ${arg})
      ENDIF (is_option GREATER -1)
    ENDIF (is_arg_name GREATER -1)
  ENDFOREACH(arg)
  SET(${prefix}_${current_arg_name} ${current_arg_list})
ENDMACRO(PARSE_ARGUMENTS)

######################################################################################
# Compile flag array building macro
######################################################################################

#taken from http://www.cmake.org/pipermail/cmake/2006-February/008334.html

MACRO(SET_COMPILE_FLAGS TARGET)
  SET(FLAGS)
  FOREACH(flag ${ARGN})
    SET(FLAGS "${FLAGS} ${flag}")
  ENDFOREACH(flag)
  SET_TARGET_PROPERTIES(${TARGET} PROPERTIES COMPILE_FLAGS "${FLAGS}")
ENDMACRO(SET_COMPILE_FLAGS)

MACRO(SET_LINK_FLAGS TARGET)
  SET(FLAGS)
  FOREACH(flag ${ARGN})
    SET(FLAGS "${FLAGS} ${flag}")
  ENDFOREACH(flag)
  SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LINK_FLAGS "${FLAGS}")
ENDMACRO(SET_LINK_FLAGS)

######################################################################################
# Generalized library building function for all C++ libraries
######################################################################################

# Function for building libraries
#
# All arguments are prefixed with BUILDSYS_LIB in the function
#
# Arguments
# NAME - name of the library
# SOURCES - list of sources to compile into library
# CXX_FLAGS - flags to pass to the compiler
# LINK_LIBS - libraries to link library to (dynamic libs only)
# LINK_FLAGS - list of flags to use in linking (dynamic libs only)
# DEPENDS - Targets that should be built before this target
# LIB_TYPES_OVERRIDE - override the global types as set by OPTION_BUILD_STATIC/SHARED
# SHOULD_INSTALL - should install commands be generated for this target?
# VERSION - version number for library naming (non-windows dynamic libs only)
# GROUP - Name of the compilation group this should be a part of (so you can build all of a group at once as a target)
# EXCLUDE_FROM_ALL - Don't add as part of all target
#
# When finished, multiple targets are created
# 
# - A target for building the library
# -- [NAME]_[BUILD_TYPE] - i.e. for a static libfoo, there'd be a foo_STATIC target
# - A target for setting dependencies on all versions of the library being built
# -- [NAME]_DEPEND - i.e. foo_DEPEND, which will clear once foo_STATIC/SHARED is built
#

FUNCTION(BUILDSYS_BUILD_LIB)

  # Parse out the arguments
  PARSE_ARGUMENTS(BUILDSYS_LIB
    "NAME;SOURCES;CXX_FLAGS;LINK_LIBS;LINK_FLAGS;DEPENDS;LIB_TYPES_OVERRIDE;SHOULD_INSTALL;VERSION;GROUP;EXCLUDE_FROM_ALL;"
    ""
    ${ARGN}
    )

  # Set up the types of library we want to build (STATIC, DYNAMIC, both)
  IF(BUILDSYS_LIB_LIB_TYPES_OVERRIDE)
	SET(BUILDSYS_LIB_TYPES_LIST ${BUILDSYS_LIB_LIB_TYPES_OVERRIDE})
  ELSE()
	SET(BUILDSYS_LIB_TYPES_LIST ${BUILDSYS_LIB_TYPES})
  ENDIF()

  # Remove all dupes from the source list, otherwise CMake freaks out
  LIST(REMOVE_DUPLICATES BUILDSYS_LIB_SOURCES)

  # Build each library type
  FOREACH(LIB_TYPE ${BUILDSYS_LIB_TYPES_LIST})
    # Setup library name, targets, properties, etc...
    SET(CURRENT_LIB ${BUILDSYS_LIB_NAME}_${LIB_TYPE})

    # To make sure we name our target correctly, but still link against the correct type
    IF(LIB_TYPE STREQUAL "FRAMEWORK")
      SET(TARGET_LIB_TYPE "SHARED")
    ELSE()
      SET(TARGET_LIB_TYPE ${LIB_TYPE})
    ENDIF()

    IF(BUILDSYS_LIB_EXCLUDE_FROM_ALL)
      ADD_LIBRARY (${CURRENT_LIB} EXCLUDE_FROM_ALL ${TARGET_LIB_TYPE} ${BUILDSYS_LIB_SOURCES})
    ELSE()
      ADD_LIBRARY (${CURRENT_LIB} ${TARGET_LIB_TYPE} ${BUILDSYS_LIB_SOURCES})      
    ENDIF()

    # Add this library to the list of all libraries we're building
    LIST(APPEND LIB_DEPEND_LIST ${CURRENT_LIB})

    # This allows use to build static/shared libraries of the same name.
    # See http://www.itk.org/Wiki/CMake_FAQ#How_do_I_make_my_shared_and_static_libraries_have_the_same_root_name.2C_but_different_suffixes.3F
	IF(USE_STATIC_SUFFIX AND LIB_TYPE STREQUAL "STATIC")
      SET_TARGET_PROPERTIES (${CURRENT_LIB} PROPERTIES OUTPUT_NAME ${BUILDSYS_LIB_NAME}_s)
	ELSE()
      SET_TARGET_PROPERTIES (${CURRENT_LIB} PROPERTIES OUTPUT_NAME ${BUILDSYS_LIB_NAME})	  
	ENDIF()
    SET_TARGET_PROPERTIES (${CURRENT_LIB} PROPERTIES CLEAN_DIRECT_OUTPUT 1)

    # Add version, if we're given one
    IF(BUILDSYS_LIB_VERSION)
      SET_TARGET_PROPERTIES (${CURRENT_LIB} PROPERTIES SOVERSION ${BUILDSYS_LIB_VERSION})
      SET_TARGET_PROPERTIES (${CURRENT_LIB} PROPERTIES VERSION ${BUILDSYS_LIB_VERSION})
    ENDIF()

    IF(LIB_TYPE STREQUAL "FRAMEWORK")
      SET_TARGET_PROPERTIES (${CURRENT_LIB} PROPERTIES FRAMEWORK 1)
      # As far as I can find, even in CMake 2.8.2, there's no way to
      # explictly copy header directories. This makes me sad.
      GET_TARGET_PROPERTY(OUT_LIB ${CURRENT_LIB} LOCATION)
      GET_FILENAME_COMPONENT(OUT_DIR ${OUT_LIB} PATH)
      MESSAGE(STATUS ${OUT_DIR})
      ADD_CUSTOM_TARGET(${CURRENT_LIB}_FRAMEWORK_HEADER_COPY
        COMMAND "${CMAKE_COMMAND}" "-E" "make_directory" "${OUT_DIR}/Headers"
        COMMAND "${CMAKE_COMMAND}" "-E" "copy_directory" "${CMAKE_SOURCE_DIR}/include" "${OUT_DIR}/Headers"
        COMMAND "${CMAKE_COMMAND}" "-E" "create_symlink" "Versions/Current/Headers" "${OUT_DIR}/../../Headers")
      ADD_DEPENDENCIES(${CURRENT_LIB} ${CURRENT_LIB}_FRAMEWORK_HEADER_COPY)
    ENDIF()

    # Libraries we should link again
    IF(BUILDSYS_LIB_LINK_LIBS)
	  TARGET_LINK_LIBRARIES(${CURRENT_LIB} ${BUILDSYS_LIB_LINK_LIBS})
    ENDIF()

    # Defines and compiler flags, if any
    IF(BUILDSYS_LIB_CXX_FLAGS)
      SET_COMPILE_FLAGS(${CURRENT_LIB} ${BUILDSYS_LIB_CXX_FLAGS})
    ENDIF()

    # Linker flags, if any
    IF(BUILDSYS_LIB_LINK_FLAGS)
      SET_LINK_FLAGS(${CURRENT_LIB} ${BUILDSYS_LIB_LINK_FLAGS})
    ENDIF()

    # Installation commands
    IF(BUILDSYS_LIB_SHOULD_INSTALL AND NOT BUILDSYS_LIB_EXCLUDE_FROM_ALL)
      INSTALL(TARGETS ${CURRENT_LIB} LIBRARY DESTINATION ${LIBRARY_INSTALL_DIR} ARCHIVE DESTINATION ${LIBRARY_INSTALL_DIR} FRAMEWORK DESTINATION ${FRAMEWORK_INSTALL_DIR})
    ELSEIF(BUILDSYS_LIB_SHOULD_INSTALL AND BUILDSYS_LIB_EXCLUDE_FROM_ALL)
      # Only install the output file if it exists. This doesn't work for targets under exclude from all, but we may build them anyways
      MESSAGE(STATUS "NOTE: Target ${BUILDSYS_LIB_NAME} will only be installed after target is specifically built (not build using all target)")
      GET_TARGET_PROPERTY(LIB_OUTPUT_NAME ${CURRENT_LIB} LOCATION)
      INSTALL(FILES ${LIB_OUTPUT_NAME} LIBRARY DESTINATION ${LIBRARY_INSTALL_DIR} ARCHIVE DESTINATION ${LIBRARY_INSTALL_DIR} OPTIONAL)
    ENDIF()

    # Rewrite of install_name_dir in apple binaries
    IF(APPLE)
      SET_TARGET_PROPERTIES(${CURRENT_LIB} PROPERTIES INSTALL_NAME_DIR ${LIBRARY_INSTALL_DIR})
    ENDIF()


    # If the library depends on anything, set up dependency
    IF(BUILDSYS_LIB_DEPENDS)
      ADD_DEPENDENCIES(${CURRENT_LIB} ${BUILDSYS_LIB_DEPENDS})
    ENDIF()

  ENDFOREACH()

  # Build the dependency name for ourselves and set up the target for it
  SET(DEPEND_NAME "${BUILDSYS_LIB_NAME}_DEPEND")
  ADD_CUSTOM_TARGET(${DEPEND_NAME} DEPENDS ${LIB_DEPEND_LIST})

  IF(BUILDSYS_LIB_GROUP)
    IF(NOT TARGET ${BUILDSYS_LIB_GROUP})
      MESSAGE(STATUS "Creating build group ${BUILDSYS_LIB_GROUP}")
      ADD_CUSTOM_TARGET(${BUILDSYS_LIB_GROUP} DEPENDS ${DEPEND_NAME})
    ELSE()
      ADD_DEPENDENCIES(${BUILDSYS_LIB_GROUP} ${DEPEND_NAME})
    ENDIF()
  ENDIF()

ENDFUNCTION()

######################################################################################
# Generalized executable building function
######################################################################################

# Function for building executables
#
# All arguments are prefixed with BUILDSYS_EXE in the function
#
# Arguments
# NAME - name of the executable
# SOURCES - list of sources to compile into executable
# CXX_FLAGS - flags to pass to the compiler
# LINK_LIBS - libraries to link executable to
# LINK_FLAGS - list of flags to use in linking
# DEPENDS - Targets that should be built before this target
# SHOULD_INSTALL - should install commands be generated for this target?
# GROUP - Name of the compilation group this should be a part of (so you can build all of a group at once as a target)
# EXCLUDE_FROM_ALL - Don't add as part of all target
# INSTALL_PDB - On windows, if this is true, always create and install a PDB. Will also always happen with BUILDSYS_GLOBAL_INSTALL_PDB is on.
#
# When finished, one target is created, which is the NAME argument
# 

FUNCTION(BUILDSYS_BUILD_EXE)
  PARSE_ARGUMENTS(BUILDSYS_EXE
    "NAME;SOURCES;CXX_FLAGS;LINK_LIBS;LINK_FLAGS;DEPENDS;SHOULD_INSTALL;GROUP;EXCLUDE_FROM_ALL;INSTALL_PDB;"
    ""
    ${ARGN}
    )

  # Remove all dupes from the source list, otherwise CMake freaks out
  LIST(REMOVE_DUPLICATES BUILDSYS_EXE_SOURCES)

  # Create the target
  IF(BUILDSYS_EXE_EXCLUDE_FROM_ALL)
    ADD_EXECUTABLE(${BUILDSYS_EXE_NAME} EXCLUDE_FROM_ALL ${BUILDSYS_EXE_SOURCES})
  ELSE()
    ADD_EXECUTABLE(${BUILDSYS_EXE_NAME} ${BUILDSYS_EXE_SOURCES})
  ENDIF()
  SET_TARGET_PROPERTIES (${BUILDSYS_EXE_NAME} PROPERTIES OUTPUT_NAME ${BUILDSYS_EXE_NAME})

  # Defines and compiler flags, if any
  IF(BUILDSYS_EXE_CXX_FLAGS)
    SET_COMPILE_FLAGS(${BUILDSYS_EXE_NAME} ${BUILDSYS_EXE_CXX_FLAGS})
  ENDIF()

  # Set up rpaths to look in a few different places for libraries
  # - . (cwd)
  # - @loader_path/. (NOTE: @loader_path with no following path seems to fail)
  # - All of the library paths we linked again

  IF(NOT BUILDSYS_EXE_LINK_FLAGS)
    SET(BUILDSYS_EXE_LINK_FLAGS)
  ENDIF()

  IF(APPLE)   
    # The three normal paths
    # Right next to us, in the path of the requesting binary, and @loader_path/../Frameworks (the bundle packing Frameworks version)
    LIST(APPEND BUILDSYS_EXE_LINK_FLAGS "-Wl,-rpath,@loader_path/." "-Wl,-rpath,@loader_path/../Frameworks" "-Wl,-rpath,.")
    IF(BUILDSYS_DEP_PATHS)
      FOREACH(PATH ${BUILDSYS_DEP_PATHS})
        LIST(APPEND BUILDSYS_EXE_LINK_FLAGS "-Wl,-rpath,${PATH}/lib")
      ENDFOREACH()
    ENDIF()
  ENDIF()

  # If we're using Visual Studio, see whether or not we should
  # generate and install PDB files, even if we're in release
  IF(MSVC)
    IF(BUILDSYS_GLOBAL_INSTALL_PDB OR BUILDSYS_EXE_INSTALL_PDB)
      LIST(APPEND BUILDSYS_EXE_LINK_FLAGS "/DEBUG")
      GET_TARGET_PROPERTY(EXE_OUTPUT_NAME ${BUILDSYS_EXE_NAME} LOCATION)
      # Strip the .exe off the end and replace with .pdb
      STRING(REGEX REPLACE ".exe$" ".pdb" PDB_OUTPUT_NAME ${EXE_OUTPUT_NAME})
      STRING(REGEX REPLACE "\\$\\(OutDir\\)" "" PDB_OUTPUT_NAME ${PDB_OUTPUT_NAME})
      INSTALL(FILES ${PDB_OUTPUT_NAME} DESTINATION ${SYMBOL_INSTALL_DIR} OPTIONAL)
    ENDIF()
  ENDIF()
  
  # Linker flags, if any
  IF(BUILDSYS_EXE_LINK_FLAGS)
    SET_LINK_FLAGS(${BUILDSYS_EXE_NAME} ${BUILDSYS_EXE_LINK_FLAGS})
  ENDIF()
  
  # Libraries to link to 
  IF(BUILDSYS_EXE_LINK_LIBS)
    TARGET_LINK_LIBRARIES(${BUILDSYS_EXE_NAME} ${BUILDSYS_EXE_LINK_LIBS})
  ENDIF()

  # Install commands
  IF(BUILDSYS_EXE_SHOULD_INSTALL AND NOT BUILDSYS_EXE_EXCLUDE_FROM_ALL)
    INSTALL(TARGETS ${BUILDSYS_EXE_NAME} RUNTIME DESTINATION ${RUNTIME_INSTALL_DIR})
  ELSEIF(BUILDSYS_EXE_SHOULD_INSTALL AND BUILDSYS_EXE_EXCLUDE_FROM_ALL)
    # Only install the output file if it exists. This doesn't work for targets under exclude from all, but we may build them anyways
    MESSAGE(STATUS "NOTE: Target ${BUILDSYS_EXE_NAME} will only be installed after target is specifically built (not build using all target)")
    GET_TARGET_PROPERTY(EXE_OUTPUT_NAME ${BUILDSYS_EXE_NAME} LOCATION)
    INSTALL(FILES ${EXE_OUTPUT_NAME} RUNTIME DESTINATION ${RUNTIME_INSTALL_DIR} OPTIONAL)
  ENDIF()


  # If the executable depends on anything, set up dependency
  IF(BUILDSYS_EXE_DEPENDS)
    ADD_DEPENDENCIES(${BUILDSYS_EXE_NAME} ${BUILDSYS_EXE_DEPENDS})
  ENDIF()

  IF(BUILDSYS_EXE_GROUP)
    IF(NOT TARGET ${BUILDSYS_EXE_GROUP})
      MESSAGE(STATUS "Creating build group ${BUILDSYS_EXE_GROUP}")
      ADD_CUSTOM_TARGET(${BUILDSYS_EXE_GROUP} DEPENDS ${BUILDSYS_EXE_NAME})
    ELSE()
      ADD_DEPENDENCIES(${BUILDSYS_EXE_GROUP} ${BUILDSYS_EXE_NAME})
    ENDIF()
  ENDIF()

ENDFUNCTION(BUILDSYS_BUILD_EXE)

######################################################################################
# Make sure we aren't trying to do an in-source build
######################################################################################

#taken from http://www.mail-archive.com/cmake@cmake.org/msg14236.html

MACRO(MACRO_ENSURE_OUT_OF_SOURCE_BUILD)
  STRING(COMPARE EQUAL "${${PROJECT_NAME}_SOURCE_DIR}" "${${PROJECT_NAME}_BINARY_DIR}" insource)
  GET_FILENAME_COMPONENT(PARENTDIR ${${PROJECT_NAME}_SOURCE_DIR} PATH)
  STRING(COMPARE EQUAL "${${PROJECT_NAME}_SOURCE_DIR}" "${PARENTDIR}" insourcesubdir)
  IF(insource OR insourcesubdir)
    MESSAGE(FATAL_ERROR 
      "${PROJECT_NAME} requires an out of source build (make a build dir and call cmake from that.)\n"
      "A script (Makefile or python) should've been included in your build to generate this, check your project root directory.\n"
      "If you get this error from a sub-directory, make sure there is not a CMakeCache.txt in your project root directory."
      )
  ENDIF()
ENDMACRO()

######################################################################################
# Create a library name that fits our platform
######################################################################################

MACRO(CREATE_LIBRARY_LINK_NAME LIBNAME)
  if(BUILD_STATIC AND NOT BUILD_SHARED)
    IF(NOT MSVC)
      SET(LIB_STATIC_PRE "lib")
      SET(LIB_STATIC_EXT ".a")
    ELSE(NOT MSVC)
      SET(LIB_STATIC_PRE "")
      SET(LIB_STATIC_EXT ".lib")
    ENDIF(NOT MSVC)
    SET(LIB_OUTPUT_PATH ${LIBRARY_OUTPUT_PATH}/)
  ELSE(BUILD_STATIC AND NOT BUILD_SHARED)
    SET(LIB_STATIC_PRE)
    SET(LIB_STATIC_EXT)
    SET(LIB_OUTPUT_PATH)
  ENDIF(BUILD_STATIC AND NOT BUILD_SHARED)
  SET(lib${LIBNAME}_LIBRARY ${LIB_OUTPUT_PATH}${LIB_STATIC_PRE}${LIBNAME}${LIB_STATIC_EXT})  
ENDMACRO(CREATE_LIBRARY_LINK_NAME)

