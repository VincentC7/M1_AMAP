create or replace function majCommande() returns trigger as $majCommande$
DECLARE
	contenu contenucommande%rowType;
	reste integer;
BEGIN
		IF new.statut = 'En attente de traitement'
		THEN
			FOR contenu IN SELECT * from contenucommande where commande = new.id_commande
			LOOP
				SELECT (produit.valeur - contenu.valeur) INTO reste
				FROM produit WHERE produit.id_produit = contenu.produit;
				
				IF reste < 0 THEN
					new.statut = 'Refusé';
					RETURN new;
					RAISE EXCEPTION 'Quantités insuffisantes en stock pour cette commande';
				END IF;
			END LOOP;
			new.datereponse := CURRENT_DATE;
			new.statut := 'En attente de validation';
		END IF;
		RETURN new;
END;
$majCommande$ language plpgsql;

create trigger majCommande before update on commande FOR EACH ROW execute procedure majCommande();

-- base saine
DELETE FROM contenucommande;
DELETE FROM commande;
DELETE FROM utilisateur;
DELETE FROM produit;

-- insert
insert into produit values (1, 'patate', 'kg', 100, 1, true);
insert into produit values (2, 'carottes', 'kg', 100, 1, true);

INSERT into utilisateur values (1, 'Arthur', 'BOILS', '02', 'rgr', 'sgf', 'Non abonné');

INSERT INTO commande values (1, CURRENT_DATE, 'En cours de création', NULL, 50, 1);

INSERT INTO contenucommande values (1, 50, 1, 1);
INSERT INTO contenucommande values (2, 150, 2, 1);

-- resultat attendu: gros nope
UPDATE commande set statut = 'En attente de traitement' WHERE id_commande = 1;

-- resultat attendu: ok
UPDATE contenucommande set valeur = 50 WHERE id_contenu = 2;
UPDATE commande set statut = 'En attente de traitement' WHERE id_commande = 1;

