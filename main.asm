# Реализация программы считывания беззнаковых
# вещественных и целых чисел из файла
# для проведения арифметических операций над ними
# и последующей записью результата вычислений
# с заданной точностью в исходный файл.
# Выражение (a + b)/(c - d)

.data
	filein: .asciiz "input.txt"
	storage: .space 1024
	byte: .byte 1
	ten: .float 10.0

.text
# Открыть файл input.txt для чтения
	li $v0, 13
	la $a0, filein
	li $a1, 0
	syscall
	move $s0, $v0

	li $t1, 0 # содержит количество итераций
	lwc1 $f30, ten
	lwc1 $f28, ten
	li $s5, 10
# Считывание 0	
	li $v0, 14
	move $a0, $s0
	la $a1, byte
	la $a2, 1
	syscall
	
	lb $t0, byte
	
	beq $t0, 48, precision
	
precision: # Заданная точность вычислений
	li $v0, 14
	move $a0, $s0
	la $a1, byte
	la $a2, 1
	syscall
	
	lb $t0, byte
	
	beq $t0, 32, n # n - количество чисел
	beq $t0, 46, delete # point
	
	add $t6, $t6, 1 # число знаков после запятой
	add $t5, $t5, 1
# Временное хранение данных	
	subu $sp, $sp, 4
	sw $t0, 0($sp)
	lw $t0, 0($sp)
	addu $sp, $sp, 4
	
	j precision
delete:
	subu $sp, $sp, 4
	sw $t0, 0($sp)
	lw $t0, 0($sp)
	addu $sp, $sp, 4
	
	j precision	
n:
	li $v0, 14
	move $a0, $s0
	la $a1, byte
	la $a2, 1
	syscall
	
	lb $t0, byte
	
	beq $t0, 32, main
# Преобразование символа в цифру	
	sub $t0, $t0, 48

	addu $t1, $t0, $t1
	mul $t1, $t1, 10
	
	j n

main:
	divu $t1, $t1, 10

		chars:
			li $v0, 14
			move $a0, $s0
			la $a1, byte
			la $a2, 1
			syscall
	
			lb $t0, byte
			
			beq $t0, 46, point
			beq $t0, 32, gap
			beq $t0, 13, exit
			# CRLF - возврат каретки и перенос строки
# Преобразование символа в цифру
			sub $t0, $t0, 48
	
			addu $t2, $t0, $t2
	        		mul $t2, $t2, 10
	
			j chars
			
gap:
	bnez $t1, replacefigures
	
	j exit
	
point:
	subu $sp, $sp, 4
	sw $t0, 0($sp)
	lw $t0, 0($sp)
	addu $sp, $sp, 4
	
	j afterpointchars

afterpointchars:
# Преобразование символов после точки	
		li $v0, 14
		move $a0, $s0
		la $a1, byte
		la $a2, 1
		syscall
	
		lb $t0, byte
		
		beq $t0, 32, gap
		beq $t0, 13, exit
	
		sub $t0, $t0, 48

	        addu $t3, $t0, $t3
	        mul $t3, $t3, 10
	        
	        add $t7, $t7, 1 # количество цифр после запятой
	        
	        j afterpointchars
	        
replacefigures:
# Целая часть	
	divu $t2, $t2, 10	
				
	mtc1 $t2, $f2
	cvt.s.w $f2, $f2
# Дробная часть	
	beqz $t3, continue
	
	divu $t3, $t3, 10
	
	mtc1 $t3, $f4
	cvt.s.w $f4, $f4
	
	jal divider

		divider:
# Привести "целую" дробную часть к нормальному виду
			div.s $f4, $f4, $f30
	
			subu $t7, $t7, 1
	
			bnez $t7, divider
# Число для вычисления результата			
	add.s $f2, $f2, $f4
	
	continue:
	
	
	addu $t1, $t1, -1
	
	beqz $t1, exit
	
	j division
	
division:
# Переместить число в другой регистр 
	beq $t1, 3, move1number
	beq $t1, 2, move2number
	beq $t1, 1, move3number
	
	j deleteprev
move1number:
	add.d $f6, $f2, $f6
	
	j deleteprev
