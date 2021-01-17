create or replace function stockPanier() returns trigger as $stockPanier$
DECLARE 
	vStock integer;
	nbAbo integer;
BEGIN
	--Récupération du stock
	SELECT valeur INTO vSTOCK
	FROM Produit
	WHERE id_produit = NEW.produit;

	--Récupération du nombre d'abonnés
	SELECT COUNT(*) INTO nbAbo
	FROM abonnement, panier
	WHERE panier.id_panier = (SELECT MAX(id_panier) FROM Panier)
	AND panier.trimestre = abonnement.trimestre
	AND abonnement.etat='Validé';
	
	IF (vStock - new.valeur * nbAbo) < 0 THEN
		RAISE EXCEPTION 'Stock négatif';
	ELSE
		--Mise à jour du stock du produit
		UPDATE Produit set valeur = (vStock - new.valeur * nbAbo)
		WHERE id_produit = new.produit;
		RETURN NEW;
	END IF;

END;
$stockPanier$ language plpgsql;

create trigger stockPanier before insert on Compose for each row execute procedure stockPanier();

-- base saine
DELETE FROM contenucommande;
DELETE FROM commande;
DELETE FROM utilisateur;
DELETE FROM produit;
DELETE FROM trimestre;
DELETE FROM panier;

-- insert
insert into produit values (1, 'patate', 'kg', 100, 1, true); --id_produit, nomproduit, unite, valeur, prixunitaire, visible
insert into produit values (2, 'carottes', 'kg', 100, 1, true); 

INSERT into utilisateur values (1, 'Arthur', 'BOILS', '02', 'rgr', 'sgf', 'Abonné');
INSERT into utilisateur values (2, 'Charly', 'BOILS', '02', 'rgr', 'sgf', 'Abonné');
INSERT into utilisateur values (3, 'Charly', 'BOILS', '02', 'rgr', 'sgf', 'Abonné');
INSERT INTO commande values (1, CURRENT_DATE, 'En cours de création', NULL, 50, 1);

INSERT INTO abonnement values(2, CURRENT_DATE, CURRENT_DATE, 'Validé',CURRENT_DATE, 3, 1, 1);

INSERT INTO contenucommande values (1, 50, 1, 1);
INSERT INTO contenucommande values (2, 150, 2, 1);

INSERT INTO trimestre values (1, CURRENT_DATE, CURRENT_DATE +1, 45);
INSERT INTO panier values (1, 1, 1); --id_panier, numsemaine, trimestre

DELETE FROM compose;

INSERT INTO compose VALUES (1, 2, 1, 1); -- id_compose, valeur, produit, panier
INSERT INTO Compose VALUES (2, 3, 2, 1);
INSERT INTO Compose VALUES (3, 99, 1, 1);


SELECT * from Produit;

