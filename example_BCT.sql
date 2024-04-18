
1. 블록체인테이블 실습 준비 

유저 bct, bct_usr1를 생성하고 블록체인 패키지 실행 권한을 부여합니다.

sqlplus sys/Welcome1@pdb17 as sysdba

REM alter system set compatible = '19.10.0' scope=spfile;


create user bct identified by Welcome1 default tablespace users;
grant create session, create table, unlimited tablespace TO bct;
grant execute on sys.dbms_blockchain_table to bct;
grant create any directory to bct;

create user bct_usr1 identified by Welcome1 default tablespace users;
grant create session, create table, unlimited tablespace TO bct_usr1;
grant execute on sys.dbms_blockchain_table to bct_usr1;
grant create any directory to bct_usr1;

create user bct_usr2 identified by Welcome1 default tablespace users;
grant create session, create table, unlimited tablespace TO bct_usr2;
grant execute on sys.dbms_blockchain_table to bct_usr2;
grant create any directory to bct_usr2;


2. 블록체인테이블 생성 및 메타정보 확인

2.1 블록체인 테이블 생성

블록체인 테이블 emp_hist_bct를 생성합니다. 블록체인테이블 옵션은 다음과 같습니다.
'no drop until 0 days idle' -> 해당 테이블은 n 날수 까지 drop 불가의 의미임
'no delete until 16 days after insert' -> 데이터를 insert 이후에 n 날수까지 삭제 불가 의미임
'hashing using "SHA2_512" version "v1"' -> hash 알고리즘 SHA2 512 버전 1을 의미함

conn bct/Welcome1@pdbxx

create blockchain table emp_hist_bct (
flight_order varchar2(12), 
empno varchar2(12),
emp_sosok_cd varchar2(4),
flight_min number,
flight_date date,
constraint flight_pk primary key(flight_order, empno)
)
no drop until 0 days idle
no delete until 16 days after insert
hashing using "SHA2_512" version "v1";

2.2 블록체인 테이블 메타정보 둘러보기

블록체인 테이블에 명시적으로 블록체인 메타정보가 들어 있는 걸럼명을 지정해주면 해당 정보를 볼수 있음

show user -- bct

set line 50
set pagesize 50
desc emp_hist_bct
 Name                    Null?    Type
 ----------------------- -------- ----------------
 FLIGHT_ORDER            NOT NULL VARCHAR2(12)
 EMPNO                   NOT NULL VARCHAR2(12)
 EMP_SOSOK_CD                     VARCHAR2(4)
 FLIGHT_MIN                       NUMBER
 FLIGHT_DATE                      DATE

set line 150
col table format A30
col column_name format a30 
col data_type format a30

select internal_column_id "Col ID", COLUMN_NAME , DATA_TYPE, DATA_LENGTH 
from user_tab_cols 
where table_name = 'EMP_HIST_BCT';

---------- ------------------------------ ------------------------------ -----------
         1 FLIGHT_ORDER                   VARCHAR2                                12
         2 EMPNO                          VARCHAR2                                12
         3 EMP_SOSOK_CD                   VARCHAR2                                 4
         4 FLIGHT_MIN                     NUMBER                                  22
         5 FLIGHT_DATE                    DATE                                     7
         6 ORABCTAB_INST_ID$              NUMBER                                  22
         7 ORABCTAB_CHAIN_ID$             NUMBER                                  22
         8 ORABCTAB_SEQ_NUM$              NUMBER                                  22
         9 ORABCTAB_CREATION_TIME$        TIMESTAMP(6) WITH TIME ZONE             13
        10 ORABCTAB_USER_NUMBER$          NUMBER                                  22
        11 ORABCTAB_HASH$                 RAW                                   2000
        12 ORABCTAB_SIGNATURE$            RAW                                   2000
        13 ORABCTAB_SIGNATURE_ALG$        NUMBER                                  22
        14 ORABCTAB_SIGNATURE_CERT$       RAW                                     16
        15 ORABCTAB_SPARE$                RAW                                   2000


SELECT row_retention, row_retention_locked, table_inactivity_retention, hash_algorithm  
FROM   user_blockchain_tables 
WHERE  table_name='EMP_HIST_BCT';

