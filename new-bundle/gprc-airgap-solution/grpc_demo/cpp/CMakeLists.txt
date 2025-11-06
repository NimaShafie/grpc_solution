cmake_minimum_required(VERSION 3.20)
project(calculator_cpp CXX)
set(CMAKE_CXX_STANDARD 17)

# deps from -DCMAKE_PREFIX_PATH=<...>\grpc-install
find_package(Protobuf CONFIG REQUIRED)   # protobuf::libprotobuf
find_package(gRPC CONFIG REQUIRED)       # gRPC::grpc++

# --- sources (pre-generated stubs live in cpp/gen) ---
set(GEN_DIR "${CMAKE_CURRENT_LIST_DIR}/gen")
file(GLOB GEN_SRCS
  "${GEN_DIR}/*.pb.cc"
  "${GEN_DIR}/*.grpc.pb.cc"
)
file(GLOB SRC_SRCS "${CMAKE_CURRENT_LIST_DIR}/src/*.cpp")

# build the generated stubs as a lib (clean layering)
add_library(calculator_protos ${GEN_SRCS})
target_include_directories(calculator_protos PUBLIC "${GEN_DIR}")
target_link_libraries(calculator_protos
  PUBLIC gRPC::grpc++ protobuf::libprotobuf
)

# your client
add_executable(calculator_client ${SRC_SRCS})
target_link_libraries(calculator_client PRIVATE calculator_protos gRPC::grpc++ protobuf::libprotobuf)

# --- Abseil: minimal, robust ---
# 1) link all absl_*.lib (small, future-proof)
# 2) WHOLE_ARCHIVE a tiny subset that MSVC sometimes drops
get_filename_component(_PREFIX_ROOT "${CMAKE_PREFIX_PATH}" ABSOLUTE)
set(_ABSL_LIBDIR "${_PREFIX_ROOT}/lib")
file(GLOB _ABSL_LIBS "${_ABSL_LIBDIR}/absl_*.lib")
if (_ABSL_LIBS)
  target_link_libraries(calculator_client PRIVATE ${_ABSL_LIBS})
endif()

# force-pull just the usual culprits using generator expressions
# (maps to /WHOLEARCHIVE:… on MSVC; no quoting hassles)
foreach(_name IN ITEMS
  absl_log_internal_message
  absl_log_internal_check_op
  absl_raw_logging_internal
  absl_cord
  absl_cord_internal
)
  if (EXISTS "${_ABSL_LIBDIR}/${_name}.lib")
    target_link_libraries(calculator_client PRIVATE
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,${_ABSL_LIBDIR}/${_name}.lib>"
    )
  endif()
endforeach()

# windows system libs commonly needed with static grpc/protobuf
if (MSVC)
  target_link_libraries(calculator_client PRIVATE
    ws2_32 secur32 crypt32 ntdll
  )
  target_compile_options(calculator_protos PRIVATE /utf-8 /bigobj)
  target_compile_options(calculator_client  PRIVATE /W3 /EHsc /utf-8 /bigobj)
endif()
