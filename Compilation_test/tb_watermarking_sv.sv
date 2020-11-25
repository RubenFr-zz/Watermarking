
`timescale 1ns/1ns

module tb_watermarking(/*AUTOARG*/);

localparam Amba_Word = 16;			// Size of every data reg
localparam Amba_Addr_Depth = 20;	// Size of the data bank 
localparam Data_Depth = 8;			// Bit depth of the pixel
localparam Block_Depth = 7;			// Max pixel per row/colomn in block is 72 (7 bits)
localparam Max_Block_Size = 5184;	// Max pixels that a block can countain (720 / 10)^2 = 5184

integer fd, index;
integer i = 0, count = 0;
integer tmp1, tmp2;

integer test;

reg [9-1:0] Np = 4;
reg [9-1:0] Nw = 4;
reg [Data_Depth-1:0] M = 2;
reg [Data_Depth-1:0] Bthr = 20;
reg [Data_Depth-1:0] Amin = 83;
reg [Data_Depth-1:0] Amax = 96;
reg [Data_Depth-1:0] Bmin = 25;
reg [Data_Depth-1:0] Bmax = 31;
reg [Data_Depth-1:0] Iwhite = 255;

reg	[Data_Depth-1:0] PrimaryImg [400-1:0];
reg	[Data_Depth-1:0] WatermarkImg [400-1:0];
reg [Data_Depth-1:0] CorrectResults [400-1:0];
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
reg  [Amba_Addr_Depth:0] 		PADDR;

wire  [Amba_Word-1:0] 			PRDATA;
wire  [Data_Depth-1:0] 			Pixel_Data;
wire					 		Image_Done;
wire					 		new_pixel;

initial begin

	$display("start");

	clk = 0;
	PENABLE = 0;
	PSEL = 0;
	PWRITE = 0;
	PWDATA = 0;
	PADDR = 0;
	start = 0;
	
	fd = $fopen("C:\\Users\\Ruben\\Documents\\Workspace\\HDS\\Visibal_Watermarking\\Matlab\\primary_image_3.txt", "r");
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", PrimaryImg[i]);
		i = i +1;
	end
	i = 0;
	
	fd = $fopen("C:\\Users\\Ruben\\Documents\\Workspace\\HDS\\Visibal_Watermarking\\Matlab\\watermark_image_3.txt", "r");
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", WatermarkImg[i]);
		i = i +1;
	end
	i = 0;
	
	fd = $fopen("C:\\Users\\Ruben\\Documents\\Workspace\\HDS\\Visibal_Watermarking\\Matlab\\watermarked_image(result)_3.txt","r");
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", CorrectResults[i]);
		i = i +1;
	end
	
	i = 1;
	rst = 1;
	#4 rst = 0;
	// Start loading data
	PWRITE = 1;	// write
	PSEL = 1;
	PADDR = 0;
	PWDATA = 0;
	PENABLE = 1;
end

always @(posedge clk) begin: load_pixel
	
	if (start == 1) begin
		PWRITE = 'b0;
		PSEL = 'b0;		// release the CPU
		PENABLE = 'b0;
	end
	
	if (PENABLE) begin
		if (i < 11 + (Np*Np + Nw*Nw)) begin 
			if (i < 10) begin	//parameters
				case(i)
					1: PWDATA = Iwhite;
					2: PWDATA = Np;
					3: PWDATA = Nw;
					4: PWDATA = M;
					5: PWDATA = Bthr;
					6: PWDATA = Amin;
					7: PWDATA = Amax;
					8: PWDATA = Bmin;
					9: PWDATA = Bmax;
				endcase	
			end
			else if (i < 11 + Np*Np) begin// primary_img
				index = i - 10;
				PWDATA = PrimaryImg[index][Data_Depth-1:0];
			end
			else begin	// Watermark_img
				index = i - 10 - Np*Np;
				PWDATA = WatermarkImg[index][Data_Depth-1:0];
			end	
			PADDR = i;
			i = i + 1;
			test = (10 + Np*Np);
		end
		else begin
			PWDATA = 1;
			PADDR = 0;
			start = 1;
		end
	end
end

always @(new_pixel) begin
	
	// if (CorrectResults[count] == Pixel_Data) 
      // $write ("TestBench for image: true") ;
    // else
      // $write ("TestBench for image: false, ERROR = %d", CorrectResults[i] - Pixel_Data);
    if (!Image_Done) begin
		count = count + 1;
	end
	
end

always #2 clk = ~clk;
// always #4 PENABLE = ~PENABLE;

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
