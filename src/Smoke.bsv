package Smoke;

import accelerator::*;
import AXI4_Types::*;

(* synthesize *)
module mkSmoke(Empty);
    Ifc_accelerator dut <- mkshaktimaan;
    Reg#(Bit#(32)) cycles <- mkReg(0);

    // Keep the accelerator's AXI inputs idle on every cycle.
    (* fire_when_enabled, no_implicit_conditions *)
    rule drive_idle_axi;
        // Fetch master: no memory responses or accepted requests.
        dut.ifc_fetch_master.m_awready(False);
        dut.ifc_fetch_master.m_wready(False);
        dut.ifc_fetch_master.m_bvalid(False, 0, 0, 0);
        dut.ifc_fetch_master.m_arready(False);
        dut.ifc_fetch_master.m_rvalid(False, 0, 0, False, 0, 0);

        // Load master.
        dut.ifc_load_master.m_awready(False);
        dut.ifc_load_master.m_wready(False);
        dut.ifc_load_master.m_bvalid(False, 0, 0, 0);
        dut.ifc_load_master.m_arready(False);
        dut.ifc_load_master.m_rvalid(False, 0, 0, False, 0, 0);

        // Store master.
        dut.ifc_store_master.m_awready(False);
        dut.ifc_store_master.m_wready(False);
        dut.ifc_store_master.m_bvalid(False, 0, 0, 0);
        dut.ifc_store_master.m_arready(False);
        dut.ifc_store_master.m_rvalid(False, 0, 0, False, 0, 0);

        // Fetch slave: host sends no requests.
        dut.ifc_fetch_slave.m_awvalid(False, 0, 0, 0, 0, 0, 0, 0);
        dut.ifc_fetch_slave.m_wvalid(False, 0, 0, False, 0);
        dut.ifc_fetch_slave.m_bready(False);
        dut.ifc_fetch_slave.m_arvalid(False, 0, 0, 0, 0, 0, 0, 0);
        dut.ifc_fetch_slave.m_rready(False);
    endrule

    rule tick;
        cycles <= cycles + 1;
        if (cycles == 20) begin
            $display("Idle smoke test completed at cycle %0d", cycles);
            $finish(0);
        end
    endrule
endmodule

endpackage
