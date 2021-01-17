<?php


namespace M1_CSI_Appli_AMAP\Controller;


use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class SubscriptionController extends Controller
{
    public function subscription_form(RequestInterface $request, ResponseInterface $response) {
        $pdo =$this->get_PDO();
        $date = date('Y-m-d H:i:s');
        $stmt = $pdo->prepare("SELECT tarifabo, id_trimestre from trimestre where datedebut < ? and datefin > ?");
        $stmt->execute([$date,$date]);
        $current_trimestre = $stmt->fetch();

        $stmt = $pdo->prepare("SELECT tarifabo, id_trimestre from trimestre where id_trimestre = ?");
        $stmt->execute([intval($current_trimestre['id_trimestre'])+1]);
        $next_trimestre = $stmt->fetch();

        $this->render($response, 'pages/subscription_form.twig',['current_trimestre'=>$current_trimestre,'next_trimestre'=>$next_trimestre]);
    }

    public function new(RequestInterface $request, ResponseInterface $response) {
        $pdo =$this->get_PDO();
        $stmt = $pdo->prepare("INSERT INTO abonnement (datedemandeabo, etat, utilisateur, trimestre) VALUES (?,?,?,?)");
        $params = $request->getParams();
        $user = $_SESSION['user_id'];
        $resultat = $stmt->execute([date('Y-m-d H:i:s'),'En cours', $user, $params['sub-start']]);
        if ($resultat) {
            $this->afficher_message('Votre demande d\'abonnement a été prise en compte');
        }else{
            $this->afficher_message('Erreur : Votre demande d\'abonnement n\'a été prise en compte ', 'echec');
        }
        return $this->redirect($response,'home');
    }
}