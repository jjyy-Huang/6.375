
import FIFO::*;
import FixedPoint::*;

import AudioProcessorTypes::*;
import Vector::*;
import Multiplier::*;
module mkFIRFilter (Vector#(tnp1, FixedPoint#(16, 16)) coeffs, AudioProcessor ifc);

	FIFO#(Sample) infifo <- mkFIFO();
	FIFO#(Sample) outfifo <- mkFIFO();

	Vector#(TSub#(tnp1, 1), Reg#(Sample)) dataReg <- replicateM(mkReg(0));
	Vector#(tnp1, Multiplier) multVec <- replicateM(mkMultiplier());


	rule mulStage (True);
		Sample sampleData = infifo.first();
		$display("got sample: %h", infifo.first());
		infifo.deq();
		for (Integer idx = 0; idx < valueOf(TSub#(tnp1, 1)); idx = idx + 1) begin
			dataReg[idx] <= (idx == 0 ? sampleData: dataReg[idx - 1]);
		end

		for (Integer idx = 0; idx < valueOf(tnp1); idx = idx + 1) begin
			multVec[idx].putOperands(coeffs[idx], (idx == 0 ? sampleData: dataReg[idx-1]));
		end
	endrule

	rule addStage (True);
		Vector#(tnp1, FixedPoint#(16,16)) multRes;
		FixedPoint#(16,16) accumulate = 0;
		for (Integer idx = 0; idx < valueOf(tnp1); idx = idx + 1) begin
			multRes[idx] <- multVec[idx].getResult;
			accumulate = accumulate + multRes[idx];
		end
		outfifo.enq(fxptGetInt(accumulate));
	endrule

	method Action putSampleInput(Sample in);
		infifo.enq(in);
	endmethod

	method ActionValue#(Sample) getSampleOutput();
		outfifo.deq();
		return outfifo.first();
	endmethod

endmodule

