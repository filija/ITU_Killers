-- xdenkf00, xcerve18

-- povoleni vypisu
SET SERVEROUTPUT ON

-- zakazani sberu dat o identifikatoru (kvuli nepochopitelnym errorum)
ALTER SESSION SET PLSCOPE_SETTINGS = "IDENTIFIERS:NONE";

-- smazani omezeni (FK)
ALTER TABLE rezervace
DROP CONSTRAINT FK_rezervace_cestujici;
ALTER TABLE letenka
DROP CONSTRAINT FK_letenka_cestujici;
ALTER TABLE letenka
DROP CONSTRAINT FK_letenka_let;
ALTER TABLE platba
DROP CONSTRAINT FK_platba_rezervace;
ALTER TABLE platba_log
DROP CONSTRAINT FK_platba_log_variabilni;
ALTER TABLE let
DROP CONSTRAINT FK_let_letadlo;
ALTER TABLE letadlo
DROP CONSTRAINT FK_letadlo_spolecnost;
ALTER TABLE letadlo
DROP CONSTRAINT FK_letadlo_linka;
ALTER TABLE zakoupene_letadlo
DROP CONSTRAINT FK_zakoupene_letadlo_letadlo;
ALTER TABLE pronajate_letadlo
DROP CONSTRAINT FK_pronajate_letadlo_letadlo;

-- smazani sekvenci
DROP SEQUENCE seq_platba_log;
DROP SEQUENCE seq_id_cestujici;
DROP SEQUENCE seq_id_rezervace;
DROP SEQUENCE seq_id_letenky;
DROP SEQUENCE seq_id_letu;
DROP SEQUENCE seq_id_linky;
DROP SEQUENCE seq_cislo_letadla;

-- smazani indexu
DROP INDEX pokus;

-- smazani tabulek
DROP TABLE cestujici;
DROP TABLE rezervace;
DROP TABLE letenka;
DROP TABLE platba;
DROP TABLE platba_log;
DROP TABLE let;
DROP TABLE linka;
DROP TABLE spolecnost;
DROP TABLE letadlo;
DROP TABLE zakoupene_letadlo;
DROP TABLE pronajate_letadlo;

--
-- VYTVORENI SEKVENCI
--

CREATE SEQUENCE seq_platba_log START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE seq_id_cestujici START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE seq_id_rezervace START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE seq_id_letenky START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE seq_id_letu START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE seq_id_linky START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;
CREATE SEQUENCE seq_cislo_letadla START WITH 0 INCREMENT BY 1 NOMAXVALUE MINVALUE 0;

--
-- VYTVORENI TABULEK
--

CREATE TABLE cestujici(
  id_cestujici INTEGER PRIMARY KEY,
  login NVARCHAR2(25) NOT NULL,
  heslo NVARCHAR2(25) NOT NULL,
  jmeno NVARCHAR2(25) NOT NULL,
  prijmeni NVARCHAR2(25) NOT NULL,
  adresa NVARCHAR2(50) NOT NULL,
  email NVARCHAR2(50) NOT NULL,
  telefon NVARCHAR2(20) NOT NULL
);

CREATE TABLE rezervace(
  id_rezervace INTEGER PRIMARY KEY,
  datum_rezervace DATE NOT NULL,
  datum_splatnosti DATE NOT NULL,
  id_cestujici INTEGER NOT NULL
);

CREATE TABLE letenka(
  id_letenky INTEGER PRIMARY KEY,
  datum_odletu DATE NOT NULL,
  cestovni_trida SMALLINT NOT NULL,
  cislo_sedadla INTEGER NOT NULL,
  id_cestujici INTEGER NOT NULL,
  id_letu INTEGER NOT NULL
);

CREATE TABLE platba(
  variabilni_symbol INTEGER PRIMARY KEY,
  castka INTEGER NOT NULL CHECK (castka>0),
  datum DATE NOT NULL,
  id_rezervace INTEGER NOT NULL,
  cislo_uctu NVARCHAR2(10)
);

