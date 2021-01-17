<?php

use M1_CSI_Appli_AMAP\Controller\BasketController;
use M1_CSI_Appli_AMAP\Controller\ConnectionController;
use M1_CSI_Appli_AMAP\Controller\HomeController;
use M1_CSI_Appli_AMAP\Controller\OrderController;
use M1_CSI_Appli_AMAP\Controller\SettingsController;
use M1_CSI_Appli_AMAP\Controller\StockController;
use M1_CSI_Appli_AMAP\Controller\SubscriptionController;
use M1_CSI_Appli_AMAP\Controller\UserController;
use M1_CSI_Appli_AMAP\Middleware\ErreurMiddleware;
use M1_CSI_Appli_AMAP\Middleware\OldMiddleware;
use Slim\App;

require __DIR__ . '/../vendor/autoload.php';
date_default_timezone_set('Europe/Paris');

session_start();
$app = new App([
    'settings' => [
        'displayErrorDetails' => true
    ]
]);

require(__DIR__ . '/../src/dependances.php');


$container = $app->getContainer();
if (!isset($_SESSION['role'])){
    $_SESSION['role'] = "Visiteur";
}

if (!isset($_SESSION['user_id'])){
    $_SESSION['user_id'] = -1;
}

// ==================== middleware ====================
$app->add(new ErreurMiddleware($container->get('view')->getEnvironment()));
$app->add(new OldMiddleware($container->get('view')->getEnvironment()));


// ==================== routes ====================
//page de d'acceuil
$app->get('/', HomeController::class.":index")->setName("home");

//Connection et inscription
$app->get('/Connexion', ConnectionController::class.":index")->setName("sign_in_page");
$app->post('/Connexion', ConnectionController::class.":sign_in")->setName("sign_in");
$app->post('/Inscription', ConnectionController::class.":sign_up")->setName("sign_up");
$app->get('/Deconnection', ConnectionController::class.":sign_out")->setName("sign_out");

//Stock
$app->get('/Stock', StockController::class.":index")->setName("stock");
$app->get('/Stock/Nouveau', StockController::class.":product_form")->setName("new_product");
$app->post('/Stock/Nouveau', StockController::class.":new")->setName("new_product_save");
$app->get('/Stock/{id}/Edit', StockController::class.":product_form")->setName("edit_product");
$app->post('/Stock/{id}/Edit', StockController::class.":update")->setName("edit_product_save");
$app->get('/Stock/{id}/Supprimer', StockController::class.":delete")->setName("delete_product");

//Paniers
$app->get('/Panier', BasketController::class.":index")->setName("basket");
$app->get('/Panier/Nouveau', BasketController::class.":basket_form")->setName("edit_basket");
$app->post('/Panier/{id}/AjouterProduit', BasketController::class.":add")->setName("add_product_to_basket");
$app->get('/Panier/{id}/SupprimerPorduit/{id_product}', BasketController::class.":remove")->setName("remove_product_from_basket");
$app->get('/Panier/{id}', BasketController::class.":view")->setName("vew_basket");
$app->post('/Panier/{id}/Vider', BasketController::class.":clear")->setName("clear_basket");
$app->get('/Panier/{id}/Cancel', BasketController::class.":cancel")->setName("cancel_basket");

//Commandes occassionnelles
$app->get('/CommandeOccassionnelle', OrderController::class.":order_form")->setName("new_order");
$app->post('/CommandeOccassionnelle', OrderController::class.":order_save")->setName("new_order_save");
$app->post('/CommandeOccassionnelle/{id}/Accept', OrderController::class.":accept")->setName("accept_order");

//User home
$app->get('/MonCompte/Gestion', UserController::class.":index")->setName("user_home");

//Sub
$app->get('/Abonnement/Nouveau', SubscriptionController::class.":subscription_form")->setName("subscription_form");
$app->post('/Abonnement/Nouveau', SubscriptionController::class.":new")->setName("subscribe");
$app->post('/Abonnement/Cancel', SubscriptionController::class.":cancel_sub")->setName("cancel_sub");
//Queue
$app->get('/FileAttente', SubscriptionController::class.":index")->setName("queue");
$app->get('/FileAttente/{id}', SubscriptionController::class.":change_rank")->setName("queue_maj");


//Settings
$app->get('/Application/Parametres', SettingsController::class.":index")->setName("settings");
$app->post('/Application/Parametres', SettingsController::class.":update")->setName("settings_save");


$app->run();
