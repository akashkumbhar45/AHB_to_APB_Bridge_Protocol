// Scoreboard class for verifying AHB to APB bridge data transactions
class ahb2apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(ahb2apb_scoreboard)

    // Analysis FIFOs to collect transactions from monitors
    uvm_tlm_analysis_fifo #(ahb_xtn) fifo_ahb[];  // AHB side transactions
    uvm_tlm_analysis_fifo #(apb_xtn) fifo_apb[];  // APB side transactions

    // Temporary handles to fetched transactions
    ahb_xtn ahb_data;
    apb_xtn apb_data;

    // Environment config handle
    ahb2apb_env_config e_cfg;

    // Count of successful data comparisons
    int data_verified_count;

    // Constructor
    extern function new(string name = "ahb2apb_scoreboard", uvm_component parent);

    // UVM Phases
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);

    // Data checking/comparison methods
    extern function void check_data(ahb_xtn ahb_data, apb_xtn apb_data);
    extern function void compare_data(int Hdata, Pdata, Haddr, Paddr);

 // ------------------ Coverage Groups ------------------
covergroup ahb_fcov;
                option.per_instance = 1;
                SIZE: coverpoint ahb_data.Hsize {bins b2[] = {[0:2]} ;}
                TRANS: coverpoint ahb_data.Htrans {bins trans[] = {[0:3]} ;}
                ADDR: coverpoint ahb_data.Haddr {bins first_slave = {[32'h8000_0000:32'h8000_03ff]} ;
                                                     bins second_slave = {[32'h8400_0000:32'h8400_03ff]};
                                                     bins third_slave = {[32'h8800_0000:32'h8800_03ff]};
                                                     bins fourth_slave = {[32'h8C00_0000:32'h8C00_03ff]};}
                WRITE : coverpoint ahb_data.Hwrite{bins read = {0};
                                                   bins write = {1};}
                SIZEXWRITE: cross SIZE, TRANS, ADDR, WRITE;
        	
	endgroup