CREATE TABLE platba_log(
  id_logu INTEGER PRIMARY KEY,
  jmeno_uzivatele NVARCHAR2(20) NOT NULL,
  cas_upravy NVARCHAR2(40) NOT NULL,
  variabilni_symbol INTEGER,
  castka INTEGER NOT NULL CHECK (castka>0),
  datum DATE NOT NULL,
  id_rezervace INTEGER NOT NULL,
  cislo_uctu NVARCHAR2(10)
);

CREATE TABLE let(
  id_letu INTEGER PRIMARY KEY,
  cislo_letadla INTEGER NOT NULL
);

CREATE TABLE linka(
  id_linky INTEGER PRIMARY KEY,
  destinace NVARCHAR2(25) NOT NULL,
  misto_odletu NVARCHAR2(25) NOT NULL
);

CREATE TABLE spolecnost(
  nazev_spolecnosti NVARCHAR2(30) PRIMARY KEY
);

CREATE TABLE letadlo(
  cislo_letadla INTEGER PRIMARY KEY,
  vyrobce NVARCHAR2(25) NOT NULL,
  kapacita_letadla INTEGER NOT NULL,
  id_linky INTEGER NOT NULL,
  spolecnost NVARCHAR2(25) NOT NULL
);

CREATE TABLE zakoupene_letadlo(
  datum_zakoupeni DATE NOT NULL,
  cena_letadla INTEGER NOT NULL CHECK (cena_letadla>0),
  cislo_letadla INTEGER NOT NULL
);

CREATE TABLE pronajate_letadlo(
  datum_pronajati DATE NOT NULL,
  datum_ukonceni_pronajmu DATE,
  vlastnik NVARCHAR2(25) NOT NULL,
  cislo_letadla INTEGER NOT NULL
);

--
-- VYTVORENI INDEXU A MATERIALIZOVANYCH POHLEDU
--

CREATE INDEX pokus ON letenka(id_cestujici);

--
-- TRIGGERY A PROCEDURY
--

-- trigger na kontrolu spravnosti cisla bankovniho uctu (podle linku ze zadani)
CREATE OR REPLACE TRIGGER tr_cislo_uctu BEFORE INSERT ON platba FOR EACH ROW
DECLARE
  cislo NVARCHAR2(10); -- cislo ke kontrole
  zbytek NUMBER(2); -- vysledek operace MOD
  suma NUMBER(3);
  -- promenne pro pozice vynasobene vahou
  pA NUMBER(2); pB NUMBER(2); pC NUMBER(2); pD NUMBER(2); pE NUMBER(2);
  pF NUMBER(2); pG NUMBER(2); pH NUMBER(2); pI NUMBER(2); pJ NUMBER(2);
  error_cislo EXCEPTION;

BEGIN
  cislo := :new.cislo_uctu;
  pA := to_number(substr(cislo, 1, 1) * 6); -- vytahnuti posledni pozice
  pB := to_number(substr(cislo, 2, 1) * 3);
  pC := to_number(substr(cislo, 3, 1) * 7);
  pD := to_number(substr(cislo, 4, 1) * 9);
  pE := to_number(substr(cislo, 5, 1) * 10);
  pF := to_number(substr(cislo, 6, 1) * 5);
  pG := to_number(substr(cislo, 7, 1) * 8);
  pH := to_number(substr(cislo, 8, 1) * 4);
  pI := to_number(substr(cislo, 9, 1) * 2);
  pJ := to_number(substr(cislo, 10, 1) * 1);
  
  suma := pA + pB + pC + pD + pE + pF + pG + pH + pI + pJ;
  zbytek := MOD((suma), 11); -- kontrola
  
  IF (zbytek != 0) THEN
    RAISE error_cislo;
  END IF;
  
  IF (length(:new.cislo_uctu) != 10) THEN
    RAISE error_cislo;
  END IF;
  
  EXCEPTION
    WHEN error_cislo THEN
      RAISE_APPLICATION_ERROR(-20001, 'Neplatné èíslo úètu!');
END tr_cislo_uctu;
/

-- trigger, ktery po jakekoliv uprave platby loguje udaje o uzivateli, casu a hodnotach do logovaci tabulky
CREATE OR REPLACE TRIGGER tr_platba AFTER UPDATE ON platba FOR EACH ROW
DECLARE
  jmeno_uzivatele platba_log.jmeno_uzivatele%TYPE; -- promena s typem ziskanym z tabulky
  datum platba_log.datum%TYPE;
