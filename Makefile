# Use make -B due to the fact that .inc changes are not getting tracked
# in dependencies.
# Not yet sure how to utilize rgbasm -M (https://rednex.github.io/rgbds/rgbasm.1.html#M)
# to resolve.

ASM = rgbasm
LINK = rgblink
FIX = rgbfix

ROM_NAME = matrix-rain
SRC_DIR     = src
INC_DIR     = include
BUILD_DIR   = build
SOURCES 	= $(foreach dir,$(SRC_DIR),$(wildcard $(dir)/*.asm))
FIX_FLAGS 	= -v -p0
OUTPUT      = $(BUILD_DIR)/$(ROM_NAME)

INCDIR = include
OBJECTS = $(SOURCES:src/%.asm=build/%.obj)

.PHONY: all clean

all:  create_build_dir $(OUTPUT)

create_build_dir:
	mkdir -p $(BUILD_DIR)

$(OUTPUT): $(OBJECTS)
	$(LINK) -m $@.map -o $@.gb -n $@.sym $(OBJECTS)
	$(FIX) $(FIX_FLAGS) $@.gb

build/%.obj: src/%.asm
	$(ASM) -I$(INCDIR)/ -o$@ $<

clean:
	rm -rf $(BUILD_DIR)/*