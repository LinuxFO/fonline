cmake_minimum_required(VERSION 3.16.3)

StatusMessage("Start project generation")

# Options
function(DeclareOption var desc value)
	if(NOT DEFINED ${var}) # Prevent moving to cache
		set(${var} ${value} PARENT_SCOPE)
	endif()

	option(${var} ${desc} ${value})

	StatusMessage("${var} = ${${var}}")
endfunction()

DeclareOption(FO_DEV_NAME "Short name for project" "") # Required
DeclareOption(FO_NICE_NAME "More readable name for project" "") # Required
DeclareOption(FO_AUTHOR_NAME "Author(s) name" "") # Required
DeclareOption(FO_GAME_VERSION "Version in any format" "") # Required
DeclareOption(FO_SINGLEPLAYER "Singleplayer mode" OFF)
DeclareOption(FO_ENABLE_3D "Supporting of 3d models" OFF)
DeclareOption(FO_NATIVE_SCRIPTING "Supporting of Native scripting" OFF)
DeclareOption(FO_ANGELSCRIPT_SCRIPTING "Supporting of AngelScript scripting" OFF)
DeclareOption(FO_MONO_SCRIPTING "Supporting of Mono scripting" OFF)
DeclareOption(FO_DEFAULT_CONFIG "Name of default config file" "")
DeclareOption(FO_DEBUGGING_CONFIG "Name of debugging config file (using during debugging)" "")
DeclareOption(FO_MAPPER_CONFIG "Name of mapper config file (embed in mapper)" "")
DeclareOption(FO_GENERATE_ANGELSCRIPT_CONTENT "Content.fos file destination" "")
DeclareOption(FO_GEOMETRY "HEXAGONAL or SQUARE gemetry mode" "") # Required
DeclareOption(FO_APP_ICON "Executable file icon" "") # Required
DeclareOption(FO_MAKE_EXTERNAL_COMMANDS "Create shortcuts for working outside CMake runner" "")
DeclareOption(FO_INFO_MARKDOWN_OUTPUT "Path where information markdown files will be stored" "")

DeclareOption(FO_VERBOSE_BUILD "Verbose build mode" OFF)
DeclareOption(FO_BUILD_CLIENT "Build Multiplayer client binaries" OFF)
DeclareOption(FO_BUILD_SERVER "Build Multiplayer server binaries" OFF)
DeclareOption(FO_BUILD_SINGLE "Build Singleplayer binaries" OFF)
DeclareOption(FO_BUILD_EDITOR "Build Editor binaries" OFF)
DeclareOption(FO_BUILD_MAPPER "Build Mapper binaries" OFF)
DeclareOption(FO_BUILD_ASCOMPILER "Build AngelScript compiler" OFF)
DeclareOption(FO_BUILD_BAKER "Build Baker binaries" OFF)
DeclareOption(FO_UNIT_TESTS "Build only binaries for Unit Testing" OFF)
DeclareOption(FO_CODE_COVERAGE "Build only binaries for Code Coverage reports" OFF)
DeclareOption(FO_OUTPUT_PATH "Common output path" "") # Required

# Quiet all non-error messages instead ourself
if(FO_VERBOSE_BUILD)
	StatusMessage("Verbose build mode")
	set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Forced by FOnline" FORCE)
else()
	set(CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Forced by FOnline" FORCE)
endif()

# Global options
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Forced by FOnline" FORCE) # Generate compile_commands.json
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Forced by FOnline" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Forced by FOnline" FORCE)

# Check options
set(requiredOptions "FO_DEV_NAME" "FO_NICE_NAME" "FO_AUTHOR_NAME" "FO_GAME_VERSION" "FO_GEOMETRY" "FO_APP_ICON" "FO_OUTPUT_PATH")

foreach(opt ${requiredOptions})
	if("${${opt}}" STREQUAL "")
		AbortMessage("${opt} not specified")
	endif()
endforeach()

