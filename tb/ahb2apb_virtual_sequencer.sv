class ahb2apb_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);

	`uvm_component_utils(ahb2apb_virtual_sequencer)

	extern function new(string name = "ahb2apb_virtual_sequencer", uvm_component parent);
	extern function void build_phase(uvm_phase phase);

endclass

//constructor
function ahb2apb_virtual_sequencer::new(string name = "ahb2apb_virtual_sequencer",uvm_component parent);
	super.new(name, parent);
endfunction

//build phase
function void ahb2apb_virtual_sequencer::build_phase(uvm_phase phase);
	super.build_phase(phase); 
endfunction