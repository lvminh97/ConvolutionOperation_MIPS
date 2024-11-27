.data
	image:		.space  	900
	kernel:		.space		64
	out:		.space		784
	input_filename:		.asciiz		"input_matrix.txt"
	output_filename:	.asciiz		"output_matrix.txt"
	buffer:			.space		1024
	N:			.word		0
	M:			.word		0
	p:			.word		0
	s:			.word		0
	newN:			.word		0
	outN:			.word		0
	float_0:		.float		0
	float_1:		.float		1
	float_10:		.float		10
	float_neg1:		.float		-1
.text
main:
	# read data
	jal read_input_file
	
	jal convolution
	
	jal write_file
	
	main_exit:
		li $v0, 10		# exit with value 0 (success)
		syscall
		
# read data from input file
read_input_file:
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s6, 16($sp)
	sw $s7, 20($sp)
	
	# open file
	li $v0, 13
	la $a0, input_filename
	li $a1, 0
	li $a2, 0
	syscall
	move $s7, $v0			# save the file descriptor
	
	# read the content of file to buffer
	li $v0, 14
	move $a0, $s7
	la $a1, buffer
	li $a2, 1024
	syscall
	move $s6, $v0			# the length of file's content
	
	# close the file
	move $a0, $s7
	li $v0, 16
	syscall
	
	# read N
	la $a0, buffer
	jal read_int
	sw $v0, N
	move $s0, $v1
	
	# read M
	move $a0, $s0
	jal read_int
	sw $v0, M
	move $s0, $v1
	
	# read p
	move $a0, $s0
	jal read_int
	sw $v0, p
	move $s0, $v1
	
	# read s
	move $a0, $s0
	jal read_int
	sw $v0, s
	move $s0, $v1

	lw $t0, N
	lw $t1, p
	mul $t1, $t1, 2
	add $t0, $t0, $t1
	sw $t0, newN
	
	# read image matrix
	read_image_matrix_init:
		lw $s1, N
		mul $s1, $s1, $s1
		li $s2, 0
	read_image_matrix_loop:
		bge $s2, $s1, read_kernel_matrix_init
		move $a0, $s0
		jal read_float
		move $s0, $v1
		move $a0, $s2
		jal compute_input_image_matrix_index
		la $t0, image
		add $t0, $t0, $v0
		swc1 $f12, 0($t0)
		addi $s2, $s2, 1
		j read_image_matrix_loop
	
	# read kernel matrix
	read_kernel_matrix_init:
		lw $s1, M
		mul $s1, $s1, $s1
		li $s2, 0		
	read_kernel_matrix_loop:
		bge $s2, $s1, read_input_file_ret
		move $a0, $s0
		jal read_float
		move $s0, $v1
		la $t0, kernel
		move $t1, $s2
		mul $t1, $t1, 4
		add $t0, $t0, $t1
		swc1 $f12, 0($t0)
		addi $s2, $s2, 1
		j read_kernel_matrix_loop
	read_input_file_ret:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s6, 16($sp)
		lw $s7, 20($sp)
		addi $sp, $sp, 24
		jr $ra		

read_int:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	move $s1, $a0
	
	read_int_trim:
		lb $t1, 0($s1)
		beq $t1, 0, read_int_null
		blt $t1, 0x30, read_int_trim_next
		bgt $t1, 0x39, read_int_trim_next
		j read_int_start
		read_int_trim_next:
			addi $s1, $s1, 1
			j read_int_trim	
	read_int_start:
		li $s0, 0
	read_int_loop:
		lb $t1, 0($s1)
		beq $t1, 0, read_int_finish
		blt $t1, 0x30, read_int_finish
		bgt $t1, 0x39, read_int_finish
		mul $s0, $s0, 10
		addi $t1, $t1, -0x30
		add $s0, $s0, $t1
		addi $s1, $s1, 1
		j read_int_loop				
	read_int_finish:
		move $v0, $s0
		move $v1, $s1
		j read_int_ret
	read_int_null:
		li $v1, -1	
	read_int_ret:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra	

