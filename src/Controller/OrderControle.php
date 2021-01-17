<?php


namespace M1_CSI_Appli_AMAP\Controller;


use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class OrderControle extends Controller {

    private static $CREATING_ORDER = "En cours de création";
    private static $PENDING_ORDER = "En attente de traitement";
    private static $WAITING_VALIDATION_ORDER = "En attente de validation";
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
        $stmt->execute([date('Y-m-d H:i:s'), self::$CREATING_ORDER , 0, $_SESSION['user_id']]);
        $id = $pdo->lastInsertId();
        $params = $request->getParams();
        $total = 0;
        foreach ($params as $key => $value) {
            if ($value != 0) {
                $key = str_replace("input","", $key);
                $stmt = $pdo->prepare("SELECT prixunitaire from produit where id_produit = ?");
                $stmt->execute([$key]);
                $product = $stmt->fetch();
                $total += ($product['prixunitaire'] * $value);
                $stmt = $pdo->prepare("INSERT INTO contenucommande (valeur, produit, commande) VALUES (?,?,?)");
                $stmt->execute([$value, $key, $id]);
            }
        }
        $stmt = $pdo->prepare("UPDATE commande set prixtotal = ? , statut = ? where id_commande = ?");
        $stmt->execute([$total,self::$PENDING_ORDER,$id]);
        $this->render($response, 'pages/order_form.twig',['id'=>$id]);
        $this->afficher_message('Votre commande à été prise en compte');
        return $this->redirect($response,'home');
    }

    public function accept(RequestInterface $request, ResponseInterface $response,$args) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("SELECT datereponse FROM commande where id_commande = ?;");
        $stmt->execute([$args['id']]);
        $datereponse = $stmt->fetch();

        $stmt = $pdo->prepare("SELECT delairefuscommande FROM parametre");
        $stmt->execute();
        $delais = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $delais = $delais[0]['delairefuscommande'];
        $datereponse = strtotime($datereponse['datereponse']);
        $now = strtotime(date('Y-m-d H:i:s'));

        if ($now - $datereponse > intval($delais)) {
            $this->afficher_message('Vous avez dépassé le délais nécessaire à la validation de votre commande, elle a été annulée', 'echec');
            $stmt = $pdo->prepare("UPDATE commande set statut = ? where id_commande = ?;");
            $stmt->execute([self::$CANCELED_ORDER,$args['id']]);
        } else {
            $this->afficher_message('Votre commande à été validée vous pourrez aller la chercher Jeudi');
            $stmt = $pdo->prepare("UPDATE commande set statut = ? where id_commande = ?;");
            $stmt->execute([self::$VALIDATED_ORDER,$args['id']]);
        }
        return $this->redirect($response,'user_home');
    }

}