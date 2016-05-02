#
#   Copyright 2016 Niclas Hedhman, All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#############################################################
# Required variables for each makefile
# Discard this section from all parent makefiles
# Expected variables (with automatic defaults):
#   CSRCS (all "C" files in the dir)
#   SUBDIRS (all subdirs with a Makefile)
#   GEN_LIBS - list of libs to be generated ()
#   GEN_IMAGES - list of object file images to be generated ()
#   GEN_BINS - list of binaries to be generated ()
#   COMPONENTS_xxx - a list of libs/objs in the form
#     subdir/lib to be extracted and rolled up into
#     a generated lib/image xxx.a ()
#

FORTHRIGHT_VERSION_MAJOR = 1
FORTHRIGHT_VERSION_MINOR = 0

# Arguments from the gen_app.sh
BOOT = none
APP = 0
SPI_SPEED = 40
SPI_MODE = DIO
SPI_SIZE_MAP = 6
CUSTOM_LD_FILE = ${PWD}/user/eagle.app.v6.common.ld

BIN_PATH = ${PWD}/target/
TARGET = eagle

FLAVOR = release
#FLAVOR = debug

#EXTRA_CCFLAGS += -u

ifndef PDIR # {
GEN_IMAGES= eagle.app.v6.out
GEN_BINS= eagle.app.v6.bin
SPECIAL_MKTARGETS=$(APP_MKTARGETS)
SUBDIRS= \
	common \
	spiffs \
	user

endif # } PDIR

LDDIR = $(SDK_PATH)/ld

CCFLAGS += -Os

TARGET_LDFLAGS = \
	-nostdlib \
	-Wl,-EL \
	--longcalls \
	--text-section-literals

ifeq ($(FLAVOR),debug)
	TARGET_LDFLAGS += -g -O2
	CCFLAGS += -DDEBUG
endif

ifeq ($(FLAVOR),release)
	TARGET_LDFLAGS += -g -O0
	CCFLAGS += -DRELEASE
endif

COMPONENTS_eagle.app.v6 = \
	user/libuser.a  \
	spiffs/libfs.a  \
	common/libforthright.a

LINKFLAGS_eagle.app.v6 = \
	-L$(SDK_PATH)/lib \
	-Wl,--gc-sections \
	-nostdlib \
	-T$(CUSTOM_LD_FILE)   \
	-Wl,--no-check-sections \
	-u call_user_start \
	-Wl,-static \
	-Wl,--start-group \
	-lminic \
	-lgcc \
	-lhal \
	-lespconn \
	-lphy \
	-lpp \
	-lnet80211 \
	-lwpa \
	-lcrypto \
	-lmain \
	-lfreertos \
	-llwip	\
	$(DEP_LIBS_eagle.app.v6) \
	-Wl,--end-group

DEPENDS_eagle.app.v6 = \
		$(CUSTOM_LD_FILE) \
		$(LDDIR)/eagle.rom.addr.v6.ld

#############################################################
# Configuration i.e. compile options etc.
# Target specific stuff (defines etc.) goes in here!
# Generally values applying to a tree are captured in the
#   makefile at its root level - these are then overridden
#   for a subtree within the makefile rooted therein
#

UNIVERSAL_TARGET_DEFINES = \
	-DFORTHRIGHT_VERSION_MAJOR=${FORTHRIGHT_VERSION_MAJOR} \
	-DFORTHRIGHT_VERSION_MINOR=${FORTHRIGHT_VERSION_MINOR} \

# Other potential configuration flags include:
#	-DTXRX_TXBUF_DEBUG
#	-DTXRX_RXBUF_DEBUG
#	-DWLAN_CONFIG_CCX
CONFIGURATION_DEFINES =	-DICACHE_FLASH

DEFINES +=				\
	$(UNIVERSAL_TARGET_DEFINES)	\
	$(CONFIGURATION_DEFINES)

DDEFINES +=				\
	$(UNIVERSAL_TARGET_DEFINES)	\
	$(CONFIGURATION_DEFINES)


#############################################################
# Recursion Magic - Don't touch this!!
#
# Each subtree potentially has an include directory
#   corresponding to the common APIs applicable to modules
#   rooted at that subtree. Accordingly, the INCLUDE PATH
#   of a module can only contain the include directories up
#   its parent path, and not its siblings
#
# Required for each makefile to inherit from the parent
#

INCLUDES := $(INCLUDES) -I $(PDIR)include
sinclude $(SDK_PATH)/Makefile

.PHONY: FORCE
FORCE:

