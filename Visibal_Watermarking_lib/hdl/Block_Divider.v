//
//	Block_Divider.v
//
//	Ruben Fratty	340895499
//	Emmanuel
//
//	Divide the primary image in blocks to be processed
//

`resetall
`timescale 1ns/10ps
module Block_Divider #(
   parameter Data_Depth = 8,
   parameter Max_Block_Size = 5184		// 72*72
)
( 
   // Port Declarations
   input 	wire						clk,
   input	wire						rst,
   input 	wire						en,
   input	wire	[Data_Depth-1:0]	Pixel_in,
   output  	reg		[Data_Depth-1:0]	Pixel_Data,
   output  	reg							new_pixel,
   output	reg							done
);

// States
localparam State0 = 6'b000001;	// Reset
localparam State1 = 6'b000010;	// Parameters init
localparam State2 = 6'b000100;	// Primary block loading
localparam State3 = 6'b001000;	// Watermark block loading
localparam State4 = 6'b010000;  // Parameters Calculation
localparam State5 = 6'b100000;	// Result Calculator
reg	[6-1:0]	curr_state;

//Internal signal declarations

integer row, col;

reg [Data_Depth-1:0] 	Primary_Block 		[Max_Block_Size-1:0]; 	// max 72*72 pixels
reg [Data_Depth-1:0] 	Watermark_Block 	[Max_Block_Size-1:0]; 	// max 72*72 pixels
reg	[13-1:0] 			index;										// max addr 72*72 = 5041 (13 bits)
reg						new_data;
	

// Parameters
reg [Data_Depth-1:0]	M; 				// Number of pixels per line
reg [Data_Depth-1:0]	White_Pixel;
reg [Data_Depth-1:0]	Np;
reg [Data_Depth-1:0]	Nw;
reg [Data_Depth-1:0]	A_min;
reg [Data_Depth-1:0]	A_max;
reg [Data_Depth-1:0]	B_min;
reg [Data_Depth-1:0]	B_max;
reg [Data_Depth-1:0]	Bthr;
	
reg	[Data_Depth-1:0]	Guk;
reg	[Data_Depth-1:0]	sk;
reg [Data_Depth-1:0]	uk;
reg [Data_Depth-1:0]	ak;
reg [Data_Depth-1:0]	bk;
reg [27-1:0]			sigma_G;		// max 720*720*255 = 132192000 (27 bits) - Sum for G
reg [27-1:0]			sigma_S;		// max 720*720*255 = 132192000 (27 bits) - Sum for Sigma
reg [27-1:0]			sigma_M;		// max 720*720*255 = 132192000 (27 bits) - Sum for Mu


