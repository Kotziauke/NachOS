ORG 0x7C00			;ustawienie offsetu
PUSH CS
POP DS				;łączenie segmentu danych z segmentem kodu

Booting:
	MOV SI, szBooting
	CALL Print		;wyświetlenie powitania

Prompt:
	MOV SI, szPrompt
	CALL Print		;wyświetlenie znaku zachęty
	MOV SI, 0x1000		;przewinięcie bufora wprowadzanego polecenia
.ReadKey:
	MOV AH, 0x00		;przerwanie klawiatury: odczyt znaku
	INT 0x16		;wywołanie przerwania klawiatury
	CMP AL, 0x0D		;czy znak to enter?
	JZ .Enter
	CMP AL, 0x08		;czy znak to backspace?
	JNZ .SkipBackspace
	CMP SI, 0x1000		;sprawdzenie, czy ciąg nie jest już pusty
	JZ .ReadKey
	DEC SI			;zmniejszenie bufora
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
	CMP SI, 0x1007		;sprawdzenie długości polecenia
	JZ .ReadKey
	CMP AL, 0x5B		;sprawdzenie, czy nie wprowadzono małej litery
	JC .SkipUpperCase
	SUB AL, 0x20		;zamiana na wielką literę
.SkipUpperCase:
	CMP AL, 0x41		;sprawdzenie, czy znak jest mniejszy od wielkiego A
	JC .ReadKey
	CMP AL, 0x5B		;sprawdzenie, czy znak jest większy od wielkiego Z
	JNC .ReadKey
	MOV BYTE [SI], AL	;zapisanie znaku w buforze
	INC SI			;zwiększenie licznika
	MOV AH, 0x0E		;przerwanie VGA: wypisanie znaku i przejście w prawo
	INT 0x10		;wywołanie przerwania VGA
	JMP .ReadKey
.Enter:
	MOV BYTE [SI+1], 0x00	;zakończenie stringa
	MOV AH, 0x0E		;przerwanie VGA: wyświetlenie znaku
	MOV AL, 0x0D		;\r
	INT 0x10		;wywołanie przerwania VGA
	MOV AL, 0x0A		;\n
	INT 0x10		;wywołanie przerwania VGA

Loader:
	MOV DI, rgProgs		;ustawiene się na początku listy poleceń
.Rewind:
	MOV SI, 0x1000		;przewinięcie bufora wprowadzanego polecenia
.Compare:
	MOV AL, [DI]		;wyłuskanie znaku spod adresu listy
	MOV BL, [SI]		;wyłuskanie znaku spod adresu polecenia
	CMP AL, BL		;porównanie znaków
	JNZ .Forward		;jeśli inne, to przeskocz do kolejnego polecenia
	CMP AL, 0x00		;czy koniec stringa?
	JZ .Execute		;jeśli tak, to polecenie jest prawidłowe
	INC DI			;jeśli nie koniec, to czytaj dalej
	INC SI			;...
	JMP .Compare		;przejdź do kolejnego znaku
.Forward:
	MOV AL, [DI]
	CMP AL, 0x00
	JZ .SkipAddress
	INC DI
	JMP .Forward
.SkipAddress:
	ADD DI, 0x03		;przeskakujemy koniec stringa i adres
	MOV AL, [DI]		;sprawdzenie, czy to nie koniec listy
	CMP AL, 0x00
	JZ .Unknown
	JMP .Rewind
.Execute:
	INC DI			;przejdź do początku adresu programu
	CALL [DI]		;wykonaj program!
	JMP Prompt		;gdy program się zakończy, wróć do linii poleceń
.Unknown:
	MOV SI, szUnknown
	CALL Print		;wypisanie komunikatu o błędzie
	JMP Prompt		;powrót do linii poleceń

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

;Lista programów
rgProgs DB 'AUTHOR', 0x00
DW Author
DB 'VERSION', 0x00
DW Version
DB 0x00				;koniec ciągu

Author:
	MOV SI, szAuthor
	CALL Print
	RET

Version:
	MOV SI, szVersion
	CALL Print
	RET

szBooting DB 'Dipping NachOS...', 0x0D, 0x0A, 0x00
szPrompt DB 0x0D, 0x0A, '>', 0x00
szUnknown DB 'Uknown command.', 0x0D, 0x0A, 0x00
szAuthor DB 'Maciej', 0x0D, 0x0A, 0x00
szVersion DB 'Version 0.1', 0x0D, 0x0A, 0x00

TIMES 510-($-$$) DB 0x00	;wypełnienie zerami do końca segmentu
DW 0xAA55			;ustawienie sygnatury zgodnej ze standardem IBM PC