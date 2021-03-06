PGDMP     7                     y            amap    12.2    12.2 ~    |           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            }           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ~           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    28256    amap    DATABASE     �   CREATE DATABASE amap WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'French_France.1252' LC_CTYPE = 'French_France.1252';
    DROP DATABASE amap;
                postgres    false            �            1255    36507    majcommande()    FUNCTION     �  CREATE FUNCTION public.majcommande() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
        new.datereponse := now();
        new.statut := 'En attente de validation';
    END IF;
    RETURN new;
END;
$$;
 $   DROP FUNCTION public.majcommande();
       public          postgres    false            �            1255    36509    majfileattente()    FUNCTION     -  CREATE FUNCTION public.majfileattente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 '   DROP FUNCTION public.majfileattente();
       public          postgres    false            �            1255    36511    stockcommande()    FUNCTION     �  CREATE FUNCTION public.stockcommande() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 &   DROP FUNCTION public.stockcommande();
       public          postgres    false            �            1255    36513    stockpanier()    FUNCTION     �  CREATE FUNCTION public.stockpanier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    vStock integer;
    nbAbo integer;
BEGIN
    --Récupération du stock
    SELECT valeur INTO vSTOCK
    FROM Produit
    WHERE id_produit = NEW.produit;

    --Récupération du nombre d'abonnés
    SELECT COUNT(*) INTO nbAbo from utilisateur where role = 'Abonné';

    IF (vStock - new.valeur * nbAbo) < 0 THEN
        RAISE EXCEPTION 'Stock négatif';
    ELSE
        --Mise à jour du stock du produit
        UPDATE Produit set valeur = (vStock - new.valeur * nbAbo)
        WHERE id_produit = new.produit;
        RETURN NEW;
    END IF;

END;
$$;
 $   DROP FUNCTION public.stockpanier();
       public          postgres    false            �            1255    36515    stockpanier2()    FUNCTION     Q  CREATE FUNCTION public.stockpanier2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    vStock integer;
    nbAbo integer;
BEGIN
    SELECT valeur INTO vStock
    FROM Produit
    WHERE id_produit = old.produit;

    RAISE NOTICE '%', vStock;

    --Récupération du nombre d'abonnés
    SELECT COUNT(*) INTO nbAbo from utilisateur where role = 'Abonné';

    RAISE NOTICE '%', nbAbo;
    RAISE NOTICE '%', (vStock + old.valeur * nbAbo);
    UPDATE Produit set valeur = (vStock + old.valeur * nbAbo)
    WHERE id_produit = old.produit;
    RETURN NEW;
