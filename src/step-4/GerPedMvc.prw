#include "totvs.ch"
#include "rwmake.ch"


/*/{Protheus.doc} GerPedMvc

Geração de pedido de vendas a partir da tela MVC de notas fiscais
    
@author fernandokodama
@since 22/10/2022
/*/
user function GerPedMvc()
 
  local oParamBox := paramBox()
  
  if oParamBox:show()
    generateOrders(oParambox)
  endIf

return


/**
 * Cria a tela de interface com o usuário
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("GerPedXml")

  dbSelectArea("SZ1")

  oParamBox:setTitle("Parâmetros para geração de Pedido de Venda")
  oParamBox:setValidation({|| ApMsgYesNo("Confirma parâmetros ?")})

  oParam := LibParamObj():newLibParamObj("fromNumber", "get", "NF Inicial", "C", 60, Len(SZ1->Z1_DOC))
  oParam:setF3("SZ1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("toNumber", "get", "NF Final", "C", 60, Len(SZ1->Z1_DOC))
  oParam:setF3("SZ1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("optionAll", "checkbox", "Gera pedido para todas as pendentes?", ".F.", 120)  
  oParamBox:addParam(oParam)

  oParamBox:addParam(oParam)

return oParamBox


/**
 * Processa a criacao dos pedidos
 */
static function generateOrders(oParambox)

  local nI        := 0
  local aInvoices := getInvoices(oParambox)
  private cNumber := ""
  private cSeries := ""
  
  if Len(aInvoices) == 0
    MsgAlert("Nenhuma NF encontrada")
    return
  endIf

  for nI := 1 to Len(aInvoices)

    createOrder(aInvoices[nI])
    
  next nI

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
  cQuery += "   Z1_LOJA    [LOJA], "
  cQuery += "   Z1_DOC     [NUMBER], "
  cQuery += "   Z1_SERIE   [SERIES], "
  cQuery += "   Z1_EMISSAO [DATE], "
  cQuery += "   Z1_STATUS  [STATUS], "
  cQuery += "   A1_COD     [CUSTOMER_CODE],"
  cQuery += "   A1_CGC     [CGC], "
  cQuery += "   A1_NOME    [CUSTOMER_NAME], "
  cQuery += "   A1_MUN     [CITY], "
  cQuery += "   A1_EST     [STATE], "
  cQuery += "   A1_COND    [PAYMENT_METHOD] "
  cQuery += " FROM %SZ1.SQLNAME% "
  cQuery += "   INNER JOIN %SA1.SQLNAME% ON "
  cQuery += "     %SA1.XFILIAL% AND A1_COD = Z1_CLIENTE AND A1_LOJA = Z1_LOJA AND %SA1.NOTDEL% "
  cQuery += " WHERE %SZ1.XFILIAL% AND "
  if !oParamBox:getValue("optionAll") == .T.
    cQuery += " Z1_DOC BETWEEN '" + oParamBox:getValue("fromNumber") + "' AND '" + oParamBox:getValue("toNumber") + "' AND Z1_STATUS <> 1 AND "
  else
    cQuery += " Z1_STATUS <> '1' AND "
  endIf    
  cQuery += "   %SZ1.NOTDEL% ""

  oSql:newAlias(cQuery)

  while oSql:notIsEof()
    
    oInvoice               := JsonObject():new()
    oInvoice["C5_TIPO"]    := "N"  
    oInvoice["C5_CLIENTE"] := oSql:getValue("CUSTOMER_CODE")
    oInvoice["C5_LOJACLI"] := oSql:getValue("LOJA")
    oInvoice["C5_CONDPAG"] := oSql:getValue("PAYMENT_METHOD")
    oInvoice["number"]     := oSql:getValue("NUMBER")
    oInvoice["series"]     := oSql:getValue("SERIES")

    getOrderItems(oInvoice)

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
    
    oItem               := JsonObject():new()
    oItem["C6_ITEM"]    := oSql:getValue("ITEM_NO")
    oItem["C6_PRODUTO"] := oSql:getValue("CODE")
    oItem["C6_QTDVEN"]  := oSql:getValue("QUANTITY")
    oItem["C6_PRCVEN"]  := oSql:getValue("PRICE")
    oItem["C6_PRUNIT"]  := oSql:getValue("PRICE")
    oItem["C6_VALOR"]   := oSql:getValue("TOTAL")
    oItem["C6_TES"]     := "502"
    
    aAdd(aItems, oItem)
      
    oSql:skip()

  endDo

  oInvoice["items"] := aItems

  oSql:close()
    
return


/**
 * Executa a função para inserção do pedido de venda
 */
static function createOrder(oInvoice)
  
  local nI            := 0
  local cOrderId      := ""
  local cError        := ""
  local cAlias        := "SZ1990"
  local cFields       := ""
  local cWhere        := "%SZ1.XFILIAL% AND Z1_DOC = '" + oInvoice["number"] + "' AND Z1_SERIE = '" + oInvoice["series"] + "'"
  local oSql          := LibSqlObj():newLibSqlObj()
  local oUtils		    := LibUtilsObj():newLibUtilsObj()
  local aHeader       := {}
  local aItem         := {}
  local aItemsAuto    := {}
  local aItems        := oInvoice["items"]
  private lMsErroAuto := .F.
  private lMsHelpAuto := .T.

  aAdd(aHeader,{"C5_TIPO", oInvoice["C5_TIPO"], nil})    
  aAdd(aHeader,{"C5_CLIENTE", oInvoice["C5_CLIENTE"], nil})
  aAdd(aHeader,{"C5_LOJACLI", oInvoice["C5_LOJACLI"], nil})
  aAdd(aHeader,{"C5_CONDPAG", "002", nil})
  aAdd(aHeader,{"C5_ZTPPAG", "1", nil})
  
  for nI := 1 to len(aItems)

    oItem     := aItems[nI]

    aItem := {}

    aAdd(aItem,{"C6_ITEM", oItem["C6_ITEM"], nil})
    aAdd(aItem,{"C6_PRODUTO", oItem["C6_PRODUTO"], nil})
    aAdd(aItem,{"C6_QTDVEN", oItem["C6_QTDVEN"], nil})
    aAdd(aItem,{"C6_PRCVEN", oItem["C6_PRCVEN"], nil})
    aAdd(aItem,{"C6_PRUNIT", oItem["C6_PRUNIT"], nil})
    aAdd(aItem,{"C6_VALOR", oItem["C6_VALOR"], nil})
    aAdd(aItem,{"C6_TES", "502", nil})

    aAdd(aItemsAuto, aItem)
  
  next nI

  MsExecAuto({|x,y,z| MATA410(x,y,z)}, aHeader, aItemsAuto, 3)

  if !lMsErroAuto
    cOrderId := SC5->C5_NUM
    cFields  := "Z1_STATUS = 1, Z1_PEDNO = '" + cOrderId + "' "
    oSql:update(cAlias, cFields, cWhere)
    MsgInfo("Pedido gerado com sucesso: " + cOrderId)    
  else
    cFields  := "Z1_STATUS = 2 "
    oSql:update(cAlias, cFields, cWhere)
    cError := oUtils:getErroAuto()
    Alert(cError)
  endIf	

return cOrderId