# Evaluate build hash
set(FO_GIT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
execute_process(COMMAND git rev-parse HEAD WORKING_DIRECTORY ${FO_GIT_ROOT} RESULT_VARIABLE FO_GIT_HASH_RESULT OUTPUT_VARIABLE FO_GIT_HASH OUTPUT_STRIP_TRAILING_WHITESPACE)

if(FO_GIT_HASH_RESULT STREQUAL "0")
	set(FO_BUILD_HASH ${FO_GIT_HASH})
else()
	string(RANDOM LENGTH 40 ALPHABET "0123456789abcdef" randomHash)
	set(FO_BUILD_HASH ${randomHash}-random)
endif()

StatusMessage("Build hash: ${FO_BUILD_HASH}")

macro(WriteBuildHash target)
	if(NOT FO_BUILD_LIBRARY)
		get_target_property(dir ${target} RUNTIME_OUTPUT_DIRECTORY)
	else()
		get_target_property(dir ${target} LIBRARY_OUTPUT_DIRECTORY)
	endif()

	add_custom_command(TARGET ${target} PRE_BUILD COMMAND ${CMAKE_COMMAND} -E remove -f "${dir}/${target}.build-hash")
	add_custom_command(TARGET ${target} POST_BUILD COMMAND ${CMAKE_COMMAND} -E echo_append ${FO_BUILD_HASH} > "${dir}/${target}.build-hash")
endmacro()

# Some info about build
StatusMessage("Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
StatusMessage("Generator: ${CMAKE_GENERATOR}")

# Build configuration
get_cmake_property(FO_MULTICONFIG GENERATOR_IS_MULTI_CONFIG)

macro(AddConfiguration name parent)
	string(TOUPPER ${name} nameUpper)
	string(TOUPPER ${parent} parentUpper)

	list(APPEND FO_CONFIGURATION_TYPES ${name})

	if(FO_MULTICONFIG)
		set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIGURATION_TYPES};${name}" CACHE STRING "Forced by FOnline" FORCE)
	endif()

	set(CMAKE_CXX_FLAGS_${nameUpper} ${CMAKE_CXX_FLAGS_${parentUpper}} CACHE STRING "Forced by FOnline" FORCE)
	set(CMAKE_C_FLAGS_${nameUpper} ${CMAKE_C_FLAGS_${parentUpper}} CACHE STRING "Forced by FOnline" FORCE)
	set(CMAKE_EXE_LINKER_FLAGS_${nameUpper} ${CMAKE_EXE_LINKER_FLAGS_${parentUpper}} CACHE STRING "Forced by FOnline" FORCE)
	set(CMAKE_MODULE_LINKER_FLAGS_${nameUpper} ${CMAKE_MODULE_LINKER_FLAGS_${parentUpper}} CACHE STRING "Forced by FOnline" FORCE)
endmacro()

if(FO_MULTICONFIG)
	set(CMAKE_CONFIGURATION_TYPES ${FO_CONFIGURATION_TYPES} CACHE STRING "Forced by FOnline" FORCE)
endif()

AddConfiguration(Profiling RelWithDebInfo)
AddConfiguration(Debug_Profiling Debug)
AddConfiguration(Release_Ext Release)

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
	AddConfiguration(San_Address RelWithDebInfo)
	AddConfiguration(San_Memory RelWithDebInfo)
	AddConfiguration(San_MemoryWithOrigins RelWithDebInfo)
	AddConfiguration(San_Undefined RelWithDebInfo)
	AddConfiguration(San_Thread RelWithDebInfo)
	AddConfiguration(San_DataFlow RelWithDebInfo)
	AddConfiguration(San_Address_Undefined RelWithDebInfo)
endif()

if(FO_MULTICONFIG)
	string(REPLACE ";" " " configs "${CMAKE_CONFIGURATION_TYPES}")
	StatusMessage("Configurations: ${configs}")
else()
	StatusMessage("Configuration: ${CMAKE_BUILD_TYPE}")

	list(FIND FO_CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE} configurationIndex)

	if(configurationIndex EQUAL -1)
		AbortMessage("Invalid requested configuration type")
	endif()
endif()

