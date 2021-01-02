<?php


namespace M1_CSI_Appli_AMAP\Controller;


use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class StockController extends Controller {

    public function index(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("SELECT * FROM produit;");
        $stmt->execute();
        $products =  $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/stock.twig',['products'=>$products]);
    }

    public function product_form(RequestInterface $request, ResponseInterface $response,$args) {
        if (isset($args["id"])){
            $pdo = $this->get_PDO();
            $stmt = $pdo->prepare("SELECT * FROM produit WHERE id_produit = ?;");
            $stmt->execute([$args["id"]]);
            $product =  $stmt->fetch();
            $this->render($response, 'pages/product_form.twig',['product'=>$product]);
            return;
        }
        $this->render($response, 'pages/product_form.twig');
    }

    public function new(RequestInterface $request, ResponseInterface $response) {
        //Récupération de l'acces base
        $pdo = $this->get_PDO();

        //Verification des champs
        $params = $request->getParams();

        $stmt = $pdo->prepare("INSERT INTO produit (nomproduit, unite, valeur, prixunitaire) VALUES (?,?,?,?);");

        $product_name = filter_var($params['product-name'],FILTER_SANITIZE_STRING);
        $product_qte = filter_var($params['product-qte'],FILTER_SANITIZE_STRING);
        $product_unity = filter_var($params['product-unity'],FILTER_SANITIZE_STRING);
        $product_price = filter_var($params['product-price'],FILTER_SANITIZE_STRING);

        $resultat = $stmt->execute([$product_name,$product_unity,floatval($product_qte),floatval($product_price)]);
        if ($resultat) {
            $this->afficher_message('Le produit a été enregistré avec succes ');
        }else{
            $this->afficher_message('Erreur : Le produit n\'a pas été enregistré ', 'echec');
        }
        return $this->redirect($response,'stock');
    }

    public function update(RequestInterface $request, ResponseInterface $response,$args) {
        $pdo = $this->get_PDO();
        $id = $args["id"];

        //Verification des champs
        $params = $request->getParams();

        $stmt = $pdo->prepare("update produit set nomproduit = ?, unite = ?, valeur = ?, prixunitaire = ? where id_produit = ?;");

        $product_name = filter_var($params['product-name'],FILTER_SANITIZE_STRING);
        $product_qte = filter_var($params['product-qte'],FILTER_SANITIZE_STRING);
        $product_unity = filter_var($params['product-unity'],FILTER_SANITIZE_STRING);
        $product_price = filter_var($params['product-price'],FILTER_SANITIZE_STRING);

        $resultat = $stmt->execute([$product_name,$product_unity,floatval($product_qte),floatval($product_price),$id]);
        if ($resultat) {
            $this->afficher_message('Le produit a été modifié avec succes ');
        }else{
            $this->afficher_message('Erreur : Le produit n\'a pas été modifié ', 'echec');
        }
        return $this->redirect($response,'stock');
    }

    public function delete(RequestInterface $request, ResponseInterface $response,$args) {
        $pdo = $this->get_PDO();
        $id = $args["id"];

        $stmt = $pdo->prepare("update produit set visible = false where id_produit = ?;");
        $resultat = $stmt->execute([$id]);
        if ($resultat) {
            $this->afficher_message('Le produit a été supprimé avec succes');
        }else{
            $this->afficher_message('Erreur : Le produit n\'a pas été supprimé ', 'echec');
        }
        return $this->redirect($response,'stock');
    }
}