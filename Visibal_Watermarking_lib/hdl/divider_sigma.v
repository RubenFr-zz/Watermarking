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
   parameter Data_Depth = 8
)
( 
   // Port Declarations
   input   wire    [4*Data_Depth-1:0]  prod1, 
   output  wire    [4*Data_Depth-1:0]  prod2
);

// Internal Declarations
//parameter Data_Depth = 8;

// Local declarations

// Internal signal declarations
reg [4*Data_Depth-1:0] temp1;
//reg [3*Data_Depth-1:0] temp2;


// Instances 
always @(prod1) begin: al_proc
  temp1 <= prod1 / 1000000.0;
  //temp2 <= temp1 / 1000;
end

assign prod2 = temp1;

// ### Please start your Verilog code here ### 

endmodule