# Basic setup
add_compile_definitions($<$<CONFIG:Debug>:DEBUG>)
add_compile_definitions($<$<CONFIG:Debug>:_DEBUG>)
add_compile_definitions($<$<CONFIG:Debug>:FO_DEBUG=1>)
add_compile_definitions($<$<NOT:$<CONFIG:Debug>>:NDEBUG>)
add_compile_definitions($<$<NOT:$<CONFIG:Debug>>:FO_DEBUG=0>)

add_compile_definitions($<$<CONFIG:San_Address>:LLVM_USE_SANITIZER=Address>)
add_compile_definitions($<$<CONFIG:San_Memory>:LLVM_USE_SANITIZER=Memory>)
add_compile_definitions($<$<CONFIG:San_MemoryWithOrigins>:LLVM_USE_SANITIZER=MemoryWithOrigins>)
add_compile_definitions($<$<CONFIG:San_Undefined>:LLVM_USE_SANITIZER=Undefined>)
add_compile_definitions($<$<CONFIG:San_Thread>:LLVM_USE_SANITIZER=Thread>)
add_compile_definitions($<$<CONFIG:San_DataFlow>:LLVM_USE_SANITIZER=DataFlow>)
add_compile_definitions($<$<CONFIG:San_Address_Undefined>:LLVM_USE_SANITIZER=Address$<SEMICOLON>Undefined>)

set(expr_FullOptimization $<OR:$<CONFIG:Release>,$<CONFIG:Release_Ext>,$<CONFIG:MinSizeRel>>)
set(expr_DebugInfo $<NOT:$<OR:$<CONFIG:Release>,$<CONFIG:Release_Ext>,$<CONFIG:MinSizeRel>>>)
set(expr_PrefixConfig $<NOT:$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>,$<CONFIG:MinSizeRel>>>)

# Headless configuration (without video/audio/input)
if(FO_BUILD_CLIENT OR FO_BUILD_SERVER OR FO_BUILD_SINGLE OR FO_BUILD_EDITOR OR FO_BUILD_MAPPER)
	set(FO_HEADLESS_ONLY NO)
else()
	set(FO_HEADLESS_ONLY YES)
endif()

if(WIN32 AND NOT WINRT)
	StatusMessage("Operating system: Windows")
	set(FO_OS "Windows")
	add_compile_definitions(FO_WINDOWS=1 FO_UWP=0 FO_LINUX=0 FO_MAC=0 FO_ANDROID=0 FO_IOS=0 FO_WEB=0 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=1 FO_OPENGL_ES=0 FO_HAVE_DIRECT_3D=1 FO_HAVE_METAL=0 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)

	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(FO_BUILD_PLATFORM "Windows-win64")
	else()
		set(FO_BUILD_PLATFORM "Windows-win32")
	endif()

	if(FO_BUILD_CLIENT OR FO_BUILD_SINGLE)
		add_compile_options($<$<CONFIG:Debug>:/MTd>)
		add_compile_options($<$<NOT:$<CONFIG:Debug>>:/MT>)
	else()
		add_compile_options($<$<CONFIG:Debug>:/MDd>)
		add_compile_options($<$<NOT:$<CONFIG:Debug>>:/MD>)
	endif()

	# Todo: debug /RTCc /sdl _ALLOW_RTCc_IN_STL release /GS-
	add_compile_options($<$<CONFIG:Debug>:/RTC1>)
	add_compile_options($<$<CONFIG:Debug>:/GS>)
	add_compile_options($<$<CONFIG:Debug>:/JMC>)
	add_compile_options($<$<NOT:$<CONFIG:Debug>>:/sdl->)
	add_compile_options(/W4 /MP /EHsc /utf-8 /volatile:iso /GR /bigobj /fp:fast)
	add_link_options(/INCREMENTAL:NO /OPT:REF /OPT:NOICF)
	add_compile_options($<${expr_FullOptimization}:/GL>)
	add_link_options($<${expr_FullOptimization}:/LTCG>)
	add_compile_options($<${expr_DebugInfo}:/Zi>)
	add_link_options($<IF:${expr_DebugInfo},/DEBUG:FULL,/DEBUG:NONE>)
	add_compile_definitions(UNICODE _UNICODE _CRT_SECURE_NO_WARNINGS _CRT_SECURE_NO_DEPRECATE _WINSOCK_DEPRECATED_NO_WARNINGS)
	list(APPEND FO_COMMON_SYSTEM_LIBS "user32" "ws2_32" "version" "winmm" "imm32" "dbghelp" "psapi" "xinput")

	if(NOT FO_HEADLESS_ONLY)
		set(FO_USE_GLEW YES)
		list(APPEND FO_RENDER_SYSTEM_LIBS "glu32" "d3d9" "d3d11" "d3dcompiler" "gdi32" "opengl32" "dxgi" "windowscodecs" "dxguid")
	endif()
