
`timescale 1ns/1ns

module tb_watermarking(/*AUTOARG*/);

localparam Amba_Word = 16;			// Size of every data reg
localparam Amba_Addr_Depth = 20;	// Size of the data bank 
localparam Data_Depth = 8;			// Bit depth of the pixel
localparam Block_Depth = 7;			// Max pixel per row/colomn in block is 72 (7 bits)
localparam Max_Block_Size = 5184;	// Max pixels that a block can countain (720 / 10)^2 = 5184

integer fd;
integer i = 0, count = 0;
integer tmp1, tmp2;

reg [Data_Depth-1:0] M = 1;
reg [Data_Depth-1:0] Np = 20*20;
reg [Data_Depth-1:0] Nw = 20*20;
reg [Data_Depth-1:0] Bthr = 20;
reg [Data_Depth-1:0] Amin = 83;
reg [Data_Depth-1:0] Amax = 96;
reg [Data_Depth-1:0] Bmin = 25;
reg [Data_Depth-1:0] Bmax = 31;
reg [Data_Depth-1:0] Iwhite = 255;

reg	[Data_Depth-1:0] PrimaryImg [401-1:0];
reg	[Data_Depth-1:0] WatermarkImg [401-1:0];
reg [Data_Depth-1:0] CorrectResults [401-1:0];
reg [Data_Depth-1:0] data;
reg [Data_Depth-1:0] str;

reg start = 0;

//Visual_Watermarking inputs/outputs
reg    							clk;
reg    							rst;

reg    							PENABLE;
reg    							PSEL;
reg    							PWRITE;
reg  [Amba_Word-1:0] 			PWDATA;
reg  [Amba_Addr_Depth:0] 	PADDR;

wire  [Amba_Word-1:0] 			PRDATA;
wire  [Data_Depth-1:0] 			Pixel_Data;
wire					 		Image_Done;
wire					 		new_pixel;

initial begin
	fd = $fopen("C:\Users\Ruben\Documents\Workspace\HDS\Visibal_Watermarking\Matlab\primary_image_3.txt", "r");
	while (!$feof(fd)) begin
		tmp1 = $fgets(str, fd);
		tmp2 = $sscanf(str, "%d", data);
		PrimaryImg[i] = data;
		i = i +1;
	end
	i = 0;
	
	fd = $fopen("C:\Users\Ruben\Documents\Workspace\HDS\Visibal_Watermarking\Matlab\watermark_image_3.txt", "r");
	while (!$feof(fd)) begin
		tmp1 = $fgets(str, fd);
		tmp2 = $sscanf(str, "%d", data);
		WatermarkImg[i] = data;
		i = i +1;
	end
	i = 0;
	
	fd = $fopen("C:\Users\Ruben\Documents\Workspace\HDS\Visibal_Watermarking\Matlab\watermarked_image(result)_3.txt","r");
	while (!$feof(fd)) begin
		tmp1 = $fgets(str, fd);
		tmp2 = $sscanf(str, "%d", data);
		CorrectResults[i] = data;
		i = i +1;
	end
	i = 0;
	
	clk = 0;
	data = 0;
	i = 1;
	tmp1 = 1;
	rst = 1'b1;
	#4 rst = 0;
	//insert Start_work = 0
	PWRITE = 'b1;
	PSEL = 'b1;
	PENABLE = 'b0;
	PADDR = 0;
	PWDATA = {Amba_Word{1'b0}};
end

always @(posedge PENABLE) begin: load_pixel
	
	if (start) begin
		PWRITE = 'b0;
		PSEL = 'b0;		// release the CPU
	end
	
	if (i < 10 + (Np*Np + Nw*Nw)) begin 
		if (i < 10) begin	//parameters
			case(i)
				1: PWDATA = Iwhite[Data_Depth-1:0];
				2: PWDATA = Np[Data_Depth-1:0];
				3: PWDATA = Nw[Data_Depth-1:0];
				4: PWDATA = M[Data_Depth-1:0];
				5: PWDATA = Bthr[Data_Depth-1:0];
				6: PWDATA = Amin[Data_Depth-1:0];
				7: PWDATA = Amax[Data_Depth-1:0];
				8: PWDATA = Bmin[Data_Depth-1:0];
				9: PWDATA = Bmax[Data_Depth-1:0];
			endcase
		end
		else if (i < 10 + Np*Np) // primaryimg
			PWDATA = PrimaryImg[i - 10][Data_Depth-1:0];
		else	// Watermarkimg
			PWDATA = WatermarkImg[i - 10 - Np*Np][Data_Depth-1:0];
			
		PADDR = i;
		i = i + 1;
	end
	else begin
		PWDATA = 1;
		PADDR = 0;
		start = 1;
	end
end

always @(new_pixel) begin: checker
	
	// if (CorrectResults[count] == Pixel_Data) 
      // $write ("TestBench for image: true") ;
    // else
      // $write ("TestBench for image: false, ERROR = %d", CorrectResults[i] - Pixel_Data);
    if (!Image_Done) begin
		count = count + 1;
	end
	
end

always #2 clk = ~clk;
always #2 PENABLE = ~PENABLE;

Visibal_Watermarking #(.Amba_Word(Amba_Word), .Amba_Addr_Depth(Amba_Addr_Depth), .Data_Depth(Data_Depth), 						.Block_Depth(Block_Depth), .Max_Block_Size(Max_Block_Size)) Visibal_Watermarking_1
(
        .clk (clk),
        .rst(rst),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
		.Image_Done(Image_Done), 	// State indicator
		.Pixel_Data(Pixel_Data), 	// Modified pixel 
		.new_pixel(new_pixel)		// New Pixel Indicator 
);

endmodule