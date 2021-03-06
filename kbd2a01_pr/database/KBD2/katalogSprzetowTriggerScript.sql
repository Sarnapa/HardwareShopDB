create or replace TRIGGER KATALOG_SPRZETOW_TRIG
-- Pozwala dodawać sprzęty przez perspektywę. W razie potrzeby dodaje też nieistniejący rodzaj sprzętu oraz producenta
INSTEAD OF INSERT ON KATALOG_SPRZETOW
FOR EACH ROW
DECLARE
  duplikat EXCEPTION;
  PRAGMA EXCEPTION_INIT (duplikat, -20000);
  PRAGMA AUTONOMOUS_TRANSACTION;
  tmp_id_producenta PRODUCENCI.ID_PRODUCENTA%type;
  tmp_id_rodzaju RODZAJE_SPRZETU.ID_RODZAJU%type;
  tmp_count char(1);
BEGIN
  IF :NEW.KRAJ_PRODUKCJI IS NULL THEN
    SELECT COUNT(*) INTO tmp_count FROM PRODUCENCI WHERE UPPER(NAZWA) = UPPER(:NEW.PRODUCENT) AND KRAJ_PRODUKCJI IS NULL;
    IF tmp_count = 0 THEN
      INSERT INTO PRODUCENCI(NAZWA) VALUES (:NEW.PRODUCENT);
    END IF;
    SELECT ID_PRODUCENTA INTO tmp_id_producenta FROM PRODUCENCI WHERE UPPER(NAZWA) = UPPER(:NEW.PRODUCENT) AND KRAJ_PRODUKCJI IS NULL;
  ELSE
    SELECT COUNT(*) INTO tmp_count FROM PRODUCENCI WHERE UPPER(NAZWA) = UPPER(:NEW.PRODUCENT) AND UPPER(KRAJ_PRODUKCJI) = UPPER(:NEW.KRAJ_PRODUKCJI);
    IF tmp_count = 0 THEN
      INSERT INTO PRODUCENCI(NAZWA, KRAJ_PRODUKCJI) VALUES (:NEW.PRODUCENT, :NEW.KRAJ_PRODUKCJI);
    END IF;
    SELECT ID_PRODUCENTA INTO tmp_id_producenta FROM PRODUCENCI WHERE UPPER(NAZWA) = UPPER(:NEW.PRODUCENT) AND UPPER(KRAJ_PRODUKCJI) = UPPER(:NEW.KRAJ_PRODUKCJI);
  END IF;
  
  SELECT COUNT(*) INTO tmp_count FROM RODZAJE_SPRZETU WHERE UPPER(NAZWA) = UPPER(:NEW.RODZAJ_SPRZETU);
  IF tmp_count = 0 THEN
    INSERT INTO RODZAJE_SPRZETU(NAZWA, OPIS) VALUES (:NEW.RODZAJ_SPRZETU, :NEW.OPIS);
  END IF;
  SELECT ID_RODZAJU INTO tmp_id_rodzaju FROM RODZAJE_SPRZETU WHERE UPPER(NAZWA) = UPPER(:NEW.RODZAJ_SPRZETU);

-- Jeśli okaże się, że sprzęt już istnieje transakcja zostanie wycofana.     
  INSERT INTO SPRZETY (NAZWA_MODELU, CENA, ILOSC, ID_PRODUCENTA, ID_RODZAJU)
  VALUES(:NEW.NAZWA_MODELU, :NEW.CENA, :NEW.ILOSC, tmp_id_producenta, tmp_id_rodzaju);
  
  COMMIT;
  
  EXCEPTION
    WHEN duplikat THEN
      ROLLBACK;
      raise_application_error(-20001, 'Produkt istnieje już w bazie sprzetów. Transakcja wycofana.');
END;