elseif(WIN32 AND WINRT)
	StatusMessage("Operating system: Universal Windows Platform")
	set(FO_OS "Windows")
	add_compile_definitions(FO_WINDOWS=1 FO_UWP=1 FO_LINUX=0 FO_MAC=0 FO_ANDROID=0 FO_IOS=0 FO_WEB=0 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=0 FO_OPENGL_ES=0 FO_HAVE_DIRECT_3D=1 FO_HAVE_METAL=0 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)

	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(FO_BUILD_PLATFORM "UWP-win64")
	else()
		set(FO_BUILD_PLATFORM "UWP-win32")
	endif()

	# Todo: debug /RTCc /sdl _ALLOW_RTCc_IN_STL release /GS-
	add_compile_options($<$<CONFIG:Debug>:/MDd>)
	add_compile_options($<$<CONFIG:Debug>:/RTC1>)
	add_compile_options($<$<CONFIG:Debug>:/GS>)
	add_compile_options($<$<CONFIG:Debug>:/JMC>)
	add_compile_options($<$<NOT:$<CONFIG:Debug>>:/MD>)
	add_compile_options($<$<NOT:$<CONFIG:Debug>>:/sdl->)
	add_compile_options(/W4 /ZW /MP /EHsc /utf-8 /volatile:iso /GR /bigobj /fp:fast)
	add_link_options(/APPCONTAINER /INCREMENTAL:NO /OPT:REF /OPT:NOICF)
	add_compile_options($<${expr_FullOptimization}:/GL>)
	add_link_options($<${expr_FullOptimization}:/LTCG>)
	add_compile_options($<${expr_DebugInfo}:/Zi>)
	add_link_options($<IF:${expr_DebugInfo},/DEBUG:FULL,/DEBUG:NONE>)
	add_compile_definitions(UNICODE _UNICODE _CRT_SECURE_NO_WARNINGS _CRT_SECURE_NO_DEPRECATE _WINSOCK_DEPRECATED_NO_WARNINGS)
	list(APPEND FO_COMMON_SYSTEM_LIBS "user32" "ws2_32" "version" "winmm" "imm32" "dbghelp" "psapi" "xinput")

	if(NOT FO_HEADLESS_ONLY)
		list(APPEND FO_RENDER_SYSTEM_LIBS "d3d9" "gdi32" "dxgi" "windowscodecs" "dxguid")
	endif()
elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
	StatusMessage("Operating system: Linux")
	set(FO_OS "Linux")
	set(LINUX 1)
	add_compile_definitions(FO_WINDOWS=0 FO_UWP=0 FO_LINUX=1 FO_MAC=0 FO_ANDROID=0 FO_IOS=0 FO_WEB=0 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=1 FO_OPENGL_ES=0 FO_HAVE_DIRECT_3D=0 FO_HAVE_METAL=0 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)

	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(FO_BUILD_PLATFORM "Linux-x64")
	else()
		set(FO_BUILD_PLATFORM "Linux-x86")
	endif()

	if(NOT FO_HEADLESS_ONLY)
		find_package(X11 REQUIRED)
		find_package(OpenGL REQUIRED)
		set(FO_USE_GLEW YES)
		list(APPEND FO_RENDER_SYSTEM_LIBS "GL")
	endif()

	add_compile_options($<${expr_DebugInfo}:-g>)
	add_compile_options($<${expr_FullOptimization}:-O3>)
	add_compile_options($<${expr_FullOptimization}:-flto>)
	add_link_options($<${expr_FullOptimization}:-flto>)
	add_link_options(-no-pie -rdynamic)

	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		# Todo: rework and use only libc++ (we use libstdc++ because fbxsdk use it)
		if(FO_UNIT_TESTS OR FO_CODE_COVERAGE OR FO_BUILD_BAKER)
			add_compile_options(-stdlib=libstdc++)
		else()
			add_compile_options(-stdlib=libc++)
			add_link_options(-stdlib=libc++)
		endif()
	endif()