read_float:
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	swc1 $f0, 4($sp)
	swc1 $f1, 8($sp)
	swc1 $f2, 12($sp)
	swc1 $f3, 16($sp)
	swc1 $f4, 20($sp)
	swc1 $f5, 24($sp)
	swc1 $f6, 28($sp)
	sw $s0, 32($sp)
	
	move $s0, $a0
	
	read_float_trim:		
		lb $t1, 0($s0)
		beq $t1, 0, read_float_null
		beq $t1, 0x20, read_float_trim_next		# space
		beq $t1, 0x0d, read_float_trim_next		# '\r'
		beq $t1, 0x0a, read_float_trim_next		# '\n'
		j read_float_start
		read_float_trim_next:
			addi $s0, $s0, 1
			j read_float_trim
	read_float_start:
		lwc1 $f0, float_0
		lwc1 $f1, float_1				# sign
		lwc1 $f2, float_1				# dividen
		lwc1 $f3, float_10
		lwc1 $f6, float_1
	read_float_loop:
		lb $t1, 0($s0)
		beq $t1, 0, read_float_finish
		beq $t1, 0x20, read_float_finish		# space
		beq $t1, 0x0d, read_float_finish		# '\r'
		beq $t1, 0x0a, read_float_finish		# '\n'
		beq $t1, 0x2e, read_float_after_point		# '.'
		beq $t1, 0x2d, read_float_sign			# '-'
		addi $t1, $t1, -0x30
		mtc1 $t1, $f4
		cvt.s.w $f5, $f4
		c.eq.s $f2, $f6
		bc1t read_float_number_part
		bc1f read_float_fraction_part
	read_float_number_part:
		mul.s $f0, $f0, $f3
		add.s $f0, $f0, $f5
		j read_float_loop_next
	read_float_fraction_part:	
		div.s $f5, $f5, $f2
		add.s $f0, $f0, $f5
		mul.s $f2, $f2, $f3	
	read_float_loop_next:
		addi $s0, $s0, 1
		j read_float_loop
	read_float_sign:
		lwc1 $f1, float_neg1
		j read_float_loop_next
	read_float_after_point:
		mul.s $f2, $f2, $f3
		j read_float_loop_next
	read_float_finish:
		mul.s $f12, $f0, $f1
		move $v1, $s0
		j read_float_ret						
	read_float_null:
		li $v1, -1
	read_float_ret:
		lw $ra, 0($sp)
		lwc1 $f0, 4($sp)
		lwc1 $f1, 8($sp)
		lwc1 $f2, 12($sp)
		lwc1 $f3, 16($sp)
		lwc1 $f4, 20($sp)
		lwc1 $f5, 24($sp)
		lwc1 $f6, 28($sp)
		lw $s0, 32($sp)
		addi $sp, $sp, 36
		jr $ra

compute_input_image_matrix_index:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	move $t0, $a0
	lw $t1, N
	div $t0, $t1
	mfhi $t2
	mflo $t3
	lw $t4, p
	lw $t5, newN
	add $t3, $t3, $t4
	mul $t5, $t5, $t3
	add $t5, $t5, $t4
	add $t5, $t5, $t2
	mul $t5, $t5, 4
	move $v0, $t5
	compute_input_image_matrix_index_ret:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra		

compute_matrix_index:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	
	move $s0, $a0	# n
	move $s1, $a1	# row
	move $s2, $a2	# col
	
	mul $s0, $s0, $s1
	add $s0, $s0, $s2
	mul $s0, $s0, 4
	
	compute_matrix_index_ret:
		move $v0, $s0
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra

convolution:
	addi $sp, $sp, -48
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	swc1 $f0, 36($sp)
	swc1 $f1, 40($sp)
	swc1 $f2, 44($sp)
	
	lw $s0, newN
	lw $s1, M
	lw $s2, s
	sub $s0, $s0, $s1	# s0 = newN - M
	div $s0, $s0, $s2	# s0 = (newN - M) / s
	addi $s0, $s0, 1
	sw $s0, outN
	lw $s7, newN
	
	convolution_loop1_init:
		li $s3, 0
	convolution_loop1:
		bge $s3, $s0, convolution_ret
		convolution_loop2_init:
			li $s4, 0
		convolution_loop2:
			bge $s4, $s0, convolution_loop2_finish
			convolution_loop3_init:
				lwc1 $f0, float_0	# sum = 0
				li $s5, 0
			convolution_loop3:
				bge $s5, $s1, convolution_loop3_finish
				convolution_loop4_init:
					li $s6, 0
				convolution_loop4:
					bge $s6, $s1, convolution_loop4_finish				
					move $a0, $s1
					move $a1, $s5
					move $a2, $s6
					jal compute_matrix_index
					move $t1, $v0
					la $t0, kernel
					add $t0, $t0, $v0					
					lwc1 $f1, 0($t0)	# kernel[m][n]
										
					move $a1, $s3
					mul $a1, $a1, $s2
					add $a1, $a1, $s5
					move $a2, $s4
					mul $a2, $a2, $s2
					add $a2, $a2, $s6
					move $a0, $s7
					jal compute_matrix_index
					la $t0, image
					add $t0, $t0, $v0
					lwc1 $f2, 0($t0)	# input[i * stride + m][j * stride + n]
					
					mul.s $f1, $f1, $f2
					add.s $f0, $f0, $f1
															
					addi $s6, $s6, 1
					j convolution_loop4
				convolution_loop4_finish:
					addi $s5, $s5, 1
					j convolution_loop3
			convolution_loop3_finish:
				move $a0, $s0
				move $a1, $s3
				move $a2, $s4
				jal compute_matrix_index
				la $t0, out
				add $t0, $t0, $v0
				swc1 $f0, 0($t0)
				
				addi $s4, $s4, 1
				j convolution_loop2
		convolution_loop2_finish:
			addi $s3, $s3, 1
			j convolution_loop1
	convolution_ret:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		lw $s4, 20($sp)
		lw $s5, 24($sp)
		lw $s6, 28($sp)
		lw $s7, 32($sp)
		lwc1 $f0, 36($sp)
		lwc1 $f1, 40($sp)
		lwc1 $f2, 44($sp)
		addi $sp, $sp, 48
		jr $ra
		
