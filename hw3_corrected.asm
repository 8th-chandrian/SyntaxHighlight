 # Homework #3
 # name: Noah Young
 # sbuid: 109960711
 
 #TODO: CHECK ARGS, MAKE SURE BACKGROUND AND FOREGROUND ORDER IS GOOD FOR ALL METHODS


##############################
#
# TEXT SECTION
#
##############################
 .text

##############################
# PART I FUNCTIONS
##############################

##############################
# This function reads a byte at a time from the file and puts it
# into the appropriate position into the MMIO with the correct
# FG and BG color.
# The function begins each time at position [0,0].
# If a newline character is encountered, the function must
# populate the rest of the row in the MMIO with the spaces and
# then continue placing the bytes at the start of the next row.
#
# @param fd file descriptor of the file.
# @param BG four-bit value indicating background color
# @param FG four-bit value indication foreground color
# @return int 1 means EOF has not been encountered yet, 0 means
# EOF reached, -1 means invalid file.
#
# Note: EOF stands for End Of File
##############################
load_code_chunk:

	# Stores the saved registers and the return address
	addi $sp, $sp, -28
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $ra, 24($sp)
	
	la $s0, ($a0) 	# The file descriptor will be held in s0
	la $s1, ($a1) 	# The background color will be held in s1
	la $s2, ($a2) 	# The foreground color will be held in s2
			
	bltz $s1, out_of_bounds_background		#If the foreground value is not in bounds, set it to 0 (black)
	bge $s1, 16, out_of_bounds_background
	j in_bounds_background
	out_of_bounds_background:
		li $s1, 15		
	in_bounds_background:
	
	bltz $s2, out_of_bounds_foreground		#If the foreground value is not in bounds, set it to 0 (black)
	bge $s2, 16, out_of_bounds_foreground
	j in_bounds_foreground
	out_of_bounds_foreground:
		li $s2, 0		
	in_bounds_foreground:
	
	sll $s1, $s1, 4		#Shift the background value left by 4 bits, then or with s1 to get the second byte
	or $s1, $s2, $s1	#Store the second byte in s1 (reused because we will not need s2 or s1 after this)
	
	
	li $s3, 0	# s3 will hold our counter for the number of bytes loaded into the simulator
			# for a given line. When s3 hits 80, we should reset it to 0 and increment s4
			
	li $s4, 0	# s4 will hold our counter for the row currently being loaded into the simulator
			# When s4 hits 25, we have hit the maximum number of bytes to be loaded.
	li $t0, 0
	sb $t0, input_byte	# Zero out input_byte
	
	load_code_loop:
	
	
	bgt $s4, 24, load_code_done
		la $a0, ($s0) 	# Load the file descriptor into a0
		la $a1, input_byte	# Load the address of the input buffer into a1
		li $a2, 1  	# Load the max number of bytes into a2
		li $v0, 14	# Load 14 into v0 to use syscall 14
		syscall
		
		la $t2, ($v0)		#Load the return value into t2
		lb $t0, input_byte	#Load the byte just read into t0
		li $t1, 0xffff0000	#Load the immediate value of the starting console memory address into t1
		
		beqz $t2, file_fully_processed		#If v0 is 0, we have reached the end of the file
		bltz $t2, invalid_file			#If v0 is negative, there was an error reading the file
		
		li $t5, 160		# Load 160 into t5 (this is what we'll be multiplying s4 by)
		mult $t5, $s4
		mflo $t5
		add $t6, $t5, $s3	#Get the position of the current cell by adding s3 to the result of the multiplication
		add $t1, $t1, $t6	#Increment t1 by t5 to get the address of the first byte
		
		bne $t0, '\n', not_newline
		beq $t0, '\n', newline
		not_newline:
			sb $t0, ($t1)		#Store the character in t0 into the first byte
			addi $t1, $t1, 1	#Increment t1 by 1 to get the address of the second byte
			sb $s1, ($t1)		#Store the value in s1 into the second byte
			
			addi $s3, $s3, 2		#Increment our line index counter
			blt $s3, 160, not_end_of_line	#If s3 equals 160, set to 0 and increment s4
				li $s3, 0
				addi $s4, $s4, 1
			not_end_of_line:
		
		j byte_processed
		
		newline:
			li $t0, ' '	#Load the space character into $t0
			sb $t0, ($t1)		#Store the space character into the first byte
			addi $t1, $t1, 1	#Increment t1 by 1 to get the address of the second byte
			sb $s1, ($t1)		#Store the value in s1 into the second byte
			addi $t1, $t1, 1	#Increment t1 again to get the address of the first byte of the next cell
			
			addi $s3, $s3, 2		#Increment our line index counter
			
			blt $s3, 160, not_end_of_line_2	#If s3 equals 80, set to 0, increment s4, and break from the loop
				li $s3, 0		#At this point, we will have filled the rest of the line with spaces
				addi $s4, $s4, 1
				j byte_processed
			not_end_of_line_2:
			j newline		#Otherwise, continue adding spaces to the line

		byte_processed:
	
	j load_code_loop
	
	file_fully_processed:		# If we have reached the end of the file and still have space left in the console, we should
					# fill it with spaces and return zero
		
		li $t0, ' '		#Load the space character into $t0		
		li $t5, 160		# Load 160 into t5 (this is what we'll be multiplying s4 by)
		mult $t5, $s4
		mflo $t5
		add $t6, $t5, $s3	#Get the position of the current cell by adding s3 to the result of the multiplication
		add $t1, $t1, $t6	#Increment t1 by t6 to get the address of the first byte
		li $t3, 0xffff0f9f
		
		fill_with_spaces_loop:
			bgt $t1, $t3, console_full	#Check if we have reached the end address of the loop

			sb $t0, ($t1)		#If not, keep adding spaces and incrementing until we do
			addi $t1, $t1, 1	#Increment t1 by 1 to get the address of the second byte
			sb $s1, ($t1)		#Store the value in s1 into the second byte
			addi $t1, $t1, 1	#Increment t1 again to get the address of the first byte of the next cell
			
		j fill_with_spaces_loop
			
		console_full:
		li $v0, 0
	j end_load_code_chunk
				
	load_code_done:		# If we have fully filled the console, we should return 1
		li $v0, 1
	j end_load_code_chunk
	
	invalid_file:		# If our file descriptor is invalid, we should return -1
		li $v0, -1
	
	end_load_code_chunk:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	addi $sp, $sp, 28
	jr $ra


