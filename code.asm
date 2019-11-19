.386
DATA SEGMENT USE16
CHOICE_PROMPT   DB   'Please choose operation mode:',0AH,0DH,'1.Input record 2.Query record',0AH,0DH,'$'  ;注意，这里的是变量而不是标号 0DH是回车 0AH是换行
INVALID_PROMPT DB 0AH,0DH,'Invalid input',0AH,0DH,'$'
INSERT_PROMPT DB 0AH,0DH,'Start input',0AH,0DH,'$'
QUERY_PROMPT DB 0AH,0DH,'Start query','$'
LIMIT_PROMPT DB 0AH,0DH,'Reach the upper limit',0AH,0DH,'$'
N   DW  000AH
DATA ENDS

STACK SEGMENT USE16 STACK
DB 200 DUP(0)
STACK ENDS

CODE SEGMENT USE16
ASSUME CS:CODE,DS:DATA,SS:STACK
START:  
        MOV AX,DATA
        MOV DS,AX            ;设置数据段寄存器的操作不可少
PRINT   MACRO   A            ;使用宏定义
        LEA DX,A
        MOV AH,9
        INT 21H
        ENDM
CHOOSE:  
        PRINT   CHOICE_PROMPT ;提示用户输入
        MOV AH,1
        INT 21H             ;等待用户输入AL
        CMP AL,49   ;1 ascii 49
        JE  INSERT
        CMP AL,50   ;2 ascii
        JE  QUERY
        PRINT   INVALID_PROMPT
        JMP CHOOSE
INSERT:
        MOV BX,0H    ;用于记录输入的数量
        PRINT   INSERT_PROMPT
INPUT:
        CMP BX,N    ;首先判断是否还可以继续进行输入
        MOV AH,1
        INT 21H
        JAE LIMIT
        ;进行输入
        INC BX       
        JMP INPUT
LIMIT:
        PRINT LIMIT_PROMPT
        JMP CHOOSE
QUERY: 
        PRINT   QUERY_PROMPT
        JMP EXIT
EXIT:
        MOV AH,4CH
        INT 21H
CODE ENDS
END START