BEGIN
  -- ziskani jmena uzivatele + casu upravy
  SELECT user INTO jmeno_uzivatele
    FROM dual;
  SELECT to_date(sysdate, 'YYYY/MM/DD HH24:MI:SS') INTO datum
    FROM dual;
  -- vlozeni dat
  INSERT INTO platba_log
    VALUES(
    seq_platba_log.nextval, 
    jmeno_uzivatele, 
    to_char(sysdate, 'YYYY/MM/DD HH24:MI:SS'),
    :old.variabilni_symbol,
    :old.castka,
    :old.datum,
    :old.id_rezervace,
    :old.cislo_uctu
    );
END tr_platba;
/

-- trigger, kontrola null u primarniho klice, tabulka let
CREATE OR REPLACE TRIGGER tr_let BEFORE INSERT ON let FOR EACH ROW
BEGIN
  IF :new.id_letu IS NULL THEN -- vlastni klic
    :new.id_letu := seq_id_letu.nextval;
  END IF;
END tr_platba;
/

-- trigger, ktery pred vlozenim nebo upravou platby provede slevu 10%, kdyz platba presahuje 30000
CREATE OR REPLACE TRIGGER tr_cena BEFORE INSERT OR UPDATE ON platba FOR EACH ROW
BEGIN
  IF INSERTING THEN
    IF (:new.castka>30000) THEN
      :new.castka:=:new.castka*0.9; 
    END IF;
  END IF;

  IF UPDATING THEN
    IF (:new.castka>30000) THEN
      :new.castka:=:new.castka*0.9; 
    END IF;
  END IF;
END tr_cena;
/

-- procedura, ktera po zavolani vypise jmena vsech cestujicich
CREATE OR REPLACE PROCEDURE pr_cestujici IS
  CURSOR c_cestujici IS SELECT * FROM cestujici;
  zaznam c_cestujici%ROWTYPE; -- format radku
BEGIN
  OPEN c_cestujici; -- otevreni kursoru
    LOOP        
      FETCH c_cestujici INTO zaznam; -- nacitani radku
      EXIT WHEN c_cestujici%NOTFOUND; -- konec
      DBMS_OUTPUT.put_line(zaznam.jmeno || ' ' || zaznam.prijmeni); -- vypis
    END LOOP;
  CLOSE c_cestujici; -- zavreni kursoru
END;
/

-- procedura, vypise vsechny upravy ( v tabulce platba) uzivatele podle argumentu
-- upravy jsou chronologicky serazeny od nejstarsiho zaznamu
CREATE OR REPLACE PROCEDURE pr_log(
  arg_jmeno_uzivatele IN platba_log.jmeno_uzivatele%TYPE -- vstupni argument
)
IS
  CURSOR c_platba_log IS SELECT * FROM platba_log;
  zaznam platba_log%ROWTYPE; -- format radku
  counter NUMBER(3);
BEGIN
counter := 0;
  OPEN c_platba_log; -- otevreni kursoru
    LOOP  
      FETCH c_platba_log INTO zaznam; -- nacitani radku z cursoru
      EXIT WHEN c_platba_log%NOTFOUND; -- konec
      IF zaznam.jmeno_uzivatele = arg_jmeno_uzivatele THEN -- match
        counter := counter + 1;
        DBMS_OUTPUT.put_line(zaznam.id_logu || ' ' || arg_jmeno_uzivatele || ' ' || zaznam.cas_upravy); -- vypis
      END IF;
    END LOOP;   
  IF counter = 0 THEN -- kontrola nalezeni
    RAISE_APPLICATION_ERROR(-20001, 'Uživatel nenalezen!');
  END IF;
  CLOSE c_platba_log; -- zavreni kursoru  
END;
/

--
-- INTEGRITNI OMEZENI
--

