create or replace function stockCommande() returns trigger as $stockCommande$
DECLARE 
	reste integer;
	vStock integer;
	tablerecord RECORD;
BEGIN
		RAISE notice 'val : %', new;
		If NEW.statut = 'Validée'
		THEN
			SELECT MAX(produit.valeur - contenucommande.valeur) INTO reste
			FROM Produit, Contenucommande
			WHERE produit.id_produit = contenucommande.produit;
			RAISE notice 'val : %', reste;
			IF reste >= 0
			THEN
				FOR tablerecord IN SELECT *
								FROM Contenucommande
							    WHERE contenucommande.commande = new.id_commande
				LOOP
					SELECT valeur INTO vStock
					FROM Produit
					WHERE id_produit = tablerecord.produit;
					
					UPDATE Produit SET valeur = (vStock - tablerecord.valeur)
					WHERE id_produit = tablerecord.produit;
				END LOOP;
			ELSE 
				RAISE EXCEPTION '%', messageException = 'Quantités insuffisantes en stock pour cette commande';
			END IF;
		END IF;
		RETURN NEW;
END;
$stockCommande$ language plpgsql;

create trigger stockCommande before update on Commande FOR EACH ROW execute procedure stockCommande();

SELECT * FROM Produit;
SELECT * FROM Commande;
SELECT * FROM Contenucommande;

UPDATE Commande SET statut = 'En cours de Validation'
WHERE id_commande = 1;

UPDATE Commande SET statut = 'Validée'
WHERE id_commande = 1;
