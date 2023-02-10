bscflags = -keep-fires -aggressive-conditions
bsvdir = ../common:../fft
build_dir = ../work
synth_dir = /tmp/6375-lab1-${USER}

src = FIRFilter.bsv

compile: $(src)
	mkdir -p ${build_dir}
	bsc -u -sim -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags) -p +:$(bsvdir) -g mkTestDriver ../common/TestDriver.bsv

link: compile
	bsc -e mkTestDriver -sim -o ${build_dir}/out -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags)

simulation: link

verilog: $(src)
	mkdir -p ${build_dir}
	bsc -u -verilog -elab -vdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags) -p +:$(bsvdir) -g mkFIRFilter $^

synth: $(src)
	mkdir -p $(synth_dir)
	synth $^ mkFIRFilter -p $(bsvdir) -s $(synth_dir) -l multisize

clean:
	rm -rf ${build_dir} out out.so