ROW_RETENTION ROW TABLE_INACTIVITY_RETENTION HASH_ALG
------------- --- -------------------------- --------
           16 NO                           0 SHA2_512


2.3 블록체인 테이블 특성 확인 - drop table 

drop table EMP_HIST_BCT;

Table dropped.


"no drop until 0 days idle" 지정으로 블록체인 테이블이 삭제가 됩니다. 1 이상의 값을 지정하면 지정된 날수 이후에만 테이블 drop이 가능함.
no drop 또는 no delete 만 명시한 경우는 테이블 drop 또는 row delete가 제한됨으로 어플리케이션 조건에 따라 적절히 사용이 필요함
no delete의 최소 값은 16일 임.


3. 블록체인 테이블에 데이터 추가

3.1 불록체인 테이블 다시 만들기

이번 블록체인 테이블을 생성 할 때는 no drop until n days 옵션을 사용합니다.

conn bct/Welcome1@pdbxx

create blockchain table emp_hist_bct (
flight_order varchar2(12), 
empno varchar2(12),
emp_sosok_cd varchar2(4),
flight_min number,
flight_date date,
constraint flight_pk primary key(flight_order, empno)
)
no drop until 1 days idle
no delete until 16 days after insert
hashing using "SHA2_512" version "v1";


3.2 앱 유저에게 권한 부여

3.2.1 테이블 액세스 권한 부여

블록체인 테이블에 타 유저가 데이터를 추가하기 위해서는 필요한 권한을 부여해야 합니다.

conn bct/Welcome1

grant select, insert, delete, update on emp_hist_bct to bct_usr1;

grant select, insert, delete, update on emp_hist_bct to bct_usr2;


3.3 블록체인 테이블에 데이터 삽입

conn bct_usr1/Welcome1@pdbxx
insert into bct.emp_hist_bct values('AR00001001','21-30210','AR',56,to_date('2021-03-01','YYYY-mm-dd'));
insert into bct.emp_hist_bct values('AR00001002','22-30211','AR',56,to_date('2021-03-02','YYYY-mm-dd'));
commit;

conn bct_usr2/Welcome1@pdbxx
insert into bct.emp_hist_bct values('AF00000001','21-40210','AF',84,to_date('2021-03-01','YYYY-mm-dd'));
insert into bct.emp_hist_bct values('AF00000002','21-40211','AF',100,to_date('2021-03-02','YYYY-mm-dd'));
commit;


3.3 블록체인 테이블 데이터 확인

conn bct/Welcome1@pdbxx

select * from bct.emp_hist_bct;
FLIGHT_ORDER EMPNO        EMP_ FLIGHT_MIN FLIGHT_DA
------------ ------------ ---- ---------- ---------
AF00000001   21-40210     AF           84 01-MAR-21
AF00000002   21-40211     AF          100 02-MAR-21
AR00001001   21-30210     AR           56 01-MAR-21
AR00001002   22-30211     AR           56 02-MAR-21


3.4 블록체인 테이블 데이터 메타정보 확인

conn bct_usr1/Welcome1

col hash format a50
col sign format a40
set pagesize 50
set line 250

select FLIGHT_ORDER, EMPNO, ORABCTAB_INST_ID$ Inst_id, ORABCTAB_CHAIN_ID$ chain_id,ORABCTAB_SEQ_NUM$ seq_num,ORABCTAB_HASH$ Hash, 
ORABCTAB_SIGNATURE$ sign from bct.emp_hist_bct;

FLIGHT_ORDER EMPNO           INST_ID   CHAIN_ID    SEQ_NUM HASH                                               SIGN
------------ ------------ ---------- ---------- ---------- -------------------------------------------------- ----------------------------------------
AF00000001   21-40210              1         13          1 D5D375E626279624017F2021D839EA62B7EC75AA6440EDDB51
                                                           FE2115D804EA3249D2D294F66FD56EB65B9A17FD6C3E8B496E
                                                           C56AB4CA8381990F9CCD4B38F51D

AF00000002   21-40211              1         13          2 0DA8935692BFB6420A9A7F29636A6AA001DC3D5F5FE0F942C6
                                                           2EFFFAA08B2398ACF7F409CA66EAF55E8AEDD266173C80B3B0
                                                           DEC88EAF94282BD22CF0F532362B