ALTER TABLE rezervace ADD CONSTRAINT FK_rezervace_cestujici FOREIGN KEY (id_cestujici) REFERENCES cestujici(id_cestujici);
ALTER TABLE letenka ADD CONSTRAINT FK_letenka_cestujici FOREIGN KEY (id_cestujici) REFERENCES cestujici(id_cestujici);
ALTER TABLE letenka ADD CONSTRAINT FK_letenka_let FOREIGN KEY (id_letu) REFERENCES let(id_letu);
ALTER TABLE platba ADD CONSTRAINT FK_platba_rezervace FOREIGN KEY (id_rezervace) REFERENCES rezervace(id_rezervace);
ALTER TABLE platba_log ADD CONSTRAINT FK_platba_log_variabilni FOREIGN KEY (variabilni_symbol) REFERENCES platba(variabilni_symbol);
ALTER TABLE let ADD CONSTRAINT FK_let_letadlo FOREIGN KEY (cislo_letadla) REFERENCES letadlo(cislo_letadla);
ALTER TABLE letadlo ADD CONSTRAINT FK_letadlo_spolecnost FOREIGN KEY (spolecnost) REFERENCES spolecnost(nazev_spolecnosti);
ALTER TABLE letadlo ADD CONSTRAINT FK_letadlo_linka FOREIGN KEY (id_linky) REFERENCES linka(id_linky);
ALTER TABLE zakoupene_letadlo ADD CONSTRAINT FK_zakoupene_letadlo_letadlo FOREIGN KEY (cislo_letadla) REFERENCES letadlo(cislo_letadla);
ALTER TABLE pronajate_letadlo ADD CONSTRAINT FK_pronajate_letadlo_letadlo FOREIGN KEY (cislo_letadla) REFERENCES letadlo(cislo_letadla);

--
-- UKAZKOVA DATA
--

INSERT INTO spolecnost VALUES('Alitalia');
INSERT INTO spolecnost VALUES('Lufthansa');
INSERT INTO spolecnost VALUES('Èeské Aerolinie');

INSERT INTO linka VALUES(seq_id_linky.nextval, 'Prague', 'London');
INSERT INTO linka VALUES(seq_id_linky.nextval, 'Prague', 'NY');
INSERT INTO linka VALUES(seq_id_linky.nextval, 'Paris', 'Barcelona');
INSERT INTO linka VALUES(seq_id_linky.nextval, 'Brno', 'LA');

INSERT INTO letadlo VALUES(seq_cislo_letadla.nextval, 'GM', 150, 0, 'Alitalia');
INSERT INTO zakoupene_letadlo VALUES(TO_DATE('2010/01/01', 'yyyy/mm/dd'), 23000000, 0);

INSERT INTO letadlo VALUES(seq_cislo_letadla.nextval, 'GM', 50, 2, 'Lufthansa');
INSERT INTO zakoupene_letadlo VALUES(TO_DATE('2012/01/01', 'yyyy/mm/dd'), 10000000, 1);

INSERT INTO letadlo VALUES(seq_cislo_letadla.nextval, 'Mercedes', 200, 3, 'Èeské Aerolinie');
INSERT INTO pronajate_letadlo VALUES(TO_DATE('2005/02/01', 'yyyy/mm/dd'), TO_DATE('2015/02/01', 'yyyy/mm/dd'), 'Rockefeller', 2);

INSERT INTO letadlo VALUES(seq_cislo_letadla.nextval, 'Renault', 220, 1, 'Lufthansa');
INSERT INTO zakoupene_letadlo VALUES(TO_DATE('2014/05/01', 'yyyy/mm/dd'), 15250000, 3);

INSERT INTO letadlo VALUES(seq_cislo_letadla.nextval, 'Audi', 145, 0, 'Èeské Aerolinie');
INSERT INTO pronajate_letadlo VALUES(TO_DATE('1999/01/01', 'yyyy/mm/dd'), TO_DATE('2019/01/01', 'yyyy/mm/dd'), 'Rotschild', 4);

INSERT INTO let VALUES(seq_id_letu.nextval, 0);
INSERT INTO let VALUES(seq_id_letu.nextval, 4);
INSERT INTO let VALUES(seq_id_letu.nextval, 2);
INSERT INTO let VALUES(seq_id_letu.nextval, 2);
INSERT INTO let VALUES(seq_id_letu.nextval, 3);