elseif(APPLE AND NOT PLATFORM)
	StatusMessage("Operating system: macOS")

	if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
		AbortMessage("Invalid pointer size for macOS build")
	endif()

	set(FO_OS "Mac")
	add_compile_definitions(FO_WINDOWS=0 FO_UWP=0 FO_LINUX=0 FO_MAC=1 FO_ANDROID=0 FO_IOS=0 FO_WEB=0 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=1 FO_OPENGL_ES=0 FO_HAVE_DIRECT_3D=0 FO_HAVE_METAL=1 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)
	set(FO_BUILD_PLATFORM "macOS-x64")

	if(NOT FO_HEADLESS_ONLY)
		find_package(OpenGL REQUIRED)
		set(FO_USE_GLEW YES)
		list(APPEND FO_RENDER_SYSTEM_LIBS ${OPENGL_LIBRARIES})
	endif()

	add_compile_options($<${expr_DebugInfo}:-g>)
	add_compile_options($<${expr_FullOptimization}:-O3>)
	add_compile_options($<${expr_FullOptimization}:-flto>)
	add_link_options($<${expr_FullOptimization}:-flto>)
	add_compile_options(-stdlib=libc++)
	add_link_options(-rdynamic)
elseif(APPLE AND PLATFORM)
	StatusMessage("Operating system: iOS")
	StatusMessage("Deployment target: ${DEPLOYMENT_TARGET}")

	if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
		AbortMessage("Invalid pointer size for iOS build")
	endif()

	set(FO_OS "iOS")
	add_compile_definitions(FO_WINDOWS=0 FO_UWP=0 FO_LINUX=0 FO_MAC=0 FO_ANDROID=0 FO_IOS=1 FO_WEB=0 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=1 FO_OPENGL_ES=1 FO_HAVE_DIRECT_3D=0 FO_HAVE_METAL=1 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)

	if(PLATFORM STREQUAL "OS64")
		StatusMessage("Platform: Device")
		set(FO_BUILD_PLATFORM "iOS-arm64")
	elseif(PLATFORM STREQUAL "SIMULATOR64")
		StatusMessage("Platform: Simulator")
		set(FO_BUILD_PLATFORM "iOS-simulator")
	else()
		AbortMessage("Invalid iOS target platform ${PLATFORM}")
	endif()

	if(NOT FO_HEADLESS_ONLY)
		find_library(OPENGLES OpenGLES)
		find_library(METAL Metal)
		find_library(COREGRAPGHICS CoreGraphics)
		find_library(QUARTZCORE QuartzCore)
		find_library(UIKIT UIKit)
		find_library(AVFOUNDATION AVFoundation)
		find_library(GAMECONTROLLER GameController)
		find_library(COREMOTION CoreMotion)
		list(APPEND FO_RENDER_SYSTEM_LIBS ${OPENGLES} ${METAL} ${COREGRAPGHICS} ${QUARTZCORE} ${UIKIT} ${AVFOUNDATION} ${GAMECONTROLLER} ${COREMOTION})
		unset(OPENGLES)
		unset(METAL)
		unset(COREGRAPGHICS)
		unset(QUARTZCORE)
		unset(UIKIT)
		unset(AVFOUNDATION)
		unset(GAMECONTROLLER)
		unset(COREMOTION)
	endif()

	add_compile_options(-stdlib=libc++)
	add_compile_options($<${expr_DebugInfo}:-g>)
	add_compile_options($<${expr_FullOptimization}:-O3>)
	add_compile_options($<${expr_FullOptimization}:-flto>)
	add_link_options($<${expr_FullOptimization}:-flto>)
	list(APPEND FO_COMMON_SYSTEM_LIBS "iconv") # Todo: ios iconv workaround for SDL, remove in future updates