AR00001001   21-30210              1         28          1 E5726D81E019D6C6CF7E0501151F27194BB1E6D4B91A1D959C
                                                           6D67D4A59B18357D07A3E2F0D6954508D1A28F65B6BAB852BD
                                                           F98BFA6B226D4CB04F0B91FFF473

AR00001002   22-30211              1         28          2 9FB53720793390150D443931519568A32AC218A494F5D1B69A
                                                           985C7B416FF9506C19727B994FD703FD52B9E9467E63DE8582
                                                           90DB2AE59C9123CE7FEA562DD242


4. 블록체인테이블 특성 테스트

4.1 DML 트랜잭션 테스트

conn bct/Welcome1@pdbxx

delete from emp_hist_bct where FLIGHT_ORDER = 'AR00001001' and EMPNO = '21-30210';

ERROR at line 1:
ORA-05715: operation not allowed on the blockchain or immutable table

update emp_hist_bct set FLIGHT_MIN = '200' where FLIGHT_ORDER = 'AR00001001' and EMPNO = '21-30210';

ERROR at line 1:
ORA-05715: operation not allowed on the blockchain or immutable table

conn bct_usr1/Welcome1@pdbxx

delete from bct.emp_hist_bct where FLIGHT_ORDER = 'AR00001002' and EMPNO = '22-30211';

ERROR at line 1:
ORA-05715: operation not allowed on the blockchain or immutable table

4.2 DDL 테스트

conn bct/Welcome1@pdbxx

TRUNCATE TABLE emp_hist_bct;
ERROR at line 1:
ORA-05715: operation not allowed on the blockchain or immutable table


DROP TABLE emp_hist_bct;
ERROR at line 1:
ORA-05723: drop blockchain or immutable table EMP_HIST_BCT not allowed


ALTER TABLE emp_hist_bct NO DELETE UNTIL 18 DAYS AFTER INSERT;


Table altered.

## 로우 데이터 보호 기간 연장은 허용

SELECT row_retention, row_retention_locked, table_inactivity_retention, hash_algorithm  
FROM   user_blockchain_tables 
WHERE  table_name='EMP_HIST_BCT';

ROW_RETENTION ROW TABLE_INACTIVITY_RETENTION HASH_ALG
------------- --- -------------------------- --------
           18 NO                           1 SHA2_512


4.3 expired row 삭제 방법

conn bct/Welcome1@pdbxx

SET SERVEROUTPUT ON
DECLARE
   NUMBER_ROWS NUMBER;
BEGIN
   DBMS_BLOCKCHAIN_TABLE.DELETE_EXPIRED_ROWS('BCT','emp_hist_bct', systimestamp - 1, NUMBER_ROWS);
   DBMS_OUTPUT.PUT_LINE('Number of rows deleted=' || NUMBER_ROWS);
END;
/ 

Rows Deleted=0

Number of rows deleted=0

PL/SQL procedure successfully completed.


5. 블록체인 테이블에 들어 있는 체인 로우에 대한 무결성 검사

conn bct/Welcome1@pdbxx

DBMS_BLOCKCHAIN_TABLE.VERIFY_ROWS 패키지를 사용하여 모든 체인에 있는 모든 행의 무결성을 검사하고 선택적으로 서명도 검사 가능.
체인의 무결성이 손상되었다면 예외가 생성됩니다. 

SET SERVEROUTPUT ON
DECLARE
   row_count NUMBER;
   verify_rows NUMBER;
   instance_id NUMBER;
BEGIN
  FOR instance_id IN 1 .. 2 LOOP
    SELECT COUNT(*) INTO row_count FROM emp_hist_bct WHERE ORABCTAB_INST_ID$=instance_id;
    DBMS_BLOCKCHAIN_TABLE.VERIFY_ROWS('BCT','emp_hist_bct', NULL, NULL, instance_id, NULL, verify_rows);
    DBMS_OUTPUT.PUT_LINE('Number of rows verified in instance Id '|| instance_id || ' = '|| row_count);
  END LOOP;
END;
/

Number of rows verified in instance Id 1 = 2
Number of rows verified in instance Id 2 = 0
PL/SQL procedure successfully completed.


