//
//	Visibal_Watermarking.v
//
//	Ruben Fratty	340895499
//	Emmanuel
//


`resetall
`timescale 1ns/10ps
module Visibal_Watermarking #(
	parameter Amba_Word = 16,			// Size of every data reg
	parameter Amba_Addr_Depth = 20,		// Size of the data bank 
	parameter Data_Depth = 8,			// Bit depth of the pixel
	parameter Block_Depth = 7,			// Max pixel per row/colomn in block is 72 (7 bits)
	parameter Max_Block_Size = 5184		// Max pixels that a block can countain (720 / 10)^2 = 5184
)
(
	// Port Declarations
	input wire 	[Amba_Addr_Depth:0] PADDR,   	// ABP Address Bus
	input wire 						PENABLE,	// APB Bus Enable/clk
	input wire 						PSEL,  		// APB Bus Select
	input wire 						PWRITE, 	// APB Bus Write
	input wire 	[Amba_Word-1:0] 	PWDATA,		// APB Write Data Bus
	input wire 						clk,    	// System clock
	input wire 						rst,    	// Reset active low
	output reg 	[Amba_Word-1:0]  	PRDATA,     // APB Read Data Bus
	output reg 				 		Image_Done, // State indicator
	output wire 	[Data_Depth-1:0] 	Pixel_Data, // Modified pixel 
	output wire						new_pixel	// New Pixel Indicator 
);

// CTRL READ WRITE
localparam APB_READ  = 1'b0;
localparam APB_WRITE = 1'b1;


//States
localparam State0 = 5'b00001;	// Reset
localparam State1 = 5'b00010;	// Parameters init
localparam State2 = 5'b00100;	// Primary block loading
localparam State3 = 5'b01000;	// Watermark block loading
localparam State4 = 5'b10000;   // Parameters Calculation
reg	[5-1:0]	curr_state;

// APB REGISTERS
reg 						APB_CTRL;		// 0 - ReadData, 1 - WriteData
reg 	[Amba_Addr_Depth:0] APB_addr;
reg 	[Amba_Word-1:0] 	APB_WriteData;
wire 	[Amba_Word-1:0] 	APB_ReadData;
wire						start;	

// Parameters
reg [Data_Depth-1:0]	M; 				// Number of pixels per line/colomn per block max 720/10=72 (7bits)
reg [10-1:0]	Np;
reg [10-1:0]	Nw;
reg [7-1:0]				count;			// How many blocks have been processed (max 10*10=100 - 7 bits)


// DATA
reg						CPU_wait_data;		// Data ready in next clk
reg						CPU_data_rdy;		// Data is available in DATA
reg						wait_data;			// Data ready in next clk
reg						first_read;			// First read from APB -> no DATA available
reg [Amba_Word-1:0]		DATA;				// Data read from APB

// PROCESSING
reg [Amba_Addr_Depth:0]		curr_addr;			// Current data address we want to reach
reg [Block_Depth-1:0] 		row;
reg [Block_Depth-1:0] 		col;
reg [Amba_Addr_Depth:0]		offset;				// Start of the curr block
reg [9:0]					curr_block;
wire						block_done;

reg test;

// MODULES

// APB Data Bank
APB #(.Amba_Word(Amba_Word),.Amba_Addr_Depth(Amba_Addr_Depth)) Data_Bank(
	.clk(clk),
	.rst(rst),
	.write_en(APB_CTRL),
	.addr(APB_addr),
	.data_in(APB_WriteData),
	.data_out(APB_ReadData),
	.start(start)
);

// DATA PROCESSING
Block_Divider #(.Data_Depth(Data_Depth), .Max_Block_Size(Max_Block_Size)) Block_Divider(
	.clk(clk),
	.rst(rst),
	.en(start && !Image_Done),				
	.Pixel_in(APB_ReadData[Data_Depth-1:0]),
	.Pixel_Data(Pixel_Data),
	.new_pixel(new_pixel),
	.done(block_done)
);



