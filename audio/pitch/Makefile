bscflags = -keep-fires -aggressive-conditions -Xc++ -D_GLIBCXX_USE_CXX11_ABI=0
bsvdir = ../common:../fir:../fft
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

synthAudioPipeline: $(src)
	mkdir -p $(synth_dir)
	synth ../common/AudioPipeline.bsv mkAudioPipeline -p $(bsvdir) -s $(synth_dir) -l multisize

clean:
	rm -rf $(build_dir) PitchAdjust AudioPipeline *.so
