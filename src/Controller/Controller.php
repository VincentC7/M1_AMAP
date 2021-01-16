<?php


namespace M1_CSI_Appli_AMAP\Controller;

use PDO;
use PDOException;
use Psr\Http\Message\ResponseInterface;


class Controller {

    protected $user_id;
    protected $user_role = "postgres";
    protected $container;
    protected $pdo;

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
        $args['user_role'] = $this->user_role;
        $this->container->view->render($response,$file, $args);
    }

    public function redirect(ResponseInterface $response, $nom,$args =[]){
        return $response->withStatus(302)->withHeader('Location', $this->container->router->pathFor($nom, $args));
    }

    public function afficher_message($message, $type = 'valide'){
        if (!isset($_SESSION['message'])) {
            $_SESSION['message'] = [];
        }
        $_SESSION['message'][$type] = $message;
    }

    public function get_PDO() : PDO {
        if(!isset($this->pdo)){
            self::change_db_connection();
        }
        return $this->pdo;
    }

    private function change_db_connection(){
        $db_info = parse_ini_file( '../conf/conf.ini', true);
        try{
            $user = $db_info[$this->user_role]['username'];
            $password = $db_info[$this->user_role]['password'];
            $this->pdo = new PDO($db_info['driver'].":host=" . $db_info['host'] . ";dbname=" . $db_info['database'] ,$user,$password);
        }catch (PDOException $e){
            print_r($db_info);
            echo "La connection a la base de données à echoué";
        }
    }

    public function isConnected(){
        return $this->user_role == "Visiteur";
    }

    public function login($user_id,$role){
        $this->user_id = $user_id;
        $this->user_role = $role;
        self::change_db_connection();
    }

    public function logout(){
        $this->user_id = -1;
        $this->user_role = "Visiteur";
        self::change_db_connection();
    }

}