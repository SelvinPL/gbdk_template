# If you move this project you can change the directory
# to match your GBDK root directory (ex: GBDK_HOME = "C:/GBDK/"
ifndef GBDK_HOME
	GBDK_HOME = ../../..
endif
LCC = $(GBDK_HOME)/bin/lcc
PNG2ASSET = $(GBDK_HOME)/bin/png2asset

# Set platforms to build here, spaced separated. (These are in the separate Makefile.targets)
# They can also be built/cleaned individually: "make gg" and "make gg-clean"
# Possible are: gb gbc pocket megaduck sms gg
TARGETS=gbc gb sms gg

# You can set the name of the ROM file here
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

PROJECTNAME = $(current_dir)

# Configure platform specific LCC flags here:
LCCFLAGS_gb      = -Wl-yt0x1B -autobank # Set an MBC for banking (1B-ROM+MBC5+RAM+BATT)
LCCFLAGS_pocket  = -Wl-yt0x1B -autobank # Usually the same as required for .gb
LCCFLAGS_duck    = -Wl-yt0x1B -autobank # Usually the same as required for .gb
LCCFLAGS_gbc     = -Wl-yt0x1B -Wm-yc -autobank # Same as .gb with: -Wm-yc (gb & gbc) or Wm-yC (gbc exclusive)
LCCFLAGS_sms     =
LCCFLAGS_gg      =
LCCFLAGS_nes     = -autobank

LCCFLAGS += $(LCCFLAGS_$(EXT)) # This adds the current platform specific LCC Flags

LCCFLAGS += -Wl-j -Wm-yoA -Wm-ya4 -Wb-ext=.rel -Wb-v # MBC + Autobanking related flags

P2AFLAGS_gb     = -map -keep_palette_order -bpp 2 -pack_mode gb -noflip
P2AFLAGS_gbc    = -map -bpp 2 -max_palettes 8 -use_map_attributes -pack_mode gb -noflip
P2AFLAGS_pocket = -map -keep_palette_order -bpp 2 -max_palettes 8 -use_map_attributes -pack_mode gb -noflip
P2AFLAGS_duck   = -map -keep_palette_order -bpp 2 -pack_mode gb -noflip
P2AFLAGS_sms    = -map -use_map_attributes -bpp 4 -max_palettes 2 -pack_mode sms -noflip
P2AFLAGS_gg     = -map -use_map_attributes -bpp 4 -max_palettes 2 -pack_mode sms -noflip
P2AFLAGS_nes    = -map -bpp 2 -max_palettes 4 -pack_mode nes -noflip -use_nes_attributes -b 0

P2AFLAGS = $(P2AFLAGS_$(EXT))


CFLAGS = -Wf-MMD 
#-Wf--Werror

# EXT?=gb # Only sets extension to default (game boy .gb) if not populated
SRCDIR			=	src
SRCDIREXT		=	src/$(EXT)
SRCDIRPORT		=	src/$(PORT)
RESOBJSRC		=	obj/$(EXT)/res
RESDIR			=	res
RESDIREXT		=	res/$(EXT)
RESDIRPORT		=	res/$(PORT)
OBJDIR			=	obj/$(EXT)
BINDIR			=	build/$(EXT)
MKDIRS			=	$(OBJDIR) $(BINDIR) $(RESOBJSRC) # See bottom of Makefile for directory auto-creation