6. 체인 로우에 사용자 디지털 서명 추가

6.1 유저의 인증키 생성

6.1.1 bct_usr1 유저의 인증키 생성

Linux용 openssl 툴을 이용하여 RSA key 생성 및 생성된 인증 키를 DB에 등록합니다.

openssl_ROOTCA 만들기 문서 참조

6.1.2 bct_usr2 유저의 인증키 생성

openssl_ROOTCA 만들기 문서 참조

6.2 DB에 유저 인증키 등록

6.2.1 directory 생성

sqlplus bct/Welcome1@pdbxx

create or replace directory bctdir as '/home/oracle/wallet/certs';

6.2.2 사용자 인증키 등록

DBMS_USER_CERTS.ADD_CERTIFICATE 패키지를 사용하여 유저의 인증키를 등록합니다.

6.2.2.1 bct_usr1의 인증키 등록

conn bct_usr1/Welcome1@pdbxx

set serveroutput on
DECLARE 
	file BFILE;
	buffer BLOB;
	amount NUMBER := 32767;
	cert_guid RAW(16);
BEGIN 
	file := BFILENAME('BCTDIR', 'bct_user1.crt');
	DBMS_LOB.FILEOPEN(file); 
	DBMS_LOB.READ(file, amount, 1, buffer); 
	DBMS_LOB.FILECLOSE(file); 
	DBMS_OUTPUT.PUT_LINE(UTL_RAW.CAST_TO_VARCHAR2(buffer));
	DBMS_USER_CERTS.ADD_CERTIFICATE(buffer, cert_guid);
	DBMS_OUTPUT.PUT_LINE('Certificate GUID = ' || cert_guid);
END; 
/ 

Certificate GUID = 3237EF0D3B9485DF059A26AE7B0B0C50

PL/SQL procedure successfully completed.

6.2.2.2 bct_usr2의 인증키 등록

conn bct_usr2/Welcome1@pdbxx

set serveroutput on
DECLARE 
	file BFILE;
	buffer BLOB;
	amount NUMBER := 32767;
	cert_guid RAW(16);
BEGIN 
	file := BFILENAME('BCTDIR', 'bct_user2.crt');
	DBMS_LOB.FILEOPEN(file); 
	DBMS_LOB.READ(file, amount, 1, buffer); 
	DBMS_LOB.FILECLOSE(file); 
	DBMS_OUTPUT.PUT_LINE(UTL_RAW.CAST_TO_VARCHAR2(buffer));
	DBMS_USER_CERTS.ADD_CERTIFICATE(buffer, cert_guid);
	DBMS_OUTPUT.PUT_LINE('Certificate GUID = ' || cert_guid);
END; 
/ 

Certificate GUID = 51D11E21117603F3C76DEB75A718E84C

# 인증키 삭제
# exec DBMS_USER_CERTS.DROP_CERTIFICATE('51D11E21117603F3C76DEB75A718E84C')

PL/SQL procedure successfully completed.

6.2.3 DB 등록된 자신의 디지털 인증키 확인

conn bct_usr1/Welcome1@pdbxx

col USER_NAME format A20 
col DISTINGUISHED_NAME format A20 
col CERTIFICATE format A50

select * from user_certificates;

CERTIFICATE_ID                   USER_NAME            DISTINGUISHED_NAME   CERTIFICATE
-------------------------------- -------------------- -------------------- --------------------------------------------------
3237EF0D3B9485DF059A26AE7B0B0C50 BCT_USR1             OU=BCT Project Team, 2D2D2D2D2D424547494E2043455254494649434154452D2D2D
                                                      O=Oracle Korea Ltd,L 2D2D0A4D49494468544343416D3267417749424167494A414D
                                                      =Seoul City,C=KR     5359496E7A52344266344D4130474353714753496233445145
                                                                           4243775541

conn bct_usr2/Welcome1@pdbxx
CERTIFICATE_ID                   USER_NAME            DISTINGUISHED_NAME   CERTIFICATE
-------------------------------- -------------------- -------------------- --------------------------------------------------
51D11E21117603F3C76DEB75A718E84C BCT_USR2             OU=BCT Project Team, 2D2D2D2D2D424547494E2043455254494649434154452D2D2D
                                                      O=Oracle Korea Ltd,L 2D2D0A4D49494468544343416D3267417749424167494A414D
                                                      =Seoul City,C=KR     5359496E7A52344266354D4130474353714753496233445145
                                                                           4243775541



