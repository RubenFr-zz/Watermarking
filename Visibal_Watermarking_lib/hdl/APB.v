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
	CTRL,
	ADDR, 
	WD, 
	RD,
	START
);

	//PARAMETERS  
	parameter Amba_Word = 16;               // Size of every data reg
	parameter Amba_Addr_Depth = 20;         // Size of the data bank 

	// DEFINE INPUTS/OUTPUTS VARS
	input wire 	clk;							
	input wire 	rst;						// Active Low
	input wire 	CTRL;                       // 0 - ReadData, 1 - WriteData
	input wire 	[Amba_Addr_Depth-1:0] ADDR;
	input wire 	[Amba_Word-1:0] WD;			// Write Data 
	output wire [Amba_Word-1:0] RD;			// Read Data
	output wire START;						// 0 - Off, 1 - Start (represent the CTRL register 0x00)

	// REGISTER BANK

	// 0x00 CTRL                Controls the design - 1: Start, 0: Off (default 0)
	// 0x01 WhitePixel          White pixel value
	// 0x02 PrimarySize         Primary Image matrix rows/columns number
	// 0x03 WatermarkSize       Watermark Image matrix rows/columns number
	// 0x04 BlockSize           The small blocks matrix row/columns number (M)
	// 0x05 EdgeThreshold       Predefined Edge detection threshold
	// 0x06 A_min               Scaling factor minimum percentage value
	// 0x07 A_max               Scaling factor maximum percentage value
	// 0x08 Bmin                Embedding factor minimum percentage value
	// 0x09 Bmax                Embedding factor maximum percentage value
	// 0x0A PrimaryPixel00      First Primry Image pixe (0,0)
	// ...
	// 0x09+(Np^2)h PrimaryPixelNN        Last Primary Image pixel (N,N)
	// 0x0A+(Np^2)h WatermarkPixel00      First Watermark Image pixe (0,0)
	// ...
	// 0x0A+(Np^2+Nw^2) PrimaryPixelNN    Last Primary Image pixel (N,N)


	reg [Amba_Word-1:0] DataBank [(2**Amba_Addr_Depth)-1:0];  	// Contains all the registers
	reg [Amba_Word-1:0] DATA_r;              	 				// Data yet to be assigned to ReadData
	reg ready;                              					// Should we read from the ReadData ?
	reg Start_r;
	

	always @(posedge clk or negedge rst) begin : Main
		if(~rst)
			begin
				DataBank[0] <= {Amba_Word{1'b0}};                 // Set CTRL = 0
				DataBank[1] <= {{(Amba_Word-8){1'b0}},{8'd255}};  // Set WhitePixel = 255
				Start_r <= 1'b0;
				ready <= 1'b0;
			end
		else
			begin
				case (CTRL)
					1'b0 : DATA_r <= DataBank[ADDR];    // Read Data from DataBank
					1'b1 : DataBank[ADDR] <= WD; 		// Write data to DataBank
				endcase
				Start_r <= DataBank[0][0];			// The system CTRL bit: 0 - wait, 1 - start 
				ready <= (CTRL) ? 1'b0 : 1'b1;
				
			end
	end 

	assign RD = (ready) ? DATA_r : {Amba_Word{1'bz}};
	assign START = Start_r;

endmodule	// APB