##############################
# PART II FUNCTIONS
##############################

##############################
# This function should go through the whole memory array and clear the contents of the screen.
##############################
clear_screen:

	li $t0, 0		# t0 holds our byte representation of black fore and backgrounds
	li $t1, ' '		# t1 holds our space character
	li $t2, 0xffff0000	# t2 holds our address in memory
	li $t3, 0xffff0f9f	# t3 holds our stopping address
	
	clear_loop:
	bgt $t2, $t3, clear_over	#writes ' ' into first byte and 0 into second for all bytes
		sb $t1, ($t2)
		addi $t2, $t2, 1
		sb $t0, ($t2)
		addi $t2, $t2, 1
		
		j clear_loop
	clear_over:
	
	jr $ra



##############################
# PART III FUNCTIONS
##############################

##############################
# This function updates the color specifications of the cell
# specified by the cell index. This function should not modify
# the text in any fashion.
#
# @param i row of MMIO to apply the cell color.
# @param j column of MMIO to apply the cell color.
# @param FG the four bit value specifying the foreground color
# @param BG the four bit value specifying the background color
##############################
apply_cell_color:

	# Stores the saved registers and the return address
	addi $sp, $sp, -24
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $ra, 20($sp)
	
	la $s0, ($a0)	# Row of MMIO cell is held in s0
	la $s1, ($a1)	# Column of MMIO cell is held in s1
	la $s2, ($a2)	# Foreground color is held in s2
	la $s3, ($a3)	# Background color is held in s3
	
	bltz $s3, out_of_bounds_bg		#If the foreground value is not in bounds, preserve it
	bge $s3, 16, out_of_bounds_bg
	j in_bounds_bg
	out_of_bounds_bg:
		li $s3, 15		
	in_bounds_bg:
	
	bltz $s2, out_of_bounds_fg	#If the foreground value is not in bounds, preserve it
	bge $s2, 16, out_of_bounds_fg
	j in_bounds_fg
	out_of_bounds_fg:
		li $s2, 0		
	in_bounds_fg:
	
	bgt $s0, 24, end_apply_cell_color	#If row or column is out of bounds, the function should terminate immediately
	bltz $s0, end_apply_cell_color
	bgt $s1, 79, end_apply_cell_color
	bltz $s1, end_apply_cell_color
	
	li $s4, 0xffff0000		# Otherwise, get the address of the byte to change and put it in s4
	li $t0, 160
	li $t1, 2
	mult $s0, $t0			# Multiply the row index by 160
	mflo $s0
	mult $s1, $t1			# Multiply the column index by 2, since each cell takes up 2 bytes
	mflo $s1
	add $s0, $s0, $s1		# Add the two together and increment by 1 to reference the color byte
	addi $s0, $s0, 1
	add $s4, $s4, $s0		# Finally add the result to s4 for the address of the byte being changed
	
	bltz $s2, process_foreground_end	# If foreground color is out of bounds, do not process it
	bgt $s2, 15, process_background_end
	j process_foreground
	process_foreground_end:
	
	bltz $s2, process_background_end	# If background color is out of bounds, do not process it
	bgt $s2, 15, process_background_end
	j process_background
	process_background_end:
	j end_apply_cell_color		# After both foreground and background colors have been processed, the function should end
	
	process_foreground:
		lb $t0, ($s4)	# Load the byte being worked with into t0
		li $t1, 0xf0	
		and $t0, $t0, $t1	# Zero out the least significant 4 bits
		or $t0, $t0, $s2	# Use or to set the least significant 4 bits to the value of s2
		sb $t0, ($s4)
	j process_foreground_end
	
	process_background:
		lb $t0, ($s4)	# Load the byte being worked with into t0
		li $t1, 0x0f	
		and $t0, $t0, $t1	# Zero out the most significant 4 bits
		sll $s3, $s3, 4		# Shift the background value left by 4
		or $t0, $t0, $s3	# Use or to set the most significant 4 bits to the value of s3
		sb $t0, ($s4)
	j process_background_end
	
	end_apply_cell_color:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $ra, 20($sp)
	addi $sp, $sp, 24
	jr $ra