6.3 체인 로우에 디지털 서명 추가(삽입)

6.3.1 체인 로우에 디지털 서명 추가를 위하여 해당 row에서 바이트값(메시지 다이제스트)을 파일로 생성

DBMS_BLOCKCHAIN_TABLE.GET_BYTES_FOR_ROW_SIGNATURE 패키지를 사용하여 row의 hash의 바이트 값을 파일로 생성합니다.

#conn bct_usr1/Welcome1@pdbxx
#insert into bct.emp_hist_bct values('AR00001001','21-30210','AR',56,to_date('2021-03-01','YYYY-mm-dd'));
#insert into bct.emp_hist_bct values('AR00001002','22-30211','AR',56,to_date('2021-03-02','YYYY-mm-dd'));
#commit;

#conn bct_usr2/Welcome1@pdbxx
#insert into bct.emp_hist_bct values('AF00000001','21-40210','AF',84,to_date('2021-03-01','YYYY-mm-dd'));
#insert into bct.emp_hist_bct values('AF00000002','21-40211','AF',100,to_date('2021-03-02','YYYY-mm-dd'));
#commit;

conn bct_usr1/Welcome1@pdbxx

set serveroutput on
DECLARE
	row_data  	BLOB;
	buffer		RAW(4000);
	inst_id 	BINARY_INTEGER;
	chain_id  	BINARY_INTEGER;
	sequence_no BINARY_INTEGER;
	row_len 	BINARY_INTEGER;
	l_file 		UTL_FILE.FILE_TYPE;

BEGIN
	SELECT ORABCTAB_INST_ID$, ORABCTAB_CHAIN_ID$, ORABCTAB_SEQ_NUM$ 
	INTO inst_id, chain_id, sequence_no
	FROM bct.EMP_HIST_BCT WHERE flight_order = 'AR00001001' and empno = '21-30210';
	DBMS_BLOCKCHAIN_TABLE.GET_BYTES_FOR_ROW_SIGNATURE('BCT','EMP_HIST_BCT',inst_id,chain_id, sequence_no, 1, row_data);
	row_len := DBMS_LOB.GETLENGTH(row_data);
	DBMS_LOB.READ(row_data, row_len, 1, buffer);
	l_file := UTL_FILE.fopen('BCTDIR','bct_usr1_sign.dat','wb',32767);
	UTL_FILE.put_raw(l_file, buffer, TRUE);
	UTL_FILE.fclose(l_file);
END;
/

PL/SQL procedure successfully completed.

bct_usr1_sign.dat 생성 확인

ls ~oracle/wallet/certs
bct_usr1_sign.dat

ROOTCA 서버의 certs 디렉토리에 bct_usr1_sign.dat 파일 전송

6.3.2 바이트 값(메시지 다이제스트) 파일을 사용하여 인증된 디지털 서명 파일 생성

ROOTCA 서버 접속
/etc/pki/tls 

openssl dgst -sha512 -sign ./private/bct_user1.key -out ./certs/bct_usr1_sign.final ./certs/bct_usr1_sign.dat

ls ./certs/bct_usr1_sign.final

BCT DB 서버의 BCTDIR 디렉토리로 bct_usr1_sign.final 파일 전송


6.3.3 블록체인 테이블의 cained row에 인증된 디지털 서명 추가

DBMS_BLOCKCHAIN_TABLE.SIGN_ROW 패키지를 이용하여 해당 row에 서명을 추가합니다.

show user
USER is "BCT_USR1"

set serveroutput on
DECLARE
	inst_id 	BINARY_INTEGER;
	cha_id 		BINARY_INTEGER;
	seq_no 		BINARY_INTEGER;
	signature 		RAW(2000);
	cert_guid	RAW(16) := HEXTORAW('3237EF0D3B9485DF059A26AE7B0B0C50');
	file 		BFILE;
	amount		NUMBER := 2000;
	buffer		RAW(4000);
