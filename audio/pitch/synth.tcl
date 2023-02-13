#read_verilog ../work/mkFFT.v
#read_verilog /home/jerry/software/bsc/inst/lib/Verilog/FIFO2.v

plugin -i bluespec
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/FIFO2.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/RevertReg.v
read_bluespec -aggressive-conditions -no-autoload-bsv-prims -I ../common:../fir:../fft:./ -top mkAudioPipeline ../common/AudioPipeline.bsv

synth
# synth_ice40