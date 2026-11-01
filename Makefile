THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SE3FloatBtn

SE3FloatBtn_FILES = Tweak.x
SE3FloatBtn_CFLAGS = -fobjc-arc
SE3FloatBtn_FRAMEWORKS = UIKit QuartzCore CoreGraphics Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
