class ahb_xtn extends uvm_sequence_item;
	
	`uvm_object_utils(ahb_xtn)
	
        // Randomizable AHB Fields (Driven by Master)
	rand bit [31:0] Haddr;   // AHB address bus
	rand bit [31:0] Hwdata;  // Write data from master
	rand bit [9:0]  length;  // Length of burst in beats
	rand bit        Hwrite;  // Direction: 1 = Write, 0 = Read
	rand bit [1:0]  Htrans;
	rand bit [2:0]  Hsize;
	rand bit [2:0]  Hburst;

        // Non-Random Fields (Observed from Slave)
	bit [31:0]      Hrdata;    // Read data from slave
	bit             Hresetn;   // Reset signal
	bit             Hreadyout; // Ready from slave (to master)
	bit             Hreadyin;  // Ready from master (to slave)
	bit [1:0]       Hresp;     // Response from slave: OKAY, ERROR, etc.

	
        // Constraints for Valid Transactions
        // Only allow valid Hsize values: 0, 1, 2 (i.e., 1, 2, 4 bytes), apb can't take more than 4 byte
	constraint valid_Hsize {Hsize inside {[0:2]};}  
 

        // Address alignment constraints:
        // If Hsize is 1 (2-byte), address must be even.
        // If Hsize is 2 (4-byte), address must be 4-byte aligned.
        constraint aligned_Haddr {Hsize == 1 -> Haddr%2 == 0; Hsize == 2 -> Haddr%4 == 0;}

        // Valid address ranges for slaves (4 valid windows of 1KB each), if use differnt addr slave not exist transfer not going to happen
	constraint valid_Haddr {Haddr inside {[32'h8000_0000 : 32'h8000_03ff], //slave0
                                              [32'h8400_0000 : 32'h8400_03ff], //slave1
                                              [32'h8800_0000 : 32'h8800_03ff], //slave2
                                              [32'h8C00_0000 : 32'h8C00_03ff]  //slave3
                                };}
	
         
        // Constraint to match legal burst types with their expected length
        constraint length_Hburst {
            (Hburst == 0) -> (length == 1);    //SINGLE TRANSFER
            (Hburst == 2) -> (length == 4);    //WRAP4
            (Hburst == 3) -> (length == 4);    // INCR4
            (Hburst == 4) -> (length == 8);   // WRAP8
            (Hburst == 5) -> (length == 8);    // INCR8
            (Hburst == 6) -> (length == 16);    // WRAP16
            (Hburst == 7) -> (length == 16);   // INCR16
        }

        // Make sure total burst doesn't exceed 1KB (1024 bytes)
	constraint bound_Haddr {(Haddr % 1024) + ((2**Hsize) * length) <= 1023;} 

	extern function new(string name = "ahb_xtn");
	extern function void do_print(uvm_printer printer);
endclass
	
function ahb_xtn::new(string name = "ahb_xtn");
	super.new(name);
endfunction

function void ahb_xtn::do_print(uvm_printer printer);
	super.do_print(printer);
        printer.print_field("Hresetn",  this.Hresetn,  1,  UVM_DEC);
        printer.print_field("Hwrite", this.Hwrite, 1, UVM_DEC);
        printer.print_field("Htrans", this.Htrans, 2, UVM_DEC);
        printer.print_field("Hburst", this.Hburst, 3, UVM_HEX);
	printer.print_field("Hsize", this.Hsize, 3, UVM_DEC);
	printer.print_field("Haddr", this.Haddr, 32, UVM_HEX);
        printer.print_field("Hwdata", this.Hwdata, 32, UVM_HEX);
	printer.print_field("Hrdata", this.Hrdata, 32, UVM_HEX);
        printer.print_field("Hreadyin",  this.Hreadyin,  1,  UVM_DEC);
        printer.print_field("Hreadyout",  this.Hreadyout,  1,  UVM_DEC);
        printer.print_field("length", this.length, 10, UVM_HEX);
endfunction