##############################
# This function goes through and clears any cell with oldBG color
# and sets it to the newBG color. It preserves the foreground
# color of the text that was present.
#
# @param oldBG old background color specs.
# @param newBG new background color defining the color specs
##############################
clear_background:

	# Stores the saved registers and the return address
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $ra, 12($sp)
	
	la $s0, ($a0)		# s0 holds old background color
	la $s1, ($a1)		# s1 holds new background color
	li $s2, 0xffff0001	# s2 holds our current cell address
	
	bltz $s0, end_clear_background		# If old background color is out of range, function should return
	bgt $s0, 15, end_clear_background
	
	bltz $s1, set_to_white
	bgt $s1, 15, set_to_white
	j new_background_in_range
	set_to_white:
		li $s1, 15	# If new background color is out of range, set it to white (int value 15) and continue
	new_background_in_range:
	sll $s0, $s0, 4		# Shift old and new colors left by 4 so that they can be compared to bytes loaded from memory
	sll $s1, $s1, 4
	
	li $t3, 0xffff0f9f
	
	clear_background_loop:
	bgt $s2, $t3, end_clear_background
		lb $t0, ($s2)		# First set least significant 4 bits to 0 and check if loaded byte equals old background
		li $t1, 0xf0
		and $t1, $t0, $t1
		bne $t1, $s0, old_background_not_equal
			li $t2, 0x0f	# If so, set most significant 4 bits to new background color
			and $t0, $t0, $t2
			or $t0, $t0, $s1
			sb $t0, ($s2)	# Then save to same address that byte was loaded from
		old_background_not_equal:
		addi $s2, $s2, 2	# Increment s2 to the next color byte
		
		j clear_background_loop		# Don't forget to loop back to the beginning again!
	
	end_clear_background:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra


