#include "totvs.ch"
#include "rwmake.ch"
#include "training.ch"


/*/{Protheus.doc} GerPedMvc

Geração de pedido de vendas a partir da tela MVC de notas fiscais
    
@author fernandokodama
@since 22/10/2022
/*/
user function GerPedMvc()
 
  local oParamBox := paramBox()
  local cLog      := ""
  local oUtils    := LibUtilsObj():newLibUtilsObj()

  if oParamBox:show()
    oUtils:msgRun({ || generateOrders(oParambox, @cLog) }, "Gerando pedido(s) ...", "Geração de Pedidos de Vendas")
  endIf

return


/**
 * Cria a tela de interface com o usuário
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("GerPedXml")

  oParamBox:setTitle("Parâmetros para geração de Pedido de Venda")
  oParamBox:setValidation({|| ApMsgYesNo("Confirma parâmetros ?")})

  oParam := LibParamObj():newLibParamObj("fromNumber", "get", "NF Inicial", "C", 60, Len(SZ1->Z1_DOC))
  oParam:setF3("SZ1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("toNumber", "get", "NF Final", "C", 60, Len(SZ1->Z1_DOC))
  oParam:setF3("SZ1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("optionAll", "checkbox", "Somente pendentes?", "L", 120)  
  oParamBox:addParam(oParam)

  oParamBox:addParam(oParam)

return oParamBox


/**
 * Processa a criacao dos pedidos
 */
static function generateOrders(oParambox, cLog)

  local nI        := 0
  local nCount    := 0
  local aInvoices := getInvoices(oParambox)
  
  if Len(aInvoices) == 0
    MsgAlert("Nenhuma NF encontrada")
    return
  endIf

  for nI := 1 to Len(aInvoices)
    
    If createOrder(aInvoices[nI])
      nCount++
    endIf
    
  next nI

  MsgInfo("Foram gerados " + AllTrim(Str(nCount)) + " pedidos de vendas de um total de " + AllTrim(Str(Len(aInvoices))) + " requisições.")

return


/**
 * Busca os dados do cabeçalho do pedido no banco
 */
static function getInvoices(oParambox)
  
  local cQuery    := ""
  local aInvoices := {}
  local oSql      := LibSqlObj():newLibSqlObj()
  
  cQuery := " SELECT "
  cQuery += "   Z1_FILIAL  [FILIAL], "
  cQuery += "   Z1_DOC     [NUMBER], "
  cQuery += "   Z1_SERIE   [SERIES], "
  cQuery += "   Z1_EMISSAO [DATE], "
  cQuery += "   Z1_STATUS  [STATUS], "
  cQuery += "   A1_COD     [CODE_CUSTOMER],"
  cQuery += "   A1_LOJA    [UNIT_CUSTOMER], "
  cQuery += "   A1_CGC     [CGC], "
  cQuery += "   A1_NOME    [NAME_CUSTOMER], "
  cQuery += "   A1_MUN     [CITY], "
  cQuery += "   A1_EST     [STATE], "
  cQuery += "   A1_COND    [PAYMENT_METHOD] "
  cQuery += " FROM %SZ1.SQLNAME% "
  cQuery += "   INNER JOIN %SA1.SQLNAME% ON "
  cQuery += "     %SA1.XFILIAL% AND A1_COD = Z1_CLIENTE AND A1_LOJA = Z1_LOJA AND %SA1.NOTDEL% "
  cQuery += " WHERE %SZ1.XFILIAL% AND "
  if !oParamBox:getValue("optionAll")
    cQuery += " Z1_DOC BETWEEN '" + oParamBox:getValue("fromNumber") + "' AND '" + oParamBox:getValue("toNumber") + "' AND Z1_STATUS <> '" + XML_NF_STATUS_OK + "' AND "
  else
    cQuery += " Z1_STATUS <> '" + XML_NF_STATUS_OK + "' AND "
  endIf    
  cQuery += "   %SZ1.NOTDEL% "

  oSql:newAlias(cQuery)

  while oSql:notIsEof()
    
    oInvoice                  := JsonObject():new()
    oInvoice["type"]          := "N"  
    oInvoice["customerCode"]  := oSql:getValue("CODE_CUSTOMER")
    oInvoice["customerUnit"]  := oSql:getValue("UNIT_CUSTOMER")
    oInvoice["paymentMethod"] := oSql:getValue("PAYMENT_METHOD")
    oInvoice["number"]        := oSql:getValue("NUMBER")
    oInvoice["series"]        := oSql:getValue("SERIES")
    oInvoice["items"]         := getOrderItems(oInvoice)
    
    aAdd(aInvoices, oInvoice)

    oSql:skip()

  endDo
 
  oSql:close()

