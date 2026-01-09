`timescale 1us/1ns

module AHB_master_tb();
	//input signals
	reg HCLK_tb; //global clk signal
	reg HRESET_n_tb; //global active low async reset 
	
	reg d_EN_tb; // if 1 indicates a read/write xact otherwise idle xact 
	reg d_busy_tb; // indicates if driver is busy
    reg d_write_tb; // indicates if request is write or read
	reg [31:0] d_wdata_tb; // data to be written to slave 
	reg [2:0] d_burst_tb; // indicates if requested transfer is a burst and of what type
	reg [31:0] d_addr_tb; // address of the requested transfer
	reg [2:0] d_size_tb; //size of the transfer
    reg d_burst_stop_tb; //stop burst for burst of undefined length
	
	reg HREADY_tb; // indicates by slave that transfer is ready. if low indicates a request to extend the data phase
	reg HRESP_tb; // given by slave to indicate the success or failure of the transfer
	wire [31:0] HRDATA_tb; //slave data
	
	//outputs 
	wire [31:0] HADDR_tb; //address bus
	wire [2:0] HBURST_tb; // indicate burst and its type
	wire [2:0] HSIZE_tb; //indicate the size of the transfer
	wire [1:0] HTRANS_tb; //indicate to slave tranfer type
	wire [31:0] HWDATA_tb; //data written to slave
	wire HWRITE_tb; // indicate to slave if transfer is a write or read transfer
	
	//dut instantiation
	AHB_master dut(.HCLK(HCLK_tb), .HRESET_n(HRESET_n_tb), .d_EN(d_EN_tb), .d_busy(d_busy_tb), .d_write(d_write_tb), .d_wdata(d_wdata_tb),.d_burst(d_burst_tb), 
				   .d_addr(d_addr_tb), .d_size(d_size_tb), .d_burst_stop(d_burst_stop_tb), .HREADY(HREADY_tb), .HRESP(HRESP_tb),.HRDATA(HRDATA_tb), 
					.HADDR(HADDR_tb), .HBURST(HBURST_tb), .HSIZE(HSIZE_tb), .HTRANS(HTRANS_tb), .HWDATA(HWDATA_tb), .HWRITE(HWRITE_tb) );
	
	//simple register that takes read address and returns it. used to act like a memory. 
	wire [31:0] mem_out; //value read from memory
	reg mem_ready;
	mem u_mem(.CLK(HCLK_tb), .EN(HTRANS_tb[1]&&mem_ready), .read(!HWRITE_tb),.RESET_n(HRESET_n_tb),.R_addr(HADDR_tb), .R_data(mem_out));
	// burst size parameters
	parameter [2:0] BYTE = 3'd0;
	parameter [2:0] HALF_WORD = 3'd1;
	parameter [2:0] WORD = 3'd2;
	parameter [2:0] TWO_WORDS = 3'd3;
	parameter [2:0] FOUR_WORDS = 3'd4;
	parameter [2:0] EIGHT_WORDS = 3'd5;
	parameter [2:0] SIXTEEN_WORDS = 3'd6;
	parameter [2:0] THIRTY_TWO_WORDS = 3'd7;
	// burst types 
	parameter [2:0] SINGLE = 3'b000;
	parameter [2:0] INC = 3'b001;
	parameter [2:0] INC4 = 3'b011;
	parameter [2:0] INC8 = 3'b101;
	parameter [2:0] INC16 = 3'b111;
	
	//initialisation
	reg [4:0] test_no;
	reg [31:0] cycle_count;
	assign HRDATA_tb = (HREADY_tb && !HRESP_tb)?mem_out:32'b0;
	initial begin
		$dumpfile("ahb_master.vcd");
		$dumpvars;
		HRESET_n_tb = 1'b0;
		d_EN_tb = 0;
	    d_busy_tb = 0;
        d_write_tb = 0;
	    d_wdata_tb = 0;
	    d_burst_tb = 0; 
	    d_addr_tb = 0;
	    d_size_tb = 0;
        d_burst_stop_tb = 0;
		mem_ready = 1;
		
		HREADY_tb = 0;
	    HRESP_tb = 0;
		test_no = 0;
		cycle_count = 0;
	    
	end
	//clk generation
	initial begin
		HCLK_tb = 1'b0;
		forever begin
			#1 HCLK_tb = ~HCLK_tb;
			cycle_count = cycle_count + 32'd1;
			#1 HCLK_tb = ~HCLK_tb;
			
		end
	end
	//stimulus 
	
	initial begin
	#2; // give some time for system to reset

	test_inc16();
	$finish;
	
	end
	
	/////////////////// test case 1: 4 consequitive writes /////////////////////////////////////
	task test_4_conseq_writes();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd1;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_write_tb = 1'b1;
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			
			
			d_wdata_tb = 32'h1;
			d_addr_tb = 32'hffff_fff1;
			#2;
			d_wdata_tb = 32'h2;
			d_addr_tb = 32'hffff_fff2;
			#2;
			d_wdata_tb = 32'h3;
			d_addr_tb = 32'hffff_fff3;
			#2;
			d_wdata_tb = 32'h4;
			d_addr_tb = 32'hffff_fff4;
			#2;
			d_EN_tb = 0;
			#6;
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	/////////////////// test 2: 4 consequitive read ///////////////////////////////////////
	task test_4_conseq_reads();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd2;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_write_tb = 1'b0;
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			d_wdata_tb = 32'h0;
			
			d_addr_tb = 32'hffff_fff4;
			#2;
			d_addr_tb = 32'hffff_fff8;
			#2;
			d_addr_tb = 32'hffff_fffc;
			#2;
			
			d_addr_tb = 32'hffff_fff0;
			#2;
			d_EN_tb = 0;
			#6; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	////////////////// test 3: write then read ///////////////////////////////////////////////
	task test_w_r();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd3;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'hffff_fff0;
			#2;
			
			d_write_tb = 1'b0;
			d_addr_tb = 32'hffff_fffc;
			d_wdata_tb = 32'h0;
			
			#2;
			d_EN_tb = 0;
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	//////////////// test 4: read then write ////////////////////////////////////////////////
	task test_r_w();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd4;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_write_tb = 1'b0;
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			d_wdata_tb = 32'h0;
			
			d_addr_tb = 32'hffff_fff4;
			#2;
			d_write_tb = 1'b1;
			d_addr_tb = 32'hffff_fff8;
			d_wdata_tb = 32'h3;
			#2;
			d_EN_tb = 0;
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	//////////////// test 5a: one wait cycle (fig 3-4) ////////////////////////////////////////////////
	task test_fig3_4();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd5;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'hffff_fff0;
			#2;
			d_write_tb = 1'b0;
			d_addr_tb = 32'h1234_5678;
			d_wdata_tb = 32'h0;
			#1.1;
			HREADY_tb = 0;
			#0.9;
			d_EN_tb = 0;
			d_addr_tb = 0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h6;
			#1.1;
			HREADY_tb = 1'b1;
			#1;
			d_EN_tb = 0;
			d_addr_tb = 0;
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	//////////////// test 5b: one wait cycle write write ////////////////////////////////////////////////
	task test_W_wait_W();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd6;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'hffff_fff0;
			#2;
			d_write_tb = 1'b1;
			d_addr_tb = 32'h1234_5678;
			d_wdata_tb = 32'h8;
			#1.1;
			HREADY_tb = 0;
			#0.9;
			d_EN_tb = 0;
			d_addr_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h6;
			#1.1;
			HREADY_tb = 1'b1;
			#0.9;

			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	/////////////// test 6a: two wait cycles RW (fig 3-3) ////////////////////////////////////////////////
	task test_2_wait_RW(); 
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd7;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'hffff_fff0;
			mem_ready = 1'b1;
			
			#2;
			d_write_tb = 1'b1;
			d_addr_tb = 32'h1234_5678;
			d_wdata_tb = 32'h8;
			
			#1.1;
			HREADY_tb = 0;
			mem_ready = 0;
			#0.9;
			d_EN_tb = 0;
			d_addr_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h6;
			
			#3.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	/////////////// test 6b: two wait cycles RR (fig 3-3) ////////////////////////////////////////////////
	task test_2_wait_RR();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd8;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'hffff_fff0;
			mem_ready = 1'b1;
			
			#2;
			d_write_tb = 1'b0;
			d_addr_tb = 32'h1234_5678;
			d_wdata_tb = 32'h8;
			
			#1.1;
			HREADY_tb = 0;
			mem_ready = 0;
			#0.9;
			d_EN_tb = 0;
			d_addr_tb = 0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h6;
			
			#3.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	////////////// test 7: write read write (wait) (fig 3-5) ///////////////////////////////////////
	task test_W_R_W_waits_fig_3_5();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd9;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_tb = 0; 
			d_size_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h13;
			d_addr_tb = 32'h8765_4321;
			mem_ready = 1'b1;
			
			#2;
			d_write_tb = 1'b0;
			d_addr_tb = 32'h1234_5678;
			d_wdata_tb = 32'h8;
			
			#2;
			d_write_tb = 1'b1;
			d_addr_tb = 32'h0000_0014;
			d_wdata_tb = 32'h10;
			#1.1;
			HREADY_tb = 0;
			mem_ready = 0;
			#0.9;
			d_EN_tb = 0;
			d_addr_tb = 32'h0012_3458;
			d_wdata_tb = 32'h0;
			d_write_tb = 1'b0;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	////////////// test 8: non sec - busy  wait (fig 3-6) /////////////////////////////////////////
	task test_nonsec_busy_wait_fig_3_6();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd10;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			d_burst_tb = INC; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#2;
			d_busy_tb = 1'b1;
			#2;
			d_busy_tb = 1'b0;
			#4;
			
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			
			#0.9;
			d_EN_tb = 0;
			d_burst_stop_tb = 1'b1;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h16;
			d_burst_tb = SINGLE; 
			d_size_tb = HALF_WORD;
			d_addr_tb = 32'h1234_5678;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#2;
			d_burst_stop_tb = 1'b0; 
			#4; 
			HRESET_n_tb = 0;
			#4;
		end
	endtask
	
	///////////// test 9: fig 3-12 testing undefined length bursts ////////////////////////////////
	task test_fig_3_12_inc();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd11;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h1234_5678;
			d_burst_tb = INC; 
			d_size_tb = HALF_WORD;
			d_addr_tb = 32'h20;
			#2;
			d_wdata_tb = 32'h8765_4321;
			#2;
			d_burst_stop_tb = 1'b1;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h1234_5678;
			d_burst_tb = INC; 
			d_size_tb = WORD;
			d_addr_tb = 32'h5c;
			#2;
			d_burst_stop_tb = 1'b0;
			
			#1.1;
			HREADY_tb = 0;
			mem_ready = 0;
			
			#0.9;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			d_burst_tb = SINGLE; 
			d_size_tb = HALF_WORD;
			d_addr_tb = 32'h0;
			#1.1;
			HREADY_tb = 1;
			mem_ready = 1;
			#0.9;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			d_burst_tb = SINGLE; 
			d_size_tb = HALF_WORD;
			d_addr_tb = 32'h4;
			#2;
			d_burst_stop_tb = 1'b1;
			#2; 
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	
	
	//////////// test 10a: fig 3-13 IDLE to NONSEQ //////////////////////////////////////////
	task test_fig_3_13_idle_to_nonseq();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd12;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h1;
			d_addr_tb = 32'h10;
			
			#1.1;
			mem_ready = 1'b0;
			HREADY_tb = 1'b0;
			#0.9;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h2;
			d_addr_tb = 32'h30;
			#2;
			d_EN_tb = 1'b1;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'h40;
			d_burst_tb = INC4; 
			d_size_tb = WORD;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h16;
			d_addr_tb = 32'h100;
			#2;
			#1.1;
			mem_ready = 1'b1;
			HREADY_tb = 1'b1;
			#0.9;
			#10;
			#2; 
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	//////////// test 10b: fig 3-13 IDLE to NONSEQ //////////////////////////////////////////
	task test_fig_3_13(); 
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd13;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h1;
			d_addr_tb = 32'h10;
			
			#1.1;
			mem_ready = 1'b0;
			HREADY_tb = 1'b0;
			#0.9;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h2;
			d_addr_tb = 32'h30;
			#2;
			d_EN_tb = 1'b1;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h5;
			d_addr_tb = 32'h40;
			d_burst_tb = INC; 
			d_size_tb = WORD;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h16;
			d_addr_tb = 32'h100;
			#2;
			#1.1;
			mem_ready = 1'b1;
			HREADY_tb = 1'b1;
			#0.9;
			#6;
			d_burst_stop_tb = 1'b1;
			#4;
			#2; 
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	//////////// test 11a: busy to SEQ in waited transfer fig 3-14 ///////////////////////////////////
	task test_fig_3_14_busy_to_seq();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd14;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			d_burst_tb = INC; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#4;
			d_busy_tb = 1'b1;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			#2;
			d_busy_tb = 1'b0;
			#4;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#2;
			d_burst_stop_tb = 1'b1;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h16;
			d_addr_tb = 32'h100;
			#4; 
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	//////////// test 11b: busy to SEQ in waited transfer fig 3-14 fixed burst ///////////////////////////////////
	task test_fig_3_14_busy_to_seq_inc4();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd15;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			d_burst_tb = INC4; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#4;
			d_busy_tb = 1'b1;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			#2;
			d_busy_tb = 1'b0;
			#4;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h16;
			d_addr_tb = 32'h100;
			#4; 
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	/////////// test 12a: fig 3-15: waited transfer busy to non seq ////////////////////////////////////
	task test_wait_busyinc_to_nonseqinc4();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd16;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h0;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			
			d_burst_tb = INC; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			#4;
			d_busy_tb = 1'b1;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			#2;
			d_busy_tb = 1'b0;
			d_burst_stop_tb = 1'b1;
			d_burst_tb = INC4; 
			d_addr_tb = 32'h10;
			#2;
			d_burst_stop_tb = 1'b0;
			#2;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h16;
			d_addr_tb = 32'h100;
			#6; 
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	
	
	/////////// test 12b: fig 3-15: waited transfer busy to non seq inc////////////////////////////////////
	task test_wait_busyinc_to_nonseqinc();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd17;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h60;
			HREADY_tb = 1;
			HRESP_tb = 0;
			mem_ready = 1'b1;
			
			
			d_burst_tb = INC; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			#2;
			d_wdata_tb = 32'h64;
			#2;
			d_wdata_tb = 32'h68;
			d_busy_tb = 1'b1;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			#2;
			d_busy_tb = 1'b0;
			d_burst_stop_tb = 1'b1;
			d_burst_tb = INC; 
			d_addr_tb = 32'h10;
			d_wdata_tb = 32'h10;
			#2;
			d_burst_stop_tb = 1'b0;
			#2;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			d_wdata_tb = 32'h14;
			#2;
			d_EN_tb = 1'b0;
			d_write_tb = 1'b1;
			d_addr_tb = 32'h100;
			d_wdata_tb = 32'h18;
			#2;
			d_wdata_tb = 32'h1c;
			#2;
			d_wdata_tb = 32'h20;
			#2;
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	///////// test 13: error signal is asserted high fig 3-17 ///////////////////////////////////////////////
	task test_error_fig3_17();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd18;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h60;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			
			d_burst_tb = INC; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#2;
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h60;
			#2;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			#2;
			#1.1;
			HRESP_tb = 1'b1;
			#0.9;
			d_addr_tb = 32'hc0;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			d_addr_tb = 32'h60;
			d_wdata_tb = 32'h80;
			#2;
			HRESP_tb = 1'b0;
			d_EN_tb = 0;
			d_addr_tb = 32'h50;
			d_wdata_tb = 32'h4;
			#4;
			HRESET_n_tb = 0;
			#2;
			
		end
	endtask
	
	//////// test 14: error signal yet again fig 5-1 /////////////////////////////////////////////////////
	task test_error_fig5_1();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd19;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h60;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h20;
			#2;
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h80;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			#1.1;
			HRESP_tb = 1'b1;
			#0.9;
			d_addr_tb = 32'hc0;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			d_addr_tb = 32'h40;
			d_wdata_tb = 32'h80;
			#2;
			HRESP_tb = 1'b0;
			d_EN_tb = 0;
			d_addr_tb = 32'h50;
			d_wdata_tb = 32'h4;
			#4;
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	///////////////////////////////////////// test 15: INC4 test fig 3-9//////////////////////////////////////////
	task test_inc4_fig3_9();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd20;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h10;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			HRESP_tb = 1'b0; 
			
			d_burst_tb = INC4; 
			d_size_tb = WORD;
			d_addr_tb = 32'h38;
			#2;
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h20;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#0.9;
			d_wdata_tb = 32'h30;
			#1.1;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			d_addr_tb = 32'h70;
			d_wdata_tb = 32'h40;
			#2;
			d_EN_tb = 0;
			d_addr_tb = 32'h50;
			d_wdata_tb = 32'h4;
			#4;
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	//////////////////////////////////////// test 16: INC8 test fig 3-11//////////////////////////////////////////
	task test_inc8_fig3_11();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd21;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h10;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			HRESP_tb = 1'b0; 
			
			d_burst_tb = INC8; 
			d_size_tb = HALF_WORD;
			d_addr_tb = 32'h38;
			#2;
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			d_write_tb = 1'b1;
			d_wdata_tb = 32'h20;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#2;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			d_addr_tb = 32'h70;
			d_wdata_tb = 32'h30;
			#2;
			d_EN_tb = 0;
			d_addr_tb = 32'h50;
			d_wdata_tb = 32'h40;
			#2;
			d_wdata_tb = 32'h50;
			#2;
			d_wdata_tb = 32'h60;
			#2;
			d_wdata_tb = 32'h70;
			#2;
			d_wdata_tb = 32'h80;
			#4;
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	/////////////////////////////////////// test 17: INC16 test /////////////////////////////////////////
	task test_inc16();
		begin
			HRESET_n_tb = 1'b1;
			test_no = 5'd22;
			d_EN_tb = 1;
			d_busy_tb = 0;
			d_burst_stop_tb = 0;
			d_write_tb = 1'b0;
			d_wdata_tb = 32'h10;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			HRESP_tb = 1'b0; 
			
			d_burst_tb = INC16; 
			d_size_tb = BYTE;
			d_addr_tb = 32'h38;
			#2;
			d_burst_tb = SINGLE; 
			d_size_tb = WORD;
			d_addr_tb = 32'h60;
			#1.1;
			HREADY_tb = 1'b0;
			mem_ready = 1'b0;
			#2;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			#0.9;
			HREADY_tb = 1'b1;
			mem_ready = 1'b1;
			d_addr_tb = 32'h70;
			#2;
			d_EN_tb = 0;
			#24;
			#4;
			HRESET_n_tb = 0;
			#2;
		end
	endtask
	
	
	


endmodule 