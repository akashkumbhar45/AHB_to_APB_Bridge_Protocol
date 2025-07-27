class apb_driver extends uvm_driver #(apb_xtn);

	`uvm_component_utils(apb_driver)

	virtual ahb2apb_if.apb_drv_mp vif;
	
	apb_agent_config m_cfg;

	extern function new(string name = "apb_driver", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task send_to_dut(apb_xtn xtn);
	extern function void report_phase(uvm_phase phase);

endclass

//constructor
function apb_driver::new(string name = "apb_driver", uvm_component parent);
	super.new(name, parent);
endfunction

//report pahse
function void apb_driver::report_phase(uvm_phase phase);
	`uvm_info(get_type_name(), $sformatf("Report : APB driver send %0d transactions", m_cfg.drv_data_count), UVM_LOW)
endfunction

//build phase: fetch the configuration object from the UVM config-DB
function void apb_driver::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(apb_agent_config)::get(this, "", "apb_agent_config", m_cfg))
		`uvm_fatal("CONFIG", "cannot get m_cfg")
endfunction

//connect phase: hook up local virtual-interface handle from configuration
function void apb_driver::connect_phase(uvm_phase phase);
	vif = m_cfg.vif;
endfunction

//run phase
task apb_driver::run_phase(uvm_phase phase);
	forever
		begin
			seq_item_port.get_next_item(req);// blocking call → waits for seq item
			send_to_dut(req);                // drive the pins for this transaction
			seq_item_port.item_done();       // sequencer handshake   
		end
endtask

//send to dut
task apb_driver::send_to_dut(apb_xtn xtn);
	begin
		`uvm_info("APB_DRIVER", $sformatf("printing from driver \n %s", xtn.sprint()), UVM_LOW)
                // Wait until PSELx is asserted, meaning a slave is selected it can ny value 0001, 0010, 0100, 1000
		wait(vif.apb_drv_cb.Pselx)

		if(vif.apb_drv_cb.Pwrite == 0)
			vif.apb_drv_cb.Prdata <= {$random};
		repeat(2)  //During every 2 cycle operation is happening
                @(vif.apb_drv_cb);
		m_cfg.drv_data_count++;
	end
endtask

