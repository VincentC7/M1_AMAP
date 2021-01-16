<?php


namespace M1_CSI_Appli_AMAP\Controller;

use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class BasketController extends Controller
{
    public function index(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("SELECT id_panier,numsemaine,date_part('year',t.datedebut) as year FROM panier inner join trimestre t on panier.trimestre = t.id_trimestre order by id_panier desc ;");
        $stmt->execute();
        $baskets = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/basket.twig', ['baskets' => $baskets]);
    }

    public function basket_form(RequestInterface $request, ResponseInterface $response, $args) {
        $pdo = $this->get_PDO();
        if (isset($args["id"])) {
            $stmt = $pdo->prepare("SELECT * FROM panier WHERE id_panier = ?;");
            $stmt->execute([$args["id"]]);
            $basket = $stmt->fetch();
            $this->render($response, 'pages/basket_form.twig', ['basket' => $basket]);
            return;
        }
        $week_number = date('W');
        $year = date('Y');

        $stmt = $pdo->prepare("select * from panier inner join trimestre t on panier.trimestre = t.id_trimestre WHERE numsemaine = ? and datedebut BETWEEN ? and ?;");
        $stmt->execute([intval($week_number),$year.'-01-01',$year.'-12-31']);
        $basket = $stmt->fetch();
        $products = [];
        if (isset($basket['id_panier'])){ //basket exist
            $stmt = $pdo->prepare("SELECT id_produit,c.valeur,nomproduit,unite FROM compose as c inner join produit p on c.produit = p.id_produit where panier = ?");
            $stmt->execute([$basket["id_panier"]]);
            $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        } else {
            $stmt = $pdo->prepare("INSERT INTO panier (numsemaine,trimestre) VALUES (?,?)");
            $stmt = $pdo->prepare("INSERT INTO panier (numsemaine,trimestre) VALUES (?,?)");
            $stmt->execute([$week_number,6]);
        }
        $stmt = $pdo->prepare("Select * from produit where visible = true and valeur > 0 and id_produit not in (select produit from compose where panier = ?)");
        $stmt->execute([$basket["id_panier"]]);
        $all_products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/basket_form.twig',['week_number'=>$week_number,'year'=>$year,'basket'=>$basket,'products'=>$products,'all_products'=>$all_products]);
    }

    public function add(RequestInterface $request, ResponseInterface $response, $args) {
        $id_basket = $args["id"];
        $pdo = $this->get_PDO();
        $subscribers_count = 20;

        $params = $request->getParams();

        $product_id = filter_var($params['basket-product'],FILTER_SANITIZE_STRING);
        $product_qte = filter_var($params['basket-product-qte'],FILTER_SANITIZE_STRING);

        $stmt = $pdo->prepare("SELECT valeur FROM produit where id_produit = ?");
        $stmt->execute([$product_id]);
        $product = $stmt->fetch();
        if ($product['valeur'] < $product_qte * $subscribers_count){
            $this->afficher_message('Erreur : Il n\'y à pas assez de stock pour faire tous les paniers', 'echec');
            return $this->redirect($response,'edit_basket');
        }

        $stmt = $pdo->prepare("INSERT INTO compose (valeur, produit, panier) VALUES (?,?,?);");

        $resultat = $stmt->execute([$product_qte,$product_id,$id_basket]);
        if ($resultat) {
            $this->afficher_message('Le produit a été ajouté au panier avec succes');
        }else{
            $this->afficher_message('Erreur : Le produit n\'a pas été ajouté au panier ', 'echec');
        }
        return $this->redirect($response,'edit_basket');
    }

    public function remove(RequestInterface $request, ResponseInterface $response, $args) {
        $id_basket = $args['id'];
        $id_product = $args['id_product'];
        $pdo = $this->get_PDO();

        $stmt = $pdo->prepare("DELETE FROM compose where produit = ? and panier = ?;");
        $resultat = $stmt->execute([$id_product,$id_basket]);
        if ($resultat) {
            $this->afficher_message('Le produit a été supprimé du panier avec succes');
        }else{
            $this->afficher_message('Erreur : Le produit n\'a pas été supprimé du panier ', 'echec');
        }
        return $this->redirect($response,'edit_basket');
    }

    public function view(RequestInterface $request, ResponseInterface $response, $args){
        $id_basket = $args["id"];
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("SELECT numsemaine,to_char( datedebut, 'YYYY') as year from panier as p inner join trimestre as t on p.trimestre = t.id_trimestre where id_panier = ?");
        $stmt->execute([$id_basket]);
        $basket = $stmt->fetch();

        $stmt = $pdo->prepare("SELECT c.valeur,nomproduit,unite FROM compose as c inner join produit p on c.produit = p.id_produit where panier = ?");
        $stmt->execute([$id_basket]);
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/basket_vew.twig', ['products' => $products, 'week_number'=>$basket['numsemaine'],'year'=>$basket['year']]);
    }

    public function clear(RequestInterface $request, ResponseInterface $response, $args){
        $id_basket = $args["id"];
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("DELETE FROM compose where panier = ?;");
        $resultat = $stmt->execute([$id_basket]);
        if ($resultat) {
            $this->afficher_message('Le panier à bien été vidé');
        }else{
            $this->afficher_message('Erreur : Un problème est survenue lors de la suppression des produits du panier', 'echec');
        }
        return $this->redirect($response,'basket');
    }

    public function cancel(RequestInterface $request, ResponseInterface $response, $args) {

    }
}