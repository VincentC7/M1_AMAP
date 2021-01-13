-- !!! verifier les todo !!!

--creer les groupes
create group utilisateur;
create group abonne;
create group admin_amap;
create group producteur;

--abonne a les droits de utilisateur
grant utilisateur to abonne;

--admin_amap
grant select on all tables in SCHEMA public to admin_amap;
grant update (tarifabo) on table trimestre to admin_amap;
grant update (etat) on table abonnement to admin_amap;
grant update on parametre to admin_amap;

--producteur
TODO upd utilisateur (procedure)
grant select (nom, prenom, tel, identifiant, role) on table utilisateur to producteur
grant insert on produit to producteur
grant insert on panier to producteur

--utilisateur
grant select on utilisateur to utilisateur
grant select on abonnement to utilisateur
grant select on trimestre to utilisateur
grant select on commande to utilisateur
grant select on panier to utilisateur
grant select on produit to utilisateur

grant insert on commande to utilisateur
grant insert on contenucommande to utilisateur
grant insert on abonnement to utilisateur

TODO upd utilisateur (procedure)
TODO upd abonnement (procedure)

--abonne
grant insert on refus to abonne
TODO upd abonnement (procedure)