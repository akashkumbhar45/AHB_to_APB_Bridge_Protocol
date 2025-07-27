# Makefile for UVM Testbench - AHB to APB Bridge

# SIMULATOR OPTIONS
# SIMULATOR = Questa for Mentor's Questasim
# SIMULATOR = VCS for Synopsys's VCS
SIMULATOR =   Questa

# Paths
FSDB_PATH=/home/cad/eda/SYNOPSYS/VERDI_2022/verdi/T-2022.06-SP1/share/PLI/VCS/LINUX64

# File paths and compile options
RTL = ../bridge_rtl/*
SVTB1 = ../tb/top.sv
SVTB2 = ../ahb2apb_test/ahb2apb_pkg.sv
INC = +incdir+../tb +incdir+../ahb2apb_test +incdir+../AHB_agent +incdir+../APB_agent
work = work

# Questa-specific
VSIMOPT = -vopt -voptargs=+acc
VSIMCOV = -coverage -sva
VSIMBATCH1 = -c -do "log -r /* ; coverage save -onexit mem_cov1; run -all; exit"
VSIMBATCH2 = -c -do "log -r /* ; coverage save -onexit mem_cov2; run -all; exit"
VSIMBATCH3 = -c -do "log -r /* ; coverage save -onexit mem_cov3; run -all; exit"

# Help menu
help:
	@echo =============================================================================================================
	@echo "! USAGE        --  make <target>                                                                         !"
	@echo "! clean        =>  Clean earlier log and intermediate files.                                             !"
	@echo "! sv_cmp       =>  Compile the code.                                                                     !"
	@echo "! run_test     =>  Run simulation for ahb_single_test (basic transfer).                                  !"
	@echo "! run_test1    =>  Run simulation for ahb_incr_test (incrementing burst).                                !"
	@echo "! run_test2    =>  Run simulation for ahb_wrap_test (wrapping burst).                                    !"
	@echo "! view_wave1   =>  View waveform for ahb_single_test.                                                    !"
	@echo "! view_wave2   =>  View waveform for ahb_incr_test.                                                      !"
	@echo "! view_wave3   =>  View waveform for ahb_wrap_test.                                                      !"
	@echo "! regress      =>  Run all tests and generate merged coverage report.                                    !"
	@echo "! report       =>  Merge all coverage databases and generate HTML report.                                !"
	@echo "! cov          =>  Open the merged coverage HTML report.                                                 !"
	@echo =============================================================================================================

# Unified targets
clean       : clean_$(SIMULATOR)
sv_cmp      : sv_cmp_$(SIMULATOR)
run_test    : run_test_$(SIMULATOR)
run_test1   : run_test1_$(SIMULATOR)
run_test2   : run_test2_$(SIMULATOR)
view_wave1  : view_wave1_$(SIMULATOR)
view_wave2  : view_wave2_$(SIMULATOR)
view_wave3  : view_wave3_$(SIMULATOR)
regress     : regress_$(SIMULATOR)
report      : report_$(SIMULATOR)
cov         : cov_$(SIMULATOR)

# ========================= Questa =========================
sv_cmp_Questa:
	vlib $(work)
	vmap work $(work)
	vlog -work $(work) $(RTL) $(INC) $(SVTB2) $(SVTB1)

run_test_Questa: sv_cmp
	vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH1) -wlf wave_file1.wlf -l test1.log -sv_seed random work.top +UVM_TESTNAME=ahb_single_test
	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov1

run_test1_Questa: sv_cmp
	vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH2) -wlf wave_file2.wlf -l test2.log -sv_seed random work.top +UVM_TESTNAME=ahb_incr_test
	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov2

run_test2_Questa:
	vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH3) -wlf wave_file3.wlf -l test3.log -sv_seed random work.top +UVM_TESTNAME=ahb_wrap_test
	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov3

view_wave1_Questa:
	vsim -view wave_file1.wlf

view_wave2_Questa:
	vsim -view wave_file2.wlf

view_wave3_Questa:
	vsim -view wave_file3.wlf

report_Questa:
	vcover merge mem_cov mem_cov1 mem_cov2 mem_cov3
	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov

regress_Questa: clean_Questa run_test_Questa run_test1_Questa run_test2_Questa report_Questa

cov_Questa:
	firefox covhtmlreport/index.html&

clean_Questa:
	rm -rf transcript* *log* fcover* covhtml* mem_cov* *.wlf modelsim.ini work
	clear

# ========================= VCS =========================
sv_cmp_VCS:
	vcs -l vcs.log -timescale=1ns/1ps -sverilog -ntb_opts uvm -debug_access+all -full64 -kdb -lca \
		-P $(FSDB_PATH)/novas.tab $(FSDB_PATH)/pli.a \
		$(RTL) $(INC) $(SVTB2) $(SVTB1)

run_test_VCS: clean sv_cmp_VCS
	./simv -a vcs.log +fsdbfile+wave1.fsdb -cm_dir ./mem_cov1 +ntb_random_seed_automatic +UVM_TESTNAME=ahb_single_test
	urg -dir mem_cov1.vdb -format both -report urgReport1

run_test1_VCS:
	./simv -a vcs.log +fsdbfile+wave2.fsdb -cm_dir ./mem_cov2 +ntb_random_seed_automatic +UVM_TESTNAME=ahb_incr_test
	urg -dir mem_cov2.vdb -format both -report urgReport2

run_test2_VCS:
	./simv -a vcs.log +fsdbfile+wave3.fsdb -cm_dir ./mem_cov3 +ntb_random_seed_automatic +UVM_TESTNAME=ahb_wrap_test
	urg -dir mem_cov3.vdb -format both -report urgReport3

view_wave1_VCS:
	verdi -ssf wave1.fsdb

view_wave2_VCS:
	verdi -ssf wave2.fsdb

view_wave3_VCS:
	verdi -ssf wave3.fsdb

report_VCS:
	urg -dir mem_cov1.vdb mem_cov2.vdb mem_cov3.vdb -dbname merged_dir/merged_test -format both -report urgReport

regress_VCS: clean_VCS sv_cmp_VCS run_test_VCS run_test1_VCS run_test2_VCS report_VCS

cov_VCS:
	verdi -cov -covdir merged_dir.vdb

clean_VCS:
	rm -rf simv* csrc* *.tmp *.vpd *.vdb *.key *.log *hdrs.h urgReport* *.fsdb novas* verdi* merged_dir*
	clear
