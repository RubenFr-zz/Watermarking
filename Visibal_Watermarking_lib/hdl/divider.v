//
// Verilog Module trainer.divider
//
// Created:
//          by - user.UNKNOWN (DESKTOP-A337LJE)
//          at - 20:12:54 10/16/2020
//
// using Mentor Graphics HDL Designer(TM) 2018.2 (Build 19)
//

`resetall
`timescale 1ns/10ps
module divider #(
	parameter Data_Depth = 8,
	parameter Divider_Depth = 8
)
( 
	// Port Declarations
	input   wire    [4*Data_Depth-1:0]  	A,
	input   wire    [4*Divider_Depth-1:0]  	B,  
	output  wire    [4*Data_Depth-1:0]  	C
);

reg [4*Data_Depth-1:0] temp;


always @(A or B) begin: al_proc
	// C = A /B
	temp <= A / B;
end

assign C = temp;


endmodule
