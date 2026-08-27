# 1. Registers Setup (Initialization)
addi $t0, $zero, 0      # $t0 = 0 (Base Address for memory operations)
addi $t1, $zero, 0x1122 # $t1 = 0x00001122 (First Word Data to write)
addi $t2, $zero, 0x3344 # $t2 = 0x00003344 (Second Word Data to write)
addi $t3, $zero, 0x55   # $t3 = 0x00000055 (Byte Data to write)
addi $t4, $zero, 1      # $t4 = 1 (Extra register for ALU operations)
addi $t5, $zero, 2      # $t5 = 2 (Extra register for ALU operations)

# 2. Test Back-to-Back Store Word (sw)
sw $t1, 0($t0)          # Store Word at address 0
sw $t2, 4($t0)          # Store Word at address 4 (Should appear back-to-back on AHB)

# 3. Insert instruction to fill the pipeline (Avoid Structural/Data Hazards)
add $t6, $t4, $t5       # $t6 = 3 (Independent instruction to keep the pipeline busy)

# 4. Test Back-to-Back Load Word (lw)
lw $s0, 0($t0)          # Load Word from address 0 
lw $s1, 4($t0)          # Load Word from address 4 

# 5. Insert instructions to avoid Load-Use Hazard
# These give the loaded data time to reach the Writeback (WB) stage without stalling the PC
sub $t7, $t5, $t4       # $t7 = 1 (Independent instruction for the first 'lw' delay)
and $t8, $t6, $t7       # $t8 = 1 (Independent instruction for the second 'lw' delay)

# 6. Test Store Byte (sb)
sb $t3, 8($t0)          # Store Byte at address 8 (AHB HSIZE should be 3'b000)

# 7. Insert an independent instruction 
or $t9, $t4, $t5        # $t9 = 3 (Separates the 'sb' from the following 'lb' to maintain flow)

# 8. Test Load Byte (lb)
lb $s2, 8($t0)          # Load Byte from address 8 

# 9. Final independent instruction 
add $s3, $zero, $s2     # We can safely use $s2 here because the pipeline had enough time to process it

# 10. End of Program (Infinite Loop to prevent PC from fetching invalid instructions)
loop:
beq $zero, $zero, loop