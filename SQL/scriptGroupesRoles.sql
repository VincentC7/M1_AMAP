--verifier les todo

--Création des utilisateurs
create user admin_amap with encrypted password 'admin_amap'; -- admin_amap
create user producteur with encrypted password 'producteur'; -- producteur
create user user_visiteur with encrypted password 'user_visiteur'; -- visiteur
create user user_abonne with encrypted password 'user_abonne'; -- utilisateur
create user user_non_abonne with encrypted password 'user_non_abonne'; -- abonne

--creer les groupes
create group utilisateur;
create group abonne;
create group admin_amap;
create group producteur;

--abonne a les droits de utilisateur
grant utilisateur to abonne;
grant utilisateur to producteur;

--admin_amap
grant select on all tables in SCHEMA public to admin_amap;
grant update (tarifabo) on table trimestre to admin_amap;
grant update (etat) on table abonnement to admin_amap;
grant update on parametre to admin_amap;

--producteur
grant insert on produit to producteur;
grant insert on panier to producteur;

--utilisateur
grant select (nom, prenom, tel, identifiant, role) on table utilisateur to utilisateur;
grant select on abonnement to utilisateur;
grant select on trimestre to utilisateur;
grant select on commande to utilisateur;
grant select on panier to utilisateur;
grant select on produit to utilisateur;

grant insert on commande to utilisateur;
grant insert on contenucommande to utilisateur;
grant insert on abonnement to utilisateur;

grant update (nom, prenom, tel, motdepasse) on table utilisateur to utilisateur;
grant update (etat) on table abonnement to utilisateur;

--abonne
grant insert on refus to abonne;