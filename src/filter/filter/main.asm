.INCLUDE "M32DEF.INC"
.equ H_M = 0x05
.equ L_M = 0x00
init:
	LDI R16, 0xFF
	OUT DDRB, R16	//set PORTB as output
	OUT DDRD, R16	//set PORTD as output
	LDI R16, 0x00
	OUT DDRA, R16	//set PORTA as input
	OUT DDRC, R16	//set PORTC as input
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	
main:
	RCALL read_int	//read n
	MOV R6, R24	//R6 = n
	RCALL read_int	//read k
	MOV R7, R24	//R7 = k
	MOV R24, R6
	LDI R17, L_M
	LDI R18, H_M
	RCALL read_matrix	//read M
	MOV R3, XH
	MOV R2, XL		//R3,R2 is the start of F
	MOV R24, R7
	MOV R17, R2
	MOV R18, R3
	RCALL read_matrix	//read F
	MOV R5, XH
	MOV R4, XL			//R5,R4 is start of R
	MOV R12, R6
	SUB R12, R7
	INC R12			//R12 = n - k + 1
	LDI R16, 0		//i = 0
li:
	LDI R17, 0	//j = 0
lj:
	RCALL apply
	ST X+, R20
	INC R17
	CP R17, R12
	BRNE lj

	INC R16
	CP R16, R12
	BRNE li

	MOV R17, R4
	MOV R18, R5
	MOV R24, R12
	RCALL print_matrix
end:
	RJMP end

read_matrix:	//size=R24, addr=R18,R17
	MOV XL, R17
	MOV XH, R18
	LDI R16, 0	//i = 0
	MUL R24, R24
loop_r:
	PUSH R0
	CALL read_int
	ST X+, R24
	INC R16		//i++
	POP R0
	CP R16, R0	//if i != size*size
	BRNE loop_r
	RET

print_matrix:	//size=R24, addr=R18,R17
	MOV XL, R17
	MOV XH, R18
	LDI R16, 0	//i = 0
	MUL R24, R24
loop_p:
	PUSH R0
	LD R24, X+
	CALL print_int
	INC R16		//i++
	POP R0
	CP R16, R0	//if i != size*size
	BRNE loop_p
	RET


read_int:	//result R24
	SBI PORTD, 0
	SBIS PINC, 0
	RJMP read_int
load:
	IN R24, PINA
	SBIC PINC, 0
	RJMP load
	CBI PORTD, 0
	RET

print_int: //print R24
	SBI PORTD, 1
	SBIS PINC, 0
	RJMP print_int
save:
	OUT PORTB, R24
	SBIC PINC, 0
	RJMP save
	CBI PORTD, 1
	RET


apply: //i=R16, j=R17-> result=R20
	LDI R20, 0	//sum_L = 0
	LDI R19, 0 //sum_H = 0
	LDI R21, 0 //l = 0
	MOV ZL, R2
	MOV ZH, R3
Loopl:
	LDI YL, L_M
	LDI YH, H_M
	MOV R24, R21
	ADD R24, R16	//R24 = i+l
	MUL R6, R24		//R0 = n*(i+l)
	ADD R0, R17		//R0 = n*(i+l) + j
	ADD YL, R0		//X = &(M[n*(i+l) + j]
	LDI R22, 0		//m = 0
Loopm:
	LD R23, Y+		//R23 = M[n(i+l) + m]
	LD R25, Z+		//R25 = F[k*l + m]
	MULS R23, R25	//R0 = M[i+l,j+m] * F[l,m]
	ADD R20, R0		//sum_L += R0
	ADC R21, R1
	INC R22			//m++
	CP R22, R7		//if m != k
	BRNE Loopm		//again
	INC R21			//l++
	CP R21, R7		//if l != k
	BRNE Loopl
	RET

