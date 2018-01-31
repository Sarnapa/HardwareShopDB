create or replace TRIGGER SPRZETY_MODEL_INSERT
-- Sprawdza czy w tabeli sprzęty istnieje już dany sprzęt (uwzględnia różne sposoby zapisu nazwy modelu)
BEFORE INSERT ON SPRZETY
FOR EACH ROW
DECLARE
	tmp_model SPRZETY.NAZWA_MODELU%type;
	liczba_znalezionych char(1);
BEGIN
	tmp_model := :NEW.NAZWA_MODELU;
	SELECT COUNT(*) INTO liczba_znalezionych
	FROM SPRZETY
	WHERE (REGEXP_REPLACE(UPPER(NAZWA_MODELU), '[^A-Z0-9]', '' )) = (REGEXP_REPLACE(UPPER(tmp_model), '[^A-Z0-9]', ''));
	IF liczba_znalezionych > 0 THEN
    raise_application_error(-20000, 'Produkt istnieje już w bazie sprzetów.');
	END IF;
END;