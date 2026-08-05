### This file heavily references ds-pokemon-hacking/White2Upgrade
### A huge thank you to the contributors of ds-pokemon-hacking
### for all of their hard work over the years!

project         := PW2Code
rom_code        := IRDO
patches         := Base BattleUpgrade FairyPatch

# Directory configuration
build_dir        = build
romfs           := $(build_dir)/romfs
romfs_data      := $(romfs)/data
incl_dir        := include
data_dir        := Assets
dll_dir         := $(romfs_data)/patches

patches_dir     := Patches
externals_dir   := Externals

# Globals
global_dir := Global/
## Code
s_src   := $(shell find $(global_dir) -type f -name '*.S')
c_src   := $(shell find $(global_dir) -type f -name '*.c')
cpp_src := $(shell find $(global_dir) -type f -name '*.cpp')
srcs     := $(s_src) $(c_src) $(cpp_src)
## Objects
asm_obj         := $(addprefix $(build_dir)/code/, $(notdir $(s_src:.S=_S.o)))
c_obj           := $(addprefix $(build_dir)/code/, $(notdir $(c_src:.c=_c.o)))
cpp_obj         := $(addprefix $(build_dir)/code/, $(notdir $(cpp_src:.cpp=_cpp.o)))
objs            := $(asm_obj) $(c_obj) $(cpp_obj)
## Headers
includes := . Global Headers Externals/swan Externals/ExtLib Externals/NitroKernel/include Externals/libRPM/include

# Libraries
lib_dir   := Libraries/
lib_build := $(build_dir)/lib
lib_romfs := $(romfs_data)/lib
## Code
lib_cpp_src  := $(shell find $(lib_dir) -type f -name '*.cpp')
lib_srcs     := $(lib_cpp_src)
## Objects
lib_cpp_obj  := $(addprefix $(lib_build)/, $(patsubst $(lib_dir)%,%,$(lib_cpp_src:.cpp=.elf)))
lib_objs     := $(lib_cpp_obj)
lib_dlls     := $(addprefix $(lib_romfs)/, $(patsubst $(lib_build)/%,%,$(lib_objs:.elf=.dll)))
lib_dll_dirs := $(sort $(dir $(lib_dlls)))

# Patches
base_dir           := $(patches_dir)/Base
battle_upgrade_dir := $(patches_dir)/BattleUpgrade
fairy_patch_dir    := $(patches_dir)/FairyPatch
## Base
base_s_src   := $(shell find $(base_dir) -type f -name '*.S')
base_c_src   := $(shell find $(base_dir) -type f -name '*.c')
base_cpp_src := $(shell find $(base_dir) -type f -name '*.cpp')

base_asm_obj := $(addprefix $(build_dir)/code/, $(notdir $(base_s_src:.S=_S.o)))
base_c_obj   := $(addprefix $(build_dir)/code/, $(notdir $(base_c_src:.c=_c.o)))
base_cpp_obj := $(addprefix $(build_dir)/code/, $(notdir $(base_cpp_src:.cpp=_cpp.o)))

base_srcs    := $(base_s_src) $(base_c_src) $(base_cpp_src)
base_objs    := $(base_asm_obj) $(base_c_obj) $(base_cpp_obj)
## Battle Upgrade
btlupg_s_src   := $(shell find $(battle_upgrade_dir) -type f -name '*.S')
btlupg_c_src   := $(shell find $(battle_upgrade_dir) -type f -name '*.c')
btlupg_cpp_src := $(shell find $(battle_upgrade_dir) -type f -name '*.cpp')

btlupg_asm_obj := $(addprefix $(build_dir)/code/, $(notdir $(btlupg_s_src:.S=_S.o)))
btlupg_c_obj   := $(addprefix $(build_dir)/code/, $(notdir $(btlupg_c_src:.c=_c.o)))
btlupg_cpp_obj := $(addprefix $(build_dir)/code/, $(notdir $(btlupg_cpp_src:.cpp=_cpp.o)))

btlupg_srcs    := $(btlupg_s_src) $(btlupg_c_src) $(btlupg_cpp_src)
btlupg_objs    := $(btlupg_asm_obj) $(btlupg_c_obj) $(btlupg_cpp_obj)

includes       += $(battle_upgrade_dir)/include
## Fairy Patch
fairy_s_src   := $(shell find $(fairy_patch_dir) -type f -name '*.S')
fairy_c_src   := $(shell find $(fairy_patch_dir) -type f -name '*.c')
fairy_cpp_src := $(shell find $(fairy_patch_dir) -type f -name '*.cpp')

fairy_asm_obj := $(addprefix $(build_dir)/code/, $(notdir $(fairy_s_src:.S=_S.o)))
fairy_c_obj   := $(addprefix $(build_dir)/code/, $(notdir $(fairy_c_src:.c=_c.o)))
fairy_cpp_obj := $(addprefix $(build_dir)/code/, $(notdir $(fairy_cpp_src:.cpp=_cpp.o)))

fairy_srcs    := $(fairy_s_src) $(fairy_c_src) $(fairy_cpp_src)
fairy_objs    := $(fairy_asm_obj) $(fairy_c_obj) $(fairy_cpp_obj)

# Add patches to final
src_dirs := $(sort $(dir $(srcs) $(lib_dir) $(base_srcs) $(btlupg_srcs) $(fairy_srcs)))

# Tools
g++             := arm-none-eabi-g++
ld              := arm-none-eabi-ld
CTRMap          := tools/CTRMap.jar

# Flags
flags           := -mthumb -march=armv5t -r -Os -mlong-calls -w

# Add our includes
headers  := $(wildcard $(includes:%=%/*.h))
includes := $(addprefix -I, $(includes))
flags    += $(includes)

vpath %.S   $(src_dirs)
vpath %.c   $(src_dirs)
vpath %.cpp $(src_dirs)

# -------------------------------------------------------------------
# Targets 
# -------------------------------------------------------------------
# Default
all: data code

# Code
code: patches libraries
patches: $(foreach item,$(patches),$(dll_dir)/$(item).dll)
libraries: $(lib_dlls)

# Data
data: $(romfs_data)

# Manually define targets
$(dll_dir)/%.dll: $(build_dir)/%.elf
	@ mkdir -p $(@D)
	@ echo "[>] Creating DLL $@..."
	@ java -cp $(CTRMap) rpm.cli.RPMTool -i $< --fourcc DLXF -o $@ --esdb ESDB.yml --generate-relocations

$(build_dir)/Base.elf: $(objs) $(base_objs)
	@ echo "[+] Linking Base objects into $@..."
	@ $(ld) -o $@ -r $$(ls $^ 2>/dev/null)

$(build_dir)/BattleUpgrade.elf: $(objs) $(btlupg_objs)
	@ echo "$$(ls $^ 2>/dev/null)"
	@ echo "[+] Linking BattleUpgrade objects into $@..."
	@ $(ld) -o $@ -r $$(ls $^ 2>/dev/null)

$(build_dir)/FairyPatch.elf: $(objs) $(fairy_objs)
	@ echo "[+] Linking FairyPatch objects into $@..."
	@ $(ld) -o $@ -r $$(ls $^ 2>/dev/null)

$(lib_romfs)/%.dll: $(lib_build)/%.elf
	@ mkdir -p $(@D)
	@ if [ -f "$<" ]; then \
		echo "[>] Creating DLL $@..."; \
		java -cp $(CTRMap) rpm.cli.RPMTool -i $< --fourcc DLXF -o $@ --esdb ESDB.yml --generate-relocations > /dev/null; \
	else \
		echo "$(CYELLOW)[?] Missing ELF $<...$(CDEFAULT)"; \
	fi

$(romfs_data): $(data_dir)/
	@ echo "[+] Storing all Assets..."
	@ mkdir -p $@
	@ cp -R $< $@

# -------------------------------------------------------------------
# Prerequisites 
# -------------------------------------------------------------------
# All standard compilation/assembly rules
$(build_dir)/code/%_S.o: %.S $(headers)
	@ echo "[+] Assembling $<..."
	@ mkdir -p $(@D)
	@ $(g++) $(flags) -c $< -o $@

$(build_dir)/code/%_c.o: %.c $(headers)
	@ echo "[+] Compiling $<..."
	@ mkdir -p $(@D)
	@ $(g++) $(flags) -c $< -o $@

$(build_dir)/code/%_cpp.o: %.cpp $(headers)
	@ echo "[+] Compiling $<..."
	@ mkdir -p $(@D)
	@ $(g++) $(flags) -c $< -o $@

# Library compilation/assembly rules
$(lib_build)/%.elf: %.cpp $(headers)
	@ echo "[+] Compiling $<..."
	@ mkdir -p $(@D)
	@ $(g++) $(flags) -c $< -o $@

# Clean the working directory
clean:
	rm -rf $(build_dir)

.PHONY: all code clean

### Misc.
CYELLOW   := \033[0;33m
CDEFAULT  := \033[0m