return aInvoices


/**
 * Busca os dados dos itens de produtos no banco
 */
static function getOrderItems(oInvoice)
  
  local cQuery  := ""
  local aItems  := {}
  local oSql    := LibSqlObj():newLibSqlObj()
  local cNumber := oInvoice["number"]
  local cSeries := oInvoice["series"]

  cQuery := " SELECT "
  cQuery += "   Z2_ITEM   [ITEM_NO], "
  cQuery += "   Z2_COD    [CODE], "
  cQuery += "   Z2_QUANT  [QUANTITY], "
  cQuery += "   Z2_PRCVEN [PRICE], "
  cQuery += "   Z2_TOTAL  [TOTAL], "
  cQuery += "   Z2_CFOP   [CFOP] "
  cQuery += " FROM %SZ2.SQLNAME% "
  cQuery += "   INNER JOIN %SB1.SQLNAME% ON "
  cQuery += "     %SB1.XFILIAL% AND B1_COD = Z2_COD AND %SB1.NOTDEL% "
  cQuery += " WHERE %SZ2.XFILIAL% AND Z2_DOC = '" + cNumber + "' AND "
  cQuery += "       Z2_SERIE = '" + cSeries + "' AND %SZ2.NOTDEL% "
  cQuery += " ORDER BY Z2_DOC, Z2_ITEM "

  oSql:newAlias(cQuery)

  while oSql:notIsEof()
    
    oItem             := JsonObject():new()
    oItem["item"]     := oSql:getValue("ITEM_NO")
    oItem["code"]     := oSql:getValue("CODE")
    oItem["quantity"] := oSql:getValue("QUANTITY")
    oItem["price"]    := oSql:getValue("PRICE")
    oItem["total"]    := oSql:getValue("TOTAL")
    oItem["tes"]      := "502"
    
    aAdd(aItems, oItem)
      
    oSql:skip()

  endDo

  oSql:close()
    
return aItems


/**
 * Executa a função para inserção do pedido de venda
 */
static function createOrder(oInvoice)
  
  local nI            := 0  
  local lOk           := .F.
  local cStatus       := ""
  local cOrderId      := ""
  local cError        := ""
  local cPedMvc       := "N"
  local oUtils		    := LibUtilsObj():newLibUtilsObj()
  local aHeader       := {}
  local aItem         := {}
  local aItemsAuto    := {}
  local aItems        := oInvoice["items"]
  private lMsErroAuto := .F.
  private lMsHelpAuto := .T.

  aAdd(aHeader,{"C5_TIPO", oInvoice["type"], nil})    
  aAdd(aHeader,{"C5_CLIENTE", oInvoice["customerCode"], nil})
  aAdd(aHeader,{"C5_LOJACLI", oInvoice["customerUnit"], nil})
  aAdd(aHeader,{"C5_CONDPAG", "002", nil})
  aAdd(aHeader,{"C5_ZTPPAG", "1", nil})
  
  for nI := 1 to len(aItems)

    oItem := aItems[nI]

    aItem := {}

    aAdd(aItem,{"C6_ITEM", oItem["item"], nil})
    aAdd(aItem,{"C6_PRODUTO", oItem["code"], nil})
    aAdd(aItem,{"C6_QTDVEN", oItem["quantity"], nil})
    aAdd(aItem,{"C6_PRCVEN", oItem["price"], nil})
    aAdd(aItem,{"C6_PRUNIT", oItem["price"], nil})
    aAdd(aItem,{"C6_VALOR", oItem["total"], nil})
    aAdd(aItem,{"C6_TES", oItem["tes"], nil})

    aAdd(aItemsAuto, aItem)
  
  next nI

  MsExecAuto({|x,y,z| MATA410(x,y,z)}, aHeader, aItemsAuto, 3)

  if lMsErroAuto
    cStatus := XML_NF_STATUS_ERROR
    cError  := oUtils:getErroAuto()
  else
    cOrderId := SC5->C5_NUM
    cStatus  := XML_NF_STATUS_OK
    cPedMvc  := "S"
    lOk      := .T.
  endIf	

  SZ1->(DbSeek(FWxFilial('SZ1') +  oInvoice["number"] + oInvoice["series"]))
  SZ1->(RecLock('SZ1', .F.))
    SZ1->Z1_STATUS := cStatus
    SZ1->Z1_PEDNO  := cOrderId
    SZ1->Z1_LOG    := cError
  SZ1->(MsUnlock())

  SC5->(DbSeek(FWxFilial('SC5') + cOrderId))
  SC5->(RecLock('SC5', .F.))
    SC5->C5_ZZMVCPD := cPedMvc
  SC5->(MsUnlock())

return lOk
