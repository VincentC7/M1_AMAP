create or replace function verifPlaceDispo() returns trigger as $verifPlaceDispo$
begin
    IF ((SELECT nbAbonnementMax FROM Parametre)
        -
        (SELECT COUNT(*) FROM Abonnement WHERE etat = 'Validé' AND trimestre = trimestre)) <= 0
    THEN
        UPDATE Abonnement set etat = 'Sur liste d attente'
        WHERE id_abonnement = (SELECT MAX(id_abonnement) FROM Abonnement);
        RAISE NOTICE 'V1111111 %', (SELECT MAX(id_abonnement) FROM Abonnement);

    ELSE
        RAISE NOTICE 'V1111111 %', (SELECT MAX(id_abonnement) FROM Abonnement);
        UPDATE Abonnement set etat = 'Validé'
        WHERE id_abonnement = (SELECT MAX(id_abonnement) FROM Abonnement);
    END IF;
    RETURN NEW;
END;
$verifPlaceDispo$ language plpgsql;

create trigger verifPlaceDispo after insert on Abonnement execute procedure verifPlaceDispo();


