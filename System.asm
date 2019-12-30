MOV AX, CS	;Nie można przypisać stałej bezpośrednio do DS.
MOV DS, AX	;Ustawia Data Segment na wartość Code Segment.

Boot:
	MOV AH, 0x00		;Rodzaj przerwania: zmiana trybu graficznego.
	MOV AL, 0x04		;Argument przerwania: 320x200, 4 kolory.
	INT 0x10		;Wywołanie przerwania obsługi ekranu.
	MOV AH, 0x0B		;Rodzaj przerwania: zmiana palety.
	MOV BH, 0x01		;Argument przerwania: zmiana frontu.
	MOV BL, 0x00		;Argument przerwania: wybór frontu.
	INT 0x10		;Wywołanie przerwania obsługi grafiki.
	
	MOV BL, 0x02		;Argument funkcji: kolor czerwony.
	MOV SI, szBoot1		;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wyświetlenie powitania
	
	MOV BL, 0x03		;Argument funkcji: kolor żółty.
	MOV SI, szBoot2		;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wyświetlenie powitania
	
	MOV BL, 0x01		;Argument funkcji: kolor zielony.
	MOV SI, szBoot3		;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wyświetlenie powitania
	
	MOV BL, 0x03		;Argument funkcji: kolor żółty.
	MOV SI, szBoot4		;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wyświetlenie powitania
	
	MOV BL, 0x01		;Argument funkcji: kolor zielony.
	MOV SI, szBoot5		;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wyświetlenie powitania
	
	MOV BL, 0x03		;Argument funkcji: kolor żółty.
	MOV SI, szBoot6		;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wyświetlenie powitania

Prompt:
	MOV BL, 0x02		;Argument funkcji: kolor czerwony.
	MOV SI, szPrompt	;Argument funkcji: adres na pierwszy znak ciągu.
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
	CMP SI, 0x100F		;sprawdzenie długości polecenia
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
	MOV BL, 0x01		;Argument przerwania: kolor zielony.
	MOV AH, 0x0E		;przerwanie VGA: wypisanie znaku i przejście w prawo
	INT 0x10		;wywołanie przerwania VGA
	JMP .ReadKey
.Enter:
	CMP SI, 0x1000		;sprawdzenie, czy ciąg nie jest pusty
	JZ .ReadKey
	MOV BYTE [SI], 0x00	;zakończenie stringa
	CALL PrintNewLine

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
	CMP AL, 0x00		;czy dotarliśmy do końca polecenia?
	JZ .SkipAddress
	INC DI			;jeśli nie, to idziemy dalej
	JMP .Forward
.SkipAddress:
	ADD DI, 0x03		;przeskakujemy koniec stringa i adres
	MOV AL, [DI]		;sprawdzenie, czy to nie koniec listy
	CMP AL, 0xFF		;czy koniec listy?
	JZ .Unknown		;zatem nieznane polecenie
	JMP .Rewind
.Execute:
	INC DI			;przejdź do początku adresu programu
	CALL [DI]		;wykonaj program!
	JMP Prompt		;gdy program się zakończy, wróć do linii poleceń
.Unknown:
	MOV BL, 0x02		;Argument funkcji: kolor czerwony.
	MOV SI, szUnknown	;Argument funkcji: adres na pierwszy znak ciągu.
	CALL Print		;wypisanie komunikatu o błędzie
	JMP Prompt		;powrót do linii poleceń

Print: ;Wymaga: SI - adres pierwszego znaku, BL - kolor
	MOV AH, 0x0E		;przerwanie VGA: wyświetlenie znaku
.Loop:
	MOV AL, [SI]		;pobranie znaku spod adresu
	CMP AL, 0x00		;sprawdzenie, czy nie natrafiono na koniec stringa
	JZ .End
	INT 0x10		;wywołanie przerwania VGA
	INC SI			;przejście do kolejnego adresu
	JMP .Loop
.End:
	RET			;powrót z funkcji

PrintBCD:
	MOV AH, 0x0E
	MOV AL, BH
	AND AL, 0xF0
	SHR AL, 0x04
	ADD AL, '0'
	INT 0x10
	MOV AL, BH
	AND AL, 0x0F
	ADD AL, '0'
	INT 0x10
	RET

