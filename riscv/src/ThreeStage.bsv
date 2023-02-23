import Types::*;
import ProcTypes::*;
import MemTypes::*;
import Reg6375::*;
import RFile::*;
import Scoreboard::*;
import Decode::*;
import Exec::*;
import CsrFile::*;
import Vector::*;
import FIFO::*;
import MemUtil::*;
import MemorySystem::*;
import ClientServer::*;
import Ehr::*;
import GetPut::*;

// Warning: "/workspace/6.375/riscv/src/ThreeStage.bsv", line 34, column 8: (G0010)
//   Rule "hostToCpu" was treated as more urgent than "doExecute". Conflicts:
//     "hostToCpu" cannot fire before "doExecute":
//       calls to
//         csrf.start vs. csrf.rd
//         pc_double_write_error.write vs. pc_double_write_error.read
//     "doExecute" cannot fire before "hostToCpu":
//       calls to pc_double_write_error.write vs. pc_double_write_error.read
// Warning: "/workspace/6.375/riscv/src/ThreeStage.bsv", line 34, column 8: (G0010)
//   Rule "doFetch" was treated as more urgent than "doExecute". Conflicts:
//     "doFetch" cannot fire before "doExecute":
//       calls to pc_double_write_error.write vs. pc_double_write_error.read
//     "doExecute" cannot fire before "doFetch":
//       calls to
//         pc.write vs. pc.read
//         epoch.write vs. epoch.read
//         pc_double_write_error.write vs. pc_double_write_error.read

typedef struct {
    Word pc;
    Word ppc;
    Bool epoch;
    } F2D deriving(Bits, Eq);

typedef struct {
    Word pc;
    Word ppc;
    Bool epoch;
    DecodedInst dInst;
    Word rVal1;
    Word rVal2;
    } D2E deriving(Bits, Eq);

(* synthesize *)
module mkProc(Proc);
////////////////////////////////////////////////////////////////////////////////
/// Processor module instantiation
////////////////////////////////////////////////////////////////////////////////
    Ehr#(2, Word) pc    <- mkEhr(0);
    Ehr#(2, Bool) epoch <- mkEhr(False);
    RFile      rf    <- mkRFile;
    CsrFile    csrf  <- mkCsrFile;

    FIFO#(F2D) f2d <- mkFIFO;
    FIFO#(D2E) d2e <- mkFIFO;

    Reg#(Bool)  loadWaitReg <- mkReg(False);
    Reg#(RIndx) dstLoad <- mkReg(0);

    Reg#(Maybe#(Bool))  hazardReg <- mkReg(tagged Invalid);
    Reg#(Maybe#(Word))  fetchedInst <- mkReg(tagged Invalid);
    Scoreboard#(1)  sb <- mkScoreboard;


////////////////////////////////////////////////////////////////////////////////
/// Section: Memory Subsystem
////////////////////////////////////////////////////////////////////////////////

   // Instantiate Wide Memory from DDR3 Client
    FIFO#(DDR3_Req) ddrReqQ <- mkFIFO;
    FIFO#(DDR3_Resp) ddrRespQ <- mkFIFO;
    let wideMem <- mkWideMemFromDDR3(ddrReqQ,ddrRespQ);

   // Initiatiate memory system( 4KB iCache + 4KB dCache)
    let memory <- mkMemorySystem(csrf.started, wideMem);
    let iMem = memory.iCache;
    let dMem = memory.dCache;

    Bool memReady = memory.init.done();

   // some garbage may get into ddr3RespFifo during soft reset
   // this rule drains all such garbage
    rule drainMemResponses( !csrf.started );
        ddrRespQ.deq;
    endrule
////////////////////////////////////////////////////////////////////////////////
/// End of Section: Memory Subsystem
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
/// Begin of Section: Processor
////////////////////////////////////////////////////////////////////////////////
    rule doFetch if (csrf.started);
        let ppc = pc[1] + 4;
        iMem.req(MemReq{op: Ld, addr: pc[1], data: ?});
        pc[1] <= ppc;
        f2d.enq(F2D {pc: pc[1], ppc: ppc, epoch: epoch[1]});
    endrule


    rule doDecode;
