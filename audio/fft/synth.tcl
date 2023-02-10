#read_verilog ../work/mkFFT.v
#read_verilog /home/jerry/software/bsc/inst/lib/Verilog/FIFO2.v

plugin -i bluespec
read_bluespec -aggressive-conditions -I ../common/ -top mkFFT FFT.bsv

synth