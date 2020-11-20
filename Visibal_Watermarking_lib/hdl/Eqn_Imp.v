//
// Eqn_Imp.v
//
// Ruben Fratty		340895499
// Emmanuel
//
// Process the primary and watermark blocks
//

`resetall
`timescale 1ns/10ps
module Eqn_Imp #(
   parameter Data_Depth = 8
)
( 
	// Port Declarations
	input   wire    [Data_Depth-1:0]  	P_pixel, 	// Primary block k
	input   wire    [Data_Depth-1:0]  	W_pixel,	// Watermark block k
	input 	wire	[Data_Depth-1:0]	G_mu_k,		// Constant
	input	wire	[Data_Depth-1:0]	B_thr,      // Constant
	input 	wire	[6:0]				A_max,      // Constant
	input 	wire	[6:0]				B_min,      // Constant
	input 	wire	[6:0]				A_k,        // Constant
	input 	wire	[6:0]				B_k,        // Constant
	output  wire	[Data_Depth-1:0]	Out_Pixel	// Watermarked pixel k
   
);

reg [Data_Depth-1:0] 	Processed_Pixel;

always @(*) begin : Processing_Pixels

	if (G_mu_k >= B_thr)
		Processed_Pixel <= A_max * P_pixel + B_min * W_pixel;
	
	else
		Processed_Pixel <= A_k * P_pixel + B_k * W_pixel;
end

assign Out_Pixel = Processed_Pixel;

endmodule // Eqn_Imp