##############################
# This function will compare cmp_string to the string in the MMIO
# starting at position (i,j). If there is a match the function
# will return (1, length of the match).
#
# @param cmp_string start address of the string to look for in
# the MMIO
# @param i row of the MMIO to start string compare.
# @param j column of MMIO to start string compare.
# @return int length of match. 0 if no characters matched.
# @return int 1 for exact match, 0 otherwise
##############################
string_compare:

	# Stores the saved registers and the return address
	addi $sp, $sp, -20
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $ra, 16($sp)
	
	la $s0, ($a0)	# s0 holds the start address of the string we will be comparing
	la $s1, ($a1)	# s1 holds the row to compare from
	la $s2, ($a2)	# s2 holds the column to compare from
	li $s3, 0	# s3 holds the number of characters matched
	
	bltz $s1, invalid_indices	# If either of the indices are out of bounds, return (0, 0) at once
	bltz $s2, invalid_indices
	bgt $s1, 24, invalid_indices
	bgt $s2, 79, invalid_indices
	
	li $t0, 0xffff0000	# Get the starting address to compare to
	li $t1, 160
	li $t2, 2
	mult $s1, $t1
	mflo $t1
	mult $s2, $t2
	mflo $t2
	add $t1, $t1, $t2
	add $t0, $t0, $t1	# Starting address will be held in t0
	
	string_compare_loop:
	add $t1, $s0, $s3	# Get the address of the character within our string to compare
	lb $t2, ($t1)		# Load that character into t2
	lb $t3, ($t0)		# Load the character being compared to from memory
	
	beqz $t2, strings_equal			# If t2 is null, we have reached the end of our string successfully
	bne $t2, $t3, strings_not_equal		# If t2 and t3 aren't equal, the strings aren't equal and we should break from the loop
	addi $s3, $s3, 1
	addi $t0, $t0, 2		# Otherwise, increment s3 by 1 and t0 by 2 to advance to the next character
	j string_compare_loop
	
	strings_not_equal:
		la $v0, ($s3)
		li $v1, 0
	j end_string_compare
	
	strings_equal:
		la $v0, ($s3)
		li $v1, 1
	j end_string_compare
	
	invalid_indices:
		li $v0, 0
		li $v1, 0
	
	end_string_compare:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $ra, 16($sp)
	addi $sp, $sp, 20
	jr $ra


