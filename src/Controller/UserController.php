<?php


namespace M1_CSI_Appli_AMAP\Controller;


use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class UserController extends Controller
{

    public function index(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("Select nom,prenom,role from utilisateur where id_utilisateur = ?");
        $stmt->execute([$_SESSION['user_id']]);
        $user = $stmt->fetch();

        $refus =[];
        if ($_SESSION['role'] == 'Abonné') {
            $stmt = $pdo->prepare("Select panier,numsemaine, to_char( datedebut, 'YYYY') as year from refus inner join panier on refus.panier = panier.id_panier inner join trimestre on panier.trimestre = trimestre.id_trimestre where utilisateur = ?");
            $stmt->execute([$_SESSION['user_id']]);
            $refus = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        $stmt = $pdo->prepare("SELECT id_trimestre,tarifabo from trimestre where datedebut <= ? and datefin >= ?");
        $date = date('Y-m-d H:i:s');
        $stmt->execute([$date,$date]);
        $current_tri = $stmt->fetch();
        $stmt = $pdo->prepare("Select id_abonnement from abonnement where trimestre = ?");
        $stmt->execute([$current_tri["id_trimestre"]+1]);
        $is_sub_up = $stmt->fetch();

        $stmt = $pdo->prepare("SELECT * FROM commande where utilisateur = ? order by datedemande");
        $stmt->execute([$_SESSION['user_id']]);
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $i = 0;
        foreach ($orders as $order) {
            $stmt2 = $pdo->prepare("SELECT nomproduit, c.valeur, unite FROM contenucommande as c inner join produit as p on p.id_produit = c.produit where commande = ?");
            $stmt2->execute([$order['id_commande']]);
            $products = $stmt2->fetchAll(PDO::FETCH_ASSOC);
            $orders[$i]['products'] = $products;
            $i++;
        }
        $this->render($response, 'pages/user_home.twig', ['orders' => $orders,'user'=>$user,'refus'=>$refus, 'is_sub_up' => isset($is_sub_up['id_abonnement']), 'tarif'=>$current_tri['tarifabo']]);
    }

}