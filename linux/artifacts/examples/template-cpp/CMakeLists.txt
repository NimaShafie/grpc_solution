cmake_minimum_required(VERSION 3.18)
project(grpc_template CXX)
set(CMAKE_CXX_STANDARD 17)

# Order matters: Protobuf first, then gRPC
find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

set(PROTO_DIR ${CMAKE_SOURCE_DIR}/proto)
set(GEN_DIR   ${CMAKE_BINARY_DIR}/gen)
file(MAKE_DIRECTORY ${GEN_DIR})

set(PROTO_FILE ${PROTO_DIR}/helloworld.proto)

# Create targets that will own generated sources
add_library(proto_cc STATIC)
add_library(grpc_cc  STATIC)

# Generate C++ message classes into GEN_DIR and attach to proto_cc
protobuf_generate(
  TARGET proto_cc
  LANGUAGE cpp
  PROTOS ${PROTO_FILE}
  IMPORT_DIRS ${PROTO_DIR}
  OUT_VAR PROTO_SRCS
  PROTOC_OUT_DIR ${GEN_DIR}
)

# Generate gRPC stubs into GEN_DIR and attach to grpc_cc
protobuf_generate(
  TARGET grpc_cc
  LANGUAGE grpc
  GENERATE_EXTENSIONS .grpc.pb.h .grpc.pb.cc
  PROTOS ${PROTO_FILE}
  IMPORT_DIRS ${PROTO_DIR}
  OUT_VAR GRPC_SRCS
  PLUGIN "protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>"
  PROTOC_OUT_DIR ${GEN_DIR}
)

# Include dirs & link deps
target_include_directories(proto_cc PUBLIC ${GEN_DIR})
target_include_directories(grpc_cc  PUBLIC ${GEN_DIR})
target_link_libraries(proto_cc PUBLIC protobuf::libprotobuf)
target_link_libraries(grpc_cc  PUBLIC gRPC::grpc++)

# Binaries — link order: grpc_cc (stubs) BEFORE proto_cc (messages)
add_executable(server src/server.cc)
target_link_libraries(server PRIVATE grpc_cc proto_cc gRPC::grpc++_reflection)

add_executable(client src/client.cc)
target_link_libraries(client PRIVATE grpc_cc proto_cc)