always @(posedge clk or negedge rst) begin: parameter_calculator
	
	if (!rst) begin
		curr_state = State0;
	end
	
	if (en) begin
	
		if (curr_state == State0) begin 	//reset
			sigma_G <= 'd0;
			sigma_S <= 'd0;
			sigma_M <= 'd0;
			index 	<= 'd0;
			Guk		<= 'd0;
			sk		<= 'd0;
			uk		<= 'd0;
			ak		<= 'd0;
			bk		<= 'd0;
			done	<= 'b0;
			curr_state <= State1;
		end
		
		else if (curr_state == State1) begin 	// init
			if(index < 9) begin
				case(index)
					0: 	White_Pixel <= Pixel_in;
					1:	Np			<= Pixel_in;
					2:	Nw			<= Pixel_in;
					3:	M			<= Pixel_in;
					4:	Bthr		<= Pixel_in;
					5:	A_min		<= Pixel_in;
					6:	A_max		<= Pixel_in;
					7:	B_min		<= Pixel_in;
					8:	B_max		<= Pixel_in;
				endcase
				index <= index + 1;
			end
			else begin
				index <= 'd0;
				curr_state <= State2;
			end	
		end

		else if (curr_state == State2) begin 	// Primary_Block loading
			if (index < M * M) begin
				Primary_Block[index] <= Pixel_in;
				index <= index + 1;
			end
			else begin
				index <= 'd0;
				curr_state <= State3;
			end
		end
		
		else if (curr_state == State3) begin		// Watermark_Block loading
			if (index < M * M) begin
				Watermark_Block[index] <= Pixel_in;	
				index <= index + 1;
			end
			else begin
				index <= 'd0;
				curr_state <= State4;
			end
		end
		
		else if (curr_state == State4) begin	// Parameters calculation
			
			// Guk calculation
			for (row = 0; row < M; row = row + 1) begin
				for (col = 0; col < M; col = col + 1) begin
				
					sigma_M <= sigma_M + Primary_Block[col + row * M];
					
					sigma_S <= sigma_S + ((Primary_Block[col + row * M] - (White_Pixel/2) > 0) ? (Primary_Block[col + row * M] - 
							(White_Pixel/2)) : ((White_Pixel/2) - Primary_Block[col + row * M]));
							
					if ((row == M-1) && (col == M-1)) 
						sigma_G <= sigma_G + (2 * Primary_Block[col + row * M]);
					else if (row == M-1)
						sigma_G <= sigma_G + Primary_Block[col + row * M] + ((Primary_Block[col + row * M] - Primary_Block[(col+1) + row * M] > 0) 
								? (Primary_Block[col + row * M] - Primary_Block[(col+1) + row * M]) 
								: (Primary_Block[(col+1) + row * M] - Primary_Block[col + row * M]));
					else if (col == M-1)
						sigma_G <= sigma_G + Primary_Block[col + row * M] + ((Primary_Block[col + row * M] - Primary_Block[col + (row+1) * M] > 0) 
								? (Primary_Block[col + row * M] - Primary_Block[col + (row+1) * M]) 
								: (Primary_Block[col + (row+1) * M] - Primary_Block[col + row * M]));
					else
						sigma_G <= sigma_G + ((Primary_Block[col + row * M] - Primary_Block[col + (row+1) * M] > 0) 
								? (Primary_Block[col + row * M] - Primary_Block[col + (row+1) * M]) 
								: (Primary_Block[col + (row+1) * M] - Primary_Block[col + row * M])) +
								((Primary_Block[col + row * M] - Primary_Block[(col+1) + row * M] > 0) 
								? (Primary_Block[col + row * M] - Primary_Block[(col+1) + row * M]) 
								: (Primary_Block[(col+1) + row * M] - Primary_Block[col + row * M]));
				end
			end
			Guk <= sigma_G / (M*M);							// 0 - 255
			uk  <= (sigma_M*100) / (M*M*(White_Pixel+1));	// 0 - 100 (in reality 0 - 1 -> divide by 100)
			sk 	<= (sigma_S*2*100) / (M*M*(White_Pixel+1));	// 0 - 100 (in reality 0 - 1 -> divide by 100)
			
			// Final Equation
			if (Guk >= Bthr) begin
				ak <= A_max;
				bk <= B_min;
			end
			else begin // need to calculate ak and bk
				if(sk) begin
					ak <= A_min + (((A_max - A_min) / (2**((uk - 50) * (uk - 50) / (100*100)))) / sk);
					bk <= B_min + sk * ((B_max - B_min) * (100 - (100 / (2**((uk - 50) * (uk - 50) / (100*100))))));
				end
				else begin
					ak <= A_min + ((A_max - A_min) / (2**((uk - 50) * (uk - 50) / (100*100))));
					bk <= B_min + ((B_max - B_min) * (100 - (100 / (2**((uk - 50) * (uk - 50) / (100*100))))));
				end
			end
			index <= 'd0;
			curr_state <= State5;
		end	
		else if (curr_state == State5) begin	// Result calculator
			if (index < M * M) begin
				Pixel_Data <= ak * Primary_Block[index] + bk * Watermark_Block[index];
				new_pixel <= ~new_pixel;	// Switch to trigger the test bench that new data arrived
				index <= index + 1;
			end
			else begin	// All the result block has been sent
				done <= 1'b1;
				index <= 'd0;
				curr_state <= State0;
			end
		end	
	end
end	

endmodule // Block_Divider
