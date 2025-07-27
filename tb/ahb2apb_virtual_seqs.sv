
class ahb2apb_vbase_seq extends uvm_sequence #(uvm_sequence_item);

	`uvm_object_utils(ahb2apb_vbase_seq)

	extern function new(string name = "ahb2apb_vbase_seq");
	

endclass

//constructor 
function ahb2apb_vbase_seq::new(string name = "ahb2apb_vbase_seq");
	super.new(name);
endfunction