END;
$$;
 %   DROP FUNCTION public.stockpanier2();
       public          postgres    false            �            1255    36491    verifplacedispo()    FUNCTION     A  CREATE FUNCTION public.verifplacedispo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    IF ( ((SELECT nbAbonnementMax FROM Parametre) - (SELECT COUNT(*) FROM utilisateur WHERE role = 'Abonné')) > 0)
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
$$;
 (   DROP FUNCTION public.verifplacedispo();
       public          postgres    false            �            1259    28275 
   abonnement    TABLE     p  CREATE TABLE public.abonnement (
    id_abonnement integer NOT NULL,
    datedemandeabo timestamp without time zone NOT NULL,
    datedebutabo timestamp without time zone,
    etat character varying(25) NOT NULL,
    datepaiement timestamp without time zone,
    utilisateur integer,
    trimestre integer,
    rang integer,
    CONSTRAINT valid_user_role_check CHECK (((etat)::text = ANY ((ARRAY['En cours'::character varying, 'Validé'::character varying, 'Sur liste d’attente'::character varying, 'En attente de paiement'::character varying, 'Annulé'::character varying, 'Résilié'::character varying])::text[])))
);
    DROP TABLE public.abonnement;
       public         heap    postgres    false            �           0    0    TABLE abonnement    ACL     v   GRANT SELECT ON TABLE public.abonnement TO admin_amap;
GRANT SELECT,INSERT ON TABLE public.abonnement TO utilisateur;
          public          postgres    false    207            �           0    0    COLUMN abonnement.datedebutabo    ACL     F   GRANT UPDATE(datedebutabo) ON TABLE public.abonnement TO utilisateur;
          public          postgres    false    207            �           0    0    COLUMN abonnement.etat    ACL     {   GRANT UPDATE(etat) ON TABLE public.abonnement TO admin_amap;
GRANT UPDATE(etat) ON TABLE public.abonnement TO utilisateur;
          public          postgres    false    207            �           0    0    COLUMN abonnement.datepaiement    ACL     F   GRANT UPDATE(datepaiement) ON TABLE public.abonnement TO utilisateur;
          public          postgres    false    207            �           0    0    COLUMN abonnement.rang    ACL     =   GRANT UPDATE(rang) ON TABLE public.abonnement TO admin_amap;
          public          postgres    false    207            �            1259    28273    abonnement_id_abonnement_seq    SEQUENCE     �   CREATE SEQUENCE public.abonnement_id_abonnement_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.abonnement_id_abonnement_seq;
       public          postgres    false    207            �           0    0    abonnement_id_abonnement_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.abonnement_id_abonnement_seq OWNED BY public.abonnement.id_abonnement;
          public          postgres    false    206            �           0    0 %   SEQUENCE abonnement_id_abonnement_seq    ACL     S   GRANT SELECT,USAGE ON SEQUENCE public.abonnement_id_abonnement_seq TO utilisateur;
          public          postgres    false    206            �            1259    36452    commande    TABLE     N  CREATE TABLE public.commande (
    id_commande integer NOT NULL,
    datedemande timestamp without time zone NOT NULL,
    statut character varying(25) NOT NULL,
    datereponse timestamp without time zone,
    prixtotal real NOT NULL,
    utilisateur integer NOT NULL,
    CONSTRAINT commande_status_check CHECK (((statut)::text = ANY ((ARRAY['En attente de traitement'::character varying, 'En cours de création'::character varying, 'En attente de validation'::character varying, 'Validée'::character varying, 'Refusée'::character varying, 'Annulée'::character varying])::text[])))
);
    DROP TABLE public.commande;
       public         heap    postgres    false            �           0    0    TABLE commande    ACL     r   GRANT SELECT ON TABLE public.commande TO admin_amap;
GRANT SELECT,INSERT ON TABLE public.commande TO utilisateur;
          public          postgres    false    218            �           0    0    COLUMN commande.statut    ACL     >   GRANT UPDATE(statut) ON TABLE public.commande TO utilisateur;
          public          postgres    false    218            �           0    0    COLUMN commande.prixtotal    ACL     A   GRANT UPDATE(prixtotal) ON TABLE public.commande TO utilisateur;
          public          postgres    false    218            �            1259    36450    commande_id_commande_seq    SEQUENCE     �   CREATE SEQUENCE public.commande_id_commande_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.commande_id_commande_seq;
       public          postgres    false    218            �           0    0    commande_id_commande_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.commande_id_commande_seq OWNED BY public.commande.id_commande;
          public          postgres    false    217            �           0    0 !   SEQUENCE commande_id_commande_seq    ACL     O   GRANT SELECT,USAGE ON SEQUENCE public.commande_id_commande_seq TO utilisateur;
          public          postgres    false    217            �            1259    28332    compose    TABLE     �   CREATE TABLE public.compose (
    id_compose integer NOT NULL,
    valeur real NOT NULL,
    produit integer NOT NULL,
    panier integer NOT NULL
);
    DROP TABLE public.compose;
       public         heap    postgres    false            �           0    0    TABLE compose    ACL     �   GRANT SELECT ON TABLE public.compose TO admin_amap;
GRANT SELECT ON TABLE public.compose TO visiteur;
GRANT SELECT ON TABLE public.compose TO utilisateur;
GRANT INSERT,DELETE ON TABLE public.compose TO producteur;
          public          postgres    false    215            �            1259    28330    compose_id_compose_seq    SEQUENCE     �   CREATE SEQUENCE public.compose_id_compose_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.compose_id_compose_seq;
       public          postgres    false    215            �           0    0    compose_id_compose_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.compose_id_compose_seq OWNED BY public.compose.id_compose;
          public          postgres    false    214            �           0    0    SEQUENCE compose_id_compose_seq    ACL     �   GRANT SELECT,USAGE ON SEQUENCE public.compose_id_compose_seq TO utilisateur;
GRANT SELECT,USAGE ON SEQUENCE public.compose_id_compose_seq TO producteur;
          public          postgres    false    214            �            1259    36465    contenucommande    TABLE     �   CREATE TABLE public.contenucommande (
    id_contenu integer NOT NULL,
    valeur real NOT NULL,
    produit integer NOT NULL,
    commande integer NOT NULL
);
 #   DROP TABLE public.contenucommande;
       public         heap    postgres    false            �           0    0    TABLE contenucommande    ACL     �   GRANT SELECT ON TABLE public.contenucommande TO admin_amap;
GRANT SELECT,INSERT ON TABLE public.contenucommande TO utilisateur;
          public          postgres    false    220            �            1259    36463    contenucommande_id_contenu_seq    SEQUENCE     �   CREATE SEQUENCE public.contenucommande_id_contenu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.contenucommande_id_contenu_seq;
       public          postgres    false    220            �           0    0    contenucommande_id_contenu_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.contenucommande_id_contenu_seq OWNED BY public.contenucommande.id_contenu;
          public          postgres    false    219            �           0    0 '   SEQUENCE contenucommande_id_contenu_seq    ACL     U   GRANT SELECT,USAGE ON SEQUENCE public.contenucommande_id_contenu_seq TO utilisateur;
          public          postgres    false    219            �            1259    28293    panier    TABLE     �   CREATE TABLE public.panier (
    id_panier integer NOT NULL,
    numsemaine integer NOT NULL,
    trimestre integer NOT NULL
);
    DROP TABLE public.panier;
       public         heap    postgres    false            �           0    0    TABLE panier    ACL     �   GRANT SELECT ON TABLE public.panier TO admin_amap;
GRANT INSERT ON TABLE public.panier TO producteur;
GRANT SELECT ON TABLE public.panier TO utilisateur;
GRANT SELECT ON TABLE public.panier TO visiteur;
          public          postgres    false    209            �            1259    28291    panier_id_panier_seq    SEQUENCE     �   CREATE SEQUENCE public.panier_id_panier_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.panier_id_panier_seq;
       public          postgres    false    209            �           0    0    panier_id_panier_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.panier_id_panier_seq OWNED BY public.panier.id_panier;
          public          postgres    false    208            �           0    0    SEQUENCE panier_id_panier_seq    ACL     J   GRANT SELECT,USAGE ON SEQUENCE public.panier_id_panier_seq TO producteur;
          public          postgres    false    208            �            1259    28374 	   parametre    TABLE       CREATE TABLE public.parametre (
    nbabonnementmax integer NOT NULL,
    delairefuspanier real NOT NULL,
    delaimajpanier timestamp without time zone NOT NULL,
    delaicommande real NOT NULL,
    delairefuscommande real NOT NULL,
    default_tarif_abo real
);
    DROP TABLE public.parametre;
       public         heap    postgres    false            �           0    0    TABLE parametre    ACL     t   GRANT SELECT,UPDATE ON TABLE public.parametre TO admin_amap;
GRANT SELECT ON TABLE public.parametre TO utilisateur;
          public          postgres    false    216            �            1259    28324    produit    TABLE     �   CREATE TABLE public.produit (
    id_produit integer NOT NULL,
    nomproduit character varying(25) NOT NULL,
    unite character varying(25) NOT NULL,
    valeur real NOT NULL,
    prixunitaire real,
    visible boolean DEFAULT true
);
    DROP TABLE public.produit;
       public         heap    postgres    false            �           0    0    TABLE produit    ACL     �   GRANT SELECT ON TABLE public.produit TO admin_amap;
GRANT INSERT,UPDATE ON TABLE public.produit TO producteur;
GRANT SELECT ON TABLE public.produit TO utilisateur;
GRANT SELECT ON TABLE public.produit TO visiteur;
          public          postgres    false    213            �           0    0    COLUMN produit.valeur    ACL     y   GRANT UPDATE(valeur) ON TABLE public.produit TO producteur;
GRANT UPDATE(valeur) ON TABLE public.produit TO utilisateur;
          public          postgres    false    213            �            1259    28322    produit_id_produit_seq    SEQUENCE     �   CREATE SEQUENCE public.produit_id_produit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.produit_id_produit_seq;
       public          postgres    false    213            �           0    0    produit_id_produit_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.produit_id_produit_seq OWNED BY public.produit.id_produit;
          public          postgres    false    212            �           0    0    SEQUENCE produit_id_produit_seq    ACL     L   GRANT SELECT,USAGE ON SEQUENCE public.produit_id_produit_seq TO producteur;
          public          postgres    false    212            �            1259    28306    refus    TABLE     |   CREATE TABLE public.refus (
    id_refus integer NOT NULL,
    utilisateur integer NOT NULL,
    panier integer NOT NULL
);
    DROP TABLE public.refus;
       public         heap    postgres    false            �           0    0    TABLE refus    ACL     g   GRANT SELECT ON TABLE public.refus TO admin_amap;
GRANT SELECT,INSERT ON TABLE public.refus TO abonne;
          public          postgres    false    211            �           0    0    COLUMN refus.utilisateur    ACL     ;   GRANT UPDATE(utilisateur) ON TABLE public.refus TO abonne;
          public          postgres    false    211            �           0    0    COLUMN refus.panier    ACL     6   GRANT UPDATE(panier) ON TABLE public.refus TO abonne;
          public          postgres    false    211            �            1259    28304    refus_id_refus_seq    SEQUENCE     �   CREATE SEQUENCE public.refus_id_refus_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.refus_id_refus_seq;
       public          postgres    false    211            �           0    0    refus_id_refus_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.refus_id_refus_seq OWNED BY public.refus.id_refus;
          public          postgres    false    210            �           0    0    SEQUENCE refus_id_refus_seq    ACL     D   GRANT SELECT,USAGE ON SEQUENCE public.refus_id_refus_seq TO abonne;
          public          postgres    false    210            �            1259    28267 	   trimestre    TABLE     �   CREATE TABLE public.trimestre (
    id_trimestre integer NOT NULL,
    datedebut timestamp without time zone NOT NULL,
    datefin timestamp without time zone NOT NULL,
    tarifabo real NOT NULL
);
    DROP TABLE public.trimestre;
       public         heap    postgres    false            �           0    0    TABLE trimestre    ACL     �   GRANT SELECT ON TABLE public.trimestre TO admin_amap;
GRANT SELECT ON TABLE public.trimestre TO utilisateur;
GRANT SELECT ON TABLE public.trimestre TO visiteur;
          public          postgres    false    205            �           0    0    COLUMN trimestre.tarifabo    ACL     @   GRANT UPDATE(tarifabo) ON TABLE public.trimestre TO admin_amap;
          public          postgres    false    205            �            1259    28265    trimestre_id_trimestre_seq    SEQUENCE     �   CREATE SEQUENCE public.trimestre_id_trimestre_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.trimestre_id_trimestre_seq;
       public          postgres    false    205            �           0    0    trimestre_id_trimestre_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.trimestre_id_trimestre_seq OWNED BY public.trimestre.id_trimestre;
          public          postgres    false    204            �            1259    28259    utilisateur    TABLE       CREATE TABLE public.utilisateur (
    id_utilisateur integer NOT NULL,
    nom character varying(25) NOT NULL,
    prenom character varying(25) NOT NULL,
    tel character varying(25) NOT NULL,
    identifiant character varying(150) NOT NULL,
    motdepasse character varying(25) NOT NULL,
    role character varying(25) NOT NULL,
    CONSTRAINT valid_user_role_check CHECK (((role)::text = ANY ((ARRAY['Abonné'::character varying, 'Non abonné'::character varying, 'Producteur'::character varying, 'Admin'::character varying])::text[])))
);
    DROP TABLE public.utilisateur;
       public         heap    postgres    false            �           0    0    TABLE utilisateur    ACL     u   GRANT SELECT ON TABLE public.utilisateur TO admin_amap;
GRANT SELECT,INSERT ON TABLE public.utilisateur TO visiteur;
          public          postgres    false    203            �           0    0 !   COLUMN utilisateur.id_utilisateur    ACL     `   GRANT SELECT(id_utilisateur),UPDATE(id_utilisateur) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �           0    0    COLUMN utilisateur.nom    ACL     J   GRANT SELECT(nom),UPDATE(nom) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �           0    0    COLUMN utilisateur.prenom    ACL     P   GRANT SELECT(prenom),UPDATE(prenom) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �           0    0    COLUMN utilisateur.tel    ACL     J   GRANT SELECT(tel),UPDATE(tel) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �           0    0    COLUMN utilisateur.identifiant    ACL     F   GRANT SELECT(identifiant) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �           0    0    COLUMN utilisateur.motdepasse    ACL     E   GRANT UPDATE(motdepasse) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �           0    0    COLUMN utilisateur.role    ACL     L   GRANT SELECT(role),UPDATE(role) ON TABLE public.utilisateur TO utilisateur;
          public          postgres    false    203            �            1259    28257    utilisateur_id_utilisateur_seq    SEQUENCE     �   CREATE SEQUENCE public.utilisateur_id_utilisateur_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.utilisateur_id_utilisateur_seq;
       public          postgres    false    203            �           0    0    utilisateur_id_utilisateur_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.utilisateur_id_utilisateur_seq OWNED BY public.utilisateur.id_utilisateur;
          public          postgres    false    202            �           0    0 '   SEQUENCE utilisateur_id_utilisateur_seq    ACL     �   GRANT SELECT,USAGE ON SEQUENCE public.utilisateur_id_utilisateur_seq TO abonne;
GRANT SELECT,USAGE ON SEQUENCE public.utilisateur_id_utilisateur_seq TO visiteur;
          public          postgres    false    202            �
           2604    28278    abonnement id_abonnement    DEFAULT     �   ALTER TABLE ONLY public.abonnement ALTER COLUMN id_abonnement SET DEFAULT nextval('public.abonnement_id_abonnement_seq'::regclass);
 G   ALTER TABLE public.abonnement ALTER COLUMN id_abonnement DROP DEFAULT;
       public          postgres    false    207    206    207            �
           2604    36455    commande id_commande    DEFAULT     |   ALTER TABLE ONLY public.commande ALTER COLUMN id_commande SET DEFAULT nextval('public.commande_id_commande_seq'::regclass);
 C   ALTER TABLE public.commande ALTER COLUMN id_commande DROP DEFAULT;
       public          postgres    false    217    218    218            �
           2604    28335    compose id_compose    DEFAULT     x   ALTER TABLE ONLY public.compose ALTER COLUMN id_compose SET DEFAULT nextval('public.compose_id_compose_seq'::regclass);
 A   ALTER TABLE public.compose ALTER COLUMN id_compose DROP DEFAULT;
       public          postgres    false    214    215    215            �
           2604    36468    contenucommande id_contenu    DEFAULT     �   ALTER TABLE ONLY public.contenucommande ALTER COLUMN id_contenu SET DEFAULT nextval('public.contenucommande_id_contenu_seq'::regclass);
 I   ALTER TABLE public.contenucommande ALTER COLUMN id_contenu DROP DEFAULT;
       public          postgres    false    220    219    220            �
           2604    28296    panier id_panier    DEFAULT     t   ALTER TABLE ONLY public.panier ALTER COLUMN id_panier SET DEFAULT nextval('public.panier_id_panier_seq'::regclass);
 ?   ALTER TABLE public.panier ALTER COLUMN id_panier DROP DEFAULT;
       public          postgres    false    209    208    209            �
           2604    28327    produit id_produit    DEFAULT     x   ALTER TABLE ONLY public.produit ALTER COLUMN id_produit SET DEFAULT nextval('public.produit_id_produit_seq'::regclass);
 A   ALTER TABLE public.produit ALTER COLUMN id_produit DROP DEFAULT;
       public          postgres    false    212    213    213            �
           2604    28309    refus id_refus    DEFAULT     p   ALTER TABLE ONLY public.refus ALTER COLUMN id_refus SET DEFAULT nextval('public.refus_id_refus_seq'::regclass);
 =   ALTER TABLE public.refus ALTER COLUMN id_refus DROP DEFAULT;
       public          postgres    false    211    210    211            �
           2604    28270    trimestre id_trimestre    DEFAULT     �   ALTER TABLE ONLY public.trimestre ALTER COLUMN id_trimestre SET DEFAULT nextval('public.trimestre_id_trimestre_seq'::regclass);
 E   ALTER TABLE public.trimestre ALTER COLUMN id_trimestre DROP DEFAULT;
       public          postgres    false    204    205    205            �
           2604    28262    utilisateur id_utilisateur    DEFAULT     �   ALTER TABLE ONLY public.utilisateur ALTER COLUMN id_utilisateur SET DEFAULT nextval('public.utilisateur_id_utilisateur_seq'::regclass);
 I   ALTER TABLE public.utilisateur ALTER COLUMN id_utilisateur DROP DEFAULT;
       public          postgres    false    202    203    203            l          0    28275 
   abonnement 
   TABLE DATA                 public          postgres    false    207   �       w          0    36452    commande 
   TABLE DATA                 public          postgres    false    218   �       t          0    28332    compose 
   TABLE DATA                 public          postgres    false    215   �       y          0    36465    contenucommande 
   TABLE DATA                 public          postgres    false    220   ��       n          0    28293    panier 
   TABLE DATA                 public          postgres    false    209   �       u          0    28374 	   parametre 
   TABLE DATA                 public          postgres    false    216   ��       r          0    28324    produit 
   TABLE DATA                 public          postgres    false    213   I�       p          0    28306    refus 
   TABLE DATA                 public          postgres    false    211   Q�       j          0    28267 	   trimestre 
   TABLE DATA                 public          postgres    false    205   ��       h          0    28259    utilisateur 
   TABLE DATA                 public          postgres    false    203   }�       �           0    0    abonnement_id_abonnement_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.abonnement_id_abonnement_seq', 37, true);
          public          postgres    false    206            �           0    0    commande_id_commande_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.commande_id_commande_seq', 32, true);
          public          postgres    false    217            �           0    0    compose_id_compose_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.compose_id_compose_seq', 43, true);
          public          postgres    false    214            �           0    0    contenucommande_id_contenu_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.contenucommande_id_contenu_seq', 34, true);
          public          postgres    false    219            �           0    0    panier_id_panier_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.panier_id_panier_seq', 38, true);
          public          postgres    false    208            �           0    0    produit_id_produit_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.produit_id_produit_seq', 20, true);
          public          postgres    false    212            �           0    0    refus_id_refus_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.refus_id_refus_seq', 4, true);
          public          postgres    false    210            �           0    0    trimestre_id_trimestre_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.trimestre_id_trimestre_seq', 6, true);
          public          postgres    false    204            �           0    0    utilisateur_id_utilisateur_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.utilisateur_id_utilisateur_seq', 16, true);
          public          postgres    false    202            �
           2606    28280    abonnement abonnement_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.abonnement
    ADD CONSTRAINT abonnement_pkey PRIMARY KEY (id_abonnement);
 D   ALTER TABLE ONLY public.abonnement DROP CONSTRAINT abonnement_pkey;
       public            postgres    false    207            �
           2606    36457    commande commande_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.commande
    ADD CONSTRAINT commande_pkey PRIMARY KEY (id_commande);
 @   ALTER TABLE ONLY public.commande DROP CONSTRAINT commande_pkey;
       public            postgres    false    218            �
           2606    28337    compose compose_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.compose
    ADD CONSTRAINT compose_pkey PRIMARY KEY (id_compose);
 >   ALTER TABLE ONLY public.compose DROP CONSTRAINT compose_pkey;
       public            postgres    false    215            �
           2606    36470 $   contenucommande contenucommande_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.contenucommande
    ADD CONSTRAINT contenucommande_pkey PRIMARY KEY (id_contenu);
 N   ALTER TABLE ONLY public.contenucommande DROP CONSTRAINT contenucommande_pkey;
       public            postgres    false    220            �
           2606    28298    panier panier_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.panier
    ADD CONSTRAINT panier_pkey PRIMARY KEY (id_panier);
 <   ALTER TABLE ONLY public.panier DROP CONSTRAINT panier_pkey;
       public            postgres    false    209            �
           2606    28378    parametre parametre_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.parametre
    ADD CONSTRAINT parametre_pkey PRIMARY KEY (nbabonnementmax, delairefuspanier, delaimajpanier, delaicommande, delairefuscommande);
 B   ALTER TABLE ONLY public.parametre DROP CONSTRAINT parametre_pkey;
       public            postgres    false    216    216    216    216    216            �
           2606    28329    produit produit_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.produit
    ADD CONSTRAINT produit_pkey PRIMARY KEY (id_produit);
 >   ALTER TABLE ONLY public.produit DROP CONSTRAINT produit_pkey;
       public            postgres    false    213            �
           2606    28311    refus refus_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.refus
    ADD CONSTRAINT refus_pkey PRIMARY KEY (id_refus);
 :   ALTER TABLE ONLY public.refus DROP CONSTRAINT refus_pkey;
       public            postgres    false    211            �
           2606    28272    trimestre trimestre_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.trimestre
    ADD CONSTRAINT trimestre_pkey PRIMARY KEY (id_trimestre);
 B   ALTER TABLE ONLY public.trimestre DROP CONSTRAINT trimestre_pkey;
       public            postgres    false    205            �
           2606    28264    utilisateur utilisateur_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT utilisateur_pkey PRIMARY KEY (id_utilisateur);
 F   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT utilisateur_pkey;
       public            postgres    false    203            �
           2620    36508    commande majcommande    TRIGGER     p   CREATE TRIGGER majcommande BEFORE UPDATE ON public.commande FOR EACH ROW EXECUTE FUNCTION public.majcommande();
 -   DROP TRIGGER majcommande ON public.commande;
       public          postgres    false    221    218            �
           2620    36510    abonnement majfileattente    TRIGGER     x   CREATE TRIGGER majfileattente BEFORE UPDATE ON public.abonnement FOR EACH ROW EXECUTE FUNCTION public.majfileattente();
 2   DROP TRIGGER majfileattente ON public.abonnement;
       public          postgres    false    207    222            �
           2620    36512    commande stockcommande    TRIGGER     t   CREATE TRIGGER stockcommande BEFORE UPDATE ON public.commande FOR EACH ROW EXECUTE FUNCTION public.stockcommande();
 /   DROP TRIGGER stockcommande ON public.commande;
       public          postgres    false    235    218            �
           2620    36514    compose stockpanier    TRIGGER     o   CREATE TRIGGER stockpanier BEFORE INSERT ON public.compose FOR EACH ROW EXECUTE FUNCTION public.stockpanier();
 ,   DROP TRIGGER stockpanier ON public.compose;
       public          postgres    false    236    215            �
           2620    36516    compose stockpanier2    TRIGGER     p   CREATE TRIGGER stockpanier2 AFTER DELETE ON public.compose FOR EACH ROW EXECUTE FUNCTION public.stockpanier2();
 -   DROP TRIGGER stockpanier2 ON public.compose;
       public          postgres    false    237    215            �
           2620    36506    abonnement verifplacedispo    TRIGGER     z   CREATE TRIGGER verifplacedispo BEFORE INSERT ON public.abonnement FOR EACH ROW EXECUTE FUNCTION public.verifplacedispo();
 3   DROP TRIGGER verifplacedispo ON public.abonnement;
       public          postgres    false    238    207            �
           2606    28286 $   abonnement abonnement_trimestre_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.abonnement
    ADD CONSTRAINT abonnement_trimestre_fkey FOREIGN KEY (trimestre) REFERENCES public.trimestre(id_trimestre);
 N   ALTER TABLE ONLY public.abonnement DROP CONSTRAINT abonnement_trimestre_fkey;
       public          postgres    false    205    207    2761            �
           2606    28281 &   abonnement abonnement_utilisateur_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.abonnement
    ADD CONSTRAINT abonnement_utilisateur_fkey FOREIGN KEY (utilisateur) REFERENCES public.utilisateur(id_utilisateur);
 P   ALTER TABLE ONLY public.abonnement DROP CONSTRAINT abonnement_utilisateur_fkey;
       public          postgres    false    207    203    2759            �
           2606    36458 "   commande commande_utilisateur_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.commande
    ADD CONSTRAINT commande_utilisateur_fkey FOREIGN KEY (utilisateur) REFERENCES public.utilisateur(id_utilisateur);
 L   ALTER TABLE ONLY public.commande DROP CONSTRAINT commande_utilisateur_fkey;
       public          postgres    false    218    203    2759            �
           2606    28343    compose compose_panier_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.compose
    ADD CONSTRAINT compose_panier_fkey FOREIGN KEY (panier) REFERENCES public.panier(id_panier);
 E   ALTER TABLE ONLY public.compose DROP CONSTRAINT compose_panier_fkey;
       public          postgres    false    2765    215    209            �
           2606    28338    compose compose_produit_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.compose
    ADD CONSTRAINT compose_produit_fkey FOREIGN KEY (produit) REFERENCES public.produit(id_produit);
 F   ALTER TABLE ONLY public.compose DROP CONSTRAINT compose_produit_fkey;
       public          postgres    false    213    2769    215            �
           2606    36471 -   contenucommande contenucommande_commande_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contenucommande
    ADD CONSTRAINT contenucommande_commande_fkey FOREIGN KEY (commande) REFERENCES public.commande(id_commande);
 W   ALTER TABLE ONLY public.contenucommande DROP CONSTRAINT contenucommande_commande_fkey;
       public          postgres    false    220    218    2775            �
           2606    28299    panier panier_trimestre_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.panier
    ADD CONSTRAINT panier_trimestre_fkey FOREIGN KEY (trimestre) REFERENCES public.trimestre(id_trimestre);
 F   ALTER TABLE ONLY public.panier DROP CONSTRAINT panier_trimestre_fkey;
       public          postgres    false    2761    205    209            �
           2606    28317    refus refus_panier_fkey    FK CONSTRAINT     }   ALTER TABLE ONLY public.refus
    ADD CONSTRAINT refus_panier_fkey FOREIGN KEY (panier) REFERENCES public.panier(id_panier);
 A   ALTER TABLE ONLY public.refus DROP CONSTRAINT refus_panier_fkey;
       public          postgres    false    2765    211    209            �
           2606    28312    refus refus_utilisateur_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.refus
    ADD CONSTRAINT refus_utilisateur_fkey FOREIGN KEY (utilisateur) REFERENCES public.utilisateur(id_utilisateur);
 F   ALTER TABLE ONLY public.refus DROP CONSTRAINT refus_utilisateur_fkey;
       public          postgres    false    2759    203    211            l     x�͒Mn�0���bv$���1Ϊ�,��B�mej+�4��5z��#7�Ij Uՠd�.��y�3��4/���fI�}�cW����u-+YkX(��+�����4��.:=(�����ե�ӪT����nT%[�H�K�?��u�"��K��b�`���1#���v]6����R���vE� @���t���y`�+L�Q�}��N<H�
�g=gprs>�f�=L���4dԷ�=�g�5`i	���km�K�fW�қd֏���l4f6�d0�I0���2kYߩm��      w   �   x�ő=n�0�w���@������"�4k��(�aKE��s�b�QwI3��{�#?����<���`H��]�^M�,�\w�:mg1ES�6G;�a��0���G��輛r1�k8�_��8AP2����@��BsRf{B���߂y-E-sUbY!��E����Kj���3n��hC��7���hׇ�S���-Ss�c������rM��4����҂QR�_PXt�ً�=٪0      t   p   x���v
Q���W((M��L�K��-�/NU��L���u�sRK�t
��SJ3K��ļ��"M�0G�P�`C#CKcMk.O�4�� h��M6�8�j0 WR�      y   u   x���v
Q���W((M��L�K��+I�+M���M�KIU��L����(�%椖�(委f��(��i*�9���+h�(�( )Mk.OX2j�!��0�Q0�Za��� W�^�      n   {   x���v
Q���W((M��L�+H��L-R��L��0u�Js�Ss3�RuJ�2sS�K�R5�}B]�4-tL��XӚ˓*�3���Ʀ@Ì�i���ЁfT3�c#j��c�y\\ ࡘ�      u   �   x�U�1�0�w��TPIBm�N�b�ڮ��'�$Q������wp�q\ݴս���n�n��c��EM�Df�a1�4���D
��y{�h$������5����=�qS�wh�������j!�`��P0�S�S~��B��}������ ���;�      r   �   x���Mj�0��>��d�����U()5-i��n��2 Gf$�^����:�]��x!13�����֛�T��t�`�:rM� )6o?���k�x�`$��5�$t��H#�S�x�&����~SC��%�Z[�\����g�3n�)�\JM�J��㰤���B0��ֽ�n[�-�	_��`Eq�	�.x8
 de��b6�W�xv���G��0QŘ4�(�H���=�Q��3������� ؼ�m��$�x�!M      p   Q   x���v
Q���W((M��L�+JM+-V��L��tJK2s2�KRK�t
�2S�4�}B]�4Lt���\Ӛ�� �      j   �   x���M�@�������1��ک�!Һ��
}a��OӖ�=��f��<0o��ɾ�4+v�誋8�d+��)[��Ojs�.%�y��ql��Y��)�������`QL�]$} 1~�Tg沟3C{m��`
��=����z�h�$�� t�e����#�D�2�c~�Pu� S?�<���0^�Q�r      h   �  x�͕Kn�0����;��<l�Q7��RE�B�"��;i]p���+	ud������8���5����
��W���T���(Y��E�1b�L: /x��x� �pU��`�r�̪��,��,�#���|̖`H �"K��Z�K0�&~�]��%�8�d��� aҨ���GO����OG�D
�a��Њ\�A@�w�n�1m޸k�{:�.y�}��a�(�.�ɞ�k̋L�͔���/y��4�MNzG�4YMa���#ǚ�BS��w�&C�69����04�M��F�4۲v����37u1E(j{�K����8>d�5/*��d| ����)�WS��t3[������M����]����G�����4���=����T�]~G�:���f~lU`     