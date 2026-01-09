//verision 1: master picks up transaction from driver/processor and sends it to slave in the next clk cycle. This is done to ease testing of the master. 

module AHB_master(
	input wire HCLK, //global clk signal
	input wire HRESET_n, //global active low async reset 
	
	input wire d_EN, // if 1 indicates a read/write xact otherwise idle xact 
	input wire d_busy, // indicates if driver is busy
	input wire d_write, // indicates if request is write or read
	input wire [31:0] d_wdata, // data to be written to slave 
	input wire [2:0] d_burst, // indicates if requested transfer is a burst and of what type
	input wire [31:0] d_addr, // address of the requested transfer
	input wire [2:0] d_size, //size of the transfer
	input wire d_burst_stop, //stop burst for burst of undefined length
	
	input wire HREADY, // indicates by slave that transfer is ready. if low indicates a request to extend the data phase
	input wire HRESP, // given by slave to indicate the success or failure of the transfer
	input wire [31:0] HRDATA, //slave data
	
	output reg [31:0] HADDR, //address bus
	output reg [2:0] HBURST, // indicate burst and its type
	output reg [2:0] HSIZE, //indicate the size of the transfer
	output reg [1:0] HTRANS, //indicate to slave tranfer type
	output reg [31:0] HWDATA, //data written to slave
	output reg HWRITE // indicate to slave if transfer is a write or read transfer
);
	parameter [1:0] IDLE = 0; //no transfer is sent from master to slave
	parameter [1:0] BUSY = 1; //master is busy in the middle of a burst
	parameter [1:0] SINGLE = 2; //prepare address, write signal and transfer type of the single burst transfer & the data in the next cycle. 
	parameter [1:0] BURST = 3; //prepare address, write signal and transfer type of the burst transfer & the data in the next cycle. 
	
	reg [1:0] cs; 
	// we assume that the driver sends the write data along with the write address because that makes sense 
	reg [31:0] pending_data; //pending data of the previous write transfer.
	reg [4:0] burst_count; // number of bursts transfers sent
	reg [4:0] required_count; //required burst count for the transation
	reg [31:0] burst_inc; //increment required to the address of the transaction
	
	reg [4:0] new_required_count;
	reg [31:0] new_burst_inc; 
	//next state & outputs 
	always@(posedge HCLK or negedge HRESET_n) begin
		if(!HRESET_n) begin
			cs <= IDLE;
			HTRANS <= 2'b0;
			HWRITE <= 1'b0; 
			HADDR <= 32'b0;
			HSIZE <= 1'b0;
			HWDATA <= 32'b0;
			HBURST <= 3'b0;
			pending_data <= 32'b0;
			burst_count <= 0;
			burst_inc <= 0;
			required_count <= 0;
		end
		else begin
			case(cs)
				IDLE: begin 
					HWRITE <= d_write; 
					HADDR <= d_addr;
					HBURST <= d_burst;
					HSIZE <= d_size;
					pending_data <= d_wdata;
					required_count <= new_required_count;
					burst_inc <= new_burst_inc;
					if(d_EN && (HREADY || (HRESP == 1'b0) )) begin
						HTRANS <= 2'b10;
						if(|d_burst) begin 
							if(d_busy) begin
								cs <= BUSY;
								HTRANS <= 2'b01;
								burst_count <= 0;
							end
							else begin
								cs <= BURST; 
								burst_count <= 1'b1;
							end
							/*
							cs <= BURST; 
							burst_count <= 1'b1;
							*/
						end
						else begin
							cs <= SINGLE;
							burst_count <= 0;
						end
					end
					else begin
						HTRANS <= 2'b00;
						burst_count <= 0;
					end
					
				end
				
				SINGLE: begin
					if(HREADY) begin
						if(HWRITE) begin
							HWDATA <= pending_data;
						end
						HWRITE <= d_write; 
						HADDR <= d_addr;
						HBURST <= d_burst;
						HSIZE <= d_size;
						pending_data <= d_wdata;
						required_count <= new_required_count;
						burst_inc <= new_burst_inc;
						if(d_EN) begin
							HTRANS <= 2'b10;
							if(|d_burst) begin 
								/*cs <= BURST;
								burst_count <= 1'b1;
								*/
								if(d_busy) begin
									cs <= BUSY;
									HTRANS <= 2'b01;
									burst_count <= 1'b0;
								end
								else begin
									cs <= BURST ;
									burst_count <= 1'b1;
								end
										
							end
							else begin
								cs <= SINGLE;
								burst_count <= 1'b0;
							end
						end
						else begin
							cs <= IDLE;
							HTRANS <= 2'b0;
							burst_count <= 1'b0;
							pending_data <= 32'b0;
						end
						
					end
					else if(HRESP == 1'b1) begin
						cs <= IDLE;
						HWRITE <= d_write; 
						HADDR <= d_addr;
						HBURST <= d_burst;
						HSIZE <= d_size;
						pending_data <= d_wdata;
						required_count <= new_required_count;
						burst_inc <= new_burst_inc;
						HTRANS <= 2'b0;
						burst_count <= 0;
					end
					
				end		
				
				BURST: begin
					if(HREADY) begin
						if(HWRITE) begin
							HWDATA <= pending_data;
						end
						if( (burst_count == required_count && (HBURST != 3'b1)) || (d_burst_stop && HBURST == 3'b1)) begin
							
							HWRITE <= d_write; 
							HADDR <= d_addr;
							HBURST <= d_burst;
							HSIZE <= d_size;
							pending_data <= d_wdata;
							required_count <= new_required_count;
							burst_inc <= new_burst_inc;
							if(d_EN) begin
								if(|d_burst) begin 					
									if(d_busy) begin
										cs <= BUSY;
										HTRANS <= 2'b01;
										burst_count <= 0;
									end
									else begin
										cs <= BURST;
										HTRANS <= 2'b10;
										burst_count <= 1'b1;
									end	
									/*
									cs <= BURST;
									HTRANS <= 2'b10;
									burst_count <= 1'b1;
									*/
								end
								else begin
									cs <= SINGLE;
									HTRANS <= 2'b10;
									burst_count <= 0;
								end
							end
							else begin
								cs <= IDLE;
								HTRANS <= 2'b0;
								burst_count <= 0;
							end		
						end
						else begin
							pending_data <= d_wdata;
							if(d_busy) begin
								HTRANS <= 2'b01;
								HADDR <= HADDR + burst_inc; 
								cs <= BUSY;
							end
							else begin
								burst_count <= burst_count + 5'b1;
								HTRANS <= 2'b11;
								HADDR <= HADDR + burst_inc; 
							end
							
						end
					end
					else if(HRESP == 1'b1) begin
						cs <= IDLE;
						HWRITE <= d_write; 
						HADDR <= d_addr;
						HBURST <= d_burst;
						HSIZE <= d_size;
						pending_data <= d_wdata;
						required_count <= new_required_count;
						burst_inc <= new_burst_inc;
						HTRANS <= 2'b0;
						burst_count <= 0;
					end
					
				end
				
				BUSY: begin
					if((HRESP == 1'b1) && !HREADY) begin
						cs <= IDLE;
						HWRITE <= d_write; 
						HADDR <= d_addr;
						HBURST <= d_burst;
						HSIZE <= d_size;
						pending_data <= d_wdata;
						required_count <= new_required_count;
						burst_inc <= new_burst_inc;
						HTRANS <= 2'b0;
						burst_count <= 0;
					end
					else if(!d_busy) begin
						if((HBURST == 3'b1) && d_burst_stop && !HREADY) begin
							HWRITE <= d_write; 
							HADDR <= d_addr;
							HBURST <= d_burst;
							HSIZE <= d_size;
							pending_data <= d_wdata;
							required_count <= new_required_count;
							burst_inc <= new_burst_inc;
							if(d_EN) begin
								if(|d_burst) begin 
									cs <= BURST;
									HTRANS <= 2'b10;
									burst_count <= 1;
								end
								else begin
									cs <= SINGLE;
									HTRANS <= 2'b10;
									burst_count <= 0;
								end
							end
							else begin
								cs <= IDLE;
								HTRANS <= 2'b0;
								burst_count <= 0;
							end
						end
						else if(burst_count == 0) begin
							cs <= BURST; 
							HTRANS <= 2'b10; 
							burst_count <= 1;
						end
						else begin
							cs <= BURST;
							HTRANS <= 2'b11; 
							burst_count <= burst_count + 1;
						end
						
						/*
						cs <= BURST;
						HTRANS <= 2'b11; 
						burst_count <= burst_count + 1;
						*/
					end
				end
			endcase
		end
	end
	
	always@(*) begin
		new_burst_inc = 0;
		new_required_count = 0;
		
		case(d_burst) 
			3'b011: begin
				new_required_count = 5'd4;
			end
			3'b101: begin
				new_required_count = 5'd8;
			end
			3'b111: begin
				new_required_count = 5'd16;
			end
			default : begin //treat non increment bursts like single bursts
				new_required_count = 0;
			end 
		endcase
		
		case(d_size)
			3'b000: begin
				new_burst_inc = 32'h1;
			end
			3'b001: begin
				new_burst_inc = 32'h2;
			end
			3'b010: begin
				new_burst_inc = 32'h4;
			end
			3'b011: begin
				new_burst_inc = 32'h8;
			end
			3'b100: begin
				new_burst_inc = 32'h10;
			end
			3'b101: begin
				new_burst_inc = 32'h20;
			end
			3'b110: begin
				new_burst_inc = 32'h40;
			end
			3'b111: begin
				new_burst_inc = 32'h80;
			end
		endcase
	end
	

endmodule
