# Watermarking

Problems:
	Doesn't read the first pixel of the watermark_img ==> tb_watermarking ?
	Redo all the parameters calculation in Block_divider to work with non blocking assignments :
		do one step of the calculation every iterations
	Check in every state that the change occurs at the clock before