##############################
# This function goes through the whole MMIO screen and searches
# for any string matches to the search_string provided by the
# user. This function should clear the old highlights first.
# Then it will call string_compare on each cell in the MMIO
# looking for a match. If there is a match it will apply the
# background color using the apply_cell_color function.
#
# @param search_string Start address of the string to search for
# in the MMIO.
# @param BG background color specs defining.
##############################
search_screen:

	la $t0, 0($sp)	# Before we mess with the stack pointer, we load the original foreground color into t0
			# Since this is the 5th argument for the method, it is stored on the stack

	# Stores the saved registers and the return address
	addi $sp, $sp, -36
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	sw $ra, 32($sp)
	
	la $s0, ($a0)	# s0 holds the address of the string to search for
	la $s1, ($a1)	# s1 holds the background color to apply if a match is found
	la $s2, ($a2)	# s2 holds the foreground color to apply if a match is found
	la $s3, ($a3)	# s3 holds the original background color (to be passed to clear_background)
	la $s7, ($t0)	# s7 holds the original foreground color (to be passed in the case that no highlighting occurs)
	
	li $s4, 0	# s4 holds the row of the current cell being searched (0 - 24)
	li $s5, 0	# s5 holds the column of the current cell being searched (0 - 79)
	li $s6, 0	# s6 holds the number of characters still to highlight
	
	# First call clear_background
	la $a0, ($s1)	# The old background color to clear, or the color we use for highlighting
	la $a1, ($s3)	# The new background color (or the original one)
	jal clear_background
	
	# NOTE: WE CAN REUSE s3 AFTER THIS POINT
	
	# The background should now be cleared, with no highlighted text on the screen
	search_screen_loop:
	li $t0, 160		# Calculate the index of the cell to check
	li $t1, 2
	mult $s4, $t0
	mflo $t0
	mult $s5, $t1
	mflo $t1
	add $t0, $t0, $t1
	
	bgt $t0, 3998, end_search_screen	# If we have incremented past the last cell, end the loop
	
		la $a0, ($s0)	# Load in the arguments for string_compare (string address goes in a0)
		la $a1, ($s4)	# row index goes in a1
		la $a2, ($s5)	# column index goes in a2
		jal string_compare
		
		la $t1, ($v1)			# If t1 is 0, there was no match and s6 stays the same
		la $t0, ($v0)			# If t1 is 1, a match was found and s6 should be set to the value of t0
		beqz $t1, no_match_cell
			la $s6, ($t0)		# s6 is reset to t0 when there is a match
		no_match_cell:
		
		beqz $s6, no_highlighting_cell		# If the counter for cells to highlight isn't zero, highlight the current
							# cell and decrement the counter by 1
			la $a0, ($s4)
			la $a1, ($s5)
			jal get_cell_foreground		# First get the cell's original foreground to pass to apply_cell_color
			la $t0, ($v0)
		
			la $a0, ($s4)	# Load in the arguments for apply_cell_color (row index goes in a0)
			la $a1, ($s5)	# column index goes in a1
			la $a2, ($t0)	# cell's original foreground color goes in a2 (so that foreground does not change)
			la $a3, ($s1)	# background color goes in a3
			jal apply_cell_color
			
			addi $s6, $s6, -1	# decrement the counter
		no_highlighting_cell:
		
			#NOTE: If we need to deal with the case in which a match wasn't found, that code goes here
			
		addi $s5, $s5, 1	# Increment column index by 1
		blt $s5, 80, not_end_of_row
			addi $s4, $s4, 1	# If s5 equals 80, increment s4 and reset s5
			li $s5, 0
		not_end_of_row:
		
	j search_screen_loop	# Continue the loop
	
	
	end_search_screen:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $s7, 28($sp)
	lw $ra, 32($sp)
	addi $sp, $sp, 36
	jr $ra
	
	
	
##############################
# Helper method for search_screen, created so that search_screen
# does not overwrite the foreground of whatever cell it is
# highlighting
##############################
get_cell_foreground:

	la $t0, ($a0)	# Load row index into t0
	la $t1, ($a1)	# Load column index into t1
	
	li $t2, 160
	li $t3, 2
	li $t4, 0xffff0001
	mult $t0, $t2
	mflo $t2
	mult $t1, $t3
	mflo $t3
	add $t2, $t2, $t3
	add $t4, $t4, $t2	# Index of cell color byte is now in t4
	
	lb $t0, 0($t4)		# Cell color byte is now in t0
	li $t1, 0x0f
	and $t0, $t0, $t1	# Use and to set the most significant 4 bits of t0 to 0 (gets the foreground bits alone)
	
	la $v0, ($t0)		# Load the foreground bits into v0
	
	jr $ra
	
	


##############################
# PART IV FUNCTIONS
##############################

