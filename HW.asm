format PE Console
entry start
                    
include 'win32a.inc'

;
; �������: ������ ���������
; ������: ���194
; �������: 15
;
; ������:
; ����������� ���������, ����������� �
; ������� ���������� ���� � ��������� ��
; ���� 0,05% �������� ������������� ������� (1+x)^m
; ��� ��������� ��������� m � x (������������ FPU)
;

section '.data' data readable writeable
x1       dq ?                                  ; �������� ������������� �������� x:
m        dd ?                                  ; �������� ������������� �������� m:
eps1     dd 0.0005                             ; �������� 0.05%

msg1     db 'Enter x: ',0                      ; ��������� ��� ����� x
msg2     db 'Enter m: ',0                      ; ��������� ��� ����� m
msg3     db 'Wrong number.',13,10,0            ; ��������� �� ������
inDouble db '%lf',0                            ; ���� ������������� �����
inInt    db '%d',0                             ; ���� ������ �����
msg4     db 'Teylor row = %lg',13,10,0         ; ������ ��� ������ �������� ���� �������
msg5     db '(1+x)^m = %lg',13,10,0            ; ������ ��� ������ ������� �������
buf      db 256 dup(0)                         ; ��� ����� ������������� �����

section '.code' code readable executable
start:
        ccall [printf],msg1                 ; ������� � ������� Enter x:
        ccall [gets],buf                    ; ��������� ��������� ������
        ccall [sscanf],buf,inDouble,x1      ; ������ ��������� ������
        
        ; ��������� ������� �� ��������������
        cmp eax,1               
        jz  nextNum

        ; ����� ������� ��������� �� ������ � ��������� ����� ��� ���
        ccall [printf],msg3
        jmp   start

nextNum:
        ccall [printf],msg2                 ; �������� � ������� Enter m:
        push  m                             ; �������� � ���� m
        push  inInt                         ; �������� � ���� ������� ��� ������ Int
        call  [scanf]                       ; ��������� m
        add   esp, 8                        ; �������� ���� �� ���������� ����������

        ; ��������� ������������ ��������� �����
        mov ebx, [m]
        cmp ebx, 0
        jg  m1

        ; ����� ������� ��������� �� ������ � ��������� ����� ��� ���
        ccall [printf],msg3
        jmp   ex

m1:
        fld [eps1]                ; �������� ����������
        
        sub  esp, 8               ; �������� � ����� ����� ��� double
        fstp qword [esp]          ; �������� � ���� double �����     
        fld  qword [x1]           ; ��������� ��������
        sub  esp, 8               ; �������� � ����� ����� ��� double
        fstp qword [esp]          ; �������� � ���� double �����
        push [m]                  ; ���������� � ���� �������� m
        call teylorRow            ; ��������� (1+x)^m ����� ��� �������
        add  esp, 20               ; ������� ���������� ���������

        sub  esp, 8               ; �������� ����� ����
        fstp qword [esp]          ; ������� ����� ����
        push msg4                 ; ������ ���������
        call [printf]             ; ������������ ���������
        add  esp, 12              ; ��������� �����


        fld  qword [x1]            ; ��������� ��������
        sub  esp, 8               ; �������� � ����� ����� ��� double
        fstp qword [esp]          ; �������� � ���� double �����
        push [m]                  ; ������ m � ����
        call function             ; ��������� (1+x)^m
        add  esp, 16              ; ������� ���������� ���������

        sub  esp, 8               ; �������� ������ �������� (1+x)^m
        fstp qword [esp]          ; ������� ����� ����
        push msg5                 ; ������ ���������
        call [printf]             ; ������������ ���������
        add  esp, 12              ; ��������� �����
        
ex:
        ccall [_getch]            ; �������� ������� ����� �������

        push 0
        call [ExitProcess]

; ��������:
; ��������� �������� (1+x)^m � ��������� eps
; ���������:
; int m - �������� m
; double x - �������� x
; double esp - �������� ����������
; �����:
; �������� (1+x)^m ����������� ����� ��� �������
;--------------------teylorRow(int m, double x, double eps)------------------------------
teylorRow:
        push ebp
        mov  ebp,esp
        sub  esp,0ch            ; ��������� ����� � ����� ��� ��������� ����������
;��������� ����������: 
t       equ  ebp-0ch
a       equ  ebp-8h

;���������� ������� ���������:
m       equ  ebp+08h
x       equ  ebp+0ch
eps     equ  ebp+14h

;����������� ��������
        fld   qword [x]         ; ��������� �
        fimul dword [m]         ; x*m
        fstp  qword [a]         ; a = x*m
        fld1                    ; 1
        fldz                    ; s=0
        mov   ecx,1             ; n=1
m11:
        fadd  qword [a]         ; s += a;
        mov   edx, [m]          ; edx = m
        inc   ecx               ; n++;
        lea   eax, [ecx-1]      ; n-1
        sub   edx, eax          ; m-n+1
        cmp   edx, 0            ; ��������� ��� m-n+1 == 0
        je    m11               ; ���������� �������� �����
        fld   qword [a]         ; a
        fmul  qword [x]         ; a*x
        mov   [t], edx          ; t=m-n+1
        fidiv dword [t]         ; a*x/(m-n+1)
        lea   eax,[ecx+1]       ; n+1
        mov   [t],eax           ; t=n+1
        fidiv dword [t]         ; a*x/(2n-1)/(n+1)
        fst   qword [a]         ; a = a*x/(2n-1)/(n+1);
        fabs                    ; |a|
        fcomp qword [eps]       ; �������� |a| c eps
        fstsw ax;               ; ��������� ����� ��������� � ��
        sahf;                   ; ������� ah � ����� ����������
        jnb   m11;              ; ���� |a|>=esp, ���������� ����
        faddp st1,st            ; 1+���������� �����
        leave              
        ret
;----------------------------------------------------------------------------------------

; ��������:
; ��������� ������ �������� (1+x)^m
; ���������:
; double x - �������� x
; int m - �������� m
; �����:
; ������ �������� �������
; ����������:
; ���������� ������ ����� cdecl
; --------------------function(double x, int m)------------------------------------------
function:
        push ebp
        mov  ebp,esp
        sub  esp,04h            ; ��������� ����� � ����� ��� ��������� ����������
;��������� ����������: 
t       equ  ebp-04h

;���������� ��������
        fld1                    ; ��� ���������
        fld   qword [ebp+12]    ; x
        fld1                    ; 1
        faddp st1, st           ; x+1
        mov   ecx, 1            ; ecx = 1
powLoop:
        cmp   ecx, [ebp+8]      ; m
        jge   endPowLoop        ; ���������� �����
        fmul  st1, st           ; (1+x)^(ecx-1) * (1+x)
        inc   ecx               ; ecx++
        jmp   powLoop           ; ������������ � ������ �����
endPowLoop:
        fmulp st1, st
        add   esp, 4
        pop   ebp
        ret
; ---------------------------------------------------------------------------------------

section '.idata' import data readable

library kernel,'kernel32.dll',\
        user,'user32.dll',\
        msvcrt,'msvcrt.dll'

import  kernel,\
        ExitProcess,'ExitProcess'

import  msvcrt,\
        sscanf,'sscanf',\
        gets,'gets',\
        _getch,'_getch',\
        printf,'printf',\
        scanf,'scanf'
