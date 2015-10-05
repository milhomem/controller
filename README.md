README
======

O que é o Controller?
---------------------

Sistema para administrar seus clientes de hospedagem de sites e cobrança
automática e recorrente. Feito em Perl em 2005 e mantido até 2014, não tinhamos
o Clean Code publicado então perdoem a legibilidade :]

É parecido com quem?
--------------------

- [WHMCS][3] Excelente e em Inglês, mas é dificil integrar com a cobrança no Brasil 
- [HOSTMGR][4] Nunca usei, mas parece ser legal porém com menos recursos e menos flexível
- [SOFT4YOU][5] Desculpa, nem se compara (:
- [GERENTEPRO][6] Nunca usei, mas parece ter bem menos recursos
- [BQHOSTCONTROL][7] Bem pareceido, porém com menos integrações ex: O registro de domínios é manual

Para que serve?
---------------

Serve para muitas coisas, vou listar as principais features e você pode usar 
sua imaginação para usar de várias formas.

- Helpdesk com leitor de email, converte emails em chamados e suas respectivas respostas.
- Cria/Modifica/Bloqueia/Remove contas através de painéis de controle como WHM/cPanel, 
Helm, Enkompass e outros.
- Gera cobranças automaticamente com personalização total de períodos.
- Cobranças podem ser pagas automaticamente com integração com gateways de pagamento como
Cielo, PagSeguro, Amex, PayPal, MercadoPago e outros.
- Cobranças podem ser cobradas através da geração de boletos já integrado com diversos 
bancos brasileiros, como Banco do Brasil, Santander, Itaú, CEF e outros.
- Importação de arquivos de retorno dos bancos no padrão CNAB 400 e 200.
- Registro automático de domínios integrado com Registro.BR e OpenSRS.
- Área de clientes para consulta de faturas, impressão de boletos, contratação self-service
de serviços totalmente automática, passe a criar recursos 24h por dia.
- Avisos de cobrança, bloqueios através de email e sms (necessário um gateway).
- Auto-signup script para integrar com formulários no seu site. 
- Totalmente personalizável.

Com o que foi feito?
--------------------

Backend em [Perl][8] assim como [DuckDuckGo e Booking.com][11]

Interface admin em [XUL][9] assim como o [Firefox][10].

O que precisa para funcionar?
-----------------------------

#####Backend
- Http Server Apache com suporte a .htaccess
- MySQL Database
- Perl v5.8+
- Cpan
- Módulos Perl

```bash
curl -L http://cpanmin.us | perl - App::cpanminus
cpanm --notest --installdeps backend/
```

#####Interface Admin
- Basta fazer o [download][2] e instalar.

> Suporte a Windows, Linux e MacOS

#####Interface web para Clientes
- Idem Backend.

Instalação
------------

#####Usando [Docker][13] para backend e interface de clientes

Substituir o `http://localhost:8080` pelo endereço de dns público acessível ao seu docker e execute:

```bash
cd backend/
BASE_URL=http://localhost:8080 docker-compose up
```

> Se preferir trocar as portas expostas edite o arquivo `backend/docker-compose.yml`

Recomendo a configuração com SSL para garantir a segurança dos seus dados:
- Crie o arquivo `backend/docker/server.key` com o conteúdo de sua chave privada
- Crie o arquivo `backend/docker/server.crt` com o conteúdo de seu certificado
- Se necessário troque o conteúdo do CA Bundle em `backend/docker/ca-bundle.crt`
- Execute o comando acima trocando o protocolo `http` por `https`

Documentação
-------------

Uma documentação parcial está disponível [aqui][1]


Contribua
---------

Controller agora é um projeto open source e meu desejo é que seja mantido pela comunidade. 

Se você quiser contribuir mande um Pull Request ou solicite acesso para ajudar a manter o projeto.

Se tiver problemas e não souber solucionar abre uma issue.

Se mesmo assim continuar com problemas e precisar de um suporte mande um email para
milhomem at [is4web.com][12]

[1]: http://www.is4web.com.br/manual/pt-br/controller/1.0/complete
[2]: http://is4web.com.br/demonstracao
[3]: http://www.whmcs.com/
[4]: http://www.hostmgr.com.br/
[5]: http://www.soft4you.com.br/
[6]: http://www.gerentepro.com.br/
[7]: http://www.bqhost.com.br/bqhostcontrol-gerenciador-financeiro/
[8]: https://www.perl.org/get.html
[9]: https://developer.mozilla.org/en-US/docs/The_Joy_of_XUL
[10]: https://www.mozilla.org/en-US/firefox/new/
[11]: http://www.builtinperl.com/
[12]: http://is4web.com.br/
[13]: https://docs.docker.com/installation/