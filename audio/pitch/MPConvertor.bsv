
import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import ComplexMP::*;
import Complex::*;
import Cordic::*;

typedef Server#(
	Vector#(fft_points, Complex#(FixedPoint#(isize, fsize))),
	Vector#(fft_points, ComplexMP#(isize, fsize, psize))
) ToMP#(
	numeric type fft_points, numeric type isize,
	numeric type fsize, numeric type psize
);

module mkToMP(ToMP#(fft_points, isize, fsize, psize) ifc);
	FIFO#(Vector#(fft_points, Complex#(FixedPoint#(isize, fsize)))) inFifo <- mkFIFO();
	FIFO#(Vector#(fft_points, ComplexMP#(isize, fsize, psize))) outFifo <- mkFIFO();

	Vector#(fft_points, ToMagnitudePhase#(isize, fsize, psize)) convertor <- replicateM(mkCordicToMagnitudePhase());

	rule inPipe (True);
		for (Integer idx = 0; idx < valueOf(fft_points); idx = idx + 1) begin
			convertor[idx].request.put(inFifo.first[idx]);
		end
		inFifo.deq();
	endrule

	rule outPipe (True);
		Vector#(fft_points, ComplexMP#(isize, fsize, psize)) convertedData;
		for (Integer idx = 0; idx < valueOf(fft_points); idx = idx + 1) begin
			convertedData[idx] <- convertor[idx].response.get();
		end
		outFifo.enq(convertedData);
	endrule

	interface Put request = toPut(inFifo);
	interface Get response = toGet(outFifo);
endmodule

typedef Server#(
	Vector#(fft_points, ComplexMP#(isize, fsize, psize)),
	Vector#(fft_points, Complex#(FixedPoint#(isize, fsize)))
) FromMP#(
	numeric type fft_points, numeric type isize,
	numeric type fsize, numeric type psize
);

module mkFromMP(FromMP#(fft_points, isize, fsize, psize) ifc);
	FIFO#(Vector#(fft_points, ComplexMP#(isize, fsize, psize))) inFifo <- mkFIFO();
	FIFO#(Vector#(fft_points, Complex#(FixedPoint#(isize, fsize)))) outFifo <- mkFIFO();

	Vector#(fft_points, FromMagnitudePhase#(isize, fsize, psize)) convertor <- replicateM(mkCordicFromMagnitudePhase());

	rule inPipe (True);
		for (Integer idx = 0; idx < valueOf(fft_points); idx = idx + 1) begin
			convertor[idx].request.put(inFifo.first[idx]);
		end
		inFifo.deq();
	endrule

	rule outPipe (True);
		Vector#(fft_points, Complex#(FixedPoint#(isize, fsize))) convertedData;
		for (Integer idx = 0; idx < valueOf(fft_points); idx = idx + 1) begin
			convertedData[idx] <- convertor[idx].response.get();
		end
		outFifo.enq(convertedData);
	endrule

	interface Put request = toPut(inFifo);
	interface Get response = toGet(outFifo);

endmodule