CONNECTALDIR ?= /workspace/connectal
MIGDIR ?= /workspacebluespecpcie/dram/vc707/
BSVROOT = $(abspath .)

S2H_INTERFACES = \
	ConnectalProcRequest:ConnectalWrapper.connectProc\
	ConnectalMemoryInitialization:ConnectalWrapper.initProc
H2S_INTERFACES = \
	ConnectalWrapper:ConnectalProcIndication:host
BSVFILES = \
	connectal/Ifc.bsv \
	connectal/ConnectalWrapper.bsv
BSVPATH = $(BSVROOT)/src:$(BSVROOT)/src/proclib:$(BSVROOT)/src/types:$(BSVROOT)/src/xilinx/ddr3_v2_0 \
	# $(CONNECTALDIR)/bsv

CPPFILES += \
	connectal/main.cpp\
	connectal/Platform.cpp


SOFTWARE_SOCKET_NAME=/tmp/connectal$(USER)
export SOFTWARE_SOCKET_NAME

CONNECTALFLAGS += -D $(VPROC) --bsvpath $(BSVPATH)
CONNECTALFLAGS += --bscflags " -D $(VPROC) -steps-max-intervals 50 +RTS -K256M -RTS"
CONNECTALFLAGS +=  --bscflags " -u -show-schedule"
CONNECTALFLAGS += -D IMPORT_HOSTIF -D XILINX_SYS_CLK
CONNECTALFLAGS += --mainclockperiod=20


include $(CONNECTALDIR)/Makefile.connectal
# CONNECTALFLAGS += -D BOARD_bluesim

# PIN_TYPE = Top_Pins
# PIN_TYPE_INCLUDE = Ifc
# AUTOTOP = --interface pins:ConnectalWrapper.pins

# ifeq ($(BOARD),vc707g2)
# CONNECTALFLAGS += --verilog=$(MIGDIR) \
# 				  --implconstraint $(MIGDIR)/ddr3_v2_0.xdc \
				  # --xci $(CONNECTALDIR)/out/$(BOARD)/ddr3_v2_0/ddr3_v2_0.xci

# endif

simulation: clean
	mkdir -p bluesim/obj/
# cp bolib/*.bo bluesim/obj/.
	make -j32 build.bluesim




clean:
	rm -rf bluesim