move2number:
	add.d $f8, $f2, $f8
	
	j deleteprev
move3number:
	add.d $f10, $f2, $f10
	
	j deleteprev

deleteprev:
	li $t2, 0
	
	li $t3, 0
	
	j chars

resultofexpression:#(a + b)/(c - d)
		#$f2 - d
		#$f6 - a
		#$f8 - b
		#$f10 - c
		add.s $f12, $f6, $f8 # a + b
		sub.s $f14, $f10, $f2 # c - d
		div.s $f18, $f12, $f14
		
		jr $ra
multprecision:
	beqz $t6, writeinteger
	
	mul.s $f28, $f28, $f30 # 0.001 -> 1000
	
	sub $t6, $t6, 1 # число знаков после запятой
	bne $t6, 1, multprecision
	
	j writedouble 
writeinteger:
#Закрыть файл input.txt	 
	 li $v0, 16
	 move $a0, $s0
	 syscall
	
	round.w.s $f16, $f18 # округление результата 5.0 -> 5
	mfc1 $t4, $f16
	
	la $s6, storage
	
	li $t2, 0
	li $t3, 0
	
	invertresult:
		div $t4, $t4, 10
		mfhi $t2 # остаток от деления
		addu $t3, $t2, $t3
		mul $t3, $t3, 10
		
		bnez $t4, invertresult
		
	div $t3, $t3, 10
	
	writeresult:
		div $t3, $t3, 10
		mfhi $s7
		add $s7, $s7, 48
		sb $s7, ($s6)
		addi $s6, $s6, 1
		
		bnez $t3, writeresult
	
#Открыть файл input.txt для записи	
	 li $v0, 13
	 la $a0, filein
	 li $a1, 1
	 syscall
	 move $s1, $v0
#Записать данные в файл input.txt	 
	 li $v0, 15
	 move $a0, $s1
	 la $a1, storage
	 la $a2, 10
	 syscall
#Закрыть файл input.txt	 
	 li $v0, 16
	 move $a0, $s1
	 syscall
	
	j shutupshop
writedouble:
	#Закрыть файл input.txt	 
	 li $v0, 16
	 move $a0, $s0
	 syscall
	
	mul.s $f20, $f18, $f28 # f.e. 1000*result
	
	round.w.s $f16, $f20 # округление результата
	mfc1 $t4, $f16
	
	move $t0, $t4
	jal placeofpoint
	
	subu $t5, $s4, $t5 # f.e 567.9: 5679 -> 9765 -> 567.9
	
	la $s6, storage
	
	li $t2, 0
	li $t3, 0
	invertresult2:
		div $t4, $t4, 10
		mfhi $t2
		addu $t3, $t2, $t3
		mul $t3, $t3, 10
		
		bnez $t4, invertresult2
		
	div $t3, $t3, 10
	
	writeresult2:
		subu $t5, $t5, 1
		
		div $t3, $t3, 10
		mfhi $s7
		add $s7, $s7, 48
		sb $s7, ($s6)
		addi $s6, $s6, 1
		
		beqz $t5, precisiontreg
		bnez $t3, writeresult2
	
#Открыть файл input.txt для записи	
	 li $v0, 13
	 la $a0, filein
	 li $a1, 1
	 syscall
	 move $s1, $v0
#Записать данные в файл input.txt	 
	 li $v0, 15
	 move $a0, $s1
	 la $a1, storage
	 la $a2, 10
	 syscall
#Закрыть файл input.txt	 
	 li $v0, 16
	 move $a0, $s1
	 syscall
	
	j shutupshop
			precisiontreg:
				li $s3, 46 # point
				sb $s3, ($s6)
				addi $s6, $s6, 1
				
				j writeresult2
			placeofpoint:
# Количество разрядов в целом числе
				divu $t0, $t0, 10
				
				add $s4, $s4, 1
				
				bnez $t0, placeofpoint
				jr $ra
exit:
	bnez $t1, replacefigures
	
	jal resultofexpression
	
	j multprecision

shutupshop:	
#Завершить программу	
li $v0, 10
syscall
	
	

	

	
	

	