//	covergroup 
covergroup apb_fcov;
                option.per_instance = 1;
                ADDR : coverpoint apb_data.Paddr {bins first_slave = {[32'h8000_0000:32'h8000_03ff]};
                                                      bins second_slave = {[32'h8400_0000:32'h8400_03ff]};
                                                      bins third_slave = {[32'h8800_0000:32'h8800_03ff]};
                                                      bins fourth_slave = {[32'h8C00_0000:32'h8C00_03ff]};}


                WRITE : coverpoint apb_data.Pwrite{
                                                  bins read = {0};
                                                  bins write = {1};}

                SEL : coverpoint apb_data.Pselx {bins first_slave = {4'b0001};
                                                     bins second_slave = {4'b0010};
                                                     bins third_slave = {4'b0100};
                                                     bins fourth_slave = {4'b1000};}

                WRITEXSEL: cross ADDR, WRITE, SEL;
        endgroup




endclass

//constructor
function ahb2apb_scoreboard::new(string name = "ahb2apb_scoreboard", uvm_component parent);
	super.new(name, parent);
	ahb_fcov = new();
	apb_fcov = new();
endfunction

//build phase: Initialize FIFOs based on number of agents
function void ahb2apb_scoreboard::build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(ahb2apb_env_config)::get(this, "", "ahb2apb_env_config", e_cfg))
		`uvm_fatal("EN_cfg", "no update")
        
        //allocate a size
	fifo_ahb = new[e_cfg.no_of_ahb_agent];

        //create a memory
	foreach(fifo_ahb[i])
		begin
			fifo_ahb[i] = new($sformatf("fifo_ahb[%0d]", i), this);
		end
	fifo_apb = new[e_cfg.no_of_apb_agent];
	foreach(fifo_apb[i])
		begin
			fifo_apb[i] = new($sformatf("fifo_apb[%0d]", i), this);
		end
endfunction

//run phase: Fetch and compare transactions in parallel
task ahb2apb_scoreboard::run_phase(uvm_phase phase);
	fork
		begin
                        // Collect and sample AHB transactions
			forever
				begin
					fifo_ahb[0].get(ahb_data);
					`uvm_info("WRITE SB", "DATA FROM MASTER SCOREBOARD", UVM_LOW)
                                        ahb_data.print();
					ahb_fcov.sample();
				end
		end
                   // Collect, sample and compare APB transactions
		begin
			forever
				begin
					fork
						begin
							fifo_apb[0].get(apb_data);
							`uvm_info("DATA FROM SLAVE SCORBOARD", "read data", UVM_LOW)
							apb_data.print();
							check_data(ahb_data, apb_data);
							apb_fcov.sample();
						end
					join
				end
		end
	join
endtask

//check data consistency between AHB and APB
function void ahb2apb_scoreboard::check_data(ahb_xtn ahb_data, apb_xtn apb_data);
$display("i am in scorrboard");
	if(ahb_data.Hwrite)  // Write verification
		begin
			case(ahb_data.Hsize)
				2'b00 : begin
						if(ahb_data.Haddr[1:0] == 2'b00)
							compare_data(ahb_data.Hwdata[7:0], apb_data.Pwdata[7:0], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b01)
							compare_data(ahb_data.Hwdata[15:8], apb_data.Pwdata[7:0], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b10)
							compare_data(ahb_data.Hwdata[23:16], apb_data.Pwdata[7:0], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b11)
							compare_data(ahb_data.Hwdata[31:24], apb_data.Pwdata[7:0], ahb_data.Haddr, apb_data.Paddr);
					end
				2'b01 : begin
						if(ahb_data.Haddr[1:0] == 2'b00)
							compare_data(ahb_data.Hwdata[15:0], apb_data.Pwdata[15:0], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b10)
							compare_data(ahb_data.Hwdata[31:16], apb_data.Pwdata[15:0], ahb_data.Haddr, apb_data.Paddr);
					end
				2'b10 : begin
						compare_data(ahb_data.Hwdata, apb_data.Pwdata, ahb_data.Haddr, apb_data.Paddr);
					end
			endcase
		end
	else
		begin
			case(ahb_data.Hsize)  // Read verification
				2'b00 : begin
						if(ahb_data.Haddr[1:0] == 2'b00)
							compare_data(ahb_data.Hrdata[7:0], apb_data.Prdata[7:0], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b01)
							compare_data(ahb_data.Hrdata[7:0], apb_data.Prdata[15:8], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b10)
							compare_data(ahb_data.Hrdata[7:0], apb_data.Prdata[23:16], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b11)
							compare_data(ahb_data.Hrdata[7:0], apb_data.Prdata[31:24], ahb_data.Haddr, apb_data.Paddr);
					end
				2'b01 : begin
						if(ahb_data.Haddr[1:0] == 2'b00)
							compare_data(ahb_data.Hrdata[15:0], apb_data.Prdata[15:0], ahb_data.Haddr, apb_data.Paddr);
						if(ahb_data.Haddr[1:0] == 2'b10)
							compare_data(ahb_data.Hrdata[15:0], apb_data.Prdata[31:16], ahb_data.Haddr, apb_data.Paddr);
					end
				2'b10 : begin
						compare_data(ahb_data.Hrdata, apb_data.Prdata, ahb_data.Haddr, apb_data.Paddr);
					end
			endcase

		end
endfunction

//-------------------------------------------------------comparing data-------------------------------------------------//
function void ahb2apb_scoreboard::compare_data(int Hdata, Pdata, Haddr, Paddr);
        if(Haddr == Paddr)
		`uvm_info("SB", "ADDR MATCHED SUCCESSFULLY", UVM_LOW)
	else
		`uvm_error("SB", "ADDR MATCHING FAILED")
        
        if(ahb_data.Hwrite)
        begin
	        if(Hdata == Pdata)
		`uvm_info("SB", "WRITE DATA MATCHED SUCCESSFULLY", UVM_LOW)
	         else
		`uvm_error("SB", "WRITE DATA MATCHING FAILED")
	end

        else
        begin
	        if(Hdata == Pdata)
		`uvm_info("SB", "READ DATA MATCHED SUCCESSFULLY", UVM_LOW)
	         else
		`uvm_error("SB", "READ DATA MATCHING FAILED")
	end
	data_verified_count++;
endfunction

//report phase
function void ahb2apb_scoreboard::report_phase(uvm_phase phase);
	`uvm_info(get_type_name(), $sformatf("Report : Number of data verified in SB %0d", data_verified_count), UVM_LOW)
endfunction