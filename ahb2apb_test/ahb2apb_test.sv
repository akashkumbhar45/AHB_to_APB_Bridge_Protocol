class ahb2apb_test extends uvm_test;

        //Register the test class with the UVM factory
	`uvm_component_utils(ahb2apb_test)

        // Environment and config object declarations
	ahb2apb_env env;
        ahb2apb_env_config e_cfg;

        // Arrays for agent-specific configurations
	ahb_agent_config ahb_cfg[];
	apb_agent_config apb_cfg[];

       	bit has_ahb_agent = 1; //Flags (has_ahb_agent and has_apb_agent) determine whether to create AHB/APB agents
	bit has_apb_agent = 1;
	int no_of_ahb_agent = 1; //how many agents of each type exist
	int no_of_apb_agent = 1;
	
        // Function declarations (defined outside the class)
	extern function new(string name = "ahb2apb_test", uvm_component parent);
        extern function void build_phase(uvm_phase phase);
        extern function void end_of_elaboration_phase(uvm_phase phase);
endclass

//constructor
function ahb2apb_test::new(string name = "ahb2apb_test", uvm_component parent);
	super.new(name, parent);
endfunction


//build phase
function void ahb2apb_test::build_phase(uvm_phase phase);
	super.build_phase(phase);

  // Create environment config
  e_cfg = ahb2apb_env_config::type_id::create("e_cfg");

  //---------------------AHB agent configuration---------------------
  if (has_ahb_agent) begin
    // Allocate memory for each AHB agent config object
    ahb_cfg = new[no_of_ahb_agent];
    e_cfg.ahb_agt_cfg = new[no_of_ahb_agent];
 
     // Create and configure each AHB agent
    foreach (ahb_cfg[i]) begin
      ahb_cfg[i] = ahb_agent_config::type_id::create($sformatf("ahb_cfg[%0d]", i));
      
      // Get AHB virtual interface from config DB
      if (!uvm_config_db #(virtual ahb2apb_if)::get(this, "", "vif_ahb", ahb_cfg[i].vif))
        `uvm_fatal("VIF CONFIG AHB", "Cannot get AHB interface from config DB")
      ahb_cfg[i].is_active = UVM_ACTIVE;

      // Pass the config to the environment
      e_cfg.ahb_agt_cfg[i] = ahb_cfg[i];
    end
  end

  // --------------------APB agent configuration-------------------
  if (has_apb_agent) begin
    apb_cfg = new[no_of_apb_agent];
    e_cfg.apb_agt_cfg = new[no_of_apb_agent];
    foreach (apb_cfg[i]) begin
      apb_cfg[i] = apb_agent_config::type_id::create($sformatf("apb_cfg[%0d]", i));
      if (!uvm_config_db #(virtual ahb2apb_if)::get(this, "", "vif_apb", apb_cfg[i].vif))
        `uvm_fatal("VIF CONFIG APB", "Cannot get APB interface from config DB")
      apb_cfg[i].is_active = UVM_ACTIVE;
      e_cfg.apb_agt_cfg[i] = apb_cfg[i];
    end
  end

  // Fill out environment-wide configuration
  e_cfg.has_ahb_agent = has_ahb_agent;
  e_cfg.has_apb_agent = has_apb_agent;
  e_cfg.no_of_ahb_agent = no_of_ahb_agent;
  e_cfg.no_of_apb_agent = no_of_apb_agent;

  // Put config object into config DB
  uvm_config_db #(ahb2apb_env_config)::set(this, "*", "ahb2apb_env_config", e_cfg);

  // Create the environment component using the factory
  env = ahb2apb_env::type_id::create("env", this);
endfunction

// End-of-elaboration phase: Print the testbench hierarchy for debugging
function void ahb2apb_test::end_of_elaboration_phase(uvm_phase phase);
	super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
endfunction

//==============================================================================
// Derived Test Class: ahb_single_test
//==============================================================================
class ahb_single_test extends ahb2apb_test;

    `uvm_component_utils(ahb_single_test)

    // Sequence instance for single transfer
    ahb_single_seq sseq;

    // Constructor
    function new(string name = "ahb_single_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase - call base class build
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    // Run phase - start the single transfer sequence
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        // Create and start the sequence
        sseq = ahb_single_seq::type_id::create("sseq");
        sseq.start(env.ahb_agt_top.agnth[0].m_sequencer); // start sequence on AHB master agent[0] sequencer
        
        #100;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Derived Test Class: ahb_incr_test
// Description: Performs an incrementing address burst transfer test on AHB.
//==============================================================================

class ahb_incr_test extends ahb2apb_test;

    `uvm_component_utils(ahb_incr_test)
    
    // Sequence instance for incrementing transfers
    ahb_incr_seq iseq;
  
    // Constructor  
    function new(string name="ahb_incr_test",uvm_component parent);
        super.new(name,parent);
    endfunction
    
    // Build phase simply calls parent
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    // Run phase: starts the incrementing sequence
    task run_phase(uvm_phase phase);
        iseq=ahb_incr_seq::type_id::create("iseq");
        phase.raise_objection(this);
        iseq.start(env.ahb_agt_top.agnth[0].m_sequencer);// start sequence on sequencer
        #100;
        phase.drop_objection(this);
    endtask

endclass


//==============================================================================
// Derived Test Class: ahb_wrap_test
// Description: Performs a wrap burst transfer test on AHB.
//==============================================================================
class ahb_wrap_test extends ahb2apb_test;

    `uvm_component_utils(ahb_wrap_test)
    
    // Sequence instance for wrap transfers
    ahb_wrap_seq wseq;
    
    // Constructor
    function new(string name="ahb_wrap_test",uvm_component parent);
        super.new(name,parent);
    endfunction
    
    // Build phase simply calls parent
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    

    // Run phase: starts the wrap sequence 
    task run_phase(uvm_phase phase);
        wseq=ahb_wrap_seq::type_id::create("wseq");
        phase.raise_objection(this);
        wseq.start(env.ahb_agt_top.agnth[0].m_sequencer);  // start sequence on sequencer
        #100;
        phase.drop_objection(this);
    endtask

endclass