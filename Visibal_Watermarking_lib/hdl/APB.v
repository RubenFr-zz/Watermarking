//
// APB.v
//
// Ruben Fratty		340895499
// Emmanuel
//

`resetall
`timescale 1ns/10ps
module APB(
	clk, 
	rst, 
	write_en,
	addr, 
	data_in, 
	data_out,
	start
);

//PARAMETERS  
parameter Amba_Word = 16;               // Size of every data reg
parameter Amba_Addr_Depth = 20;         // Size of the data bank 

// DEFINE INPUTS/OUTPUTS VARS
input wire 							clk;							
input wire 							rst;		// Active Low
input wire 							write_en;   // 0 - ReadData, 1 - WriteData
input wire 	[Amba_Addr_Depth:0] 	addr;
input wire 	[Amba_Word-1:0] 		data_in;	// Write Data 
output reg 	[Amba_Word-1:0] 		data_out;	// Read Data
output wire 						start;		// 0 - Off, 1 - Start (represent the CTRL register 0x00)

// REGISTER BANK

// 0x00 CTRL                Controls the design - 1: Start, 0: Off (default 0)
// 0x01 WhitePixel          White pixel value
// 0x02 PrimarySize         Primary Image matrix rows/columns number
// 0x03 WatermarkSize       Watermark Image matrix rows/columns number
// 0x04 BlockSize           The small blocks matrix row/columns number (M)
// 0x05 EdgeThreshold       Predefined Edge detection threshold
// 0x06 A_min               Scaling factor minimum percentage value
// 0x07 A_max               Scaling factor maximum percentage value
// 0x08 B_min               Embedding factor minimum percentage value
// 0x09 B_max               Embedding factor maximum percentage value
// 0x0A PrimaryPixel00      First Primary Image pixel (0,0)
// ...
// 0x09+(Np^2)h PrimaryPixelNpNp        Last Primary Image pixel (Np,Np)
// 0x0A+(Np^2)h WatermarkPixel00      First Watermark Image pixel (0,0)
// ...
// 0x0A+(Np^2+Nw^2) WatermarkPixelNN    Last Primary Image pixel (Nw,Nw)

// reg [Amba_Word-1:0] DataBank [(2**Amba_Addr_Depth)-1:0];  	// Contains all the registers
reg [Amba_Word-1:0] DataBank [42-1:0];  	// Contains all the registers

// always @(posedge clk or posedge rst) begin : Main
always @(negedge clk or negedge rst) begin : Main
	if(rst) begin
		DataBank[0] <= 'd0;     // Set CTRL = 0
		DataBank[1] <= 'd255;  	// Set WhitePixel = 255
	end
	else begin
		if (write_en)
			DataBank[addr] <= data_in;
		else
			data_out <= DataBank[addr];					
	end
end 

assign start = DataBank[0][0];

endmodule	// APB
