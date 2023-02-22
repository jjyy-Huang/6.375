plugin -i bluespec
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/FIFOL1.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/FIFO1.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/FIFO2.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/RevertReg.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/RegFile.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/SizedFIFO.v
read_verilog /home/jerry/software/bsc/inst/lib/Verilog/BRAM2.v
read_bluespec -aggressive-conditions -no-autoload-bsv-prims -I ./connectal/:./src/:./src/proclib/:./src/types/ -top mkProc ./src/MultiCycle.bsv

synth