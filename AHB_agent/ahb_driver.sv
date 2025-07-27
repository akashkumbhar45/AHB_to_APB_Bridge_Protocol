class ahb_driver extends uvm_driver #(ahb_xtn);

	`uvm_component_utils(ahb_driver)

	virtual ahb2apb_if.ahb_drv_mp vif;

	ahb_agent_config m_cfg;

	extern function new(string name = "ahb_driver", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task send_to_dut(ahb_xtn xtn);

endclass

//constructor
function ahb_driver::new(string name = "ahb_driver", uvm_component parent);
	super.new(name, parent);
endfunction

//build phase
function void ahb_driver::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(ahb_agent_config)::get(this, "", "ahb_agent_config", m_cfg))
		`uvm_fatal("CONFIG", "cannot get() method")
endfunction

//connect phase
function void ahb_driver::connect_phase(uvm_phase phase);
	vif = m_cfg.vif;
endfunction

//run phase
task ahb_driver::run_phase(uvm_phase phase);
	@(vif.ahb_drv_cb);
	vif.ahb_drv_cb.Hresetn <= 0;
	@(vif.ahb_drv_cb);
	vif.ahb_drv_cb.Hresetn <= 1;
	forever
		begin
			seq_item_port.get_next_item(req);
			send_to_dut(req);
			seq_item_port.item_done();
		end
endtask

//send to dut logic
task ahb_driver::send_to_dut(ahb_xtn xtn);
	`uvm_info("AHB_DRIVER", $sformatf("printing from driver \n %s",xtn.sprint()), UVM_LOW)
        wait(vif.ahb_drv_cb.Hreadyout===1)  // Waits until slave is ready to accept new transfer.

        // Drives key signals to the DUT from the transaction object.
	vif.ahb_drv_cb.Hsize <= xtn.Hsize;
        vif.ahb_drv_cb.Hburst <= xtn.Hburst;
	vif.ahb_drv_cb.Hwrite <= xtn.Hwrite;
	vif.ahb_drv_cb.Htrans <= xtn.Htrans;
	vif.ahb_drv_cb.Haddr <= xtn.Haddr;
	vif.ahb_drv_cb.Hreadyin <= 1;

        // Waits for one clock and ensures slave is still ready before writing data.
	@(vif.ahb_drv_cb);
	wait(vif.ahb_drv_cb.Hreadyout===1)

        // Only write data (Hwdata) when Hwrite is asserted.
	if(xtn.Hwrite)
		vif.ahb_drv_cb.Hwdata <= xtn.Hwdata;
	else
		vif.ahb_drv_cb.Hwdata <= 32'd0;

	//repeat(2)
	 @(vif.ahb_drv_cb);
        xtn.print();
	m_cfg.drv_data_count++;
	`uvm_info(get_type_name(), $sformatf("Report : AHB driver sent %d transactions", m_cfg.drv_data_count), UVM_LOW)
endtask
