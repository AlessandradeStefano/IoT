cmake_minimum_required(VERSION 3.25)
project(IoT)

set(CMAKE_CXX_STANDARD 14)

add_executable(IoT
        .idea/.gitignore
        .idea/IoT.iml
        .idea/modules.xml
        .idea/vcs.xml
        .idea/workspace.xml
        RoutingAppC.nc
        RoutingC.nc
        Topology.h)
