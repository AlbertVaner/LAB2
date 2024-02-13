;*******************************************************************************************************************************
;Universidad del valle
;Prelab_2.asm
;Autor: Albert Vandercam Hart
;Hardware ATmega328P
;Creado: 31/01/2024
;*******************************************************************************************************************************
; ENCABEZADO
;*******************************************************************************************************************************
.include "M328PDEF.inc"
.CSEG
.ORG 0x0000
;*******************************************************************************************************************************
; STACK POINTER
;*******************************************************************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL,R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17
;*******************************************************************************************************************************
; CONFIGURACI[ON
;*******************************************************************************************************************************

 TABLAD: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66,0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0xFC, 0x39, 0x5E, 0x79, 0x71

setup:
	LDI R16, (1<<CLKPCE) ; aqui se habilita para que se pueda  configurar
	STS CLKPR, R16
	LDI R16, 0b0000_0001 ; A 4Mhz
	STS CLKPR, R16
	

	call prescaler


	; ACTIVAR LOS PUERTOS
	;ACTIVAR PUERTOS C
	LDI R16,0xF0 ; CONFIUGURAR SI SON ENTRADA: 1PULL UP, SI ES SALIDA 1 5V
	OUT DDRC, R16 ;SE CONFIGURARON LOS PINES DE OUTPUTS/INPUTS, 1 SALIDA 0  ENTRADA
	LDI R17,0x03
	OUT PORTC, R17
	; ACTIVAR PUERTOS B
	LDI R16, 0xFF 
	OUT DDRB, R16 ;SE CONFIGURARON LOS PINES DE OUTPUTS/INPUTS 1 SALIDA 0  ENTRADA
	LDI R17, 0x00 ; CONFIUGURAR SI SON ENTRADA: 1PULL UP, SI ES SALIDA 1 5V
	OUT PORTB, R17
	;ACTIVAR PUERTOS D
	LDI R16, 0xFF
	LDI R17, 0x00
	OUT DDRD, R16 ;SE CONFIGURARON LOS PINES DE OUTPUTS/INPUTS 1 SALIDA 0  ENTRADA
	OUT PORTD, R17
	LDI R16, 0x00
	STS UCSR0B, R16
	; CONFIGURACIÓN DEL DISPLAY PA QUE EMPIECE EN 0
	LDI ZH, HIGH(TABLAD<<1) ; CON ESTO SE LOGRA QUE EL DISPLAY EMPIECE EN 0
	 LDI ZL, LOW(TABLAD<<1)
	 LPM R21, Z
	 OUT PORTD, R17
	 LDI R22, 1

MAIN_LOOP:	
	LDI R25, 254
	SBIS PINC,  PC0	 ; SI ES VERDADERO QUE SUME
	JMP DELAY
	SBIS PINC, PC1
	JMP DELAY		 ;SI ES FALSO QUE RESTE	
	CP R17, R19
	BREQ ALARMA
	IN R16, TIFR0
	SBRS R16, TOV0 ;   SE COMPARA SI LA BANDER DE OVERFLOW TA ARRIBA
	RJMP MAIN_LOOP

	LDI R16, 158
	OUT TCNT0, R16 

	SBI TIFR0, TOV0 ; AQUI SE APAGA LA BANDERA DE OVERFLOW 

	INC R20 
	CPI R20, 100
	BRNE MAIN_LOOP
	CLR R20
CONTAR_LEDS:
	CPI R17, 0b0001_1111
	BREQ REINICIAR_LEDS ; SI EL NUMERO ES MAYOR A 15 ENTONCES LAS LEDS SE APAGAN TODAS
	INC R17				 ;AQU[I SE INCREMENTA PARA QUE SE REPRESENTE EN LAS LEDS
	OUT PORTB, R17
	RJMP MAIN_LOOP
;*******************************************************************************************************************************
; SUBRUTINAS
;*******************************************************************************************************************************
ALARMA:
	CLR R17
	SBIS PORTC, PC5
	RJMP PRENDER
	SBIC PORTC, PC5
	RJMP APAGAR
	RJMP  MAIN_LOOP
PRENDER:
	SBI PORTC, PC5
	JMP MAIN_LOOP
APAGAR:
	CBI PORTC, PC5
	JMP MAIN_LOOP
COMPROBAR_BOTO:
	IN R18, PINC
	CPI R18, 0x03
	BREQ MAIN_LOOP ; SALTA SI NO ES IGUAL
	SBIS PINC,  PC0	 ; SI ES VERDADERO QUE SUME
	JMP SUMAR
	SBIS PINC, PC1
	JMP RESTAR		 ;SI ES FALSO QUE RESTE
	JMP MAIN_LOOP
SUMAR: 
	IN R18, PINC
	SBRS R18, PC0 ; SI EL BIT NO ES 1 ENTONCES QUE REGRESE AL RESTAR
	JMP SUMAR
	CPI R19, 0x0F ; SI ES F NO HACE NADA
	BREQ MAIN_LOOP
	 INC R19 ;: SE INCREMENTE PARA QUE NO SE PASE DE15 LA TABLA Y SALGA UN VALOR RANDOM
	 ADD ZL, R22
	 LPM R21, Z
	 OUT PORTD, R21

	JMP MAIN_LOOP
RESTAR:
	IN R18, PINC
	SBRS R18, PC1 ; SI EL BIT NO ES 1 ENTONCES QUE REGRESE AL RESTAR
	JMP RESTAR
	CPI R19, 0x00 ; SE COMPARA PARA QUE SI ES 0 QUE NO HAGA NADA
	BREQ SALTAR
	 DEC R19 ;: SE DECREMENTA PARA QUE NO SE PASE DE15 LA TABLA Y SALGA UN VALOR RANDOM
	 SUB ZL, R22
	 LPM R21, Z
	 OUT PORTD, R21
	JMP MAIN_LOOP

REINICIAR_LEDS:
	CLR R17 ;  AQUI APAGAMOS LAS TODAS LAS LEDS
	RET
	
prescaler:
	LDI R16, (1<<CS02)|(1<<CS00) ; SE CONFIGURA EL PRESACALER 1024
	OUT TCCR0B, R16

	LDI R16, 158 ; LE CARGO EL VALOR DEL MAXIMO
	OUT TCNT0, R16 ; CARGO VALOR INICAL DEL CONTADPR

	RET ; REGRESAR AL MAIN LOOP
DELAY: 
	LDI R24, 254
LOOP_DELAY:
	DEC R24
	BRNE LOOP_DELAY
	DEC R25
	BRNE DELAY
	RJMP COMPROBAR_BOTO
SALTAR:
	JMP MAIN_LOOP