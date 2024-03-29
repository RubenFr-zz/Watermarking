
`timescale 1ns/1ns

module tb_Visibal_Watermarking(/*AUTOARG*/);

localparam Amba_Word = 16;			// Size of every data reg
localparam Amba_Addr_Depth = 20;	// Size of the data bank 
localparam Data_Depth = 8;			// Bit depth of the pixel
localparam Block_Depth = 7;			// Max pixel per row/colomn in block is 72 (7 bits)
localparam Max_Block_Size = 5184;	// Max pixels that a block can countain (720 / 10)^2 = 5184
localparam Max_Img_Size = 12;

integer fd, index;
integer i = 0;
integer tmp1, tmp2;
integer count=0, row=0, col=0, offset=0;

integer test;

reg [9-1:0] Np = Max_Img_Size;
reg [9-1:0] Nw = Max_Img_Size;
reg [Data_Depth-1:0] M = 3;
reg [Data_Depth-1:0] Bthr = 20;
reg [Data_Depth-1:0] Amin = 83;
reg [Data_Depth-1:0] Amax = 96;
reg [Data_Depth-1:0] Bmin = 25;
reg [Data_Depth-1:0] Bmax = 31;
reg [Data_Depth-1:0] Iwhite = 255;

reg	[Data_Depth-1:0] PrimaryImg [(Max_Img_Size*Max_Img_Size)-1:0];
reg	[Data_Depth-1:0] WatermarkImg [(Max_Img_Size*Max_Img_Size)-1:0];
reg [Data_Depth-1:0] CorrectResults [(Max_Img_Size*Max_Img_Size)-1:0];
reg [Data_Depth-1:0] Output [(Max_Img_Size*Max_Img_Size)-1:0];
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
wire  [Data_Depth-1:0] 			PixelData;
wire					 		Image_Done;
wire					 		new_pixel;

initial begin

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
	
	fd = $fopen("C:\\Users\\Ruben\\Documents\\Workspace\\HDS\\Visibal_Watermarking\\output.txt","w");
	
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
		if (Image_Done) begin
			for (i = 0; i < Np*Np; i = i+1) begin
				$fwrite(fd,"%d\n", Output[i]);
			end
			$display("FINISHED");
			$finish;
		end
		PWRITE <= 'b0;
		PSEL <= 'b0;		// release the CPU
		PENABLE <= 'b0;
	end
	
	if (PENABLE) begin
		if (i < 10 + (Np*Np + Nw*Nw)) begin 
			if (i < 10) begin	//parameters
				case(i)
					1: PWDATA <= Iwhite;
					2: PWDATA <= Np;
					3: PWDATA <= Nw;
					4: PWDATA <= M;
					5: PWDATA <= Bthr;
					6: PWDATA <= Amin;
					7: PWDATA <= Amax;
					8: PWDATA <= Bmin;
					9: PWDATA <= Bmax;
				endcase	
			end
			else if (i < 10 + Np*Np) begin // primary_img
				
				PWDATA <= PrimaryImg[i-10];
			end
			else begin 	// Watermark_img
				PWDATA <= WatermarkImg[i - 10 - Np*Np];
			end
			PADDR <= i;
			i <= i + 1;
		end
		else begin
			PWDATA = 1;
			PADDR = 0;
			start = 1;
		end
	end
end

always @(negedge new_pixel) begin
	if (!Image_Done) begin
		Output[offset + col + row * Np] <= PixelData;
		
		if (col + 1 == M) begin		// Next col isn't in the block
			col <= 0;
			if (row + 1 == M) begin		// Next row isn't in the block
				row <= 0;
				count <= count + 1;
				offset <= offset + (((count + 1) % (Np/M) == 0) ? Np*(M-1)+M : M);	// First pixel of next primary block
			end
			else begin
				row <= row + 1;
			end
		end
		else 
			col <= col + 1;
			
		$display("Output[%d] = %d", offset + col + row * Np, PixelData );
	end

end

always #2 clk = ~clk;

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
		.Pixel_Data(PixelData), 	// Modified pixel 
		.new_pixel(new_pixel)		// New Pixel Indicator 
);

endmodule
