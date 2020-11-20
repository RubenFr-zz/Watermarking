//
//	Visibal_Watermarking.v
//
//	Ruben Fratty	340895499
//	Emmanuel
//


`resetall
`timescale 1ns/10ps
module Visibal_Watermarking(
	PADDR, 
	PENABLE, 
	PSEL, 
	PWDATA, 
	PWRITE, 
	clk, 
	rst, 
	PRDATA, 
	Image_Done, 
	Pixel_Data
);

// MACROS
`define APB_READ  	1'b0
`define APB_WRITE  	1'b1


// PARAMETERS
parameter Amba_Word = 16;               // Size of every data reg
parameter Amba_Addr_Depth = 20;         // Size of the data bank 
parameter Data_Depth = 8;               // Bit depth of the pixel
parameter Max_Image_Size = 10;			// The size of an image is max 10 bits

// DEFINE INPUTS VARS
input wire [Amba_Addr_Depth:0] PADDR;   // ABP Address Bus
input wire PENABLE;                     // APB Bus Enable/clk
input wire PSEL;                        // APB Bus Select
input wire PWRITE;                      // APB Bus Write
input wire [Amba_Word-1:0] PWDATA;      // APB Write Data Bus
input wire clk;                         // System clock
input wire rst;                         // Reset active low

// DEFINE OUTPUT VARS
output wire [Amba_Word-1:0]  PRDATA;     // APB Read Data Bus
output wire 				 Image_Done; // State indicator
output wire [Data_Depth-1:0] Pixel_Data; // Modified pixel 

// APB REGISTERS
reg 						APB_CTRL;		// 0 - ReadData, 1 - WriteData
reg 	[Amba_Addr_Depth:0] APB_addr;
reg 	[Amba_Word-1:0] 	APB_WriteData;
wire 	[Amba_Word-1:0] 	APB_ReadData;
wire						start;	

// CALCULATION CONST
// Iwhite;			// WhitePixel 		0x00
// Np;				// PrimarySize 		0x01	
// Nw;				// WatermarkSize 	0x02
// M;				// BlockSize 		0x03
// Bthr;			// EdgeThreshold 	0x04
// Amin;			//					0x05
// Amax;			//					0x06
// Bmin;			//					0x07
// Bmax;			//					0x08
reg [Amba_Word-1:0] Calc_const [3:0];
reg [3:0]			index;


// DATA
reg						CPU_wait_data;		// Data ready in next clk
reg						CPU_data_rdy;		// Data is available in DATA
reg						wait_data;			// Data ready in next clk
reg						data_rdy;			// Data is available in DATA
reg [Amba_Word-1:0]		DATA;				// Data read from APB

// PROCESSING
reg 					done;				// Processed all the pixels
reg						init_over;			// Ended to initiate the system (get all the registers values)
reg [Amba_Addr_Depth:0]	curr_addr;			// Current data address we want to reach
reg [Amba_Word-1:0]		curr_Primary;
reg [Amba_Word-1:0]		curr_Watergate;		// Current Watergate 

// MODULES

// APB Data Bank
APB #(.Amba_Word(Amba_Word),.Amba_Addr_Depth(Amba_Addr_Depth)) Data_Bank(
	.clk(clk),
	.rst(rst),
	.CTRL(APB_CTRL),
	.ADDR(APB_addr),
	.WD(APB_WriteData),
	.RD(APB_ReadData),
	.START(start)
);

// DATA PROCESSING
Eqn_Imp Data_Processing(

);



// BODY
always @(posedge clk or negedge rst) begin : Main
	
	if(~rst)
	begin
		APB_CTRL = 1'b0;
		APB_addr = {Amba_Addr_Depth+1{1'b0}};
		APB_WriteData = {Amba_Word{1'b0}};
		CPU_wait_data = 1'b0;
		CPU_data_rdy = 1'b0;
		CPU_wait_data = 1'b0;
		CPU_data_rdy = 1'b0;
		DATA = {Amba_Word{1'bz}};
		init_over = 1'b0;
		done = 1'b0;
		curr_addr = {{Amba_Addr_Depth{1'b0}}, 1'b1};		// Reset addr to 0x01 (White pixel)
		
		
	end
	
	//AMBA PROTOCOL
	// IDLE		--> PSEL = 0 & PENABLE = 0 	(Do nothing)	(CPU SIDE)
	// SETUP 	--> PSEL = 1 & PENABLE = 0	(transfer) 		(CPU SIDE)
	// ACCESS 	--> PSEL = 1 & PENABLE = 1 	(while PREADY = 0 stay in this state) 	(Our SIDE)
	else if(PSEL)
	begin
	
		// CPU INIT/READ
		if (PENABLE && PWRITE) // ACCESS WRITE
		begin
			APB_WriteData <= PWDATA;
			APB_addr <= PADDR;
			APB_CTRL <= `APB_WRITE;
		end
		
		else if (PENABLE && ~PWRITE) // ACCESS READ
		begin
			APB_addr <= PADDR;
			APB_CTRL <= `APB_READ;
			CPU_wait_data <= 1'b1;
		end
		
		else if (CPU_wait_data) // Data ready
		begin
			CPU_wait_data <= ~CPU_wait_data;
			DATA <= APB_ReadData;
			CPU_data_rdy <= 1'b1;
			data_rdy <= 1'b0;
		end
		
		else if (CPU_data_rdy) // CPU Reads Data
		begin
			CPU_data_rdy <= ~CPU_data_rdy;
		end
		
	end // if PSEL	
	
	
	// PROCESSING THE DATA
	else if (start && !done) 
	begin
		// Loop to initiate the constants for the calculation
		if (~data_rdy)
		begin
			APB_addr <= curr_addr;
			APB_CTRL <= `APB_READ;
			data_rdy <= ~data_rdy;
		end
		
		else // Data is available
		begin
			APB_addr <= curr_addr;
			APB_CTRL <= `APB_READ;
			DATA <= APB_ReadData;	// Some data is already available 
			
			if (~init_over)
				Calc_const[curr_addr[3:0] - 'd1] <= DATA;
			
			else 	// Pixel available
			begin
				if (~Primary_rdy)
				begin
					curr_Primary <= DATA;
					Primary_rdy = ~Primary_rdy;
				end
				
				else
				begin
					curr_Watergate <= DATA;
				end
			end
			curr_addr <= curr_addr + 1;
			init_over <= (curr_addr > 'd9); 	// addr 0x0A is the first pixel
		end
		
	end
	
end
    
assign PRDATA = (CPU_data_rdy) ? DATA : {(Amba_Word){1'bz}};
assign Image_Done = done;
  
endmodule

