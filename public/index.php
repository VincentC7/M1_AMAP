<?php

use M1_CSI_Appli_AMAP\Controller\BasketController;
use M1_CSI_Appli_AMAP\Controller\ConnectionController;
use M1_CSI_Appli_AMAP\Controller\HomeController;
use M1_CSI_Appli_AMAP\Controller\OrderControle;
use M1_CSI_Appli_AMAP\Controller\StockController;
use M1_CSI_Appli_AMAP\Middleware\ErreurMiddleware;
use M1_CSI_Appli_AMAP\Middleware\OldMiddleware;
use Slim\App;

require __DIR__ . '/../vendor/autoload.php';


session_start();
$app = new App([
    'settings' => [
        'displayErrorDetails' => true
    ]
]);

require(__DIR__ . '/../src/dependances.php');


$container = $app->getContainer();
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
$app->get('/Panier/{id}', BasketController::class.":vew")->setName("vew_basket");
$app->post('/Panier/{id}/Vider', BasketController::class.":clear")->setName("clear_basket");
$app->get('/Panier/{id}/Cancel', BasketController::class.":cancel")->setName("cancel_basket");

//Commandes occassionnelles
$app->get('/CommandeOccassionnelle', OrderControle::class.":new")->setName("new_order");
$app->post('/CommandeOccassionnelle', OrderControle::class.":new")->setName("new_order_save");

$app->run();
