<?php


namespace M1_CSI_Appli_AMAP\Controller;

use PDO;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class SettingsController extends Controller {

    public function index(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $stmt = $pdo->prepare("select nbabonnementmax,default_tarif_abo,delairefuscommande from parametre");
        $stmt->execute();
        $params = $stmt->fetch();
        $this->render($response, 'pages/settings.twig',['params'=>$params]);
    }

    public function update(RequestInterface $request, ResponseInterface $response) {
        $pdo = $this->get_PDO();
        $params = $request->getParams();
        $stmt = $pdo->prepare("update parametre set nbabonnementmax = ?, delairefuscommande = ?, default_tarif_abo=?");
        $result = $stmt->execute([$params['param_nb_sub'],$params['param_rejection_deadlines'],$params['param_sub_cost']]);
        if ($result) {
            $this->afficher_message('Les paramètres de l\'application ont bien été modifié');
        } else {
            $this->afficher_message('Erreur : les paramètres n\'ont pas été modifié', 'echec');
        }
        return $this->redirect($response,'settings');
    }
}