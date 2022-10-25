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
    getNfsData(oParambox)
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
 * Busca os dados no banco
 */
static function getNfsData(oParambox)

  local cQuery     := ""
  local cAux       := ""
  local cOrderNo   := GetSxeNum("SC5", "C5_NUM")
  local aSellOrder := {}
  local oSellOrder := nil
  local oItem      := nil
  local oSql       := LibSqlObj():newLibSqlObj()

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
    oSellOrder                  := JsonObject():new()
    oSellOrder["filial"]        := oSql:getValue("FILIAL")  
    oSellOrder["loja"]          := oSql:getValue("LOJA")
    oSellOrder["orderNumber"]   := cOrderNo
    oSellOrder["customerCode"]  := oSql:getValue("CUSTOMER_CODE")
    oSellOrder["paymentMethod"] := oSql:getValue("PAYMENT_METHOD")
    if oSellOrder["paymentMethod"] == " "
      oSellOrder["paymentMethod"] := "002"  
    endIf
    aAdd(aSellOrder, oSellOrder)
    oSql:skip()

  endDo
  
  oSql:close()

return


/**
 * Executa a função para inserção do pedido de venda
 */
static function AddNewOrder(aSellOrder)

  nOpcX := 3
  MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aSellOrder, aItems, nOpcX, .F.)
  
  if !lMsErroAuto
    ConOut("Incluido com sucesso! " + cDoc)
  else
    ConOut("Erro na inclusao!")
  endIf

return
