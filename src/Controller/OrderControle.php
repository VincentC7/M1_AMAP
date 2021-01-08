<?php


namespace M1_CSI_Appli_AMAP\Controller;


use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class OrderControle extends Controller {

    public function order_form(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("SELECT * FROM produit where valeur > 0;");
        $stmt->execute();
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/order_form.twig', ['products' => $products]);
    }

    public function order_save(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("INSERT INTO commande (datedemande, statut, prixtotal, utilisateur) VALUES (?,?,?,?)");
        $stmt->execute([date('Y-m-d H:i:s'), 'En attente de traitement', 0, 4]);
        $id = $pdo->lastInsertId();
        $params = $request->getParams();
        $total = 0;
        foreach ($params as $key => $value) {
            if ($value != 0){
                $key = str_replace("input","", $key);
                $stmt = $pdo->prepare("SELECT prixunitaire from produit where id_produit = ?");
                $stmt->execute([$key]);
                $product = $stmt->fetch();
                $total += ($product['prixunitaire'] * $value);
                $stmt = $pdo->prepare("INSERT INTO contenucommande (valeur, produit, commande) VALUES (?,?,?)");
                $stmt->execute([$value, $key, $id]);
            }
        }
        $stmt = $pdo->prepare("UPDATE commande set prixtotal = ? where id_commande = ?");
        $stmt->execute([$total,$id]);
        $this->render($response, 'pages/order_form.twig',['id'=>$id]);
        $this->afficher_message('Votre commande à été prise en compte');
        return $this->redirect($response,'home');
    }
}