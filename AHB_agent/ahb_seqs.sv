// Base Sequence class for AHB transactions
class ahb_seq extends uvm_sequence #(ahb_xtn);

    // Registering with factory
    `uvm_object_utils(ahb_seq)

    // Constructor
    extern function new(string name = "ahb_seq");

endclass

// Constructor definition
function ahb_seq::new(string name = "ahb_seq");
    super.new(name);
endfunction

// AHB SINGLE burst transaction (single beat)
class ahb_single_seq extends ahb_seq;

    `uvm_object_utils(ahb_single_seq)

    // Constructor
    function new(string name = "ahb_single_seq");
        super.new(name);
    endfunction

    // Body task - sends one NONSEQ transfer with SINGLE burst
    task body();
        // Create and randomize one transaction
        req = ahb_xtn::type_id::create("req");
        start_item(req);

        assert(req.randomize() with {
            Htrans == 2'b10;      // NONSEQ - first and only transfer
            Hburst == 3'b000;     // SINGLE burst
            Hwrite == 1;          // Write transfer
        });

        finish_item(req);
    endtask

endclass


// AHB INCR burst transaction sequence (multiple beats)
class ahb_incr_seq extends ahb_seq;

    `uvm_object_utils(ahb_incr_seq)

    // Local variables for tracking state
    bit [31:0] haddr;  // current address
    bit hwrite;        // direction
    bit [2:0] hsize;   // transfer size
    bit [2:0] hburst;  // burst type
    bit [9:0] length;  // number of transfers

    function new(string name = "ahb_incr_seq");
        super.new(name);
    endfunction

    task body();
        // First transfer: NONSEQ
        req = ahb_xtn::type_id::create("req");
        start_item(req);

        assert(req.randomize() with {
            Htrans == 2'b10;                 // NONSEQ (start of burst)
            Hburst inside {1,3,5,7};         // INCR types (wraps excluded)
            Hwrite == 1;                     // Write
        });

        finish_item(req);

        // Save initial fields for later use
        haddr  = req.Haddr;
        hwrite = req.Hwrite;
        hsize  = req.Hsize;
        hburst = req.Hburst;
        length = req.length;

        // Remaining transfers: SEQ with address increment
        for (int i = 1; i < length; i++) begin
            start_item(req);
            assert(req.randomize() with {
                Htrans == 2'b11;                     // SEQ
                Hsize  == hsize;
                Hwrite == hwrite;
                Hburst == hburst;
                Haddr  == (haddr + (2**hsize));      // Proper address increment
            });
            finish_item(req);
            haddr = req.Haddr;                       // Update address for next transfer
        end
    endtask

endclass

// AHB WRAP burst transaction sequence (wrap-around after boundary)
class ahb_wrap_seq extends ahb_seq;

    `uvm_object_utils(ahb_wrap_seq)

    // Address and transfer control variables
    bit [31:0] start_addr, bound_addr;
    bit [31:0] haddr;
    bit hwrite;
    bit [2:0] hsize;
    bit [2:0] hburst;
    bit [9:0] length;

    function new(string name = "ahb_wrap_seq");
        super.new(name);
    endfunction

    task body();

        // First transfer: NONSEQ
        req = ahb_xtn::type_id::create("req");
        start_item(req);

        assert(req.randomize() with {
            Htrans == 2'b10;                                 // NONSEQ
            Hburst inside {3'b010, 3'b100, 3'b110};          // WRAP4, WRAP8, WRAP16
        });

        finish_item(req);

        // Capture transaction parameters
        haddr  = req.Haddr;
        hwrite = req.Hwrite;
        hsize  = req.Hsize;
        hburst = req.Hburst;
        length = req.length;

        // Calculate wrap boundaries
        start_addr = int'((haddr / ((2**hsize) * length))) * ((2**hsize) * length);
        bound_addr = start_addr + ((2**hsize) * length);
        haddr = req.Haddr + (2**hsize);  // move to next beat

        // Generate SEQ transfers with wrap-around handling
        for (int i = 1; i < length; i++) begin
            if (haddr == bound_addr)
                haddr = start_addr;  // wrap-around back to base address

            start_item(req);
            assert(req.randomize() with {
                Htrans == 2'b11;        // SEQ
                Hsize  == hsize;
                Hwrite == hwrite;
                Hburst == hburst;
                Haddr  == haddr;
            });
            finish_item(req);

            haddr = req.Haddr + (2**hsize);  // advance address
        end

    endtask

endclass
