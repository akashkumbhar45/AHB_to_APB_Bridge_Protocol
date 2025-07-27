//------------------------------------------------------------------------------
// Class: apb_monitor
// Description: Passive UVM component that observes APB protocol activity on the
//              bus and sends observed transactions to the analysis port.
//------------------------------------------------------------------------------
class apb_monitor extends uvm_monitor;

        // Registers this component with the UVM factory for dynamic creation
	`uvm_component_utils(apb_monitor)

        // Virtual interface handle to access APB signals (monitor modport)
	virtual ahb2apb_if.apb_mon_cb vif;

        // Handle to agent-level configuration object, includes interface & counters
	apb_agent_config m_cfg;

        // Analysis port to broadcast monitored transactions to scoreboard or coverage
	uvm_analysis_port #(apb_xtn) monitor_port;

        
        // Standard UVM constructor and phase declarations
	extern function new(string name = "apb_monitor", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task collect_data();
	extern function void report_phase(uvm_phase phase);


endclass

//constructor: Initializes the analysis port
function apb_monitor::new(string name = "apb_monitor", uvm_component parent);
	super.new(name, parent);
        monitor_port = new("monitor_port", this);
endfunction


//build phase: Retrieves the configuration object from the UVM config database
function void apb_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(apb_agent_config)::get(this, "", "apb_agent_config", m_cfg))
		`uvm_fatal("CONFIG", "cannot get cfg")
endfunction

//connect phase: Connects the monitor's virtual interface from config object
function void apb_monitor::connect_phase(uvm_phase phase);
	vif = m_cfg.vif;
endfunction

//run phase: Continuously calls collect_data to sample bus activity
task apb_monitor::run_phase(uvm_phase phase);
	forever
		begin
			collect_data();
		end
endtask

//collect data: Captures APB signals when a valid transaction occurs and sends them to the analysis port
task apb_monitor::collect_data();
	apb_xtn mon_data;

        // Create a new instance of the APB transaction using factory
	mon_data = apb_xtn::type_id::create("mon_data");

        // Wait for the enable phase (PENABLE = 1) indicating valid data/control
	wait(vif.apb_mon_cb.Penable == 1)

        // Sample control and address signals
	mon_data.Paddr = vif.apb_mon_cb.Paddr;
	mon_data.Pwrite = vif.apb_mon_cb.Pwrite;
	mon_data.Pselx = vif.apb_mon_cb.Pselx;

        // Sample data depending on whether it is a write or read
	if(mon_data.Pwrite == 1)
		mon_data.Pwdata = vif.apb_mon_cb.Pwdata;
	else
		mon_data.Prdata = vif.apb_mon_cb.Prdata;
	@(vif.apb_mon_cb);
	`uvm_info("ROUTER_RD_MONITOR", $sformatf("printing from monitor \n %s", mon_data.sprint()), UVM_LOW)
	m_cfg.mon_data_count++;

        // Send the transaction to any subscribers (scoreboard, coverage)
	monitor_port.write(mon_data); 
endtask

//report phase
function void apb_monitor::report_phase(uvm_phase phase);
	`uvm_info(get_type_name(), $sformatf("Report : APB monitor send %0d transactions", m_cfg.mon_data_count), UVM_LOW)
endfunction