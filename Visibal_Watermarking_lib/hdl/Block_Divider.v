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

localparam Max_Size_DATA = 3*3; // M*M

//Internal signal declarations

integer row, col;

// reg [Data_Depth-1:0] 	Primary_Block 		[Max_Block_Size-1:0]; 	// max 72*72 pixels
// reg [Data_Depth-1:0] 	Watermark_Block 	[Max_Block_Size-1:0]; 	// max 72*72 pixels
reg [Data_Depth-1:0] 	Primary_Block 		[Max_Size_DATA-1:0]; 	// max 72*72 pixels
reg [Data_Depth-1:0] 	Watermark_Block 	[Max_Size_DATA-1:0]; 	// max 72*72 pixels
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
	
	if (rst) begin
		curr_state = State0;
	end
	
	else if (en) begin
	
		if (curr_state == State0) begin 	//reset
			sigma_G <= 0;
			sigma_S <= 0;
			sigma_M <= 0;
			index 	<= 0;
			Guk		<= 0;
			sk		<= 0;
			uk		<= 0;
			ak		<= 0;
			bk		<= 0;
			done	<= 0;
			if (done)
				curr_state <= State2;
			else begin
				curr_state <= State1;
			end
		end
		
		else if (curr_state == State1) begin 	// init
			
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
			
			if (index + 1 < 9) 
				index <= index + 1;
			else begin
				index <= 0;
				curr_state <= State2;
			end
		end

		else if (curr_state == State2) begin 	// Primary_Block loading
			Primary_Block[index] <= Pixel_in;
			if (index < (M * M) - 1) begin		
				index <= index + 1;
			end
			else begin					// Next pixel is the first of Watermark_Block
				index <= 0;
				curr_state <= State3;
			end
			
			
			/////////////////////////////////////////////////////////////////////////
			/* Sigma_M - Eqn3 */
			sigma_M <= sigma_M + Pixel_in;
			/* Sigma_S - Eqn4 */
			sigma_S <= sigma_S + ((Pixel_in > ((White_Pixel+1)/2)) 
									? (Pixel_in - ((White_Pixel+1)/2)) 
									: (((White_Pixel+1)/2) - Pixel_in));
			/* Sigma_G - Eqn5 */
			if (index == 0) 
				continue;
			else if (index < M) begin					// row = 0, col > 0 - There is a pixel on the left
				sigma_G <= sigma_G + Pixel_in + 
									((Primary_Block[index - 1] > Pixel_in) 
									? (Primary_Block[index - 1] - Pixel_in) 
									: (Pixel_in - Primary_Block[index - 1]));
			end
			else if (index == (M*M) - 1) begin
				sigma_G <= sigma_G + Pixel_in + Pixel_in +
									((Primary_Block[index - 1] > Pixel_in) 
									? (Primary_Block[index - 1] - Pixel_in) 
									: (Pixel_in - Primary_Block[index - 1])) +
									((Primary_Block[index - M] > Pixel_in) 
									? (Primary_Block[index - M] - Pixel_in) 
									: (Pixel_in - Primary_Block[index - M]));
			end
			else if (index % M == 0 ) begin 			// col = 0 (row > 0) - There is a pixel above
				sigma_G <= sigma_G + Pixel_in +
									((Primary_Block[index - M] > Pixel_in) 
									? (Primary_Block[index - M] - Pixel_in) 
									: (Pixel_in - Primary_Block[index - M]));
			end
			else begin									// col > 0, row > 0 - There is a pixel above and on the left
				sigma_G <= sigma_G + ((Primary_Block[index - 1] > Pixel_in) 
									? (Primary_Block[index - 1] - Pixel_in) 
									: (Pixel_in - Primary_Block[index - 1])) +
									((Primary_Block[index - M] > Pixel_in) 
									? (Primary_Block[index - M] - Pixel_in) 
									: (Pixel_in - Primary_Block[index - M]));
			end
			/////////////////////////////////////////////////////////////////////////
		end
		
		else if (curr_state == State3) begin		// Watermark_Block loading
			
			Watermark_Block[index] <= Pixel_in;	
			
			if (index + 1 < M * M) 
				index <= index + 1;
			else begin 								// At this stage everything is ready !
				
				Guk <= sigma_G / (M*M);							// 0 - 255
				uk  <= (sigma_M*100) / (M*M*(White_Pixel+1));	// 0 - 100 (in reality 0 - 1 -> divide by 100)
				sk 	<= (sigma_S*2*100) / (M*M*(White_Pixel+1));	// 0 - 100 (in reality 0 - 1 -> divide by 100)
				
				index <= 0;
				curr_state <= State4;
			end
		end
		
		else if (curr_state == State4) begin	// ak, bk
			if (Guk >= Bthr) begin
				ak <= A_max;
				bk <= B_min;
			end
			else begin // need to calculate ak and bk
				if(sk != 0) begin
					ak <= A_min + (((A_max - A_min) / (2**((uk - 50) * (uk - 50) / (100*100)))) / sk);
					bk <= B_min + sk * ((B_max - B_min) * (100 - (100 / (2**((uk - 50) * (uk - 50) / (100*100))))));
				end
				else begin
					ak <= A_min + ((A_max - A_min) / (2**((uk - 50) * (uk - 50) / (100*100))));
					bk <= B_min + ((B_max - B_min) * (100 - (100 / (2**((uk - 50) * (uk - 50) / (100*100))))));
				end
			end
			index = 0;
			curr_state <= State5;
		end	
		
		else if (curr_state == State5) begin	// Result calculator
			
			Pixel_Data <= (((ak * Primary_Block[index] + bk * Watermark_Block[index]) / 100) < 255)
							? ((ak * Primary_Block[index] + bk * Watermark_Block[index]) / 100)
							: 255;
			new_pixel <= 1'b1;	// Switch to trigger the test bench that new data arrived
			
			if (index + 1 < M * M) begin	
				index <= index + 1;
			end
			else begin		// All the result block has been sent
				done <= 1'b1;
				curr_state <= State0;
			end
		end	
	end
end	

always @(negedge clk)begin: trigger
	if(new_pixel)
		new_pixel <= ~new_pixel;
end

endmodule // Block_Divider
