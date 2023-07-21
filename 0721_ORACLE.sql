-- 연습용 ORACLE 서버

-- ORACLE에는 없는 명령어
SHOW TABLES;

-- 오라클은 외부에서 DESC 명령을 사용하지 못하도록 제한
-- 서버 > 스키마 > 유저 > 테이블 을 통해서 직접 확인 가능
DESC EMP;

SELECT *
FROM EMP;

SELECT *
FROM DEPT;

SELECT *
FROM TCITY;


-- EMP 테이블의 최대 높이 조회
SELECT MAX(LEVEL)
FROM EMP
START WITH MGR IS NULL
CONNECT BY PRIOR EMPNO = MGR;

-- EMP 테이블에서 JOB이 PRESIDENT 인 데이터부터 아래 방향으로 LEVEL, ENAME, EMPNO, MGR을 조회
-- CONNECT_BY_ISLEAF 컬럼을 통해 LEAF NODE 인지(아래 직원이 있는지) 파악 가능
SELECT LEVEL, ENAME, EMPNO, MGR, CONNECT_BY_ISLEAF
FROM EMP
START WITH UPPER(JOB) = 'PRESIDENT' -- JOB 이 소문자로 적혀 있을 수 있으므로
CONNECT BY PRIOR EMPNO = MGR AND LEVEL <= 2
ORDER BY LEVEL, ENAME;

-- BLAKE 의 부하 직원을 조회(위에서 아래 방향)
-- 자신의 EMPNO 를 MGR 로 가지는 데이터를 조회하는 방향으로 진행
SELECT LEVEL, ENAME, EMPNO, MGR, CONNECT_BY_ISLEAF
FROM EMP
START WITH ENAME = 'BLAKE' 
CONNECT BY PRIOR EMPNO = MGR 
ORDER BY LEVEL, ROWNUM DESC;

-- BLAKE 의 상사를 조회(아래에서 위 방향)
SELECT LEVEL, ENAME, EMPNO, MGR, CONNECT_BY_ISLEAF
FROM EMP
START WITH ENAME = 'BLAKE' 
CONNECT BY PRIOR MGR = EMPNO 
ORDER BY LEVEL;

-- ROWID 조회
SELECT ROWID, ENAME, EMPNO
FROM EMP;

-- EMP 테이블에서 DEMPNO 별로 1명의 DEPTNO 와 ENAME 을 조회
-- 여러 명이 포함된 DEMPNO 에서 1명만 출력

-- DISTICT 는 여러 컬럼이 작성되면 모든 컬럼이 같아야 제거
SELECT DISTINCT ENAME, DEPTNO
FROM EMP;

-- GROUP BY는 그룹화에 사용하지 않은 컬림을 SELECT 절에 출력할 수 없음
-- ENAME 컬럼은 GROUP BY 절에 없으므로 출력 불가능
SELECT ENAME, DEPTNO
FROM EMP
GROUP BY DEPTNO

-- 다른 컬럼을 사용하지 않고 그룹화 한 후 
-- DEPTNO 그룹 내에서 ROWID 가 가장 큰 값을 가지는 사람에 대한 데이터만 추출
SELECT ENAME, DEPTNO
FROM EMP
WHERE ROWID IN (SELECT MAX(ROWID) FROM EMP GROUP BY DEPTNO)
ORDER BY DEPTNO;

-- 행 번호(ROWNUM) 조회
SELECT ROWNUM, ENAME
FROM EMP;

-- ROWNUM 을 통해 조회 조건을 만들 때 주의
SELECT ROWNUM, ENAME
FROM EMP
WHERE ROWNUM < 5;

-- 아무런 데이터도 가져오지 못함
SELECT ROWNUM, ENAME
FROM EMP
WHERE ROWNUM > 5;



-- EMP 테이블에서 SAL이 높은 순서대로 10명만 조회
SELECT *
FROM EMP
ORDER BY SAL DESC 
OFFSET 0
ROWS FETCH NEXT 10 ROWS ONLY;

-- EMP 테이블에 사원정보 라는 SYNONYM 부여
CREATE SYNONYM 사원정보
FOR EMP;

SELECT *
FROM 사원정보;

-- 새로운 이름을 붙이는게 아니라 별명을 붙이는 것이기 때문에
-- 기존의 이름도 계속 사용할 수 있음
SELECT *
FROM EMP;


-- SEQUENCE 생성
-- 초기 값은 41, 증가는 1씩
CREATE SEQUENCE NUM_SEQ
	START WITH 41
	INCREMENT BY 1;

-- SEQUENCE 값 확인
-- 오라클에서는 DUAL 이라는 임의의 이름을 사용해야 함
SELECT NUM_SEQ.NEXTVAL
FROM DUAL;

-- SEQUENCE 를 이용한 데이터 삽입
INSERT INTO DEPT(DEPTNO, DNAME, LOC) 
VALUES(NUM_SEQ.NEXTVAL, 'STU', '서울');

-- 데이터 확인
SELECT *
FROM DEPT;


-- EMP 테이블에서 JOB 별로 SAL의 평균을 조회
-- 기존 방식
SELECT JOB, AVG(SAL)
FROM EMP
GROUP BY JOB
ORDER BY AVG(SAL) DESC;

-- ROLLUP 을 적용한 방식
-- 전체에 대한 평균도 결과에 나타남(JOB 이름은 NULL)
-- MySQL 의 IFNULL 대신 오라클에서는 NVL 을 사용해서 처리
SELECT NVL(JOB, '전체 평균') AS JOB, AVG(SAL)
FROM EMP
GROUP BY ROLLUP(JOB)
ORDER BY AVG(SAL) DESC;

