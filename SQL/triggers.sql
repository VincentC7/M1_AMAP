create or replace function verifPlaceDispo() returns trigger as $verifPlaceDispo$
begin
IF ((SELECT nbAbonnementMax FROM Parametre)
	-
    (SELECT COUNT(*) FROM Abonnement WHERE etat = 'Validé' AND trimestre = trimestre)) <= 0
	THEN
     		new.etat := 'Sur liste d’attente';
	ELSE
     		new.etat := 'Validé';
		UPDATE Utilisateur set role ='Abonné' WHERE id_utilisateur = new.utilisateur;
		new.datedebutabo := CURRENT_DATE;
		new.datepaiement := CURRENT_DATE;
	END IF;
	RETURN NEW;
 END;
$verifPlaceDispo$ language plpgsql;

create trigger verifPlaceDispo before insert on abonnement FOR EACH ROW execute procedure verifPlaceDispo();