format_float:
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	swc1 $f0, 16($sp)
	swc1 $f1, 20($sp)
	swc1 $f2, 24($sp)
	swc1 $f3, 28($sp)


	lwc1 $f2, float_0
	lwc1 $f3, float_neg1
	mov.s $f0, $f12
	
	la $s0, buffer
	c.lt.s $f0, $f2
	bc1f format_float_loop1_init
	format_float_nega:
		li $t0, 0x2d
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		mul.s $f0, $f0, $f3
	format_float_loop1_init:
		li $s2, 1
		cvt.w.s $f1, $f0
		mfc1 $s1, $f1
	format_float_loop1:
		div $s1, $s1, $s2
		beq $s1, 0, format_float_loop1_finish
		mul $s2, $s2, 10
		j format_float_loop1
	format_float_loop1_finish:
		div $s2, $s2, 10
		
	format_float_loop2_init:
		mfc1 $s1, $f1
	format_float_loop2:
		div $s1, $s2
		mfhi $s1
		mflo $t0
		addi $t0, $t0, 0x30
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		div $s2, $s2, 10
		beq $s2, 0, format_float_loop2_finish
		j format_float_loop2
	format_float_loop2_finish:
		li $t0, 0x2e
		sb $t0, 0($s0)
		addi $s0, $s0, 1
	format_float_fractal:
		lwc1 $f2, float_10
		mul.s $f0, $f0, $f2
		cvt.w.s $f1, $f0
		mfc1 $t0, $f1
		li $t1, 10
		div $t0, $t1
		mfhi $t0
		addi $t0, $t0, 0x30
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		mul.s $f0, $f0, $f2
		cvt.w.s $f1, $f0
		mfc1 $t0, $f1
		li $t1, 10
		div $t0, $t1
		mfhi $t0
		addi $t0, $t0, 0x30
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		mul.s $f0, $f0, $f2
		cvt.w.s $f1, $f0
		mfc1 $t0, $f1
		li $t1, 10
		div $t0, $t1
		mfhi $t0
		addi $t0, $t0, 0x30
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		mul.s $f0, $f0, $f2
		cvt.w.s $f1, $f0
		mfc1 $t0, $f1
		li $t1, 10
		div $t0, $t1
		mfhi $t0
		addi $t0, $t0, 0x30
		sb $t0, 0($s0)
		addi $s0, $s0, 1
	format_float_ret:
		li $t0, 0x20
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		li $t0, 0
		sb $t0, 0($s0)
		move $v0, $s0
		la $s0, buffer
		sub $v0, $v0, $s0
		
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lwc1 $f0, 16($sp)
		lwc1 $f1, 20($sp)
		lwc1 $f2, 24($sp)
		lwc1 $f3, 28($sp)
		addi $sp, $sp, 32
		jr $ra

write_file:
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s7, 20($sp)
	
	la $a0, output_filename
	li $a1, 1
	li $s2, 0
	li $v0, 13
	syscall
	move $s7, $v0		# file descriptor
	
	lw $s0, outN
	mul $s0, $s0, $s0
	li $s1, 0
	
	write_file_loop:
		bge $s1, $s0, write_file_close
		la $t0, out
		move $t1, $s1
		mul $t1, $t1, 4
		add $t0, $t0, $t1
		lwc1 $f12, 0($t0)
		jal format_float
		move $s3, $v0
		
		move $a0, $s7
		la $a1, buffer
		move $a2, $s3
		li $v0, 15
		syscall
		
		addi $s1, $s1, 1
		j write_file_loop  
	
	write_file_close:
		move $a0, $s7
		li $v0, 16
		syscall
	write_file_ret:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		lw $s7, 20($sp)
		addi $sp, $sp, 24
		jr $ra								