##############################
# This function goes through the whole MMIO screen and searches
# for Java syntax keywords, operators, data types, etc and
# applies the appropriate color specifications for to that match.
##############################
apply_java_syntax:

	# Stores the saved registers and the return address
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $ra, 4($sp)
	
	#First iterate through the java keywords array and apply a red foreground to each one
	
	li $s0, 0	# s0 holds our index in the array (increment by 4 because array contains words)
	keywords_loop:
	lw $t0, java_keywords($s0)	# get the address of the keyword being searched for
	lb $t1, 0($t0)			# load the first byte of the word at that address into t1
	bltz $t1, end_keywords_loop	# if that word is equal to -1, we have hit the end of the array
	
		la $a0, ($t0)	# otherwise, load the address of the keyword being searched for into a0
		li $a1, 0	# load the background color to apply (black) into a1
		li $a2, 9	# load the foreground color to apply (red) into a2
		li $a3, 0	# load the original background color (black) into a3
		
		addi $sp, $sp -4	# load the original foreground color (white) onto the stack for a4
		li $t1, 15
		sw $t1, 0($sp)
		jal search_screen_java	# call the search_screen method
		
		addi $sp, $sp, 4	# put the stack pointer back
		addi $s0, $s0, 4	# increment s0 to the next word index
	j keywords_loop
	end_keywords_loop:
	
	# Then iterate through the java operators array and apply a green foreground to each one
	
	li $s0, 0	# s0 holds our index in the array (increment by 4 because array contains words)
	operators_loop:
	lw $t0, java_operators($s0)	# get the address of the keyword being searched for
	lb $t1, 0($t0)			# load the first byte of the word at that address into t1
	bltz $t1, end_operators_loop	# if that word is equal to -1, we have hit the end of the array
	
		la $a0, ($t0)	# otherwise, load the address of the keyword being searched for into a0
		li $a1, 0	# load the background color to apply (black) into a1
		li $a2, 10	# load the foreground color to apply (green) into a2
		li $a3, 0	# load the original background color (black) into a3
		
		addi $sp, $sp -4	# load the original foreground color (white) onto the stack for a4
		li $t1, 15
		sw $t1, 0($sp)
		jal search_screen_java	# call the search_screen method
		
		addi $sp, $sp, 4	# put the stack pointer back
		addi $s0, $s0, 4	# increment s0 to the next word index
	j operators_loop
	end_operators_loop:
	
	# Then iterate through the java brackets array and apply a magenta foreground to each one
	
	li $s0, 0	# s0 holds our index in the array (increment by 4 because array contains words)
	brackets_loop:
	lw $t0, java_brackets($s0)	# get the address of the keyword being searched for
	lb $t1, 0($t0)			# load the first byte of the word at that address into t1
	bltz $t1, end_brackets_loop	# if that word is equal to -1, we have hit the end of the array
	
		la $a0, ($t0)	# otherwise, load the address of the keyword being searched for into a0
		li $a1, 0	# load the background color to apply (black) into a1
		li $a2, 13	# load the foreground color to apply (magenta) into a2
		li $a3, 0	# load the original background color (black) into a3
		
		addi $sp, $sp -4	# load the original foreground color (white) onto the stack for a4
		li $t1, 15
		sw $t1, 0($sp)
		jal search_screen_java	# call the search_screen method
		
		addi $sp, $sp, 4	# put the stack pointer back
		addi $s0, $s0, 4	# increment s0 to the next word index
	j brackets_loop
	end_brackets_loop:
	
	# Finally iterate through the java data types array and apply a cyan foreground to each one
	
	li $s0, 0	# s0 holds our index in the array (increment by 4 because array contains words)
	datatypes_loop:
	lw $t0, java_datatypes($s0)	# get the address of the keyword being searched for
	lb $t1, 0($t0)			# load the first byte of the word at that address into t1
	bltz $t1, end_datatypes_loop	# if that word is equal to -1, we have hit the end of the array
	
		la $a0, ($t0)	# otherwise, load the address of the keyword being searched for into a0
		li $a1, 0	# load the background color to apply (black) into a1
		li $a2, 14	# load the foreground color to apply (cyan) into a2
		li $a3, 0	# load the original background color (black) into a3
		
		addi $sp, $sp -4	# load the original foreground color (white) onto the stack for a4
		li $t1, 15
		sw $t1, 0($sp)
		jal search_screen_java	# call the search_screen method
		
		addi $sp, $sp, 4	# put the stack pointer back
		addi $s0, $s0, 4	# increment s0 to the next word index
	j datatypes_loop
	end_datatypes_loop:
	
	
	lw $s0, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra


