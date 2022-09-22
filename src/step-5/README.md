# Etapa 5

## Validação da Alteração dos Pedidos de Vendas

### Requisitos:

* Criar campo no cabeçalho dos pedidos de vendas (SC5) para identificar que um pedido foi criado a partir de um XML
* Criar parâmetro para informar os códigos de usuários autorizados a alterar pedidos gerados a partir de um XML
* Criar ponto de entrada para não permitir a alteração ou exclusão desses pedidos caso o usuário não esteja definido no parâmetro

### Dicas

* Utilizar a função RetCodUsr() para obter o código do usuário logado