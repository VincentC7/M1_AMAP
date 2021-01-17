<?php


namespace M1_CSI_Appli_AMAP\Controller;

use PDO;
use PDOException;
use Psr\Http\Message\ResponseInterface;


class Controller {

    protected $container;

    /**
     * Controller constructor.
     * @param $container
     */
    public function __construct($container) {
        $this->container = $container;
    }

    /**
     * @param ResponseInterface $response
     * @param $file
     * @param $args
     */
    public function render(ResponseInterface $response, $file, $args = []){
        $args['user_role'] = $_SESSION['role'];
        $args['user_id'] = $_SESSION['user_id'];
        $this->container->view->render($response,$file, $args);
    }

    public function redirect(ResponseInterface $response, $nom,$args =[]){
        return $response->withStatus(302)->withHeader('Location', $this->container->router->pathFor($nom, $args));
    }

    public function afficher_message($message, $type = 'valide') {
        if (!isset($_SESSION['message'])) {
            $_SESSION['message'] = [];
        }
        $_SESSION['message'][$type] = $message;
    }

    public function get_PDO() : PDO {
        $db_info = parse_ini_file( '../conf/conf.ini', true);
        try {
            $role = $_SESSION['role'];
            $user = $db_info[$role]['username'];
            $password = $db_info[$role]['password'];
            return new PDO($db_info['driver'].":host=" . $db_info['host'] . ";dbname=" . $db_info['database'] ,$user,$password);
        }catch (PDOException $e){
            echo "La connection a la base de données à echoué";
            return null;
        }
    }
}