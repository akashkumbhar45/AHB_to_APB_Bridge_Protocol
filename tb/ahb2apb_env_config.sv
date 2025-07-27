class ahb2apb_env_config extends uvm_object;
	

        //Register this class with the UVM factory
	`uvm_object_utils(ahb2apb_env_config)
        
        bit has_ahb_agent = 1;
	bit has_apb_agent = 1;
	bit has_virtual_sequencer = 1;
	bit has_scoreboard = 1;
	int no_of_ahb_agent = 1;
	int no_of_apb_agent = 1;
 
        // Array to store configuration objects for each AHB agent & APB agent
	ahb_agent_config ahb_agt_cfg[];
	apb_agent_config apb_agt_cfg[];

	extern function new(string name = "ahb2apb_env_config");

endclass

//constructor
function ahb2apb_env_config::new(string name = "ahb2apb_env_config");
	super.new(name);
endfunction