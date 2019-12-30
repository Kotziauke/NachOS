;Źródło: https://stackoverflow.com/a/39537072.

CPU 8086	;Ogranicza zestaw instrukcji do Intela 8086.
ORG 0x7C00	;Offset, względem którego przesunięte będą adresy.

Loader:
	MOV AX, 0x0000	;Nie można przypisać stałej bezpośrednio do DS.
	MOV DS, AX	;Ustawia Data Segment na 0x0000.
	CLI	;Wyłącza obsługę przerwań (koniecznie dla Intela 8088).
	MOV SS, AX	;Ustawia Stack Segment na 0x0000.
	MOV SP, 0x7C00	;Ustawia Stack Pointer na 0x7C00.
	STI	;Włącza z powrotem obsługę przerwań.
.Reset:
	MOV AH, 0x00	;Rodzaj przerwania: reset stacji dyskietek.
	INT 0x13	;Wywołanie przerwania stacji dyskietek.
	JC .Reset	;Powtórzenie w przypadku niepowodzenia.
	MOV CH, 0x00	;Argument przerwania: numer cylindra.
	MOV CL, 0x02	;Argument przerwania: numer sektora.
	MOV DH, 0x00	;Argument przerwania: numer strony.
	MOV AX, 0x07E0	;Nie można przypisać stałej bezpośrednio do ES.
	MOV ES, AX	;Argument przerwania: segment bufora.
	MOV BX, 0x0000	;Argument przerwania: offset bufora.
.Read:
	MOV AH, 0x02	;Rodzaj przerwania: odczyt z dyskietki.
	MOV AL, 0x02	;Argument przerwania: ilość sektorów do oczytu.
	INT 0x13	;Wywołanie przerwania stacji dyskietek.
	JC .Read	;Powtórzenie w przypadku niepowodzenia.
	JMP 0x07E0:0x0000	;Daleki skok do załadowanego systemu.

TIMES 510 - ($ - $$) DB 0x00	;Dopełnia zerami do końca segmentu.
DW 0xAA55	;Ustawia sygnaturę MBR zgodną z IBM PC.