PrintNewLine:
	MOV AH, 0x0E
	MOV AL, 0x0D
	INT 0x10
	MOV AL, 0x0A
	INT 0x10
	RET

szBoot1 DB 'Witaj w moim systemie!', 0x0D, 0x0A, 0x0D, 0x0A, 0x00
szBoot2 DB "Wpisz ", 0x00
szBoot3 DB "POMOC", 0x00
szBoot4 DB " i nacisnij ", 0x00
szBoot5 DB "ENTER", 0x00
szBoot6 DB " aby", 0x0D, 0x0A, "zobaczyc liste dostepnych komend.", 0x0D, 0x0A, 0x00
szPrompt DB 0x0D, 0x0A, '>', 0x00
szUnknown DB 'Nieznane polecenie!', 0x0D, 0x0A, 0x00

;Lista programów
rgProgs DB 'AUTOR', 0x00
DW Author
DB 'CZAS', 0x00
DW Time
DB 'DATA', 0x00
DW Date
DB 'POMOC', 0x00
DW Help
DB 'WERSJA', 0x00
DW Version
DB 'WYCZYSC', 0x00
DW Clear
DB 0xFF				;znak końca listy

Author:
	MOV BL, 0x03
	MOV SI, szAuthorMsg
	CALL Print
	RET
szAuthorMsg DB 'Autorem jest Maciej Gabrys, gr. 211A.', 0x0D, 0x0A, 0x00

Date:
	MOV AH, 0x04		;przerwanie RTC: odczyt daty
	INT 0x1A		;wywołanie przerwania RTC
	JC .Err			;obsługa braku RTC
	MOV BH, CH
	MOV BL, 0x03
	CALL PrintBCD
	MOV BH, CL
	CALL PrintBCD
	MOV AL, '-'
	INT 0x10
	MOV BH, DH
	CALL PrintBCD
	MOV AL, '-'
	INT 0x10
	MOV BH, DL
	CALL PrintBCD
	CALL PrintNewLine
	RET
.Err:
	MOV BL, 0x02
	MOV SI, szDateErr
	CALL Print
	RET
szDateErr DB 'Date nie ustawiona!', 0x0D, 0x0A, 0x00

Time:
	MOV AH, 0x02		;przerwanie RTC: odczyt czasu
	INT 0x1A		;wywołanie przerwania RTC
	JC .Err			;obsługa braku RTC
	MOV BH, CH
	MOV BL, 0x03
	CALL PrintBCD
	MOV AL, ':'
	INT 0x10
	MOV BH, CL
	CALL PrintBCD
	MOV AL, ':'
	INT 0x10
	MOV BH, DH
	CALL PrintBCD
	CALL PrintNewLine
	RET
.Err:
	MOV BL, 0x02
	MOV SI, szTimeErr
	CALL Print
	RET
szTimeErr DB 'Czas nie ustawiony!', 0x0D, 0x0A, 0x00


Help:
	MOV BL, 0x03
	MOV SI, szHelpMsg
	CALL Print
	MOV SI, rgProgs
.Loop:
	MOV AL, [SI]
	CMP AL, 0xFF
	JZ .End
	MOV DI, SI
	MOV SI, szHelpPr
	CALL Print
	MOV SI, DI
	CALL Print
	ADD SI, 0x03
	JMP .Loop
.End:
	CALL PrintNewLine
	RET
szHelpMsg DB 'Lista dostepnych komend:', 0x00
szHelpPr DB 0x0D, 0x0A, '- ', 0x00

Version:
	MOV BL, 0x03
	MOV SI, szVersionMsg
	CALL Print
	RET
szVersionMsg DB 'Wersja 0.2', 0x0D, 0x0A, 0x00

Clear:
	TIMES 24 CALL PrintNewLine
	MOV AH, 0x02		;Rodzaj przerwania: przesunięcie kursora.
	MOV BH, 0x00		;Argument przerwania: strona.
	MOV DH, 0x00		;Argument przerwania: wiersz.
	MOV DL, 0x00		;Argument przerwania: kolumna.
	INT 0x10		;Wywołanie przerwania obsługi grafiki.
	RET

TIMES 4 * 512 - ($ - $$) DB 0x00 ;Dopełnia zerami do końca sektora.
