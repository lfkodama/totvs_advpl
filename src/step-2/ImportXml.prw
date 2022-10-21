#include "totvs.ch"

/*/{Protheus.doc} ImportXml

Importação do XML de Notas Fiscais de Saida
	
@author soulsys:fernandokodama
@since 10/10/2022
/*/

user function ImportXml()

  local oParamBox := paramBox()

  if oParamBox:show()
    importFiles(oParamBox)
  endIf 

return

/**
 * Cria a tela de interface com o usuário
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("importXml")

  oParam := LibParamObj():newLibParamObj("folder", "file", "Diretório", "C", 80, 1000)
  oParam:setFileTypes("Arquivos XML |*.xml")
  oParam:setFileParams(GETF_LOCALHARD + GETF_NETWORKDRIVE + GETF_MULTISELECT)
  oParam:setRequired(.T.)
  oParamBox:addParam(oParam)

return oParamBox

/**
 * Pega os arquivos selecionados na Parambox e prepara a leitura
 */
static function importFiles(oParamBox)

  local nI        := 0
  local nCount    := 0
  local cFile     := ""
  local cFiles    := oParamBox:getValue("folder")
  local aXmlFiles := StrTokArr(cFiles, "|")  
    
  for nI := 1 to Len(aXmlFiles)
    cFile := AllTrim(aXmlFiles[nI])
    if readFile(cFile)
      nCount++
    endIf
  next nI

  if nCount == Len(aXmlFiles)
    MsgAlert(AllTrim(str(nCount)) + " notas Fiscais importadas com sucesso.", "Importação de XML")  
  else
    MsgAlert("Ocorreram erros na importação dos arquivos. Importados " + AllTrim(str(nCount)) + " de " + str(Len(aXmlFiles)) + " arquivos.")  
  endIf 

return

/**
 * Faz a leitura do arquivo XML e cria o Json
 */
static function readFile(cFile)

  local nI        := 0
  local aItems    := {}
  local aXmlItems := {}
  local oXmlItem  := nil 
  local oItem     := nil 
  local oNfe      := JsonObject():new()
  local oXml      := LibXmlObj():newLibXmlObj(cFile)

  if !oXml:parse()
    MsgAlert("Falha ao realizar parser do XML:" + CRLF + oXml:getError())
    return .F.
  endIf

  oNfe["number"]       := oXml:text("notafiscal:numero")
  oNfe["serie"]        := oXml:text("notafiscal:serie")
  oNfe["date"]         := oXml:text("notafiscal:emissao")
  oNfe["customerCgc"]  := oXml:text("notafiscal:cliente:cgc")
  oNfe["customerName"] := oXml:text("notafiscal:cliente:razaoSocial")
  oNfe["city"]         := oXml:text("notafiscal:cliente:municipio")
  oNfe["state"]        := oXml:text("notafiscal:cliente:uf")
  
  aXmlItems := oXml:list("notafiscal:items:item")
  
  for nI := 1 to Len(aXmlItems)

    oXmlItem := aXmlItems[nI]
    oItem    := JsonObject():new()

    oItem["item"]        := nI 
    oItem["productCode"] := oXmlItem:text("codigo")
    oItem["description"] := oXmlItem:text("descricao")
    oItem["quantity"]    := oXmlItem:text("quantidade")
    oItem["price"]       := oXmlItem:text("preco")
    oItem["total"]       := oXmlItem:text("total")
    oItem["cfop"]        := oXmlItem:text("cfop")

    aAdd(aItems, oItem)

  next nI

  oNfe["items"] := aItems

return saveDatatoDb(oNfe)

/**
 * Grava as informações nas tabelas customizadas do banco de dados
 */
static function saveDatatoDb(oNfe)

  local nI      := 0
  local aData   := {}
  local aItems  := oNfe["items"]
  local oItem   := nil
  local oSql    := LibSqlObj():newLibSqlObj()
  
  SA1->(DbSetOrder(3))
  
  if !SA1->(dbSeek(xFilial("SA1") + AllTrim(oNfe["customerCgc"])))
    MsgAlert("Cliente não cadastrado.", "Importação de XML")
    return .F.
  endIf

  if oSql:exists("SZ1", "%SZ1.XFILIAL% AND Z1_DOC = '" + AllTrim(oNfe["number"]) + "' AND Z1_SERIE = '" + AllTrim(oNfe["serie"]) + "'")
    MsgAlert("Nota fiscal já foi importada. Número: " + oNfe["number"] + ", série: " + oNfe["serie"], "Importação de XML")
    return .F.
  endIf

  aAdd(aData, {"Z1_FILIAL", xFilial("SZ1")})               // Filial 
  aAdd(aData, {"Z1_DOC", oNfe["number"]})                  // Número da NF
  aAdd(aData, {"Z1_SERIE", oNfe["serie"]})                 // Série da NF
  aAdd(aData, {"Z1_LOJA", SA1->A1_LOJA})                   // Loja
  aAdd(aData, {"Z1_CLIENTE", SA1->A1_COD})                 // CNPJ/CPF do Cliente da NF
  aAdd(aData, {"Z1_NOMECL", SA1->A1_NOME})                 // Nome do Cliente da NF
  aAdd(aData, {"Z1_EMISSAO", CtoD(oNfe["date"])})          // Data de emissão da NF

  oSql:insert("SZ1", aData)
  
  for nI := 1 to Len(aItems)

    aData := {}
    oItem := aItems[nI]    

    aAdd(aData, {"Z2_FILIAL", xFilial("SZ2")})               
    aAdd(aData, {"Z2_DOC", oNfe["number"]})
    aAdd(aData, {"Z2_SERIE", oNfe["serie"]})
    aAdd(aData, {"Z2_ITEM", AllTrim(Str(nI))})
    aAdd(aData, {"Z2_COD", oItem["productCode"]})
    aAdd(aData, {"Z2_QUANT", Val(oItem["quantity"])})
    aAdd(aData, {"Z2_PRCVEN", Val(oItem["price"])})
    aAdd(aData, {"Z2_TOTAL", Val(oItem["total"])})
    aAdd(aData, {"Z2_CFOP", oItem["cfop"]})  

    oSql:insert("SZ2", aData)
  
  next nI  

return .T.     
