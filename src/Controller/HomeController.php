<?php

namespace M1_CSI_Appli_AMAP\Controller;

use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class HomeController extends Controller {

    private $occasional_order_start_day = "Monday";
    private $occasional_order_start_hour = 12;
    private $occasional_order_end_day = "Tuesday";
    private $occasional_order_end_hour = 9;

    public function index(RequestInterface $request, ResponseInterface $response){
        $pdo = $this->get_PDO();
        $week_number = date('W');
        $year = date('Y');

        $stmt = $pdo->prepare("select * from panier inner join trimestre t on panier.trimestre = t.id_trimestre WHERE numsemaine = ? and datedebut BETWEEN ? and ?;");
        $stmt->execute([$week_number,$year.'-01-01',$year.'-12-31']);
        $basket = $stmt->fetch();

        $stmt = $pdo->prepare("select c.valeur,nomproduit,unite from compose c inner join produit p on c.produit = p.id_produit WHERE panier = ?;");
        $stmt->execute([$basket['id_panier']]);
        $current_basket = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $stmt = $pdo->prepare("select c.valeur,nomproduit,unite from compose c inner join produit p on c.produit = p.id_produit WHERE panier = ?;");
        $stmt->execute([$basket['id_panier']-1]);
        $last_basket = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $occassional = [];
        $day = date('l');
        $hour = intval(date('G'));
        $occassional_msg = "Pas de produits disponibles";
        if (($day == $this->occasional_order_start_day && $hour > $this->occasional_order_start_hour || $day == $this->occasional_order_end_day  && $hour < $this->occasional_order_end_hour )) {
            $stmt = $pdo->prepare("select valeur,nomproduit,unite from produit WHERE valeur > 0;");
            $stmt->execute();
            $occassional = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }else{
            $occassional_msg = "Les commandes occassionnelles sont actuellements fermés";
        }

        $this->render($response,'pages/home.twig', ['current_basket'=>$current_basket,'last_basket'=>$last_basket,'occasional_order'=>$occassional,'occasional_msg'=>$occassional_msg,'current_basket_id'=>$basket['id_panier']]);
    }
}