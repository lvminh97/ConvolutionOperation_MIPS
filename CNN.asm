.data
	image_matrix:		.space  	196
	kernel_matrix:		.space		64
	input_filename:		.asciiz		"input_matrix.txt"
	buffer:			.space		1024
	N:			.word		0
	M:			.word		0
	p:			.word		0
	s:			.word		0
	
	float_0:		.float		0
	float_1:		.float		1
	float_10:		.float		10
	float_neg1:		.float		-1
.text
main:
	# read data
	move $a0, $s7
	jal read_input_file
	
	main_exit:
		li $v0, 10		# exit with value 0 (success)
		syscall
		
# read data from input file
read_input_file:
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	
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
	
	#
	la $a0, buffer
	jal read_int
	sw $v0, N
	
	move $a0, $v1
	jal read_int
	sw $v0, M
	
	move $a0, $v1
	jal read_int
	sw $v0, p
	
	move $a0, $v1
	jal read_int
	sw $v0, s
	
	move $a0, $v1
	jal read_float
	li $v0, 2
	syscall
	jal print_newline
	
	move $a0, $v1
	jal read_float
	li $v0, 2
	syscall
	jal print_newline
	
	move $a0, $v1
	jal read_float
	li $v0, 2
	syscall
	jal print_newline
	
	move $a0, $v1
	jal read_float
	li $v0, 2
	syscall
	jal print_newline
	
	move $a0, $v1
	jal read_float
	li $v0, 2
	syscall
	
	read_input_file_ret:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		lw $s4, 20($sp)
		lw $s5, 24($sp)
		lw $s6, 28($sp)
		lw $s7, 32($sp)
		addi $sp, $sp, 36
		jr $ra		

read_int:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
	move $t0, $a0
	
	read_int_trim:
		lb $t1, 0($t0)
		beq $t1, 0, read_int_null
		blt $t1, 0x30, read_int_trim_next
		bgt $t1, 0x39, read_int_trim_next
		j read_int_start
		read_int_trim_next:
			addi $t0, $t0, 1
			j read_int_trim	
	read_int_start:
		li $s0, 0
	read_int_loop:
		lb $t1, 0($t0)
		beq $t1, 0, read_int_null
		blt $t1, 0x30, read_int_finish
		bgt $t1, 0x39, read_int_finish
		mul $s0, $s0, 10
		addi $t1, $t1, -0x30
		add $s0, $s0, $t1
		addi $t0, $t0, 1
		j read_int_loop				
	read_int_finish:
		move $v0, $s0
		move $v1, $t0
		j read_int_ret
	read_int_null:
		li $v1, -1	
	read_int_ret:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		addi $sp, $sp, 8
		jr $ra	

read_float:
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	swc1 $f0, 4($sp)
	swc1 $f1, 8($sp)
	swc1 $f2, 12($sp)
	swc1 $f3, 16($sp)
	swc1 $f4, 20($sp)
	swc1 $f5, 24($sp)
	swc1 $f6, 28($sp)
	
	move $t0, $a0
	
	read_float_trim:		
		lb $t1, 0($t0)
		beq $t1, 0, read_float_null
		beq $t1, 0x20, read_float_trim_next		# space
		beq $t1, 0x0d, read_float_trim_next		# '\r'
		beq $t1, 0x0a, read_float_trim_next		# '\n'
		j read_float_start
		read_float_trim_next:
			addi $t0, $t0, 1
			j read_float_trim
	read_float_start:
		lwc1 $f0, float_0
		lwc1 $f1, float_1				# sign
		lwc1 $f2, float_1				# dividen
		lwc1 $f3, float_10
		lwc1 $f6, float_1
	read_float_loop:
		lb $t1, 0($t0)
		beq $t1, 0, read_float_null
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
		addi $t0, $t0, 1
		j read_float_loop
	read_float_sign:
		lwc1 $f1, float_neg1
		j read_float_loop_next
	read_float_after_point:
		mul.s $f2, $f2, $f3
		j read_float_loop_next
	read_float_finish:
		mul.s $f12, $f0, $f1
		move $v1, $t0
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
		addi $sp, $sp, 32
		jr $ra

print_newline:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 10
	li $v0, 11
	syscall
	
	print_newline_ret:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra