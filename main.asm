
# Helper macro for grabbing two command line arguments
.macro load_two_args
	lw $t0, 0($a1)
	sw $t0, arg1
	lw $t0, 4($a1)
	sw $t0, arg2
.end_macro

# Helper macro for grabbing one command line argument
.macro load_one_arg
	lw $t0, 0($a1)
	sw $t0, arg1
.end_macro

############################################################################
##
##  TEXT SECTION
##
############################################################################
.text
.globl main

main:
#check if command line args are provided
#if zero command line arguments are provided exit
beqz $a0, exit_program
li $t0, 1
#check if only one command line argument is given and call marco to save them
beq $t0, $a0, one_arg
#else save the two command line arguments
load_two_args()
j done_saving_args

#if there is only one arg, call macro to save it
one_arg:
	load_one_arg()

#you are done saving args now, start writing your code.
done_saving_args:

# YOUR CODE SHOULD START HERE
	
	lw $a0, arg1	# Print the name of the file being loaded
	li $v0, 4
	syscall
	
	lw $a0, arg1	# Load the text file and get its file descriptor
	li $a1, 0
	li $v0, 13
	syscall
	
	lw $t0, arg2
	beqz $t0, run_with_text
	
	run_with_java:
	la $s0, ($v0)
	la $a0, ($s0)	# Run load_code_chunk the first time
	lw $a1, background_java
	lw $a2, foreground_java
	jal load_code_chunk
	
	jal apply_java_syntax		# apply syntax and line comment highlighting
	jal apply_java_line_comments
	
	prompt_loop_java:
		la $a0, prompt	# Print out the prompt to the user
		li $v0, 4
		syscall
	
		li $v0, 12	# Read in the selected character
		syscall
	
		la $t0, ($v0)	# Load the selected character into t0
		li $t1, 11
		beq $t0, 'q', exit_program	# If t0 is q, clear the screen and exit the program
		beq $t0, ' ', load_again_java	# If t0 is ' ' or ENTER, clear the screen and load the next chunk
		beq $t0, $t1, load_again_java
		beq $t0, '/', search_for_string_java
		j prompt_loop_java
	load_again_java:
		jal clear_screen
		
		la $a0, ($s0)	# Run load_code_chunk again
		lw $a1, background_java
		lw $a2, foreground_java
		jal load_code_chunk
		
		jal apply_java_syntax		# apply syntax and line comment highlighting
		jal apply_java_line_comments
		
		j prompt_loop_java
	search_for_string_java:
	
		la $a0, search_prompt	# Prompt to enter a string to search for
		li $v0, 4
		syscall
		
		la $a0, user_search_buffer	# Read string into search buffer from user
		li $a1, 100
		li $v0, 8
		syscall
		
		li $t0, 0		# Strip the newline character from the end of the search buffer (set that byte to null instead)
		strip_newline_character_loop_java:
			lb $t1, user_search_buffer($t0)
			beqz $t1, null_terminator_found_java
			addi $t0, $t0, 1
		j strip_newline_character_loop_java
		null_terminator_found_java:
		addi $t0, $t0, -1
		li $t1, 0
		sb $t1, user_search_buffer($t0)
		
		la $a0, user_search_buffer
		li $a1, 11		# a1 holds the highlighted background color
		li $a2, 15		# a2 holds the highlighted foreground color
		li $a3, 0		# a3 holds the original background color
		addi $sp, $sp, -4
		li $t0, 15
		sw $t0, 0($sp)		# store the original foreground color on the stack
		jal search_screen
		
		addi $sp, $sp, 4	# put the stack back after running the method
		
	
		j prompt_loop_java
	
	run_with_text:
	la $s0, ($v0)
	la $a0, ($s0)	# Run load_code_chunk the first time
	lw $a1, background_text
	lw $a2, foreground_text
	jal load_code_chunk
	
	prompt_loop_text:
		la $a0, prompt	# Print out the prompt to the user
		li $v0, 4
		syscall
	
		li $v0, 12	# Read in the selected character
		syscall
	
		la $t0, ($v0)	# Load the selected character into t0
		li $t1, 11
		beq $t0, 'q', exit_program	# If t0 is q, clear the screen and exit the program
		beq $t0, ' ', load_again_text	# If t0 is ' ' or ENTER, clear the screen and load the next chunk
		beq $t0, $t1, load_again_text
		beq $t0, '/', search_for_string_text
		j prompt_loop_text
	load_again_text:
		jal clear_screen
		
		la $a0, ($s0)	# Run load_code_chunk again
		lw $a1, background_text
		lw $a2, foreground_text
		jal load_code_chunk
		
		j prompt_loop_text
	search_for_string_text:
	
		la $a0, search_prompt	# Prompt to enter a string to search for
		li $v0, 4
		syscall
		
		la $a0, user_search_buffer	# Read string into search buffer from user
		li $a1, 100
		li $v0, 8
		syscall
		
		li $t0, 0		# Strip the newline character from the end of the search buffer (set that byte to null instead)
		strip_newline_character_loop_text:
			lb $t1, user_search_buffer($t0)
			beqz $t1, null_terminator_found_text
			addi $t0, $t0, 1
		j strip_newline_character_loop_text
		null_terminator_found_text:
		addi $t0, $t0, -1
		li $t1, 0
		sb $t1, user_search_buffer($t0)
		
		la $a0, user_search_buffer
		li $a1, 11		# a1 holds the highlighted background color
		li $a2, 0		# a2 holds the highlighted foreground color
		li $a3, 15		# a3 holds the original background color
		addi $sp, $sp, -4
		li $t0, 0
		sw $t0, 0($sp)		# store the original foreground color on the stack
		jal search_screen
		
		addi $sp, $sp, 4	# put the stack back after running the method
		
		# All code for reading a string from input, stripping off the newline character at the end of it, and then passing
		# arguments to search_screen goes here
	
		j prompt_loop_text


exit_program:
jal clear_screen
li $v0, 10
syscall

############################################################################
##
##  DATA SECTION
##
############################################################################
.data

.align 2

#for arguments read in
arg1: .word 0
arg2: .word 0

foreground_text: .word -1
background_text: .word 15
foreground_java: .word 15
background_java: .word 0

#prompts to display asking for user input
prompt: .asciiz "\nSpace or Enter to continue\n'q' to Quit\n'/' to search for text\n: "
search_prompt: .asciiz "\nEnter search string: "





#################################################################
# Student defined functions will be included starting here
#################################################################

.include "hw3.asm"
