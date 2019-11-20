.386
DATA SEGMENT USE16
CHOICE_PROMPT   DB   'Please choose operation mode:',0AH,0DH,'1.Input record 2.Query record',0AH,0DH,'$'  ;注意，这里的是变量而不是标号 0DH是回车 0AH是换行
INVALID_PROMPT DB 0AH,0DH,'Invalid input',0AH,0DH,'$'
INSERT_PROMPT DB 0AH,0DH,'Start input',0AH,0DH,'$'
QUERY_PROMPT DB 0AH,0DH,'Start query','$'
ASK_NUMBER DB 0AH,0DH,'Please Input the Student number',0AH,0DH,'$'
HEADER	DB	0AH,0DH,'NUMBER',09H,'SCORE',09H,'RANK',09H,0AH,0DH,'$'
FOUND_TARGET DB 0AH,0DH,'Student found!','$'
LIMIT_PROMPT DB 0AH,0DH,'Reach the upper limit',0AH,0DH,'$'
NUMBER_PROMPT DB 0AH,0DH,'Please Input Student number',0AH,0DH,'$'
SCORE_PROMPT DB 0AH,0DH,'Please Input Student score',0AH,0DH,'$'
RANK_PROMPT DB 0AH,0DH,'Please Input Student rank',0AH,0DH,'$'
NOT_FOUND DB 0AH,0DH,'Student not found',0AH,0DH,'$'
TAB	DB	09H,'$'
DEBUG DB 0AH,0DH,'DEBUG',0AH,0DH,'$'
N	EQU  3
INBUF	DB      6 ;定义一个字大小的缓冲区,一个ASCII就是一个字节了，回车也会占用一个字节，最长的是学号，有5位，所以缓冲区要分配6个字节
    	DB      0
        DB      6       DUP(0)
OUTBUF	DB	18	DUP(0),0AH,0DH,'$'	;输出暂存
ENGLI	DW	N*9 DUP(0) ;用于储存具体数据的 每一项用3个字储存
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
PRINT   MACRO   A           ;使用宏定义
        PUSH AX
		LEA DX,A
        MOV AH,9
        INT 21H
		POP AX
        ENDM
CHOOSE:  
        PRINT   CHOICE_PROMPT ;提示用户输入
        MOV AH,1
        INT 21H             ;等待用户输入AL
        CMP AL,49   ;1 ascii 49
        JE  INSERT
        CMP AL,50   ;2 ascii
        JE  QUERY
		CMP AL,51H
		JE 	EXIT
		CMP AL,71H
		JE	EXIT
        PRINT   INVALID_PROMPT
        JMP CHOOSE
INSERT:
		CALL CLEAR ;先清空储存区
        MOV BX,0H    ;用于记录输入的数量
        PRINT   INSERT_PROMPT
		LEA AX,ENGLI
INPUT:
        CMP BX,N    ;首先判断是否还可以继续进行输入
        JAE LIMIT
        ;进行输入 学号，分数，排名 	
        PRINT NUMBER_PROMPT ;还需要仔细查看关于输入缓冲区的问题
		CALL INPUT_PROC	;向缓冲区输入字符串，长度为一个字，首先输入学号,注意在字符串操作中DI会改变，使用AX暂存储存开始的位置
		PRINT SCORE_PROMPT
		CALL INPUT_PROC
		PRINT RANK_PROMPT
		CALL INPUT_PROC
        INC BX       
        JMP INPUT ;继续下一个输入

LIMIT:
        PRINT LIMIT_PROMPT
        JMP CHOOSE
QUERY: 
        PRINT QUERY_PROMPT
		;要求输入学号
		PRINT ASK_NUMBER
		PRINT HEADER
		LEA DX,INBUF
		MOV AH,10
		INT 21H
		MOV CH,0
		MOV CL,INBUF+1
		CMP CX,1
		JNE	DONTQUIT
		CMP BYTE PTR INBUF+2,'q'
		JE	EXIT
		CMP BYTE PTR INBUF+2,'Q'
		JE	EXIT
DONTQUIT:
		MOV CX,N
		LEA AX,ENGLI
		MOV SI,AX
		PUSH AX
SEARCH:
		PUSH CX
		MOV CH,0       ;SEARCH会影响CX
		MOV CL,INBUF+1
		LEA DI,INBUF
		ADD DI,2
		REPZ CMPSB
		POP CX ;恢复CX
		JNE NOTMATCH ;这个串不匹配的话进行下一个学号的比较
		JMP FOUND;如果学号相同		
NOTMATCH: ;一个学号不匹配
		POP AX
		DEC CX ;
		CMP CX,0
		JL NOTFOUND
		ADD AX,18
		MOV SI,AX
		PUSH AX
		JMP SEARCH
NOTFOUND:
		PRINT NOT_FOUND
		JMP CHOOSE
FOUND:		
		;AX起始的9个字区域，为记录
		LEA DI,OUTBUF
		MOV SI,AX
		MOV CX,18
		CLD
		REP MOVSB
		;按书上的格式显示
		PRINT OUTBUF
		;PRINT FOUND_TARGET
        JMP CHOOSE
EXIT:
        MOV AH,4CH
        INT 21H
INPUT_PROC	PROC	NEAR ;定义一个获取缓冲区输入的子程序
PUSH CX
PUSH AX
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
CMP CX,1
JNE COPY
CMP BYTE PTR INBUF+2,51H ;大写Q
JE  EXIT
CMP BYTE PTR INBUF+2,71H
JE EXIT
COPY:
POP AX
MOV DI,AX
ADD SI,2
CLD
REP MOVSB

POP CX
ADD AX,6
RET
INPUT_PROC	ENDP

CLEAR	PROC	NEAR ;用于清空储存区域的子程序
PUSH BX
PUSH CX
LEA	BX,ENGLI
MOV CX,N*18
CLE:
MOV BYTE PTR [BX],0
INC BX
LOOP CLE

LEA BX,OUTBUF
MOV CX,18
CLOUT:
MOV BYTE PTR [BX],0
INC BX
LOOP CLOUT

POP CX
POP BX
RET
CLEAR	ENDP
CODE ENDS
END START