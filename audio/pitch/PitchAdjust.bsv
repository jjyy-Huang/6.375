
import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import ComplexMP::*;


typedef Server#(
	Vector#(nbins, ComplexMP#(isize, fsize, psize)),
	Vector#(nbins, ComplexMP#(isize, fsize, psize))
) PitchAdjust#(
	numeric type nbins, numeric type isize,
	numeric type fsize, numeric type psize
);


// s - the amount each window is shifted from the previous window.
//
// factor - the amount to adjust the pitch.
//  1.0 makes no change. 2.0 goes up an octave, 0.5 goes down an octave, etc...
module mkPitchAdjust(
											Integer s,
											FixedPoint#(isize, fsize) factor,
											PitchAdjust#(nbins, isize, fsize, psize) ifc
										) provisos (
											Add#(a__, TAdd#(3, TLog#(nbins)), isize),
											Add#(b__, psize, isize),
											Add#(c__, psize, TAdd#(isize, isize))
										);

	// TODO: implement this module
	FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) inFifo <- mkFIFO();
	FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outFifo <- mkFIFO();


	Vector#(nbins, Reg#(Phase#(psize))) inPhases  <- replicateM(mkReg(0));
	Vector#(nbins, Reg#(Phase#(psize))) outPhases <- replicateM(mkReg(0));

	rule pitchAdjust(True);
		let inData = inFifo.first();
		inFifo.deq();

		Vector#(nbins, ComplexMP#(isize, fsize, psize)) out = replicate(cmplxmp(0, 0));

		for(Integer i = 0; i < valueof(nbins); i = i + 1) begin
			let phase = inData[i].phase;
			let mag = inData[i].magnitude;
			// $display("IN: i:%d, p:%d", mag, phase);

			let dPhase = phase - inPhases[i];
			inPhases[i] <= phase;

			Int#(TAdd#(3, TLog#(nbins))) bin = truncate(fxptGetInt(fromInteger(i) * factor));
			Int#(TAdd#(3, TLog#(nbins))) nbin = truncate(fxptGetInt(fromInteger(i + 1) * factor));

			if (nbin != bin && bin >= 0 && bin < fromInteger(valueof(nbins))) begin
				FixedPoint#(isize, fsize) dPhaseFxpt = fromInt(dPhase); // int2fp
				let multiplied = fxptMult(dPhaseFxpt, factor);
				let multInt = fxptGetInt(multiplied);
				let shifted = truncate(multInt);
				outPhases[bin] <= outPhases[bin] + shifted;
				out[bin] = cmplxmp(mag, outPhases[bin] + shifted);
				// $display("OUT: i:%d, p:%d\n", mag, phase);
			end
		end

		outFifo.enq(out);
	endrule

	interface Put request = toPut(inFifo);
	interface Get response = toGet(outFifo);

endmodule