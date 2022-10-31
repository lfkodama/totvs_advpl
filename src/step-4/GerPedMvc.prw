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
  local aItems := {}
  private cNumber   := ""
  private cSeries   := ""

  
  if Len(aInvoices) == 0
    MsgAlert("Nenhuma NF encontrada")
    return
  endIf

  for nI := 1 to Len(aInvoices)

    cNumber := aInvoices[6,2]
    cSeries := aInvoices[7,2]
    aItems := getOrderItems(cNumber, cSeries)

    createOrder(aInvoices[nI], aItems)
    
  next nI

return


/**
 * Busca os dados do cabeçalho do pedido no banco
 */
static function getInvoices(oParambox)
  
  local cQuery    := ""
  local aHeader   := {}
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
    cQuery += "       Z1_DOC BETWEEN '" + oParamBox:getValue("fromNumber") + "' AND '" + oParamBox:getValue("toNumber") + "' AND "
  else
    cQuery += "       Z1_STATUS <> '2' AND "
  endIf    
  cQuery += "       %SZ1.NOTDEL% ""

  oSql:newAlias(cQuery)

  while oSql:notIsEof()

    aAdd(aHeader,{"C5_TIPO", "N", nil})    
    aAdd(aHeader,{"C5_CLIENTE", oSql:getValue("CUSTOMER_CODE"), nil})
    aAdd(aHeader,{"C5_LOJACLI", oSql:getValue("LOJA"), nil})
    aAdd(aHeader,{"C5_CONDPAG", "002", nil})
    aAdd(aHeader,{"C5_ZTPPAG", "1", nil})
    aAdd(aHeader,{"number", oSql:getValue("NUMBER"), nil})
    aAdd(aHeader,{"series", oSql:getValue("SERIES"), nil})
    
    oSql:skip()

  endDo
  
  oSql:close()

return aHeader


/**
 * Busca os dados dos itens de produtos no banco
 */
static function getOrderItems(cNumber, cSeries)
  
  local cQuery  := ""
  local aItems  := {}
  local oSql    := LibSqlObj():newLibSqlObj()

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

  MsgInfo(cQuery)

  oSql:newAlias(cQuery)

  while oSql:notIsEof()
    
    aItem := {}

    aAdd(aItem,{"C6_ITEM", oSql:getValue("ITEM_NO"), nil})
    aAdd(aItem,{"C6_PRODUTO", oSql:getValue("CODE"), nil})
    aAdd(aItem,{"C6_QTDVEN", oSql:getValue("QUANTITY"), nil}) 
    aAdd(aItem,{"C6_PRCVEN", oSql:getValue("PRICE"), nil})
    aAdd(aItem,{"C6_PRUNIT", oSql:getValue("PRICE"), nil})
    aAdd(aItem,{"C6_VALOR", oSql:getValue("TOTAL"), nil})
    aAdd(aItem,{"C6_TES", "502", nil})

    aAdd(aItems, aItem)
      
    oSql:skip()

  endDo

  oSql:close()
    
return aItems


/**
 * Executa a função para inserção do pedido de venda
 */
static function createOrder(aHeader, aItems)
  
  local cOrderId      := ""
  local cError        := ""
  local oUtils		    := LibUtilsObj():newLibUtilsObj()
  private lMsErroAuto := .F.
  private lMsHelpAuto := .T.
  
  MsExecAuto({|x,y,z| MATA410(x,y,z)}, aHeader, aItems, 3)

  if !lMsErroAuto
    cOrderId := SC5->C5_NUM
    MsgInfo("Pedido gerado com sucesso: " + cOrderId)    
  else
    cError := oUtils:getErroAuto()
    Alert(cError)
  endIf	

return
