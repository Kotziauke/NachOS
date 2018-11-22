ORG 0x7C00			;ustawienie offsetu
PUSH CS
POP DS				;łączenie segmentu danych z segmentem kodu

Booting:
	MOV SI, szBooting
	CALL Print		;wyświetlenie powitania

Prompt:
	MOV SI, szPrompt
	CALL Print		;wyświetlenie znaku zachęty
	MOV DI, 0x0000		;przewinięcie bufora wprowadzanego polecenia
.ReadKey:
	MOV AH, 0x00		;przerwanie klawiatury: odczyt znaku
	INT 0x16		;wywołanie przerwania klawiatury
	CMP AL, 0x0D		;czy znak to enter?
	JZ .Enter
	CMP AL, 0x08		;czy znak to backspace?
	JNZ .SkipBackspace
	CMP DI, 0x0000		;sprawdzenie, czy ciąg nie jest już pusty
	JZ .ReadKey
	DEC DI			;zmniejszenie bufora
	MOV AH, 0x03		;przerwanie VGA: pobranie pozycji kursora
	MOV BH, 0x00		;numer strony, równy zero
	INT 0x10		;wywołanie przerwania VGA
	DEC DL			;cofnięcie kursora
	MOV AH, 0x02		;przerwanie VGA: ustawienie pozycji kursora
	INT 0x10		;wywołanie przerwania VGA
	MOV AH, 0x0A		;przerwanie VGA: tylko wypisanie znaku
	MOV AL, 0x20		;spacja
	MOV BH, 0x00		;numer strony, równy zeru
	MOV CX, 0x0001		;ilość znaków do wypisania
	INT 0x10		;wywołanie przerwania VGA
.SkipBackspace:
	CMP DI, 0x000F		;sprawdzenie długości polecenia
	JZ .ReadKey
	CMP AL, 0x5B		;sprawdzenie, czy nie wprowadzono małej litery
	JC .SkipUpperCase
	SUB AL, 0x20		;zamiana na wielką literę
.SkipUpperCase:
	CMP AL, 0x41		;sprawdzenie, czy znak jest mniejszy od wielkiego A
	JC .ReadKey
	CMP AL, 0x5B		;sprawdzenie, czy znak jest większy od wielkiego Z
	JNC .ReadKey
	MOV BYTE [DI], AL	;zapisanie znaku w buforze
	INC DI			;zwiększenie licznika
	MOV AH, 0x0E		;przerwanie VGA: wypisanie znaku i przejście w prawo
	INT 0x10		;wywołanie przerwania VGA
	JMP .ReadKey
.Enter:
	MOV BYTE [DI+1], 0x00	;zakończenie stringa
	MOV AH, 0x0E		;przerwanie VGA: wyświetlenie znaku
	MOV AL, 0x0D		;\r
	INT 0x10		;wywołanie przerwania VGA
	MOV AL, 0x0A		;\n
	INT 0x10		;wywołanie przerwania VGA
	JMP Prompt

Print:
	MOV AH, 0x0E		;przerwanie VGA: wyświetlenie znaku
.Loop:
	MOV AL, [SI]		;pobranie znaku spod adresu
	CMP AL, 0		;sprawdzenie, czy nie natrafiono na koniec stringa
	JZ .End
	INT 0x10		;wywołanie przerwania VGA
	INC SI			;przejście do kolejnego adresu
	JMP .Loop
.End:
	RET			;powrót z funkcji

szBooting DB 'Dipping NachOS...', 0x0D, 0x0A, 0x00
szPrompt DB 0x0D, 0x0A, '>', 0x00

TIMES 510-($-$$) DB 0x00	;wypełnienie zerami do końca segmentu
DW 0xAA55			;ustawienie sygnatury zgodnej ze standardem IBM PC