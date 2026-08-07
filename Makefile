# =============================================================================
# LUTify.jl — Verilator HDL test suite
#
# Requires: julia, verilator (>= 5.0), g++ >= 11
#
# Targets:
#   make all          - generate Verilog, compile, simulate (default)
#   make verilog      - generate .v files only
#   make compile      - run verilator + build sim libraries
#   make simulate     - link testbenches and run simulations
#   make clean        - remove build artifacts
#   make info         - print detected paths and configs
# =============================================================================

JULIA    ?= julia
VERILATOR?= verilator
CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++17
BUILD    ?= build

# Locate Verilator include dirs
VERILATED_H   := $(shell find /home/phil/bin /usr -name verilated.h 2>/dev/null | head -1)
VERILATOR_INC := $(shell dirname $(VERILATED_H))
VLTSTD        := $(VERILATOR_INC)/vltstd

# =============================================================================
# Phony targets
# =============================================================================
.PHONY: all verilog compile simulate clean info help         sin_8bit sin_16bit cos_8bit sin_4bit

all: $(BUILD)/results.txt

help:
	@echo "LUTify HDL test suite"
	@echo ""
	@echo "Targets:"
	@echo "  make all          - generate Verilog, compile, simulate (default)"
	@echo "  make verilog      - generate .v files only"
	@echo "  make compile      - run verilator + build sim libraries"
	@echo "  make simulate     - link testbenches and run simulations"
	@echo "  make clean        - remove build artifacts"
	@echo "  make info         - print detected paths and configs"
	@echo ""
	@echo "Single-config tests:"
	@echo "  make sin_8bit     - sine LUT, 8-bit, 200 entries"
	@echo "  make sin_16bit    - sine LUT, 16-bit, 200 entries"
	@echo "  make cos_8bit     - cosine LUT, 8-bit, 200 entries"
	@echo "  make sin_4bit     - sine LUT, 4-bit, 64 entries (low-precision demo)"

# =============================================================================
# Info
# =============================================================================
info:
	@echo "Julia       : $(shell $(JULIA) --version 2>/dev/null || echo not found)"
	@echo "Verilator   : $(shell $(VERILATOR) --version 2>/dev/null || echo not found)"
	@echo "C++         : $(shell $(CXX) --version | head -1)"
	@echo "Verilog inc : $(VERILATOR_INC)"
	@echo ""
	@echo "Configs: sin_8bit(8b,200), sin_16bit(16b,200), cos_8bit(8b,200), sin_4bit(4b,64)"

# =============================================================================
# Directory setup
# =============================================================================
$(BUILD)/verilog $(BUILD)/sim $(BUILD)/runners:
	@mkdir -p $@

# =============================================================================
# Config 1: sin_8bit -- 8-bit, 200 entries, [0, 2*pi]
# =============================================================================
$(BUILD)/verilog/lut_sin.v: | $(BUILD)/verilog
	@echo "[gen]  $@"
	$(JULIA) --project -e 'using LUTify; s=2pi/199; r=0.0:s:2pi; lut=LUT_cordic(:sin, r, 8, 16); vlog=export_verilog(lut, 8, "sin"); open("$@", "w") do f; write(f, vlog); end'

$(BUILD)/sim/sin_8bit: $(BUILD)/verilog/lut_sin.v | $(BUILD)/sim
	@echo "[verilator]  sin_8bit"
	$(VERILATOR) --cc --Mdir $@ --top-module lut_sin_bits8 $<

$(BUILD)/runners/sin_8bit.exe: $(BUILD)/sim/sin_8bit test/hdl/testbench.cpp | $(BUILD)/runners
	@echo "[link]   sin_8bit"
	$(CXX) $(CXXFLAGS) -I. -I$(BUILD)/sim/sin_8bit 	    -I$(VERILATOR_INC) -I$(VLTSTD) 	    -DVERILATOR=1 	    -DMODULE_CLASS=Vlut_sin_bits8 	    -DMODULE_HEADER='"'$(BUILD)/sim/sin_8bit/Vlut_sin_bits8.h'"' 	    $(BUILD)/sim/sin_8bit/Vlut_sin_bits8__Syms__Slow.cpp 	    $(BUILD)/sim/sin_8bit/Vlut_sin_bits8___024root__Slow.cpp 	    $(BUILD)/sim/sin_8bit/Vlut_sin_bits8___024root__0__Slow.cpp 	    $(BUILD)/sim/sin_8bit/Vlut_sin_bits8___024root__0.cpp 	    $(BUILD)/sim/sin_8bit/Vlut_sin_bits8.cpp 	    $(VERILATOR_INC)/verilated.cpp 	    $(VERILATOR_INC)/verilated_threads.cpp 	    test/hdl/testbench.cpp 	    -o $@ -lm

