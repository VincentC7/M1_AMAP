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
	rang INTEGER NOT NULL,
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
	statut VARCHAR(25) NOT NULL CHECK(statut in ('En cours', 'En cours de Validation', 'Validée', 'Refusée', 'Annulée')),
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
	delaiRefusCommande FLOAT(10),
	PRIMARY KEY(nbAbonnementMax, delaiRefusPanier, delaiMajPanier, delaiCommande, delaiRefusCommande)
);
