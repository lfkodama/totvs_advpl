# Etapa 1

## Rotina para Geração de XML de NF de Saída

### Requisitos:

* Tela de parâmetros solicitando intervalo de datas de emissão (De/Até)
* Diretório para geração do arquivo
* O nome do arquivo de ser definido automaticamente: nfs_20220901_20220930.xml

### Layout do XML:

```xml
<notafiscal>
  <numero>000123456</numero>
  <serie>1</serie>
  <emissao>22/09/2022</emissao>
  <cliente>
    <cgc>27400291000192</cgc>
    <razaoSocial>RAZAO SOCIAL DO CLIENTE LTDA</razaoSocial>
    <municipio>AMERICANA</municipio>
    <uf>SP</uf>
  </cliente>
  <items>
    <item>
      <codigo>P00001</codigo>
      <descricao>PRODUTO TESTE 1</descricao>
      <quantidade>10</quantidade>
      <preco>123.45</preco>
      <total>1234.5</total>
      <cfop>5102</cfop>
    </item>
    <item>
      <codigo>P00002</codigo>
      <descricao>PRODUTO TESTE 2</descricao>
      <quantidade>20</quantidade>
      <preco>600</preco>
      <total>12000</total>
      <cfop>5102</cfop>
    </item>
  </items>
</notafiscal>
```

### Dicas:

* Tabela SF2 - Cabeçalho NF Saída
* Tabela SD2 - Itens NF Saída
* Gravar o arquivo texto através da função Fwrite
* Quebras de linhas através da constante CRLF