elseif(ANDROID)
	StatusMessage("Operating system: Android")
	set(FO_OS "Android")
	add_compile_definitions(FO_WINDOWS=0 FO_UWP=0 FO_LINUX=0 FO_MAC=0 FO_ANDROID=1 FO_IOS=0 FO_WEB=0 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=1 FO_OPENGL_ES=1 FO_HAVE_DIRECT_3D=0 FO_HAVE_METAL=0 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)
	set(FO_BUILD_PLATFORM "Android-${ANDROID_ABI}")
	set(FO_BUILD_LIBRARY YES)

	if(NOT FO_HEADLESS_ONLY)
		list(APPEND FO_RENDER_SYSTEM_LIBS "GLESv3")
	endif()

	list(APPEND FO_COMMON_SYSTEM_LIBS "android" "log" "atomic")
	add_compile_options($<${expr_DebugInfo}:-g>)
	add_compile_options($<${expr_FullOptimization}:-O3>)
	add_compile_options($<${expr_FullOptimization}:-flto>)
	add_link_options($<${expr_FullOptimization}:-flto>)
	add_link_options(-pie)
elseif(EMSCRIPTEN)
	StatusMessage("Operating system: Web")
	set(FO_OS "Web")
	add_compile_definitions(FO_WINDOWS=0 FO_UWP=0 FO_LINUX=0 FO_MAC=0 FO_ANDROID=0 FO_IOS=0 FO_WEB=1 FO_PS4=0)
	add_compile_definitions(FO_HAVE_OPENGL=1 FO_OPENGL_ES=1 FO_HAVE_DIRECT_3D=0 FO_HAVE_METAL=0 FO_HAVE_VULKAN=0 FO_HAVE_GNM=0)
	set(FO_BUILD_PLATFORM "Web-wasm")
	set(CMAKE_EXECUTABLE_SUFFIX ".js")
	add_compile_options($<${expr_DebugInfo}:-g>)
	add_compile_options($<${expr_FullOptimization}:-O3>)
	add_compile_options($<${expr_FullOptimization}:-flto>)
	add_link_options($<${expr_FullOptimization}:-flto>)
	add_compile_options(--no-heap-copy)
	add_link_options(-sSTRICT=1)
	add_compile_options(-sSTRICT=1)
	add_link_options(-sINITIAL_MEMORY=268435456) # 256 Mb
	add_link_options(-sABORT_ON_WASM_EXCEPTIONS=1)
	add_link_options(-sERROR_ON_UNDEFINED_SYMBOLS=1)
	add_link_options(-sALLOW_MEMORY_GROWTH=1)
	add_link_options(-sMIN_WEBGL_VERSION=2)
	add_link_options(-sMAX_WEBGL_VERSION=2)
	add_link_options(-sUSE_SDL=0)
	add_link_options(-sFORCE_FILESYSTEM=1)
	add_link_options(-sDYNAMIC_EXECUTION=0)
	add_link_options(-sEXIT_RUNTIME=0)
	add_link_options(-sEXPORTED_RUNTIME_METHODS=['FS_createPath','FS_createDataFile','intArrayFromString','UTF8ToString','addRunDependency','removeRunDependency','stackTrace','autoResumeAudioContext','dynCall'])
	add_link_options(-sDISABLE_EXCEPTION_CATCHING=0)
	add_compile_options(-sDISABLE_EXCEPTION_CATCHING=0)
	add_link_options(-sWASM_BIGINT=1)

	add_link_options(-lhtml5)
	add_link_options(-lGL)
	add_link_options(-legl.js)
	add_link_options(-lhtml5_webgl.js)
	add_link_options(-lidbfs.js)

	add_link_options(-Wl,-u,ntohs)
