bscflags = -keep-fires -aggressive-conditions -Xc++ -D_GLIBCXX_USE_CXX11_ABI=0
bsvdir = ../common:../fir:../fft
build_script = yosys -s ./synth.tcl
build_dir = ../work
synth_dir = /tmp/6375-lab3-${USER}

src = PitchAdjust.bsv PitchAdjustTest.bsv $(wildcard ../common/*.bsv) $(wildcard ../fft/*.bsv) $(wildcard ../fir/*.bsv)


PitchAdjust: PitchAdjust.bsv PitchAdjustTest.bsv
	mkdir -p $(build_dir)
	bsc -u -sim -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags) -p +:$(bsvdir) -g mkPitchAdjustTest PitchAdjustTest.bsv
	bsc -e mkPitchAdjustTest -sim -o $(build_dir)/$@ -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags)
AudioPipeline: $(src)
	mkdir -p $(build_dir)
	bsc -u -sim -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags) -p +:$(bsvdir) -g mkTestDriver ../common/TestDriver.bsv
	bsc -e mkTestDriver -sim -o $(build_dir)/$@ -simdir $(build_dir) -bdir $(build_dir) -info-dir $(build_dir) $(bscflags)

cmp:
	@cmp ./out.pcm ../data/mitrib_pa8_2_2.pcm

synthAudioPipeline: $(src)
	@$(build_script)

clean:
	rm -rf $(build_dir) PitchAdjust AudioPipeline *.so out.pcm
