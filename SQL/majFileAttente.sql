create or replace function majFileAttente() returns trigger as $majFileAttente$
DECLARE
id_next_user int;
id_next_abo int;
BEGIN
		If new.etat = 'Résilié' AND old.etat != 'Résilié'
		THEN
			UPDATE Utilisateur set role ='Non abonné'
			WHERE id_utilisateur = new.utilisateur;

			SELECT id_abonnement, utilisateur INTO id_next_abo, id_next_user FROM abonnement
			WHERE rang = (SELECT MIN(rang) FROM Abonnement WHERE etat = 'Sur liste d’attente');
			
			IF id_next_user IS NOT NULL THEN
				UPDATE Abonnement SET
				etat = 'Validé',
				datedebutabo = CURRENT_DATE,
				datepaiement = CURRENT_DATE
				WHERE id_abonnement = id_next_abo;
				UPDATE Utilisateur SET role ='Abonné' WHERE id_utilisateur = id_next_user;
			END IF;
		END IF;
		RETURN NEW;
 END;
$majFileAttente$ language plpgsql;

create trigger majFileAttente before update on abonnement FOR EACH ROW execute procedure majFileAttente();

-- clear tables
DELETE FROM abonnement;
DELETE FROM utilisateur;
DELETE FROM trimestre;

--insertion de donnees
insert into trimestre values (1, current_date, current_date, 1)

INSERT into utilisateur values (1, 'Jean', 'NEYMAR', '02', 'rgr', 'sgf', 'Abonné');
INSERT into abonnement values (1, CURRENT_DATE, CURRENT_DATE, 'En cours', CURRENT_DATE, 1, 1, 1);
			
INSERT into utilisateur values (2, 'Arthur', 'BOILS', '02', 'rgr', 'sgf', 'Non abonné');
INSERT into abonnement values (2, CURRENT_DATE, CURRENT_DATE, 'Sur liste d’attente', CURRENT_DATE, 2, 1, 3);
			
INSERT into utilisateur values (3, 'Michel', 'CEMO', '02', 'rgr', 'sgf', 'Non abonné');
INSERT into abonnement values (3, CURRENT_DATE, CURRENT_DATE, 'Sur liste d’attente', CURRENT_DATE, 3, 1, 2);

-- resultat attendu : Michel CEMO PASSE abonne, et Jean NEYMAR passe resilie
update abonnement set etat = 'Résilié' where id_abonnement = 1