elseif(PS4)
	StatusMessage("Operating system: PS4")
	set(FO_OS "PS4")
	add_compile_definitions(FO_WINDOWS=0 FO_UWP=0 FO_LINUX=0 FO_MAC=0 FO_ANDROID=0 FO_IOS=0 FO_WEB=0 FO_PS4=1)
	add_compile_definitions(FO_HAVE_OPENGL=0 FO_OPENGL_ES=0 FO_HAVE_DIRECT_3D=0 FO_HAVE_METAL=0 FO_HAVE_VULKAN=0 FO_HAVE_GNM=1)
	set(FO_BUILD_PLATFORM "PS4-x64")
	add_compile_options($<${expr_DebugInfo}:-g>)
	add_compile_options($<$<CONFIG:Debug>:-O0>)
	add_compile_options($<$<NOT:$<CONFIG:Debug>>:-O2>)
else()
	AbortMessage("Unknown OS")
endif()

string(TOUPPER "${FO_OS}" FO_OS_UPPER)
add_compile_definitions(FO_${FO_OS_UPPER}=1)

# Information about CPU architecture
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	StatusMessage("CPU architecture: 64-bit")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
	StatusMessage("CPU architecture: 32-bit")
else()
	AbortMessage("Invalid pointer size, nor 8 or 4 bytes")
endif()

