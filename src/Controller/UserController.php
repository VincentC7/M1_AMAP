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
        $this->render($response, 'pages/user_home.twig', ['orders' => $orders,'user'=>$user,'refus'=>$refus]);
    }

}