sin_8bit: $(BUILD)/runners/sin_8bit.exe
	@echo ""
	@echo "=== sin_8bit (8-bit, 200 entries) ==="
	$< Vlut_sin_bits8 200 8 0.0 6.283185307179586 0.032

# =============================================================================
# Config 2: sin_16bit -- 16-bit, 200 entries, [0, 2*pi]
# =============================================================================
$(BUILD)/verilog/lut_sin_16.v: | $(BUILD)/verilog
	@echo "[gen]  $@"
	$(JULIA) --project -e 'using LUTify; s=2pi/199; r=0.0:s:2pi; lut=LUT_cordic(:sin, r, 16, 16); vlog=export_verilog(lut, 16, "sin"); open("$@", "w") do f; write(f, vlog); end'

$(BUILD)/sim/sin_16bit: $(BUILD)/verilog/lut_sin_16.v | $(BUILD)/sim
	@echo "[verilator]  sin_16bit"
	$(VERILATOR) --cc --Mdir $@ --top-module lut_sin_bits16 $<

$(BUILD)/runners/sin_16bit.exe: $(BUILD)/sim/sin_16bit test/hdl/testbench.cpp | $(BUILD)/runners
	@echo "[link]   sin_16bit"
	$(CXX) $(CXXFLAGS) -I. -I$(BUILD)/sim/sin_16bit 	    -I$(VERILATOR_INC) -I$(VLTSTD) 	    -DVERILATOR=1 	    -DMODULE_CLASS=Vlut_sin_bits16 	    -DMODULE_HEADER='"'$(BUILD)/sim/sin_16bit/Vlut_sin_bits16.h'"' 	    $(BUILD)/sim/sin_16bit/Vlut_sin_bits16__Syms__Slow.cpp 	    $(BUILD)/sim/sin_16bit/Vlut_sin_bits16___024root__Slow.cpp 	    $(BUILD)/sim/sin_16bit/Vlut_sin_bits16___024root__0__Slow.cpp 	    $(BUILD)/sim/sin_16bit/Vlut_sin_bits16___024root__0.cpp 	    $(BUILD)/sim/sin_16bit/Vlut_sin_bits16.cpp 	    $(VERILATOR_INC)/verilated.cpp 	    $(VERILATOR_INC)/verilated_threads.cpp 	    test/hdl/testbench.cpp 	    -o $@ -lm

sin_16bit: $(BUILD)/runners/sin_16bit.exe
	@echo ""
	@echo "=== sin_16bit (16-bit, 200 entries) ==="
	$< Vlut_sin_bits16 200 16 0.0 6.283185307179586 0.063

# =============================================================================
# Config 3: cos_8bit -- 8-bit, 200 entries, [0, 2*pi]
# =============================================================================
$(BUILD)/verilog/lut_cos.v: | $(BUILD)/verilog
	@echo "[gen]  $@"
	$(JULIA) --project -e 'using LUTify; s=2pi/199; r=0.0:s:2pi; lut=LUT_cordic(:cos, r, 8, 16); vlog=export_verilog(lut, 8, "cos"); open("$@", "w") do f; write(f, vlog); end'

$(BUILD)/sim/cos_8bit: $(BUILD)/verilog/lut_cos.v | $(BUILD)/sim
	@echo "[verilator]  cos_8bit"
	$(VERILATOR) --cc --Mdir $@ --top-module lut_cos_bits8 $<