BEGIN
	SELECT ORABCTAB_INST_ID$, ORABCTAB_CHAIN_ID$, ORABCTAB_SEQ_NUM$ 
	INTO inst_id, cha_id, seq_no
	FROM bct.EMP_HIST_BCT WHERE flight_order = 'AR00001001' and empno = '21-30210';
	file := BFILENAME('BCTDIR','bct_usr1_sign.final');
	DBMS_LOB.FILEOPEN(file);
	DBMS_LOB.READ(file, amount, 1, signature);
	DBMS_LOB.FILECLOSE(file);
    DBMS_BLOCKCHAIN_TABLE.SIGN_ROW(
     	schema_name 		=> 'BCT',
     	table_name 			=> 'EMP_HIST_BCT',
     	instance_id 		=> inst_id,
     	chain_id    		=> cha_id,
     	sequence_id  		=> seq_no,
     	hash                => NULL,
     	signature 			=> signature, 
     	certificate_guid 	=> cert_guid,
     	signature_algo  	=> DBMS_BLOCKCHAIN_TABLE.SIGN_ALGO_RSA_SHA2_512);
END;
/

6.3.4 디지털 서명이 포함된 chaied row 확인

col hash format a20
col sign format a25
col ORABCTAB_SPARE$ format a30

select FLIGHT_ORDER, EMPNO, ORABCTAB_INST_ID$ inst_id, ORABCTAB_CHAIN_ID$ chain_id,ORABCTAB_SEQ_NUM$ seg_num,
ORABCTAB_HASH$ hash, ORABCTAB_SIGNATURE$ sign, ORABCTAB_SIGNATURE_ALG$ algo, ORABCTAB_SIGNATURE_CERT$ sign_cert
from bct.emp_hist_bct
where flight_order = 'AR00001001' and empno = '21-30210' ;

FLIGHT_ORDER EMPNO           INST_ID   CHAIN_ID    SEG_NUM HASH                 SIGN                            ALGO SIGN_CERT
------------ ------------ ---------- ---------- ---------- -------------------- ------------------------- ---------- --------------------------------
AR00001001   21-30210              1         28          1 E5726D81E019D6C6CF7E 201EF35BD4D447F458913B089          3 3237EF0D3B9485DF059A26AE7B0B0C50
                                                           0501151F27194BB1E6D4 586E23F97312DB7B9B2DEF892
                                                           B91A1D959C6D67D4A59B D9F472190D92E09233C7E1B66
                                                           18357D07A3E2F0D69545 409F3DBFFCFA4636DD3BB1B89
                                                           08D1A28F65B6BAB852BD 185BE69C8343ECCCDEE0A0856
                                                           F98BFA6B226D4CB04F0B 710F0F70F147321E90A97BC2C
                                                           91FFF473             93EF151B0691AAD6874F2CA45
                                                                                D16D06E541EAE46F6DA385442
                                                                                A8C5DAB41AB713CA8427A883D
                                                                                18CA1BFF8F124D712165344EA
                                                                                512F5



0. 실습 정리

conn sys/Welcome1@pdbxx as sysdba
drop user bct;
drop user bct_usr1;

## 인증서 삭제

exec DBMS_USER_CERTS.DROP_CERTIFICATE('3D55C1A596483B37CF841C0BA1AAF9B0');


서명 알고리즘

SIGN_ALGO_RSA_SHA2_256, SIGN_ALGO_RSA_SHA2_384, or SIGN_ALGO_RSA_SHA2_512. 


DBMS_BLOCKCHAIN_TABLE Package Subprograms
1. DELETE_EXPIRED_ROWS  -- procedure
  : 보호 기간 외부의 행에 대한 삭제 프로시져 
  - DBMS_BLOCKCHAIN_TABLE.DELETE_EXPIRED_ROWS(schema_name, table_name, before_timestamp, numer_of_rows_deleted);
2. GET_BYTES_FOR_ROW_HASH -- procedure
  : 식별된 특정 행에 대한 바이트(열 위치 순서 대로 meta-data-value column-data-value 시리즈)와 체인의 이전 행에 대한 해시를 차례로 반환 
  - DBMS_BLOCKCHAIN_TABLE.GET_BYTES_FOR_ROW_HASH(shema_name, table_name,instance_id,chain_id, sequence_id, data_format, rwo_data)