INSERT INTO cestujici VALUES(seq_id_cestujici.nextval, 'XDENKF00', 'tajneheslo', 'Filip', 'Denk', 'Obora 896', 'filip@fleda.com', '123456789');
INSERT INTO cestujici VALUES(seq_id_cestujici.nextval, 'XCERVE18', 'dalsisupertajneheslo', 'Ondrej', 'Cervenka', 'Brno 50', 'ondra@caribic.com', '+420555456294');
INSERT INTO cestujici VALUES(seq_id_cestujici.nextval, 'XLOGIN99', 'fitfit', 'Arnold', 'Pascal', 'Božetìchova 1', 'arni@stud.fit.vutbr.cz', '666666666');
INSERT INTO cestujici VALUES(seq_id_cestujici.nextval, 'papousek', 'brr546', 'Frantisek', 'Skala', 'Èernohorská 88', 'email@nsa.com', '605478912');

INSERT INTO rezervace VALUES(seq_id_rezervace.nextval, TO_DATE('2015/05/03', 'yyyy/mm/dd'), TO_DATE('2015/05/10', 'yyyy/mm/dd'), 1);
INSERT INTO rezervace VALUES(seq_id_rezervace.nextval, TO_DATE('2015/02/01', 'yyyy/mm/dd'), TO_DATE('2015/03/10', 'yyyy/mm/dd'), 0);
INSERT INTO rezervace VALUES(seq_id_rezervace.nextval, TO_DATE('2015/02/01', 'yyyy/mm/dd'), TO_DATE('2015/03/10', 'yyyy/mm/dd'), 2);
INSERT INTO rezervace VALUES(seq_id_rezervace.nextval, TO_DATE('2015/02/01', 'yyyy/mm/dd'), TO_DATE('2015/03/10', 'yyyy/mm/dd'), 3);

INSERT INTO platba VALUES(254783, 5000, TO_DATE('2015/05/07', 'yyyy/mm/dd'), 0, '2600193976');
INSERT INTO platba VALUES(1111, 35000, TO_DATE('2015/02/25', 'yyyy/mm/dd'), 1, '6000538414');

INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/06/06 17:00:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 25, 0, 1);
INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/06/06 17:00:00', 'yyyy/mm/dd hh24:mi:ss'), 1, 13, 1, 1);
INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/06/06 17:00:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 44, 2, 1);
INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 1, 0, 3);
INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);

--
-- SELECTY
--

-- vypise jednotlive letecke spolecnosti a cisla jednotlivych letadel, ktere vlastni
--SELECT DISTINCT nazev_spolecnosti,cislo_letadla
--FROM spolecnost INNER JOIN letadlo
--ON spolecnost.nazev_spolecnosti=letadlo.spolecnost
--ORDER BY spolecnost.nazev_spolecnosti;

-- vyhleda data jednotlivych spolecnosti a to kolik ma kazda letadel
--SELECT DISTINCT S.nazev_spolecnosti, COUNT(*) AS pocet_letadel
--FROM spolecnost S, letadlo L
--WHERE S.nazev_spolecnosti=L.spolecnost 
--GROUP BY S.nazev_spolecnosti;

-- vyhleda vsechny cestujici, kteri maji rezervaci a pocet, kolik maji rezervovanych letenek
--SELECT C.jmeno, C.prijmeni, R.datum_rezervace, COUNT(*) AS pocet_letenek
--FROM cestujici C, rezervace R, letenka L
--WHERE C.id_cestujici=R.id_cestujici 
--AND R.id_cestujici=L.id_cestujici
--GROUP BY C.jmeno, C.prijmeni, R.datum_rezervace; 

-- vyhleda znacku letadla, ktere ma kapacitu vesti jak 149 sedadel a jeho destinaci je Praha
--SELECT L.vyrobce, L.kapacita_letadla, LA.destinace, LA.misto_odletu
--FROM letadlo L , Linka LA
--WHERE L.id_linky=LA.id_linky AND destinace='Prague' AND kapacita_letadla > 149; 

-- pokud existuje letadlo, ktere je znacky Mercedes a ma kapacitu vice jak 149 sedadel, tak jej vypise
--SELECT vyrobce, kapacita_letadla
--FROM letadlo
--WHERE vyrobce='Mercedes' AND EXISTS (SELECT * FROM letadlo WHERE kapacita_letadla > 149);