$(BUILD)/runners/cos_8bit.exe: $(BUILD)/sim/cos_8bit test/hdl/testbench.cpp | $(BUILD)/runners
	@echo "[link]   cos_8bit"
	$(CXX) $(CXXFLAGS) -I. -I$(BUILD)/sim/cos_8bit 	    -I$(VERILATOR_INC) -I$(VLTSTD) 	    -DVERILATOR=1 	    -DMODULE_CLASS=Vlut_cos_bits8 	    -DMODULE_HEADER='"'$(BUILD)/sim/cos_8bit/Vlut_cos_bits8.h'"' 	    $(BUILD)/sim/cos_8bit/Vlut_cos_bits8__Syms__Slow.cpp 	    $(BUILD)/sim/cos_8bit/Vlut_cos_bits8___024root__Slow.cpp 	    $(BUILD)/sim/cos_8bit/Vlut_cos_bits8___024root__0__Slow.cpp 	    $(BUILD)/sim/cos_8bit/Vlut_cos_bits8___024root__0.cpp 	    $(BUILD)/sim/cos_8bit/Vlut_cos_bits8.cpp 	    $(VERILATOR_INC)/verilated.cpp 	    $(VERILATOR_INC)/verilated_threads.cpp 	    test/hdl/testbench.cpp 	    -o $@ -lm

cos_8bit: $(BUILD)/runners/cos_8bit.exe
	@echo ""
	@echo "=== cos_8bit (8-bit, 200 entries) ==="
	$< Vlut_cos_bits8 200 8 0.0 6.283185307179586 0.032

# =============================================================================
# Config 4: sin_4bit -- 4-bit, 64 entries, [0, 2*pi] (low-precision demo)
# =============================================================================
$(BUILD)/verilog/lut_sin_4.v: | $(BUILD)/verilog
	@echo "[gen]  $@"
	$(JULIA) --project -e 'using LUTify; s=2pi/63; r=0.0:s:2pi; lut=LUT_cordic(:sin, r, 4, 16); vlog=export_verilog(lut, 4, "sin"); open("$@", "w") do f; write(f, vlog); end'

$(BUILD)/sim/sin_4bit: $(BUILD)/verilog/lut_sin_4.v | $(BUILD)/sim
	@echo "[verilator]  sin_4bit"
	$(VERILATOR) --cc --Mdir $@ --top-module lut_sin_bits4 $<

$(BUILD)/runners/sin_4bit.exe: $(BUILD)/sim/sin_4bit test/hdl/testbench.cpp | $(BUILD)/runners
	@echo "[link]   sin_4bit"
	$(CXX) $(CXXFLAGS) -I. -I$(BUILD)/sim/sin_4bit 	    -I$(VERILATOR_INC) -I$(VLTSTD) 	    -DVERILATOR=1 	    -DMODULE_CLASS=Vlut_sin_bits4 	    -DMODULE_HEADER='"'$(BUILD)/sim/sin_4bit/Vlut_sin_bits4.h'"' 	    $(BUILD)/sim/sin_4bit/Vlut_sin_bits4__Syms__Slow.cpp 	    $(BUILD)/sim/sin_4bit/Vlut_sin_bits4___024root__Slow.cpp 	    $(BUILD)/sim/sin_4bit/Vlut_sin_bits4___024root__0__Slow.cpp 	    $(BUILD)/sim/sin_4bit/Vlut_sin_bits4___024root__0.cpp 	    $(BUILD)/sim/sin_4bit/Vlut_sin_bits4.cpp 	    $(VERILATOR_INC)/verilated.cpp 	    $(VERILATOR_INC)/verilated_threads.cpp 	    test/hdl/testbench.cpp 	    -o $@ -lm

sin_4bit: $(BUILD)/runners/sin_4bit.exe
	@echo ""
	@echo "=== sin_4bit (4-bit, 64 entries) ==="
	$< Vlut_sin_bits4 64 4 0.0 6.283185307179586 0.125

# =============================================================================
# Aggregate targets
# =============================================================================
verilog: $(BUILD)/verilog/lut_sin.v $(BUILD)/verilog/lut_sin_16.v          $(BUILD)/verilog/lut_cos.v $(BUILD)/verilog/lut_sin_4.v
	@echo "[verilog] Done -- .v files in $(BUILD)/verilog/"

compile: verilog
	@echo "[compile] Done -- sim libs in $(BUILD)/sim/"

simulate: compile sin_8bit sin_16bit cos_8bit sin_4bit
	@echo ""
	@echo "=========================================="
	@echo "  All HDL simulations complete"
	@echo "=========================================="

# =============================================================================
# Results summary
# =============================================================================
$(BUILD)/results.txt: simulate
	@echo "All simulations passed." > $@

# =============================================================================
# Clean
# =============================================================================
clean:
	rm -rf $(BUILD) obj_dir
	@echo "Cleaned $(BUILD)/ and obj_dir/"
