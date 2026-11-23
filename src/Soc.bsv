package Soc;
	`define VERBOSITY 0
	import accelerator :: *;
	import bram :: *;
	import Semi_FIFOF :: *;
	import AXI4_Types :: *;
	import AXI4_Fabric::*;
	import Connectable::*;
	`include "systolic.defines"

	`define ADDR_WIDTH 32
	`define BUS_WIDTH 128
	`define ADDR_SPACE 20

	// Must match software/gen_code_mem.py (OUT_BEATS and NUM_INS come from the generated soc_test.defines)
	`define OUT_BASE 'h00830000
	`define EXP_BASE 'h00840000
	`define POLL_INTERVAL 16
	`include "soc_test.defines"

	typedef enum {WaitCfg, PollWait, PollRsp, CmpReqA, CmpRspA, CmpReqB, CmpRspB, Report} PollState deriving(Bits, Eq, FShow);

	function Bit#(TLog#(`Num_slaves)) fn_slave_map (Bit#(`ADDR_WIDTH) addr);
    Bit#(TLog#(`Num_slaves)) slave_num = 0;
    if(addr >= `MemoryBase && addr<= `MemoryEnd)begin
      slave_num = `Memory_slave;
		end
		else if(addr >= `SysBase && addr <= `SysEnd)begin
			slave_num = `Systolic_slave;
		end
		return slave_num;
	endfunction

	module mkTbSoc(Empty);
	
		Reg#(Bool) rg_start <- mkReg(True);

		Ifc_accelerator systolic <- mk_accelerator;
		AXI4_Fabric_IFC#(`Num_masters, `Num_slaves, `ADDR_WIDTH, `BUS_WIDTH, 0) fabric <- mkAXI4_Fabric(fn_slave_map);

    AXI4_Master_Xactor_IFC#(`ADDR_WIDTH, `BUS_WIDTH, 0) m_xactor <- mkAXI4_Master_Xactor;  
    Ifc_bram_axi4#(`ADDR_WIDTH, `BUS_WIDTH, 0, `ADDR_SPACE) main_memory <- mkbram_axi4(`MemoryBase, "code.mem", "MainMEM");
	
		mkConnection(m_xactor.axi_side, fabric.v_from_masters[`CPU_master]);
		mkConnection(systolic.ifc_fetch_master, fabric.v_from_masters[`Fetch_master]);
		mkConnection(systolic.ifc_load_master, fabric.v_from_masters[`Load_master]);
		mkConnection(systolic.ifc_store_master, fabric.v_from_masters[`Store_master]);

		mkConnection(fabric.v_to_slaves[`Memory_slave], main_memory.slave);
		mkConnection(fabric.v_to_slaves[`Systolic_slave], systolic.ifc_fetch_slave);

		rule rl_start(rg_start);
			rg_start <= False;
     AXI4_Wr_Addr#(`ADDR_WIDTH, 0) write_addr = AXI4_Wr_Addr {awaddr: `CONFIG_ADDR, awuser: 0, awlen: 0,
                       awsize: 4, awburst: 'b01, awid: `CPU_master, awprot: ?};
      m_xactor.i_wr_addr.enq(write_addr);
     
			Bit#(128) lv_value = (`NUM_INS << 32) | ('h00800000) ;//'h0123456789ABCDEFFEDCBA9876543210;
//			lv_value[`ADDR_WIDTH-1:0] = fromInteger(`MemoryBase);
//			lv_value[16+`ADDR_WIDTH-1:`ADDR_WIDTH] = fromInteger(3);

			AXI4_Wr_Data#(`BUS_WIDTH) write_data = AXI4_Wr_Data {wdata: lv_value, wstrb: '1, wlast: True, wid: `CPU_master};
			m_xactor.i_wr_data.enq(write_data);
		endrule
		Reg#(Bit#(32)) rg_cycle <- mkReg(0);
		rule rl_cycle;
			rg_cycle <= rg_cycle + 1;
			if(rg_cycle == 200000) begin
				$display("TIMEOUT: result never appeared (FAIL)");
				$finish(1);
			end
		endrule

		// The CPU master polls the last output beat until it differs from the sentinel, then compares OUT with EXP.
		Bit#(128) sentinel = 128'hDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
		Reg#(PollState) rg_state <- mkReg(WaitCfg);
		Reg#(Bit#(8)) rg_wait <- mkReg(0);
		Reg#(Bit#(16)) rg_idx <- mkReg(0);
		Reg#(Bit#(16)) rg_errors <- mkReg(0);
		Reg#(Bit#(128)) rg_got <- mkReg(0);
		Reg#(Bit#(32)) rg_done_cycle <- mkReg(0);

		function Action fn_read(Bit#(`ADDR_WIDTH) addr);
			action
				m_xactor.i_rd_addr.enq(AXI4_Rd_Addr {araddr: addr, aruser: 0, arlen: 0, arsize: 4,
															 arburst: 'b01, arid: `CPU_master, arprot: ?});
			endaction
		endfunction

		rule rl_drain_wr_resp;
			let r <- pop_o(m_xactor.o_wr_resp);
		endrule

		rule rl_wait_cfg(rg_state == WaitCfg && !rg_start);
			rg_wait <= `POLL_INTERVAL;
			rg_state <= PollWait;
		endrule

		rule rl_poll_wait(rg_state == PollWait);
			if(rg_wait == 0) begin
				fn_read(`OUT_BASE + 16 * (`OUT_BEATS - 1));
				rg_state <= PollRsp;
			end
			else
				rg_wait <= rg_wait - 1;
		endrule

		rule rl_poll_rsp(rg_state == PollRsp);
			let r <- pop_o(m_xactor.o_rd_data);
			if(r.rdata != sentinel) begin
				rg_done_cycle <= rg_cycle;
				rg_idx <= 0;
				rg_state <= CmpReqA;
			end
			else begin
				rg_wait <= `POLL_INTERVAL;
				rg_state <= PollWait;
			end
		endrule

		rule rl_cmp_req_a(rg_state == CmpReqA);
			fn_read(`OUT_BASE + 16 * zeroExtend(rg_idx));
			rg_state <= CmpRspA;
		endrule

		rule rl_cmp_rsp_a(rg_state == CmpRspA);
			let r <- pop_o(m_xactor.o_rd_data);
			rg_got <= r.rdata;
			rg_state <= CmpReqB;
		endrule

		rule rl_cmp_req_b(rg_state == CmpReqB);
			fn_read(`EXP_BASE + 16 * zeroExtend(rg_idx));
			rg_state <= CmpRspB;
		endrule

		rule rl_cmp_rsp_b(rg_state == CmpRspB);
			let r <- pop_o(m_xactor.o_rd_data);
			Bool bad = (r.rdata != rg_got);
			$display("CMP beat %0d got=%h exp=%h %s", rg_idx, rg_got, r.rdata, bad ? "MISMATCH" : "ok");
			if(bad) rg_errors <= rg_errors + 1;
			if(rg_idx == `OUT_BEATS - 1)
				rg_state <= Report;
			else begin
				rg_idx <= rg_idx + 1;
				rg_state <= CmpReqA;
			end
		endrule

		rule rl_report(rg_state == Report);
			$display("RESULT: %s, beats=%0d, errors=%0d, result_seen_at_cycle=%0d",
				rg_errors == 0 ? "PASS" : "FAIL", `OUT_BEATS, rg_errors, rg_done_cycle);
			$finish(rg_errors == 0 ? 0 : 1);
		endrule
	endmodule

endpackage