# Output path
StatusMessage("Output path: ${FO_OUTPUT_PATH}")
set(FO_CLIENT_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Client-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_SERVER_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Server-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_SINGLE_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Single-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_EDITOR_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Editor-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_MAPPER_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Mapper-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_ASCOMPILER_OUTPUT "${FO_OUTPUT_PATH}/Binaries/ASCompiler-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_BAKER_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Baker-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_TESTS_OUTPUT "${FO_OUTPUT_PATH}/Binaries/Tests-${FO_BUILD_PLATFORM}$<${expr_PrefixConfig}:-$<CONFIG>>")
set(FO_BACKED_RESOURCES_OUTPUT "${FO_OUTPUT_PATH}/Bakering")
file(MAKE_DIRECTORY "${FO_OUTPUT_PATH}/Binaries")
file(MAKE_DIRECTORY "${FO_BACKED_RESOURCES_OUTPUT}")

# Contributions
macro(ResolveContributedFiles)
	set(result "")

	foreach(file ${ARGN})
		file(GLOB globFiles LIST_DIRECTORIES FALSE CONFIGURE_DEPENDS "${FO_CONTRIBUTION_DIR}/${file}/*.fos")
		list(APPEND FO_CONTENT_META_FILES ${globFiles})
		file(GLOB globFiles LIST_DIRECTORIES TRUE "${FO_CONTRIBUTION_DIR}/${file}")

		foreach(globFile ${globFiles})
			get_filename_component(globFile ${globFile} ABSOLUTE)
			list(APPEND result ${globFile})
		endforeach()
	endforeach()
endmacro()

macro(AddContent)
	ResolveContributedFiles(${ARGN})

	foreach(resultEntry ${result})
		StatusMessage("+ Content at ${resultEntry}")
		list(APPEND FO_CONTENT ${resultEntry})
	endforeach()
endmacro()

macro(AddResources packName)
	ResolveContributedFiles(${ARGN})

	foreach(resultEntry ${result})
		StatusMessage("+ Resources to ${packName} at ${resultEntry}")
		list(APPEND FO_RESOURCES "${packName},${resultEntry}")
	endforeach()
endmacro()

macro(AddRawResources)
	ResolveContributedFiles(${ARGN})

	foreach(resultEntry ${result})
		StatusMessage("+ Raw resources at ${resultEntry}")
		list(APPEND FO_RESOURCES "Raw,${resultEntry}")
	endforeach()
endmacro()

macro(AddEmbeddedResources)
	ResolveContributedFiles(${ARGN})

	foreach(resultEntry ${result})
		StatusMessage("+ Embedded resources at ${resultEntry}")
		list(APPEND FO_RESOURCES "Embedded,${resultEntry}")
	endforeach()
endmacro()

macro(AddEngineSource target)
	ResolveContributedFiles(${ARGN})

	foreach(resultEntry ${result})
		StatusMessage("+ Engine source at ${resultEntry}")
		list(APPEND FO_${target}_SOURCE ${resultEntry})
		list(APPEND FO_SINGLE_SOURCE ${resultEntry})
		list(APPEND FO_SOURCE_META_FILES ${resultEntry})
	endforeach()
endmacro()

macro(AddNativeIncludeDir)
	if(FO_NATIVE_SCRIPTING)
		foreach(dir ${ARGN})
			StatusMessage("+ Native include dir at ${FO_CONTRIBUTION_DIR}/${dir}")
			include_directories("${FO_CONTRIBUTION_DIR}/${dir}")
		endforeach()
	endif()
endmacro()

macro(AddNativeSource)
	if(FO_NATIVE_SCRIPTING)
		# ResolveContributedFiles( ${ARGN} )
		# foreach( resultEntry ${result} )
		# StatusMessage( "+ Engine source at ${resultEntry}" )
		# list( APPEND FO_${target}_SOURCE ${resultEntry} )
		# endforeach()
	endif()
endmacro()

macro(AddMonoAssembly assembly)
	if(FO_MONO_SCRIPTING)
		StatusMessage("+ Mono assembly ${assembly}")
		list(APPEND FO_MONO_ASSEMBLIES ${assembly})
		set(MonoAssembly_${assembly}_CommonRefs "")
		set(MonoAssembly_${assembly}_ServerRefs "")
		set(MonoAssembly_${assembly}_ClientRefs "")
		set(MonoAssembly_${assembly}_SingleRefs "")
		set(MonoAssembly_${assembly}_MapperRefs "")
		set(MonoAssembly_${assembly}_CommonSource "")
		set(MonoAssembly_${assembly}_ServerSource "")
		set(MonoAssembly_${assembly}_ClientSource "")
		set(MonoAssembly_${assembly}_SingleSource "")
		set(MonoAssembly_${assembly}_MapperSource "")
	endif()
endmacro()

macro(AddMonoReference assembly target)
	if(FO_MONO_SCRIPTING)
		foreach(arg ${ARGN})
			StatusMessage("+ Mono assembly ${target}/${assembly} redefence to ${arg}")
			list(APPEND MonoAssembly_${assembly}_${target}Refs ${arg})
		endforeach()
	endif()
endmacro()

macro(AddMonoSource assembly target)
	if(FO_MONO_SCRIPTING)
		ResolveContributedFiles(${ARGN})

		foreach(resultEntry ${result})
			StatusMessage("+ Mono source for assembly ${target}/${assembly} at ${resultEntry}")
			list(APPEND MonoAssembly_${assembly}_${target}Source ${resultEntry})
		endforeach()
	endif()
endmacro()

macro(CreatePackage package config)
	list(APPEND FO_PACKAGES ${package})
	set(Package_${package}_Config ${config})
	set(Package_${package}_Parts "")
endmacro()

macro(AddToPackage package binary platform arch packType)
	list(APPEND Package_${package}_Parts "${binary},${platform},${arch},${packType},${ARGN}")
endmacro()

# Core contribution
set(FO_CONTRIBUTION_DIR ${FO_ENGINE_ROOT})
AddNativeIncludeDir("Source/Scripting/Native")

if(FO_ANGELSCRIPT_SCRIPTING)
	AddContent("Source/Scripting/AngelScript")
endif()

AddMonoAssembly("FOnline")
AddMonoSource("FOnline" "Common" "Source/Scripting/Mono/*.cs")
AddResources("Core" "Resources/Core")
AddEmbeddedResources("Resources/Embedded")
AddResources("Core" "Resources/Embedded") # Duplicate embedded to core for correct data updating

set(FO_CONTRIBUTION_DIR ${CMAKE_CURRENT_SOURCE_DIR})