-- DEPTNO 별로 SAL의 합계를 조회
-- 숫자 컬럼은 조회할 때 DECODE 로 감싸지 않으면 에러
-- DECODE 값이 NULL 이면 '전체', 아니면 DEPTNO 를 변환해서(숫자니까) 조회함
-- DECODE 함수는 IF-ELSE 처럼 작동
SELECT DECODE(DEPTNO, NULL, '전체', DEPTNO) AS DEPTNO, SUM(SAL)
FROM EMP
GROUP BY ROLLUP(DEPTNO)
ORDER BY DEPTNO;

-- ROLLUP 으로 2개 컬럼을 묶어서 중간 결과도 볼 수 있음
SELECT DEPTNO, NVL(JOB, '합계'), SUM(SAL)
FROM EMP
GROUP BY ROLLUP(DEPTNO, JOB)
ORDER BY DEPTNO;

-- 1개에 대해서만 ROLLUP 으로 묶어서 전체 합계 제외할 수도 있음
SELECT DEPTNO, JOB, SUM(SAL)
FROM EMP
GROUP BY DEPTNO, ROLLUP(JOB)
ORDER BY DEPTNO;

-- CUBE 는 모든 중간 집계를 조회 가능
-- DEPTNO 와 JOB 에 대한 SUM 을 각각 제공
-- 그룹을 하나만 만들 수 있는 ROLLUP 과 달리 더 많은 그룹을 만들 수 있음
SELECT DEPTNO, NVL(JOB, '합계') AS JOB, SUM(SAL)
FROM EMP
GROUP BY CUBE(DEPTNO, JOB)
ORDER BY DEPTNO;

-- GROUPING : 중간 집계이면 1 그렇지 않으면 0 을 리턴
-- 보통 타이틀을 만들기 위해서 사용
SELECT DEPTNO, DECODE(GROUPING (DEPTNO), 1, '전체 합계') AS ALLTOTAL, 
	JOB, DECODE(GROUPING (JOB), 1, '직업별 합계') AS JOBTOTAL, SUM(SAL) AS 합계
FROM EMP
GROUP BY ROLLUP(DEPTNO, JOB)
ORDER BY DEPTNO;

-- GROUPING SETS 는 개별 그룹화를 수행하여 조회
-- DEPTNO 별로 따로, JOB 별로 따로 결과를 나타냄
SELECT DEPTNO, NVL(JOB, '-') AS JOB, SUM(SAL) AS SUM
FROM EMP
GROUP BY GROUPING SETS(DEPTNO, JOB)
ORDER BY DEPTNO;

-- EMP 테이블에서 전체 SAL에서 자신의 비율 나타내기

-- SUM(SAL)과 SAL의 CARDINALITY가 같지 않으므로 수행 불가능한 구문
-- SELECT 절의 내용들은 모두 동일한 CARDINALITY를 가져야 함
SELECT ENAME, SAL, SAL/SUM(SAL)
FROM EMP;

-- OVER 함수를 사용
-- 동일한 계산을 수행하지만 에러가 발생하지 않음
-- 결과가 1개로 나타나는 SUM(SAL)을 전부 복사해서 14개의 행으로 만들고 조회
SELECT ENAME, SAL, 100 * SAL/SUM(SAL) OVER() AS "급여의 비율(%)"
FROM EMP;

-- 컬럼 이름에 별명을 부여하고자 하는 경우에는 컬럼 이름이나 연산식 다음에 'AS 별명'
-- AS 는 생략이 가능함
-- 별명에 영문 대문자나 공백이 있으면 ""(큰 따옴표)를 사용해서 감싸야 함



-- EMP 테이블에서 EMPNO, ENAME, SAL, 현재 행까지의 SAL 합계 를 조회

-- 전체 합계를 각각에 대해 나타내지만 현재 행까지의 합은 나타내지 못함
SELECT EMPNO, ENAME, SAL, SUM(SAL) OVER() 
FROM EMP;

-- 현재 행까지의 누적 합
SELECT EMPNO, ENAME, SAL, SUM(SAL) OVER(ORDER BY SAL
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) "현재 행까지의 누적 합" 
FROM EMP;

-- 현재 행부터 마지막 행까지의 합
SELECT EMPNO, ENAME, SAL, SUM(SAL) OVER(ORDER BY SAL
	ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) "마지막까지의 합계" 
FROM EMP;

-- 현재 행부터 3개 뒤의 행까지의 합
SELECT EMPNO, ENAME, SAL, SUM(SAL) OVER(ORDER BY SAL
	ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING) "3개 누적 합" 
FROM EMP;

SELECT EMPNO, ENAME, SAL, SUM(SAL) OVER(ORDER BY SAL
	ROWS BETWEEN 2 PRECEDING AND 3 FOLLOWING) "앞으로 2개, 뒤로 3개" 
FROM EMP;


-- 부서 별 급여 평균
SELECT EMPNO, ENAME, SAL, AVG(SAL) OVER(PARTITION BY DEPTNO) "부서별 평균"
FROM EMP;


-- 부서별 SAL 순위
-- RANK 함수를 사용했으므로 같은 순위 다음에는 순위를 건너뜀
-- DENSE_RANK 는 같은 순위 다음에도 이어서
SELECT ENAME, DEPTNO, SAL, 
	RANK() OVER(PARTITION BY DEPTNO ORDER BY SAL DESC) "부서 내 순위",
	DENSE_RANK ()  OVER(PARTITION BY DEPTNO ORDER BY SAL DESC) "부서 내 순위",
	ROW_NUMBER ()  OVER(PARTITION BY DEPTNO ORDER BY SAL DESC) "부서 내 순위"
FROM EMP;


-- PIVOT
SELECT ENAME, JOB
FROM EMP
PIVOT(MAX(SAL) FOR DEPTNO IN (10, 20, 30));







