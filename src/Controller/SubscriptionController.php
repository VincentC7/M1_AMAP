<?php


namespace M1_CSI_Appli_AMAP\Controller;


use PDO;
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

    public function index(RequestInterface $request, ResponseInterface $response) {
        $pdo =$this->get_PDO();
        $stmt = $pdo->prepare("SELECT nom,prenom, id_abonnement
                                            from abonnement inner join trimestre on abonnement.trimestre = trimestre.id_trimestre 
                                                inner join utilisateur u on abonnement.utilisateur = u.id_utilisateur 
                                        where abonnement.etat = 'Sur liste d’attente' and datedebut < ? and datefin > ? order by rang");
        $date = date('Y-m-d H:i:s');
        $stmt->execute([$date,$date]);
        $queue = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->render($response, 'pages/queue.twig',['queue'=>$queue]);
    }

    public function change_rank(RequestInterface $request, ResponseInterface $response,$args){
        $pdo =$this->get_PDO();
        $stmt = $pdo->prepare("SELECT min(rang) as rank from abonnement");
        $stmt->execute();
        $min_rank = $stmt->fetch();

        $stmt = $pdo->prepare("UPDATE abonnement set rang = ? where id_abonnement = ?");
        $resultat = $stmt->execute([$min_rank['rank'] -1 , $args['id']]);

        if ($resultat) {
            $this->afficher_message('Le rang de l\'utilisateur a bien été mis à jour');
        }else{
            $this->afficher_message('Erreur : Le rang de l\'utilisateur n\'a pas été mis à jour', 'echec');
        }
        return $this->redirect($response,'queue');
    }
}