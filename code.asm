.386
DATA SEGMENT USE16
CHOICE_PROMPT   DB   'Please choose operation mode:',0AH,0DH,'1.Input record 2.Query record',0AH,0DH,'$'  ;注意，这里的是变量而不是标号 0DH是回车 0AH是换行
INVALID_PROMPT DB 0AH,0DH,'Invalid input',0AH,0DH,'$'
INSERT_PROMPT DB 0AH,0DH,'Start input',0AH,0DH,'$'
QUERY_PROMPT DB 0AH,0DH,'Start query','$'
LIMIT_PROMPT DB 0AH,0DH,'Reach the upper limit',0AH,0DH,'$'
NUMBER_PROMPT DB 0AH,0DH,'Please Input Student number',0AH,0DH,'$'
SCORE_PROMPT DB 0AH,0DH,'Please Input Student score',0AH,0DH,'$'
RANK_PROMPT DB 0AH,0DH,'Please Input Student rank',0AH,0DH,'$'
N	EQU  5
INBUF	DB      6 ;定义一个字大小的缓冲区,一个ASCII就是一个字节了，回车也会占用一个字节，最长的是学号，有5位，所以缓冲区要分配6个字节
    	DB      0
        DB      6       DUP(0)
ENGLI DW  9*N DUP(0) ;用于储存具体数据的 每一列用3个字储存
DATA ENDS

STACK SEGMENT USE16 STACK
DB 200 DUP(0)
STACK ENDS

CODE SEGMENT USE16
ASSUME CS:CODE,DS:DATA,ES:DATA,SS:STACK
START:  
        MOV AX,DATA
        MOV DS,AX            ;设置数据段寄存器的操作不可少
		MOV ES,AX
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
        LEA DI,ENGLI  ;储存区
        PRINT   INSERT_PROMPT

INPUT:
        CMP BX,N    ;首先判断是否还可以继续进行输入
        JAE LIMIT
        ;进行输入 学号，分数，排名 	
        PRINT NUMBER_PROMPT ;还需要仔细查看关于输入缓冲区的问题
        CALL INPUT_PROC	;向缓冲区输入字符串，长度为一个字，首先输入学号
		ADD	DI,6;DS：SI指向下一个字储存单元
		PRINT SCORE_PROMPT
		CALL INPUT_PROC
		ADD DI,6
		PRINT RANK_PROMPT
		CALL INPUT_PROC
		ADD DI,6
        INC BX       
        JMP INPUT ;继续下一个输入

LIMIT:
        PRINT LIMIT_PROMPT
        JMP CHOOSE
QUERY: 
        PRINT QUERY_PROMPT
        JMP EXIT
EXIT:
        MOV AH,4CH
        INT 21H
INPUT_PROC	PROC	NEAR ;定义一个获取缓冲区输入的子程序
LEA	DX,INBUF
MOV	AH,10
INT	21H
LEA SI,INBUF ;DS:SI -> ES:DI  DI在子程序外设置
MOV CL,INBUF+1 ;获取缓冲区字符长度
			  ;如果缓冲区字符长度为0（只有回车，那么返回程序一开始的地方
MOV CH,0
CMP CX,0
JE	CHOOSE
;如果字符长度为1,且第一个字符为Q，退出程序
ADD SI,2
CLD
REP MOVSB
RET
INPUT_PROC	ENDP
		

CODE ENDS
END START