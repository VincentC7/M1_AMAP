create or replace function verifPlaceDispo() returns trigger as $verifPlaceDispo$
begin
IF ((SELECT nbAbonnementMax FROM Parametre)
	-
    (SELECT COUNT(*) FROM utilisateur WHERE role = 'Abonné')) > 0
	THEN
     		IF CURRENT_DATE >= (SELECT dateDebut FROM Trimestre WHERE id_trimestre = new.trimestre)
     	      	AND CURRENT_DATE <= (SELECT dateFin FROM Trimestre WHERE id_trimestre = new.trimestre)
     			THEN
				new.etat := 'Validé';
				UPDATE Utilisateur set role ='Abonné' WHERE id_utilisateur = new.utilisateur;
				new.datedebutabo := CURRENT_DATE;
				new.datepaiement := CURRENT_DATE;
     			ELSE
     				new.etat := 'Sur liste d’attente';
     			END IF;
	ELSE
     		new.etat := 'Sur liste d’attente';	
	END IF;
	RETURN NEW;
 END;
$verifPlaceDispo$ language plpgsql;

create trigger verifPlaceDispo before insert on abonnement FOR EACH ROW execute procedure verifPlaceDispo();
