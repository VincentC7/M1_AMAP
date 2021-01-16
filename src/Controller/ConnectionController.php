<?php


namespace M1_CSI_Appli_AMAP\Controller;


use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;
use Respect\Validation\Validator;

class ConnectionController extends Controller {

    public function index(RequestInterface $request, ResponseInterface $response){
        $this->render($response,'pages/connection.twig');
    }

    public function sign_in(RequestInterface $request, ResponseInterface $response){
        //Récupération de l'acces base
        $pdo = $this->get_PDO();
        //Verification des champs
        $params = $request->getParams();
        $erreurs = [];

        //Verification de l'existance de l'utilisateur
        $stmt = $pdo->prepare("SELECT identifiant,motdepasse,role,id_utilisateur FROM utilisateur WHERE identifiant = ? ");
        $stmt->execute([$params['email']]);
        $user = $stmt->fetch();

        if (!isset($user['identifiant']) || $user['motdepasse'] != $params["password"]){
            $this->afficher_message('Identifiant ou mot de passe incorrect', 'echec');
            return $this->redirect($response,'sign_in_page');
        }
        $_SESSION['role'] = $user['role'];
        $_SESSION['user_id'] = $user['id_utilisateur'];
        return $this->redirect($response,'home');
    }

    public function sign_out(RequestInterface $request, ResponseInterface $response){
        $_SESSION['role'] = "Visiteur";
        $_SESSION['user_id'] =  -1;
        return $this->redirect($response,'home');
    }

    public function sign_up(RequestInterface $request, ResponseInterface $response){
        //Récupération de l'acces base
        $pdo = $this->get_PDO();

        //Verification des champs
        $params = $request->getParams();
        $erreurs = [];

        //Vérification du num tel => bon format
        (Validator::length(10,10)->validate($params['tel']) && is_numeric($params['tel'])) || $erreurs['tel'] = "Format incorrect";

        //Verification de l'existance de l'utilisateu
        if (!isset($erreurs['email'])){
            $stmt = $pdo->prepare("SELECT identifiant FROM utilisateur WHERE identifiant = ? ");
            $stmt->execute([$params['email']]);
            if (isset($stmt->fetch()['identifiant'])){
                $this->afficher_message("Cet identifiant existe déjà", 'echec');
                return $this->redirect($response,'sign_in_page');
            }
        }

        //Affichage des erreurs s'il y en a
        if (!empty($erreurs)){
            $this->afficher_message('Certains champs n\'ont pas été rempli correctement','echec');
            $this->afficher_message($erreurs,'erreurs');
            return $this->redirect($response,'sign_in_page');
        }

        $stmt = $pdo->prepare("INSERT INTO Utilisateur (nom, prenom, tel, identifiant, motdepasse, role) VALUES (?,?,?,?,?,?)");

        $email = filter_var($params['email'],FILTER_SANITIZE_STRING);
        $nom = filter_var($params['name'],FILTER_SANITIZE_STRING);
        $prenom = filter_var($params['surname'],FILTER_SANITIZE_STRING);
        $tel = filter_var($params['tel'],FILTER_SANITIZE_STRING);
        $password = filter_var($params['password'],FILTER_SANITIZE_STRING);

        $resultat = $stmt->execute([$nom,$prenom,$tel,$email,$password,'Non abonné']);
        if ($resultat) {
            $this->afficher_message('Votre inscription est validée');
        }else{
            $this->afficher_message('Erreur : Echec de l\'inscription ', 'echec');
        }
        return $this->redirect($response,'sign_in_page');
    }
}