BINS			=	$(OBJDIR)/$(PROJECTNAME).$(EXT)
CSOURCES		=	$(foreach dir,$(SRCDIR),$(notdir $(wildcard $(dir)/*.c)))
CSOURCES		+=	$(foreach dir,$(SRCDIREXT),$(notdir $(wildcard $(dir)/*.c)))
CSOURCES   		+=	$(foreach dir,$(SRCDIRPORT),$(notdir $(wildcard $(dir)/*.c)))
CSOURCES		+=	$(foreach dir,$(RESDIR),$(notdir $(wildcard $(dir)/*.c)))
CSOURCES		+=	$(foreach dir,$(RESDIREXT),$(notdir $(wildcard $(dir)/*.c)))
CSOURCES		+=	$(foreach dir,$(RESDIRPORT),$(notdir $(wildcard $(dir)/*.c)))
ASMSOURCES		=	$(foreach dir,$(SRCDIR),$(notdir $(wildcard $(dir)/*.s)))
ASMSOURCES		+=	$(foreach dir,$(SRCDIREXT),$(notdir $(wildcard $(dir)/*.s)))
ASMSOURCES		+=	$(foreach dir,$(SRCDIRPORT),$(notdir $(wildcard $(dir)/*.s)))
OBJS			=	$(CSOURCES:%.c=$(OBJDIR)/%.o) $(ASMSOURCES:%.s=$(OBJDIR)/%.o)

# For png2asset: converting map source pngs -> .c -> .o
MAPPNGS			=	$(foreach dir,$(RESDIR),$(notdir $(wildcard $(dir)/*.png)))
MAPPNGS			+=	$(foreach dir,$(RESDIREXT),$(notdir $(wildcard $(dir)/*.png)))
MAPPNGS			+=	$(foreach dir,$(RESDIRPORT),$(notdir $(wildcard $(dir)/*.png)))
MAPSRCS			=	$(MAPPNGS:%.png=$(RESOBJSRC)/%.c)
MAPOBJS			=	$(MAPSRCS:$(RESOBJSRC)/%.c=$(OBJDIR)/%.o)

.PRECIOUS: $(MAPSRCS)

#add include
CFLAGS += -I$(OBJDIR)  -Iinclude

DEBUG ?= 0
ifeq ($(DEBUG), 1)
    CFLAGS	+= -debug -v
else
    CFLAGS	+= -Wf--peep-asm -Wf--peep-return -Wf--opt-code-speed -Wf"--max-allocs-per-node 6000000"
endif

# Builds all targets sequentially
all: $(TARGETS)

# Use png2asset to convert the png into C formatted map data
# -c ...   : Set C output file
# Convert metasprite .pngs in res/ -> .c files in obj/<platform ext>/src/
$(RESOBJSRC)/%.c:	$(RESDIR)/%.png
	$(PNG2ASSET) $< $(P2AFLAGS) -c $@
$(RESOBJSRC)/%.c:	$(RESDIREXT)/%.png
	$(PNG2ASSET) $< $(P2AFLAGS) -c $@
$(RESOBJSRC)/%.c:	$(RESDIRPORT)/%.png
	$(PNG2ASSET) $< $(P2AFLAGS) -c $@

# Compile the map pngs that were converted to .c files
# .c files in obj/<platform ext>/src/ -> .o files in obj/
$(OBJDIR)/%.o:	$(RESOBJSRC)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<

# Dependencies
DEPS = $(OBJS:%.o=%.d)

-include $(DEPS)

# Compile .c files in "src/" to .o object files
$(OBJDIR)/%.o:	$(SRCDIR)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<
$(OBJDIR)/%.o:	$(SRCDIREXT)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<
$(OBJDIR)/%.o:	$(SRCDIRPORT)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<

# Compile .c files in "res/" to .o object files
$(OBJDIR)/%.o:	$(RESDIR)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<
$(OBJDIR)/%.o:	$(RESDIREXT)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<
$(OBJDIR)/%.o:	$(RESDIRPORT)/%.c
	$(LCC) $(CFLAGS) -c -o $@ $<

# Compile .s assembly files in "src/" to .o object files
$(OBJDIR)/%.o:	$(SRCDIR)/%.s
	$(LCC) $(CFLAGS) -c -o $@ $<
$(OBJDIR)/%.o:	$(SRCDIREXT)/%.s
	$(LCC) $(CFLAGS) -c -o $@ $<
$(OBJDIR)/%.o:	$(SRCDIRPORT)/%.s
	$(LCC) $(CFLAGS) -c -o $@ $<

# If needed, compile .c files in "src/" to .s assembly files
# (not required if .c is compiled directly to .o)
$(OBJDIR)/%.s:	$(SRCDIR)/%.c
	$(LCC) $(CFLAGS) -S -o $@ $<
$(OBJDIR)/%.s:	$(SRCDIREXT)/%.c
	$(LCC) $(CFLAGS) -S -o $@ $<
$(OBJDIR)/%.s:	$(SRCDIRPORT)/%.c
	$(LCC) $(CFLAGS) -S -o $@ $<

# Convert and build maps first so they're available when compiling the main sources
$(OBJS):	$(MAPOBJS)

# Link the compiled object files into a .gb ROM file
$(BINS):	$(OBJS)
	$(LCC) $(LCCFLAGS) $(CFLAGS) -o $(BINDIR)/$(PROJECTNAME).$(EXT) $(MAPOBJS) $(OBJS)

clean:
	@echo Cleaning
	@for target in $(TARGETS); do \
		$(MAKE) $$target-clean; \
	done

# Include available build targets
include Makefile.targets


# create necessary directories after Makefile is parsed but before build
# info prevents the command from being pasted into the makefile
ifneq ($(strip $(EXT)),)           # Only make the directories if EXT has been set by a target
$(info $(shell mkdir -p $(MKDIRS)))
endif