##############################
# This function goes through the whole MMIO screen finds any java
# comments and applies a blue foreground color to all of the text
# in that line.
##############################
apply_java_line_comments:
	
	# Stores the saved registers and the return address
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $ra, 12($sp)

	li $s0, 0	# s0 will hold our row index (0 - 24)
	li $s1, 0	# s1 will hold our column index (0 - 79)
	
	check_for_comments_loop:
	beq $s0, 25, apply_java_line_comments_done
		
		la $a0, comment_start($zero)	# Load the address of the "//" string into a0
		la $a1, ($s0)			# Load the row index into a1
		la $a2, ($s1)			# Load the column index into a2
		jal string_compare
		
		la $t0, ($v1)		# If v1 is 1, we have found the starting address of a comment
		
		beqz $t0, not_a_comment		# If this is the starting address of a comment, set the foreground of every remaining
						# cell in the row to bright blue
		comment_highlighting_loop:
			beq $s1, 80, comment_highlighting_complete
				la $a0, ($s0)	# Load the row index into a0
				la $a1, ($s1)	# Load the column index into a1
				li $a2, 12	# Load the foreground color (bright blue) into a2
				li $a3, 0	# Load the background color (black) into a3
				jal apply_cell_color
				
				addi $s1, $s1, 1	# Increment s1 by 1
				
			j comment_highlighting_loop
			comment_highlighting_complete:
				addi $s0, $s0, 1
				li $s1, 0	
			j check_for_comments_loop	# When comments are finally finished being highlighted, continue in search loop
		
		not_a_comment:			# Otherwise, increment indices and loop
			addi $s1, $s1, 1
			bne $s1, 80, not_end_of_line_comment
				addi $s0, $s0, 1
				li $s1, 0
			not_end_of_line_comment:
		j check_for_comments_loop	# Once indices have been incremented, continue in search loop

	apply_java_line_comments_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	
	
	
##############################
# This is a helper method for the apply_java_syntax method which alters
# the foreground as well as the background colors for a given cell
# (the original method is designed to only alter the background)
##############################	
search_screen_java:

	la $t0, 0($sp)	# Before we mess with the stack pointer, we load the original foreground color into t0
			# Since this is the 5th argument for the method, it is stored on the stack

	# Stores the saved registers and the return address
	addi $sp, $sp, -36
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	sw $ra, 32($sp)
	
	la $s0, ($a0)	# s0 holds the address of the string to search for
	la $s1, ($a1)	# s1 holds the background color to apply if a match is found
	la $s2, ($a2)	# s2 holds the foreground color to apply if a match is found
	la $s3, ($a3)	# s3 holds the original background color (to be passed to clear_background)
	la $s7, ($t0)	# s7 holds the original foreground color (to be passed in the case that no highlighting occurs)
	
	li $s4, 0	# s4 holds the row of the current cell being searched (0 - 24)
	li $s5, 0	# s5 holds the column of the current cell being searched (0 - 79)
	li $s6, 0	# s6 holds the number of characters still to highlight
	
	# First call clear_background
	la $a0, ($s1)	# The old background color to clear, or the color we use for highlighting
	la $a1, ($s3)	# The new background color (or the original one)
	jal clear_background
	
	# NOTE: WE CAN REUSE s3 AFTER THIS POINT
	
	# The background should now be cleared, with no highlighted text on the screen
	search_screen_loop_java:
	li $t0, 160		# Calculate the index of the cell to check
	li $t1, 2
	mult $s4, $t0
	mflo $t0
	mult $s5, $t1
	mflo $t1
	add $t0, $t0, $t1
	
	bgt $t0, 3998, end_search_screen_java	# If we have incremented past the last cell, end the loop
	
		la $a0, ($s0)	# Load in the arguments for string_compare (string address goes in a0)
		la $a1, ($s4)	# row index goes in a1
		la $a2, ($s5)	# column index goes in a2
		jal string_compare
		
		la $t1, ($v1)			# If t1 is 0, there was no match and s6 stays the same
		la $t0, ($v0)			# If t1 is 1, a match was found and s6 should be set to the value of t0
		beqz $t1, no_match_cell_java
			la $s6, ($t0)		# s6 is reset to t0 when there is a match
		no_match_cell_java:
		
		beqz $s6, no_highlighting_cell_java		# If the counter for cells to highlight isn't zero, highlight the current
							# cell and decrement the counter by 1
		
			la $a0, ($s4)	# Load in the arguments for apply_cell_color (row index goes in a0)
			la $a1, ($s5)	# column index goes in a1
			la $a2, ($s2)	# foreground color goes in a2
			la $a3, ($s1)	# background color goes in a3
			jal apply_cell_color
			
			addi $s6, $s6, -1	# decrement the counter
		no_highlighting_cell_java:
		
			#NOTE: If we need to deal with the case in which a match wasn't found, that code goes here
			
		addi $s5, $s5, 1	# Increment column index by 1
		blt $s5, 80, not_end_of_row_java
			addi $s4, $s4, 1	# If s5 equals 80, increment s4 and reset s5
			li $s5, 0
		not_end_of_row_java:
		
	j search_screen_loop_java	# Continue the loop
	
	
	end_search_screen_java:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $s7, 28($sp)
	lw $ra, 32($sp)
	addi $sp, $sp, 36
	jr $ra