-- vyhleda letadla, ktera letaji do destinace Brno a Praha
--SELECT L.vyrobce, LA.destinace
--FROM Letadlo L, Linka LA
--WHERE L.id_linky=LA.id_linky AND destinace IN (SELECT destinace FROM linka WHERE destinace='Prague' OR destinace='Brno');

--
-- EXPLAIN PLAN
--

--EXPLAIN PLAN FOR SELECT C.jmeno, C.prijmeni, R.datum_rezervace, COUNT(*) AS pocet_letenek
--FROM cestujici C, rezervace R, letenka L
--WHERE C.id_cestujici=R.id_cestujici 
--AND R.id_cestujici=L.id_cestujici
--GROUP BY C.jmeno, C.prijmeni, R.datum_rezervace; 
--SELECT * FROM TABLE(dbms_xplan.display());

--
-- TESTY
--


-- test pro tigger tr_cislo_uctu
-- spravne cislo uctu
--INSERT INTO platba VALUES(58585, 1565, TO_DATE('2010/01/3', 'yyyy/mm/dd'), 1, '6000538414');
-- spatne cislo uctu
--INSERT INTO platba VALUES(58586, 1565, TO_DATE('2010/01/3', 'yyyy/mm/dd'), 1, '6000538415');
--SELECT * FROM platba;


-- test pro trigger tr_platba
--UPDATE platba SET castka = 69989 WHERE variabilni_symbol = 1111;
--SELECT * FROM platba_log;
--SELECT * FROM platba;


-- test pro trigger tr_let
--INSERT INTO let VALUES(null, 4);
--SELECT * FROM let;


-- test pro trigger tr_cena
--INSERT INTO platba VALUES(3874, 100000, TO_DATE('2015/08/07', 'yyyy/mm/dd'), 0, '2600193976');
--SELECT * FROM platba;


-- test pro proceduru pr_cestujici
--CALL pr_cestujici();


-- test pro proceduru pr_log
-- uspesne vyhledani
--CALL pr_log('XDENKF00');
-- neuspesne vyhledani
--CALL pr_log('jhdytr');


-- test prava

-- ONDRA
--DROP MATERIALIZED VIEW cest_rez;
--
--CREATE materialized VIEW cest_rez
--nologging --nechceme zaznamenavat operace s pohledem
--cache -- pouziti cache pameti
--build immediate --okamzite se naplni daty
----refresh fast on commit --pri aktualizaci nejake tabulky se pohled obnovi
--enable query rewrite --pohled bude pouzitelny v optimalizatoru
----for update
--AS
--SELECT jmeno,prijmeni,datum_rezervace,
--XDENKF00.cestujici.rowid as cestujici_rowid, XDENKF00.rezervace.rowid as rezervace_rowid
--FROM XDENKF00.cestujici NATURAL JOIN XDENKF00.rezervace;
--
----prava na mat. pohled pro 1. OSOBU
--GRANT ALL on cest_rez to xdenkf00;


-- FILIP
--GRANT ALL on cestujici to XCERVE18;
--GRANT ALL on rezervace to XCERVE18;
--GRANT ALL on letenka to XCERVE18;
--GRANT ALL on platba to XCERVE18;
--GRANT ALL on platba_log to XCERVE18;
--GRANT ALL on let to XCERVE18;
--GRANT ALL on linka to XCERVE18;
--GRANT ALL on spolecnost to XCERVE18;
--GRANT ALL on letadlo to XCERVE18;
--GRANT ALL on zakoupene_letadlo to XCERVE18;
--GRANT ALL on pronajate_letadlo to XCERVE18;
--COMMIT;
--SELECT jmeno, prijmeni, datum_rezervace FROM XCERVE18.cest_rez;

-- test pro index
--DROP INDEX pokus;
--CREATE INDEX pokus ON letenka(id_cestujici);
--
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 0);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 2);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 2);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 3);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 0);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 0);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 2);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);
--INSERT INTO letenka VALUES(seq_id_letenky.nextval, TO_DATE('2015/07/18 07:10:00', 'yyyy/mm/dd hh24:mi:ss'), 2, 5, 1, 1);