class ahb_monitor extends uvm_monitor;

	`uvm_component_utils(ahb_monitor)

	virtual ahb2apb_if.ahb_mon_mp vif;

	ahb_agent_config m_cfg;
       	uvm_analysis_port #(ahb_xtn) monitor_port;
	

	extern function new(string name = "ahb_monitor", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task collect_data();
	
endclass

//constructor
function ahb_monitor::new(string name = "ahb_monitor", uvm_component parent);
	super.new(name, parent);
        monitor_port = new("monitor_port", this);

endfunction

//build phase
function void ahb_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(ahb_agent_config)::get(this, "", "ahb_agent_config", m_cfg)) 
		`uvm_fatal("CONFIG", "cannot get m_cfg")
endfunction

//connect phase
function void ahb_monitor::connect_phase(uvm_phase phase);
	vif = m_cfg.vif;
endfunction

//run phase
task ahb_monitor::run_phase(uvm_phase phase);
	forever
		begin
		collect_data();
		end
endtask

//collect data
task ahb_monitor::collect_data();
	ahb_xtn mon_data;
	begin
		mon_data = ahb_xtn::type_id::create("mon_data");
                
                //Waits for a valid transaction (IDEAL or NONSEQ or SEQ) when the slave is ready (Hreadyout == 1).
		wait(vif.ahb_mon_cb.Hreadyout===1)
		 wait(vif.ahb_mon_cb.Htrans === 2'b10 || vif.ahb_mon_cb.Htrans === 2'b11)

                //Captures the command phase signals
		mon_data.Haddr = vif.ahb_mon_cb.Haddr;
		mon_data.Htrans = vif.ahb_mon_cb.Htrans;
                mon_data.Hburst = vif.ahb_mon_cb.Hburst;
		mon_data.Hwrite = vif.ahb_mon_cb.Hwrite;
		mon_data.Hsize = vif.ahb_mon_cb.Hsize;

                //Wait one clock after capturing control signals, then wait for Hreadyout again before collecting data.
		@(vif.ahb_mon_cb);
		wait(vif.ahb_mon_cb.Hreadyout===1)
		if(vif.ahb_mon_cb.Hwrite)
			mon_data.Hwdata = vif.ahb_mon_cb.Hwdata;
		else
			mon_data.Hrdata = vif.ahb_mon_cb.Hrdata;
		m_cfg.mon_data_count++;
		`uvm_info("ROUTER_WR_MONITOR", $sformatf("printing from monitor \n %s", mon_data.sprint()), UVM_LOW)
		monitor_port.write(mon_data);
	end
endtask

