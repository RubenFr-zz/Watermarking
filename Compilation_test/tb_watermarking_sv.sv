
`timescale 1ns/1ns

module tb_Visibal_Watermarking(/*AUTOARG*/);

`define NULL 0

localparam Amba_Word = 16;			// Size of every data reg
localparam Amba_Addr_Depth = 20;	// Size of the data bank 
localparam Data_Depth = 8;			// Bit depth of the pixel
localparam Block_Depth = 7;			// Max pixel per row/colomn in block is 72 (7 bits)
localparam Max_Block_Size = 5184;	// Max pixels that a block can countain (720 / 10)^2 = 5184
localparam Max_Img_Size = 720;

integer fd, index;
integer i = 0, img = 1;
integer tmp1, param;
integer count=0, row=0, col=0, offset=0;

string  str0 = "C:/Users/Ruben/Documents/Workspace/HDS/Visibal_Watermarking/Matlab/primary_image_";
string  str1 = "C:/Users/Ruben/Documents/Workspace/HDS/Visibal_Watermarking/Matlab/watermark_image_";
string  str2 = "C:/Users/Ruben/Documents/Workspace/HDS/Visibal_Watermarking/Matlab/parameters_random_value_";
string 	str3 = "C:/Users/Ruben/Documents/Workspace/HDS/Visibal_Watermarking/Matlab/watermarked_image(result)_";
string 	str4 = "C:/Users/Ruben/Documents/Workspace/HDS/Visibal_Watermarking/Matlab/output_";
string 	val;

reg [10-1:0] Np = Max_Img_Size;
reg [10-1:0] Nw = Max_Img_Size;
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

initial begin: init

	clk = 0;
	PENABLE = 0;
	PSEL = 0;
	PWRITE = 0;
	PWDATA = 0;
	PADDR = 0;
	start = 0;
	
	val.itoa(img);
	
	// Read and Store the primary image
	fd = $fopen($sformatf({str0, val, ".txt"}), "r");
	
	if (fd == `NULL) begin 	// checking if we managed to open it
		$display("Couldn't open %s", str0);
		$finish;
    end
	
    if (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", Np);
    end
	
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", PrimaryImg[i]);
		i = i +1;
	end
	$fclose(fd);
	i = 0;
	
	
	// Read and Store the watermark image
	fd = $fopen($sformatf({str1, val, ".txt"}), "r");
	
	if (fd == `NULL) begin
		$display("Couldn't open %s", str1);
		$finish;
    end
	
    if (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", Nw);
    end
	
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", WatermarkImg[i]);
		i = i +1;
	end
	$fclose(fd);
	i = 0;
	
	
	// Read the Parameters
	fd = $fopen($sformatf({str2, val, ".txt"}), "r");
	
	if (fd == `NULL) begin 
		$display("Couldn't open %s", str2);
		$finish;
    end
	
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d", param);
		case(i)
			0: 	M = param;
			1:	Bthr = param;
			2:	Amin = param;
			3:	Amax = param;
			4: 	Bmin = param;
			5: 	Bmax = param;
		endcase
		i = i +1;
	end
	$fclose(fd);
	i = 0;
	
	
	// Read and Store the GoldenRatio result
	fd = $fopen($sformatf({str3, val, ".txt"}), "r");
	
	if (fd == `NULL) begin 
		$display("Couldn't open %s", str2);
		$finish;
    end
	
	while (!$feof(fd)) begin
		tmp1 = $fscanf(fd, "%d\n", CorrectResults[i]);
		i = i +1;
	end
	$fclose(fd);
	
	//Open the file to write the output
	fd = $fopen($sformatf({str4, val, ".txt"}), "w");
	
	
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
	
	if (start == 1) 
	begin
		if (Image_Done) 
		begin
			for (i = 0; i < Np*Np; i = i+1) 
			begin
				$fwrite(fd,"%d\n", Output[i]);
			end
			$display("The image has been Watermarked!");
			$fclose(fd);
			$finish;
		end
		
		PWRITE <= 'b0;
		PSEL <= 'b0;		// release the CPU
		PENABLE <= 'b0;
	end
	
	if (PENABLE) 
	begin
		if (i < 10 + (Np*Np + Nw*Nw)) 
		begin 
			if (i < 10) 	//parameters
			begin
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
			else if (i < 10 + Np*Np)  	// primary_img
				PWDATA <= PrimaryImg[i-10];
			else  						// Watermark_img
				PWDATA <= WatermarkImg[i - 10 - Np*Np];
			
			PADDR <= i;
			i <= i + 1;
		end
		else 
		begin
			PWDATA = 1;
			PADDR = 0;
			start = 1;
		end
	end
end

always @(negedge new_pixel) begin: PixelData_Reading
	if (!Image_Done) 
	begin
		Output[offset + col + row * Np] <= PixelData;
		
		if (col + 1 == M) 			// Next col isn't in the block
		begin
			col <= 0;
			if (row + 1 == M) 		// Next row isn't in the block
			begin
				row <= 0;
				count <= count + 1;
				offset <= offset + (((count + 1) % (Np/M) == 0) ? Np*(M-1)+M : M);	// First pixel of next primary block
			end
			else
				row <= row + 1;
		end
		else 
			col <= col + 1;
			
		// $display("Output[%d] = %d", offset + col + row * Np, PixelData );
	end
end

always #2 begin: clock
	clk = ~clk;
end

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
