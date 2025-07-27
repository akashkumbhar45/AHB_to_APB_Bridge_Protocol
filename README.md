Project Overview
This project focuses on the functional verification of the AHB to APB bridge protocol, a commonly used bridge in AMBA-based SoC architectures. The purpose of this verification environment is to ensure the correctness, reliability, and completeness of the protocol conversion logic between the Advanced High-performance Bus (AHB) and the Advanced Peripheral Bus (APB).

Objectives
Verify correct data transfer and protocol handshaking between AHB and APB domains.
Validate support for read and write transactions, burst handling, and response mechanisms.
Check protocol timing, interface assertions, and edge conditions.
Ensure the design under test (DUT) adheres to AMBA protocol standards.

 Project Components
 Design Under Test (DUT): AHB to APB bridge
 Testbench: SystemVerilog testbench with modular structure
 Driver: Generates AHB read/write transactions
 Monitor: Observes and checks AHB/APB side signals
 Scoreboard: Compares expected vs actual results
 Assertions (SVA): Protocol compliance checks
 Functional Coverage: Ensures full transaction space is exercised

🛠️ Tools & Technologies
Language: SystemVerilog
Methodology: UVM (Universal Verification Methodology)
Assertions: SystemVerilog Assertions (SVA)
Simulator: Compatible with ModelSim, VCS, or Questa

