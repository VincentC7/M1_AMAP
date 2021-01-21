create or replace function stockPanier2() returns trigger as $stockPanier2$
DECLARE 
	vStock integer;
	nbAbo integer;
BEGIN
	SELECT valeur INTO vStock
	FROM Produit
	WHERE id_produit = old.produit;

	RAISE NOTICE '%', vStock;

    --Récupération du nombre d'abonnés
    SELECT COUNT(*) INTO nbAbo from utilisateur where role = 'Abonné';
	
	RAISE NOTICE '%', nbAbo;
	RAISE NOTICE '%', (vStock + old.valeur * nbAbo);
	UPDATE Produit set valeur = (vStock + old.valeur * nbAbo)
	WHERE id_produit = old.produit;
	RETURN NEW;
END;
$stockPanier2$ language plpgsql;

create trigger stockPanier2 after delete on Compose FOR EACH ROW execute procedure stockPanier2();

DELETE FROM Compose;
INSERT INTO Compose VALUES (1, 2, 1, 1);
INSERT INTO Compose VALUES (2, 3, 2, 1);
INSERT INTO Compose VALUES (3, 1, 3, 1);
Select * from Compose;
SELECT * from Produit;
