# Etapa 7

## Web Service para consulta de Notas Fiscais importadas

### Requisitos:

* API REST ADVPL
* Receber como parâmetro o número e série de um documento
* Retornar um JSON contendo dados do documento solicitado

### Layout do JSON:

```json
{
  "notafiscal": "000123456",
  "serie": "1",
  "emissao": "2022-09-22",
  "cliente": {
    "codigo": "000123",
    "loja": "01",
    "razaoSocial": "RAZAO SOCIAL DO CLIENTE LTDA",
    "municipio": "AMERICANA",
    "uf": "SP"
  },
  "items": [
    {
      "codigo": "P00001",
      "descricao": "PRODUTO TESTE 1",
      "quantidade": 10,
      "preco": 1234.56,
      "total": 12345.6,
      "cfop": "5102"
    },
    {
      "codigo": "P00002",
      "descricao": "PRODUTO TESTE 2",
      "quantidade": 20,
      "preco": 600,
      "total": 12000,
      "cfop": "5102"
    }
  ]
}
```

### Dicas

* Utilizar o padrão wsRestful e a classe JsonObject()