// BODY
always @(posedge clk or negedge rst) begin : Main
	
	if(rst) begin
		curr_state <= State0;
		APB_CTRL <= 1'b0;
		APB_addr <= {Amba_Addr_Depth+1{1'b0}};
		APB_WriteData <= {Amba_Word{1'b0}};
		CPU_wait_data <= 1'b0;
		CPU_data_rdy <= 1'b0;
		CPU_wait_data <= 1'b0;
		CPU_data_rdy <= 1'b0;
		DATA <= {Amba_Word{1'bz}};
		Image_Done <= 1'b0;
		curr_addr <= {{Amba_Addr_Depth{1'b0}}, 1'b1};		// Reset addr to 0x01 (White pixel)
		offset <= {{Amba_Addr_Depth-8{1'b0}}, 8'h0A};		// Addr first pixel
		row <= 'd0;
		col <= 'd0;	
			
		test = 0;
	end
	
	//AMBA PROTOCOL
	// IDLE		--> PSEL = 0 & PENABLE = 0 	(Do nothing)	(CPU SIDE)
	// SETUP 	--> PSEL = 1 & PENABLE = 0	(transfer) 		(CPU SIDE)
	// ACCESS 	--> PSEL = 1 & PENABLE = 1 	(while PREADY = 0 stay in this state) 	(Our SIDE)
	else if(PSEL == 1'b1) begin
	
		// CPU INIT/READ
		if (PENABLE == 1'b1 && PWRITE == APB_WRITE) begin	// ACCESS WRITE
			APB_WriteData <= PWDATA;
			APB_addr <= PADDR;
			APB_CTRL <= APB_WRITE;
		end
		
		else if (PENABLE == 1'b1 && PWRITE == APB_READ) begin 	// ACCESS READ
			APB_addr <= PADDR;
			APB_CTRL <= APB_READ;
			CPU_wait_data <= 1'b1;
		end
		
		else if (CPU_wait_data) begin // Data ready
			CPU_wait_data <= ~CPU_wait_data;
			PRDATA <= APB_ReadData;
			CPU_data_rdy <= 1'b1;
			first_read <= 1'b1;
		end
		
		else if (CPU_data_rdy)  // CPU Reads Data
			CPU_data_rdy <= ~CPU_data_rdy;
	
	end // if PSEL	
	
		
	// CPU not in action
	// PROCESSING THE DATA
	else if (start && !Image_Done) begin
	
		////////////////////////// Start the process ////////////////////////////////
		if (curr_state == State0) begin	
			curr_addr = 'd1;				// First addr to 0x01 (White pixel)
			APB_addr <= curr_addr;
			APB_CTRL <= APB_READ;
			curr_addr <= curr_addr + 1;
			curr_state <= State1;
		end
	
		/////////////////// Loading parameters (0x01 - 0x09) /////////////////////////
		else if (curr_state == State1) begin
	
			APB_addr <= curr_addr;
			APB_CTRL <= APB_READ;
			// DATA <= APB_ReadData;			// Register from the APB
			
			case(curr_addr - 1)
				2:	Np	<= APB_ReadData[10-1:0];
				3:	Nw	<= APB_ReadData[10-1:0];
				4:	M	<= APB_ReadData[Data_Depth-1:0];
			endcase
				
			if (curr_addr == 'd10) begin		// On the next clk the register at addr 0x0A (First Pixel) will be on the bus
				offset <= curr_addr;
				row <= 'd0;
				col <= 'd0;
				count <= 'd0;
				curr_state <= State2;
			end
			else
				curr_addr <= curr_addr + 1;

		end
	
		////////////////////// Loading Primary_block ////////////////////////////
		else if (curr_state == State2) begin
			if (col + 1 == M) begin		// Next col isn't in the block
				col <= 0;
				if (row + 1 == M) begin		// Next row isn't in the block
					row <= 0;
					APB_addr <= offset + Np*Np;	// First pixel of next Watermark_block
					APB_CTRL <= APB_READ;
					curr_state <= State3;
				end
				else begin
					row <= row + 1;
					APB_addr <= offset + ((row+1) * Np);	// Next pixel in the block
					APB_CTRL <= APB_READ;
				end
			end
			else begin
				col <= col + 1;
				APB_addr <= offset + ((col+1) + row * Np);	// Next pixel in the block
				APB_CTRL <= APB_READ;
			end
		end
				
		////////////////////// Loading Watermark_block ////////////////////////////
		else if (curr_state == State3) begin
			if (col + 1 == M) begin		// Next col isn't in the block
				col <= 0;
				if (row + 1 == M) begin		// Next row isn't in the block
					row <= 0;
					count <= count + 1;
					offset <= offset + (((count + 1) % (Np/M) == 0) ? Np*(M-1)+M : M);	// First pixel of next primary block
					APB_addr <= offset + (((count + 1) % (Np/M) == 0) ? Np*(M-1)+M : M);	// First pixel of next Watermark
					APB_CTRL <= APB_READ;
					curr_state = State4;
				end
				else begin
					row <= row + 1;
					APB_addr <= offset + Np*Np + ((row+1) * Np);	// Next pixel in the block
					APB_CTRL <= APB_READ;
				end
			end
			else begin
				col <= col + 1;
				APB_addr <= offset + Np*Np + ((col+1) + row * Np);	// Next pixel in the block
				APB_CTRL <= APB_READ;
			end
		end
		
		///////////////////////// Processing Block ////////////////////////////////
		///////// Block the run until the whole block has been processed //////////
		///////////////////////////////////////////////////////////////////////////
		else if (curr_state == State4) begin
			if (block_done) begin
				if (count == (Np*Np)/(M*M)) begin
					Image_Done <= 1'b1;
					curr_state <= State0;
				end
				else begin
					row <= 'd0;
					col <= 'd0;
					curr_state = State2;
				end
			end
		end
		
	end	// start & !Image_Done
end	// Main
    

  
endmodule // Visibal_Watermarking