////////////////////////////////////////////////////////////////////////////////
/// Student's Task : Issue 1
/// Fix the code in this rule such that no new instruction
/// should be fetched in the stalled state
////////////////////////////////////////////////////////////////////////////////
        Data inst;
        if (isValid(fetchedInst)) begin
            inst = fromMaybe(?,fetchedInst);
        end else begin
            inst <- iMem.resp();
        end

       // Uncomment the following to have a pretty instruction print for debugging
       // $display(showInst(inst));

        let x = f2d.first;
        let epochD = x.epoch;
        if (epochD == epoch[0]) begin  // right-path instruction
            let dInst = decode(inst); // rs1, rs2 are Maybe types
          // check for data hazard
            let hazard = (sb.search1(dInst.src1) || sb.search2(dInst.src2));
          // if no hazard detected
            if (!hazard) begin
                let rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
                let rVal2 = rf.rd2(fromMaybe(?, dInst.src2));
                sb.insert(dInst.dst); // for detecting future data hazards
                d2e.enq(D2E {pc: x.pc, ppc: x.ppc, epoch: x.epoch,
                dInst: dInst, rVal1: rVal1, rVal2: rVal2});
                f2d.deq;
                fetchedInst <= tagged Invalid;
            end
          // if hazard detected
            else if (hazard) begin
                fetchedInst <= tagged Valid inst;
                $display("hazard detected");
            end
        end
        else begin // wrong-path instruction
            f2d.deq;
            // a JType-Inst / BType-Inst cause hazard, just flush it
            fetchedInst <= tagged Invalid;
        end
        $display("pc: %h inst: (%h) expanded: ", x.pc, inst, showInst(inst));
    endrule

    rule doExecute(!loadWaitReg);
////////////////////////////////////////////////////////////////////////////////
/// Student's Task: Issue 2
/// Fix the code in this rule by removing item from scoreboard when
/// an instruction completes execution
////////////////////////////////////////////////////////////////////////////////

        let x = d2e.first;
        let pcE = x.pc; let ppc = x.ppc; let epochE = x.epoch;
        let rVal1 = x.rVal1; let rVal2 = x.rVal2;
        let dInst = x.dInst;
        d2e.deq;


       // read CSR values (for CSRR inst)
        Word csrVal = csrf.rd(fromMaybe(?, dInst.csr));

       // execute
        ExecInst eInst = exec(dInst, rVal1, rVal2, pcE, csrVal);

        if(epochE != epoch[0] || eInst.iType != Ld) begin
            sb.remove(eInst.dst);
        end

        if (epochE == epoch[0]) begin  // right-path instruction

            if(dInst.iType == Unsupported) begin
                $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", pcE);
                $finish;
            end

////////////////////////////////////////////////////////////////////////////////
/// Student's Task: Issue 3
/// Modifying the following code section to fix doFetch and doExecute rule conflicts
////////////////////////////////////////////////////////////////////////////////
            let misprediction = eInst.nextPC != ppc;
                if ( misprediction ) begin
             // redirect the pc
                pc[0] <= eInst.nextPC;
                epoch[0] <= !epoch[0];
            end
////////////////////////////////////////////////////////////////////////////////
/// End of code section for Student's Task: Issue 3
////////////////////////////////////////////////////////////////////////////////

            if (eInst.iType == Ld) begin
                dMem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
                dstLoad <= fromMaybe(?, eInst.dst);
                loadWaitReg <= True;
            end
            else if (eInst.iType == St) begin
                dMem.req(MemReq{op: St, addr: eInst.addr,
                data: eInst.data});
            end
            else begin
                if(isValid(eInst.dst)) begin
                    rf.wr(fromMaybe(?, eInst.dst), eInst.data);
                end
            end

            csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);
        end
    endrule

    rule doLoadWait(loadWaitReg);
////////////////////////////////////////////////////////////////////////////////
/// Student's Task: Issue 2
/// Fix the code in this rule by removing item from scoreboard when
/// an instruction completes execution
////////////////////////////////////////////////////////////////////////////////
        let data <- dMem.resp();
        rf.wr(dstLoad, data);
        sb.remove(tagged Valid dstLoad);
        loadWaitReg <= False;
    endrule


    method ActionValue#(CpuToHostData) cpuToHost;
        let ret <- csrf.cpuToHost;
        return ret;
    endmethod

    method Action hostToCpu(Bit#(32) startpc) if ( !csrf.started && memReady );
        csrf.start(0); // only 1 core, id = 0
        $display("Start at pc 200\n");
        $fflush(stdout);
        pc[1] <= startpc;
    endmethod

    interface memInit = memory.init;

    interface DDR3_Client ddr3client;
        interface request = toGet(ddrReqQ);
        interface response = toPut(ddrRespQ);
    endinterface

endmodule

