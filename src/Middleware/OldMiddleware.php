<?php

namespace M1_CSI_Appli_AMAP\Middleware;



use Slim\Http\Response;
use Slim\Http\Request;
use Twig\Environment;

class OldMiddleware {
    private $twig;

    /**
     * ErreurMiddleware constructor.
     * @param $twig
     */
    public function __construct(Environment $twig) {
        $this->twig = $twig;
    }

    public function __invoke(Request $request, Response $response, $fonction) {
        $this->twig->addGlobal('old',isset($_SESSION['old']) ? $_SESSION['old'] : []);
        if (isset($_SESSION['old'])){
            unset($_SESSION['old']);
        }

        $response = $fonction($request,$response);
        if ($response->getStatusCode() != 200){
            $_SESSION['old'] = $request->getParams();
        }
        return $response;
    }
}