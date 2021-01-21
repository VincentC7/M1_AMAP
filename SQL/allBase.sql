CREATE TABLE IF NOT EXISTS Utilisateur (
	id_utilisateur SERIAL,
	nom VARCHAR(25) NOT NULL,
	prenom VARCHAR(25) NOT NULL,
    	tel VARCHAR(25) NOT NULL,
	identifiant VARCHAR(150) NOT NULL,
	motDePasse VARCHAR(25) NOT NULL,
	role VARCHAR(25) NOT NULL CHECK(role in ('Abonné', 'Non abonné', 'Producteur', 'Admin')),
	PRIMARY KEY(id_utilisateur)
);

CREATE TABLE IF NOT EXISTS Trimestre (
	id_trimestre SERIAL,
	dateDebut TIMESTAMP NOT NULL,
	dateFin TIMESTAMP NOT NULL,
	tarifAbo FLOAT(10) NOT NULL,
	PRIMARY KEY(id_trimestre)
);

CREATE TABLE IF NOT EXISTS Abonnement (
	id_abonnement SERIAL,
	dateDemandeAbo TIMESTAMP NOT NULL,
 	dateDebutAbo TIMESTAMP,
	etat VARCHAR(25) NOT NULL CHECK(etat in ('En cours', 'Validé', 'Sur liste d’attente', 'En attente de paiement', 'Annulé', 'Résilié')),
	datePaiement TIMESTAMP,
	utilisateur INTEGER,
	trimestre INTEGER,
	rang INTEGER,
	PRIMARY KEY(id_abonnement),
	FOREIGN KEY(utilisateur) REFERENCES Utilisateur(id_utilisateur),
	FOREIGN KEY(trimestre) REFERENCES Trimestre(id_trimestre)
);

CREATE TABLE IF NOT EXISTS Panier (
	id_panier SERIAL,
	numSemaine INTEGER NOT NULL,
	trimestre INTEGER NOT NULL,
	PRIMARY KEY(id_panier),
	FOREIGN KEY(trimestre) REFERENCES Trimestre(id_trimestre)
);

CREATE TABLE IF NOT EXISTS Refus (
	id_refus SERIAL,
	utilisateur INTEGER NOT NULL,
	panier INTEGER NOT NULL,
	PRIMARY KEY(id_refus),
	FOREIGN KEY(utilisateur) REFERENCES Utilisateur(id_utilisateur),
	FOREIGN KEY(panier) REFERENCES Panier(id_panier)
);

CREATE TABLE IF NOT EXISTS Produit (
	id_produit SERIAL,
	nomProduit VARCHAR(25) NOT NULL,
	unite VARCHAR(25) NOT NULL,
	valeur FLOAT(10) NOT NULL,
	prixUnitaire FLOAT(10),
	visible bool,
	PRIMARY KEY(id_produit)
);

CREATE TABLE IF NOT EXISTS Compose (
	id_compose SERIAL,
	valeur FLOAT(10) NOT NULL, 
	produit INTEGER NOT NULL,
	panier INTEGER NOT NULL,
	PRIMARY KEY(id_compose),
	FOREIGN KEY(produit) REFERENCES Produit(id_produit),
	FOREIGN KEY(panier) REFERENCES Panier(id_panier)
);

CREATE TABLE IF NOT EXISTS Commande (
	id_commande SERIAL,
	dateDemande TIMESTAMP NOT NULL,
	statut VARCHAR(25) NOT NULL CHECK(statut in ('En attent de traitemente','En cours de création', 'En attente de validation', 'Validée', 'Refusée', 'Annulée')),
	dateReponse TIMESTAMP,
	prixTotal FLOAT(10) NOT NULL,
	utilisateur INTEGER NOT NULL,
	PRIMARY KEY(id_commande),
	FOREIGN KEY(utilisateur) REFERENCES Utilisateur(id_utilisateur)
);

CREATE TABLE IF NOT EXISTS ContenuCommande (
	id_contenu SERIAL,
	valeur FLOAT(10) NOT NULL,
	produit INTEGER NOT NULL,
	commande INTEGER NOT NULL,
	PRIMARY KEY(id_contenu),
	FOREIGN KEY(commande) REFERENCES Commande(id_commande)
);

CREATE TABLE IF NOT EXISTS Parametre (
	nbAbonnementMax INTEGER,
	delaiRefusPanier FLOAT(10),
	delaiMajPanier TIMESTAMP,
	delaiCommande FLOAT(10),
    default_tarif_abo FLOAT(10),
	delaiRefusCommande FLOAT(10),
	PRIMARY KEY(nbAbonnementMax, delaiRefusPanier, delaiMajPanier, delaiCommande, delaiRefusCommande)
);

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
					new.statut = 'Refusée';
					RETURN new;
				END IF;
			END LOOP;
			new.datereponse := CURRENT_DATE;
			new.statut := 'En attente de validation';
		END IF;
		RETURN new;
END;
$majCommande$ language plpgsql;

create trigger majCommande before update on commande FOR EACH ROW execute procedure majCommande();

create or replace function majFileAttente() returns trigger as $majFileAttente$
DECLARE
id_next_user int;
id_next_abo int;
BEGIN
		If new.etat = 'Résilié' AND old.etat != 'Résilié'
		THEN
			UPDATE Utilisateur set role ='Non abonné'
			WHERE id_utilisateur = new.utilisateur;

			SELECT id_abonnement, utilisateur INTO id_next_abo, id_next_user
			FROM abonnement
			WHERE rang = (SELECT MIN(rang)
				      FROM Abonnement
				      WHERE etat = 'Sur liste d’attente'
				      AND trimestre = new.trimestre);
			
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

create or replace function stockCommande() returns trigger as $stockCommande$
DECLARE 
	reste integer;
	vStock integer;
	tablerecord RECORD;
BEGIN
		RAISE notice 'val : %', new;
		If NEW.statut = 'Validée'
		THEN
			SELECT MIN(produit.valeur - contenucommande.valeur) INTO reste
			FROM Produit, Contenucommande
			WHERE produit.id_produit = contenucommande.produit
			AND contenucommande.commande = new.id_commande;
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

create or replace function stockPanier2() returns trigger as $stockPanier2$
DECLARE 
	vStock integer;
	nbAbo integer;
BEGIN
	SELECT valeur INTO vStock
	FROM Produit
	WHERE id_produit = old.produit;

	RAISE NOTICE '%', vStock;

	SELECT COUNT(*) INTO nbAbo
	FROM abonnement, panier
	WHERE panier.id_panier = (SELECT MAX(id_panier) FROM Panier)
	AND panier.trimestre = abonnement.trimestre
	AND abonnement.etat='Validé';
	
	RAISE NOTICE '%', nbAbo;
	RAISE NOTICE '%', (vStock + old.valeur * nbAbo);
	UPDATE Produit set valeur = (vStock + old.valeur * nbAbo)
	WHERE id_produit = old.produit;
	RETURN NEW;
END;
$stockPanier2$ language plpgsql;

create trigger stockPanier2 after delete on Compose FOR EACH ROW execute procedure stockPanier2();

create or replace function verifPlaceDispo() returns trigger as $verifPlaceDispo$
begin
IF ((SELECT nbAbonnementMax FROM Parametre)
	-
    (SELECT COUNT(*) FROM Abonnement WHERE etat = 'Validé' AND trimestre = trimestre)) <= 0
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

