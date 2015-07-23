if(MACOSX OR APPLE)

set(COCOS_PLATFORM_SPECIFIC_SRC
  platform/virtual/CCApplication-virtual.cpp
  platform/mac/CCCommon-mac.mm
  platform/mac/CCDevice-mac.mm
  platform/apple/CCLock-apple.cpp
  platform/apple/CCFileUtils-apple.mm
  platform/apple/CCThread-apple.mm
  platform/desktop/CCGLViewImpl-desktop.cpp
)

elseif(LINUX)

include_directories(
  /usr/include
  /usr/include/GLFW
  /usr/local/include/GLFW
)

set(COCOS_PLATFORM_SPECIFIC_SRC
  platform/linux/CCStdC-linux.cpp
  platform/linux/CCFileUtils-linux.cpp
  platform/linux/CCCommon-linux.cpp
  #platform/linux/CCApplication-linux.cpp
  platform/virtual/CCApplication-virtual.cpp
  platform/linux/CCDevice-linux.cpp
  platform/desktop/CCGLViewImpl-desktop.cpp
)

endif()

#leave andatory external stuff here also

include_directories(
  platform/desktop
  platform
  ../external/ConvertUTF
  ../external/edtaa3func
  ../external/poly2tri
  ../external/poly2tri/common
  ../external/poly2tri/sweep
)

set(COCOS_PLATFORM_SRC

  platform/CCSAXParser.cpp
  platform/CCThread.cpp
  platform/CCGLView.cpp
  platform/CCFileUtils.cpp
  platform/CCImage.cpp
  ../external/edtaa3func/edtaa3func.cpp
  ../external/ConvertUTF/ConvertUTFWrapper.cpp
  ../external/ConvertUTF/ConvertUTF.c
  ../external/poly2tri/common/shapes.cc
  ../external/poly2tri/sweep/advancing_front.cc
  ../external/poly2tri/sweep/cdt.cc
  ../external/poly2tri/sweep/sweep_context.cc
  ../external/poly2tri/sweep/sweep.cc
  ${COCOS_PLATFORM_SPECIFIC_SRC}

)
