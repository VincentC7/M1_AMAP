<?php


namespace M1_CSI_Appli_AMAP\Controller;


use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class OrderControle extends Controller {

    private static $PENDING_ORDER = "En cours";
    private static $WAITING_VALIDATION_ORDER = "En cours de Validation";
    private static $REFUSED_ORDER = "Refusée";
    private static $CANCELED_ORDER = "Annulée";
    private static $VALIDATED_ORDER = "Validée";

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
        $stmt->execute([date('Y-m-d H:i:s'), self::$PENDING_ORDER , 0, 4]);
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

    public function index(RequestInterface $request, ResponseInterface $response){
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("SELECT * FROM commande where statut = ? order by datedemande");
        $stmt->execute([self::$PENDING_ORDER]);
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/order_management.twig', ['orders' => $orders]);
    }

    public function accept_order(RequestInterface $request, ResponseInterface $response,$args) {
        return $this->answer_order($response, $args['order_id'], self::$WAITING_VALIDATION_ORDER);
    }

    public function refuse_order(RequestInterface $request, ResponseInterface $response,$args){
        return $this->answer_order($response, $args['order_id'], self::$REFUSED_ORDER);
    }

    private function answer_order(ResponseInterface $response, $id_order, $answer) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("UPDATE commande SET statut = ?, datereponse = ? where id_commande = ?");
        $resultat = $stmt->execute([$answer, date('Y-m-d H:i:s') , intval($id_order)]);
        if ($resultat) {
            $answer_text = $answer == self::$REFUSED_ORDER ? 'refusée' : 'acceptée';
            $this->afficher_message('La commande a été '.$answer_text.' avec succes '. $id_order);
        } else {
            $this->afficher_message('Erreur : Un problème est survenue veuillez ressayer', 'echec');
        }
        return $this->redirect($response,'order_management');
    }

    public function validate_order(RequestInterface $request, ResponseInterface $response,$args){
        return $this->answer_order($response, $args['order_id'], self::$VALIDATED_ORDER);
    }

}