3. GET_BYTES_FOR_ROW_SIGNATURE  -- function
  : 식별된 특정 행 해시의 바이트 반환. 메타데이터 불포함
  -  DBMS_BLOCKCHAIN_TABLE.GET_BYTES_FOR_ROW_SIGNATURE(schema_name, table_name, instance_id, chain_id, sequence_id, data_format, row_data)
4. GET_SIGNED_BLOCKCHAIN_DIGEST -- Function
 : 스키마 사용자의 인증서를 사용하여 지정된 BCT에 서명된 다이제스트를 생성하고 반환함. signed_bytes, signed_row_indexes 및 schema_certificate_guid 도 반환됨
 - DBMS_BLOCKCHAIN_TABLE.GET_SIGNED_BLOCKCHAIN_DIGEST(schema_name, table_name, signed_rows_indexes, schema_certificate_guid, signature_algo)
5. SIGN_ROW -- Procedure
 : 이 프로시저는 현재 사용자가 이전에 삽입된 행에 대한 서명을 넣는데 사용됨. BCT 에 행을 삽입한 사용자는 행 서명할 수 있는 유일한 사용자임.  
 - DBMS_BLOCKCHAIN_TABLE.SIGN_ROW(schema_name, table_name, instance_id, chain_id, sequence_id, hash, signature, certificate_guid, signature_algo)
6. VERIFY_ROWS -- Procedure
  : LOW_TIMESTAMP ~ HIGH_TIMESTAMP 사이에 생성된 행에 대한 Hash 컬럼값의 무결성을 위해 적용 가능한 모든 체인의 모든 행을 확인 .
  행 서명은 옵션으로 확인할 수 있음
  - DBMS_BLOCKCHAIN_TABLE.VERIFY_ROWS(schema_name, table_name, low_timestamp, high_timestamp, instance_id, chain_id, number_of_rows_verified, verify_signature)
7. VERIFY_TABLE_BLOCKCHAIN -- Procedure
  : 이 프로시저는 생성 시간이 signed_buffer_previous의 행 생성 시간 최소값과 signed_buffer_latest의 행 생성 시간 최대값 사이에 속하는 모든 행을 확인하고 성공적으로 확인된 행 수를 반환함.
 -DBMS_BLOCKCHAIN_TABLE.VERIFY_TABLE_BLOCKCHAIN(signed_bytes_latest,signed_bytes_previous,number_of_rows_verified)



## BCT에서 디지털 서명 삽입 절차 및 앱 구현 방안 

* 디지털 서명 삽입 절차
0. 사용자(DB 계정) 서명 파일 등록
  - CA 인증기관 이용하여 PKI public 키 준비(사설 인증 가능)
  - DBMS_USER_CERTS.ADD_CERTIFICATE 프로시져 사용하여 DB에 사용자 계정 인증서 등록
  - User_certiticates 뷰에서 확인
  - DB 메타정보에 사용자별 GUID별로 디지털 서명 파일 등록됨.

1. DB 사용자 계정으로 BCT에서 서명을 넣을 행의 바이트(16진수 값, 메시지 다이제스트라고 함)를 추출
  - DBMS_BLOCKCHAIN_TABLE.GET_BYTES_FOR_ROW_SIGNATURE 프로시져 활용
  - 파일로 추출됨

2. CA 인증기관에서 바이트 값(메시지 다이제스트)으로 디지털 서명 생성

3. 인증된 디지털 서명을 BCT의 지정 행의 서명란에 추가
  - DBMS_BLOCKCHAIN_TABLE.SIGN_ROW 프로시저 활용

* BCT 사용자 디지털 서명 앱 구현 방안
체인 행에 디지털 서명을 추가하는 의미는 부인방지 즉, 삽입 데이터의 높은 신뢰성 및 규정 준수의 의미가 있음.
오라클BCT에서는 체인 행 삽입과 디지털 서명 추가는 개별 트랜젝션으로 수행될 수 있음. 
따라서 행에 디지털 서명이 반드시 필요한 경우는 "Insert + commit + 디지털 서명 추가" 절차를 하나의 트랜젝션으로 처리하도록 앱을 구현하는 것을 권장함.


