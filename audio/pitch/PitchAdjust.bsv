
import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import ComplexMP::*;
import AudioProcessorTypes::*;


typedef Server#(
	Vector#(nbins, ComplexMP#(isize, fsize, psize)),
	Vector#(nbins, ComplexMP#(isize, fsize, psize))
) PitchAdjust#(
	numeric type nbins, numeric type isize,
	numeric type fsize, numeric type psize
);
interface SettablePitchAdjust#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);
	interface PitchAdjust#(nbins, isize, fsize, psize) adjust;
	interface Put#(FixedPoint#(isize, fsize)) setfactor;
endinterface

// s - the amount each window is shifted from the previous window.
//
// factor - the amount to adjust the pitch.
//  1.0 makes no change. 2.0 goes up an octave, 0.5 goes down an octave, etc...
module mkPitchAdjust(
											Integer s,
											SettablePitchAdjust#(nbins, isize, fsize, psize) ifc
										) provisos (
											Add#(a__, TAdd#(3, TLog#(nbins)), isize),
											Add#(b__, psize, isize),
											Add#(c__, psize, TAdd#(isize, isize)),
											Add#(TAdd#(1, TLog#(TAdd#(3, nbins))), e__, isize)
										);
	FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) inFifo  <- mkFIFO();
	FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outFifo <- mkFIFO();

	Vector#(nbins, Reg#(Phase#(psize))) inPhases  <- replicateM(mkReg(0));
	Vector#(nbins, Reg#(Phase#(psize))) outPhases <- replicateM(mkReg(0));
	Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) out <- mkReg(replicate(cmplxmp(0, 0)));
	Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) in <- mkReg(replicate(cmplxmp(0, 0)));

	Reg#(Maybe#(FixedPoint#(isize, fsize))) factor <- mkReg(tagged Invalid);
	Reg#(Bool) isDone <- mkReg(True);
	let isRunning = !isDone;
	Reg#(Int#(TAdd#(1, TLog#(TAdd#(3, nbins))))) i <- mkReg(0);

	//Reg#(FixedPoint#(misize, mfsize)) multiplied <- mkRegU();
	let multiplied <- mkRegU();
	Reg#(Int#(3)) abcd <- mkReg(0);
	Reg#(Int#(TAdd#(3, TLog#(nbins)))) binR <- mkRegU();
	Reg#(Int#(TAdd#(3, TLog#(nbins)))) nbinR <- mkRegU();
	let magR <- mkRegU();
	let iFxptR <- mkRegU();
	let ip1FxptR <- mkRegU();
	Reg#(Int#(psize)) dphaseR <- mkRegU();

	rule pitchAdjustIn(isValid(factor) && i == 0 && isDone);
		in <= inFifo.first();
		inFifo.deq();

		out <= replicate(cmplxmp(0, 0));
		isDone <= False;
	endrule

	rule pitchAdjustA(isValid(factor) && i < fromInteger(valueof(nbins)) && abcd == 0 && isRunning);
		let phase = phaseof(in[i]);
		let mag = in[i].magnitude;

		let dphase = phase - inPhases[i];
		inPhases[i] <= phase;
		magR <= mag;
		dphaseR <= dphase;
		abcd <= -1;
	endrule

	rule pitchAdjustB(isValid(factor) && i < fromInteger(valueof(nbins)) && abcd == -1 && isRunning);
		iFxptR <= fromInt(i);
		ip1FxptR <= fromInt(i + 1);
		abcd <= 1;
	endrule
	rule pitchAdjustB2(isValid(factor) && i < fromInteger(valueof(nbins)) && abcd == 1 && isRunning);
		Int#(TAdd#(3, TLog#(nbins))) bin = truncate(fxptGetInt(iFxptR * fromMaybe(2, factor)));
		Int#(TAdd#(3, TLog#(nbins))) nbin = truncate(fxptGetInt(ip1FxptR * fromMaybe(2, factor)));
		binR <= bin;
		nbinR <= nbin;
		abcd <= 2;
	endrule

	rule pitchAdjustC(isValid(factor) && i < fromInteger(valueof(nbins)) && abcd == 2 && isRunning);

		if (nbinR != binR && binR >= 0 && binR < fromInteger(valueof(nbins))) begin
			FixedPoint#(isize, fsize) dphaseFxpt = fromInt(dphaseR);
			multiplied <= fxptMult(dphaseFxpt, fromMaybe(2, factor));
		end
		abcd <= 3;
	endrule

	rule pitchAdjustD(isValid(factor) && i < fromInteger(valueof(nbins)) && abcd == 3 && isRunning);
		if (nbinR != binR && binR >= 0 && binR < fromInteger(valueof(nbins))) begin
			let multInt = fxptGetInt(multiplied);
			let shifted = truncate(multInt);
			outPhases[binR] <= outPhases[binR] + shifted;
			out[binR] <= cmplxmp(magR, outPhases[binR] + shifted);
		end

		i <= i + 1;
		abcd <= 0;
	endrule

	rule pitchAdjustOut(isValid(factor) && i == fromInteger(valueof(nbins)) && isRunning);
		outFifo.enq(out);
		i <= 0;
		isDone <= True;
	endrule

	interface PitchAdjust adjust;
		interface Put request  = toPut(inFifo);
		interface Get response = toGet(outFifo);
	endinterface

	interface Put setfactor;
		method Action put(FixedPoint#(isize, fsize) x) if (!isValid(factor));
			factor <= tagged Valid x;
		endmethod
	endinterface
endmodule