bscflags = -keep-fires -aggressive-conditions -Xc++ -D_GLIBCXX_USE_CXX11_ABI=0
bsvdir = ../common:../fir
build_script = yosys -s ./synth.tcl
build_dir = ../work
synth_dir = /tmp/6375-lab2-${USER}

src = FFT.bsv

compile: $(src)
	mkdir -p $(build_dir)
	bsc -u -sim -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags) -p +:$(bsvdir) -g mkTestDriver ../common/TestDriver.bsv

link: compile
	bsc -e mkTestDriver -sim -o $(build_dir)/out -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags)

simulation: link

verilog: $(src)
	mkdir -p $(build_dir)
	bsc -u -verilog -elab -vdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags) -p +:$(bsvdir) -g mkFFT $^

synth: $(src)
	$(build_script)

cmp:
	@cmp ./out.pcm ../data/mitrib_fft8.pcm


clean:
	rm -rf $(build_dir) out.pcm