##############################
#
# DATA SECTION
#
##############################
.data
#put the users search string in this buffer

#The space where load_code_chunk will load its individual bytes
.align 2
input_byte: .space 1

#The starting address of the console memory
.align 2
console_starting_address: .word 0xffff0000

.align 2
negative: .word -1

#java keywords red
java_keywords_public: .asciiz "public"
java_keywords_private: .asciiz "private"
java_keywords_import: .asciiz "import"
java_keywords_class: .asciiz "class"
java_keywords_if: .asciiz "if"
java_keywords_else: .asciiz "else"
java_keywords_for: .asciiz "for"
java_keywords_return: .asciiz "return"
java_keywords_while: .asciiz "while"
java_keywords_sop: .asciiz "System.out.println"
java_keywords_sop2: .asciiz "System.out.print"

.align 2
java_keywords: .word java_keywords_public, java_keywords_private, java_keywords_import, java_keywords_class, java_keywords_if, java_keywords_else, java_keywords_for, java_keywords_return, java_keywords_while, java_keywords_sop, java_keywords_sop2, negative

#java datatypes
java_datatype_int: .asciiz "int "
java_datatype_byte: .asciiz "byte "
java_datatype_short: .asciiz "short "
java_datatype_long: .asciiz "long "
java_datatype_char: .asciiz "char "
java_datatype_boolean: .asciiz "boolean "
java_datatype_double: .asciiz "double "
java_datatype_float: .asciiz "float "
java_datatype_string: .asciiz "String "

.align 2
java_datatypes: .word java_datatype_int, java_datatype_byte, java_datatype_short, java_datatype_long, java_datatype_char, java_datatype_boolean, java_datatype_double, java_datatype_float, java_datatype_string, negative

#java operators
java_operator_plus: .asciiz "+"
java_operator_minus: .asciiz "-"
java_operator_division: .asciiz "/"
java_operator_multiply: .asciiz "*"
java_operator_less: .asciiz "<"
java_operator_greater: .asciiz ">"
java_operator_and_op: .asciiz "&&"
java_operator_or_op: .asciiz "||"
java_operator_not_op: .asciiz "!="
java_operator_equal: .asciiz "="
java_operator_colon: .asciiz ":"
java_operator_semicolon: .asciiz ";"

.align 2
java_operators: .word java_operator_plus, java_operator_minus, java_operator_division, java_operator_multiply, java_operator_less, java_operator_greater, java_operator_and_op, java_operator_or_op, java_operator_not_op, java_operator_equal, java_operator_colon, java_operator_semicolon, negative

#java brackets
java_bracket_paren_open: .asciiz "("
java_bracket_paren_close: .asciiz ")"
java_bracket_square_open: .asciiz "["
java_bracket_square_close: .asciiz "]"
java_bracket_curly_open: .asciiz "{"
java_bracket_curly_close: .asciiz "}"

.align 2
java_brackets: .word java_bracket_paren_open, java_bracket_paren_close, java_bracket_square_open, java_bracket_square_close, java_bracket_curly_open, java_bracket_curly_close, negative

java_line_comment: .asciiz "//"

.align 2
user_search_buffer: .space 101

.align 2
comment_start: .asciiz "//"
