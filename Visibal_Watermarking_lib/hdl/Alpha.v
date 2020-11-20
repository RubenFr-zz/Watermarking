//
//	Alpha.v
//
//	Ruben Fratty	340895499
//	Emmanuel
//
//	Calculation of Alpha
//

`resetall
`timescale 1ns/10ps
module Alpha #(
   parameter MU_SIZE = 10
)
( 
   // Port Declarations
   input   wire    [6:0]          A_max, 
   input   wire    [6:0]          A_min, 
   input   wire    [MU_SIZE-1:0]  mu_k, 
   input   wire    [6:0]          sigma_k, 
   output  wire    [6:0]          A_k
);


// Internal signal declarations
wire  [15:0]        dout;
wire  [MU_SIZE-1:0] power;
wire  [15:0]        prod;
wire  [


// Instances 
power_2 power_mu(
	.mu_k (mu_k), 
	.out  (power)
); 

divider #(.Data_Depth( divide_100(
	.A(temp3),
	.B(100),		// Alpha / 100
	.C(A_k)
);

assign prod = A_min * sigma_k;			// Common Denominator

assign temp1 = A_max - A_min;

assign temp2 = temp1 * power;			// (alpha_max - alpha_min) * 2^-(mu_k-0.5)

assign prod = A_min * sigma_k;

assign temp3 = temp2 + prod;
 
endmodule // Alpha

