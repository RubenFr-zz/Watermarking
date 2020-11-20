//
// Verilog Module Visibal_Watermarking_lib.power_2
//
// Created:
//          by - Ruben.UNKNOWN (RUBEN-LAPTOP)
//          at - 10:24:03 11/19/2020
//
// using Mentor Graphics HDL Designer(TM) 2018.2 (Build 19)
//

`resetall
`timescale 1ns/10ps
module power_2 #(
    parameter MU_SIZE = 10
)
(
    input wire [MU_SIZE-1:0] mu_k,
    output wire [MU_SIZE-1:0] out
);

reg [4*MU_SIZE-1:0] temp1;

// Instances 
always @(mu_k) begin: power
  temp1 <= 2 ** ((-1) * (mu_k -  5.0e-1) * (mu_k -  5.0e-1));
end

assign out = temp1;

endmodule
