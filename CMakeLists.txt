cmake_minimum_required(VERSION 3.16)
project(Test1)
include_directories(./glew/include/)
include_directories(./glfw/include/)
include_directories(./include/)
link_directories(./glew/lib/)
link_directories(./glfw/lib/)

include_directories(/usr/local/Cellar/sdl2/2.0.12_1/include)
link_directories(/usr/local/Cellar/sdl2/2.0.12_1/lib)
set(SDL2_LIBS SDL2)
link_directories(/usr/local/Cellar/sdl2_image/2.0.5/lib)
set(SDL2_IMAGE_LIBS SDL2_IMAGE)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework Security -framework CFNetwork -framework CoreText -framework OpenGL -framework CoreServices -framework CoreFoundation -framework CoreGraphics -framework AudioToolbox -framework CoreVideo -framework VideoToolbox -framework CoreMedia -framework CoreImage -framework Cocoa")
aux_source_directory(SRC include)

add_executable(Test1 main.cpp include/shader.cpp)
target_link_libraries (
        Test1
        libGLEW.a
        libglfw3.a
        ${SDL2_LIBS}
        ${SDL2_IMAGE_LIBS}
)
