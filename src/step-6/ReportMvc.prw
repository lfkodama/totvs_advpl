#include "totvs.ch"

/*/{Protheus.doc} MvcReport

Geração de relatório analítico/sintético a partir do Browse MVC
    
@author fernandokodama
@since 17/11/2022
/*/
user function ReportMvc()
  
  local oParamBox    := paramBox()
  local oUtils       := LibUtilsObj():newLibUtilsObj()
  local cName        := "MvcReport"
  local cTitle       := "Relatório de Notas Fiscais"
  local bParams      := { || oParamBox:show() }
  local bRunReport   := { || runReport() }
  local cDescription := "Este relatório irá listas as notas fiscais com opção analítico (listando a seção de itens da nota fiscal) ou sintético (listando somente o cabeçalho da nota fiscal"
  private oReport      := nil
  private oHeaderSection := nil
  private oItemSection := nil

  oReport := TReport():new(cName, cTitle, bParams, bRunReport, cDescription)
  oReport:SetLandScape(.T.)

  if oParamBox:show()
    createSections()
    oUtils:msgRun({ || runReport(oParambox) }, "Gerando relatório ...", "Geração de Relatório de Notas Fiscais")
  endIf

return


/**
 * Cria as seções do relatório
 */
static function createSections()

  oHeaderSection := TRSection():new(oReport)

  TRCell():new(oHeaderSection, "number", nil, "Nro. NF", nil, 9)
  TRCell():new(oHeaderSection, "series", nil, "Série", nil, 3)
  TRCell():new(oHeaderSection, "date", nil, "Dt. Emissão", nil,  10)
  TRCell():new(oHeaderSection, "customer", nil, "Cód. Cliente", nil, 6)
  TRCell():new(oHeaderSection, "customerName", nil, "Nome/Razão Social", nil, 40)
  TRCell():new(oHeaderSection, "total", nil, "Valor Total da NF", nil, 20)

  oItemSection := TRSection():new(oReport)

  TRCell():new(oItemSection, "item", nil, "Item da NF", nil, 3)
  TRCell():new(oItemSection, "productCode", nil, "Cód. do Produto", nil, 15)
  TRCell():new(oItemSection, "productDescription", nil, "Descrição do Produto", nil, 60)
  TRCell():new(oItemSection, "cfop", nil, "CFOP", nil, 5)
  TRCell():new(oItemSection, "quantity", nil, "Quantidade", nil, 15)
  TRCell():new(oItemSection, "price", nil, "Valor Unit.", nil, 28)
  TRCell():new(oItemSection, "total", nil, "Valor Total", nil, 28)

return


/**
 * Cria a tela de interface com o usuário
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("MvcReport")

  oParamBox:setTitle("Parâmetros para geração do relatório de notas fiscais")
  oParamBox:setValidation({|| ApMsgYesNo("Confirma parâmetros ?")})

  oParam := LibParamObj():newLibParamObj("startDate", "get", "Data Inicial", "D", 60, 8) 
	oParam:setRequired(.T.)
	oParamBox:addParam(oParam)
	
	oParam := LibParamObj():newLibParamObj("endDate", "get", "Data Final", "D", 60, 8)
	oParam:setRequired(.T.) 
	oParamBox:addParam(oParam)
  
  oParam := LibParamObj():newLibParamObj("fromNumber", "get", "NF Inicial", "C", 60, Len(SZ1->Z1_DOC))
  oParam:setF3("SZ1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("toNumber", "get", "NF Final", "C", 60, Len(SZ1->Z1_DOC))
  oParam:setF3("SZ1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("fromCustomer", "get", "Cliente Inicial", "C", 60, Len(SZ1->Z1_CLIENTE))
  oParam:setF3("SA1")
  oParamBox:addParam(oParam)
  
  oParam := LibParamObj():newLibParamObj("toCustomer", "get", "Cliente Final", "C", 60, Len(SZ1->Z1_CLIENTE))
  oParam:setF3("SA1")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("option", "combo", "Tipo do Relatório", "C", 60)
  oParam:setValues({"A=Analítico","S=Sintético"})
  oParamBox:addParam(oParam)    

  oParamBox:addParam(oParam)

return oParamBox


static function runReport(oParamBox)

  local cReportType := oParamBox:getValue("option")
  local oSql        := createSql(oParamBox)
  local aInvoices   := {}
  local aItems      := {}
  local oInvoice    := nil

  oReport:setMeter(oSql:count())
	oReport:startPage()
	
  oSql:goTop()

  while oSql:notIsEof()

    oInvoice := JsonObject():new()
    oInvoice["number"] := oSql:getValue("NUMBER")
    oInvoice["series"] := oSql:getValue("SERIES")
    oInvoice["customer"] := oSql:getValue("CUSTOMER")
    oInvoice["customerName"] := oSql:getValue("CUSTOMER_NAME")
    oInvoice["date"] := oSql:getValue("DATE")
    oInvoice["total"] := oSql:getValue("TOTAL")

    oHeaderSection:cell("number"):setValue(oInvoice["number"])
    oHeaderSection:cell("series"):setValue(oInvoice["series"])
  
    aAdd(aInvoices, oInvoice)

    if cReportType == "A"
      getItemsData(oSql, oInvoice["number"], oInvoice["series"])
    endIf

    oInvoice["items"] := aItems
    
    oInvoice:printLine()

    oSql:skip()

  endDo

  oSql:close()

return


/**
 * Busca os itens de produto da NF
 */
static function getItemsData(oSql, cNumber, cSeries) 
  
  local oItem  := nil
  local aItems := {}
  
  while (oSql:isNotEof() .and. (oSql:getValue("NUMBER") == cNumber .and. oSql:getValue("SERIES") == cSeries))
  
      oItem := JsonObject():new()
      oItem["item"] := oSql:getValue("ITEM")
      oItem["productCode"] := oSql:getValue("PRODUCT_CODE")
      oItem["productDescription"] := oSql:getValue("PRODUCT_DESCRIPTION")
      oItem["quantity"] := oSql:getValue("QUANTITY")
      oItem["price"] := oSql:getValue("PRICE")
      oItem["productTotal"] := oSql:getValue("PRODUCT_TOTAL")
  
      aAdd(aItems, oItem)
      
      oSql:skip()

    endDo    

return aItems


/**
 * Cria o SQL do Relatório
 */
static function createSql(oParamBox)

	local cQuery 	      := ""
	local cFromNumber   := oParamBox:getValue("fromNumber")
	local cToNumber     := oParamBox:getValue("toNumber")
  local cFromCustomer := oParamBox:getValue("fromCustomer")
  local cToCustomer   := oParamBox:getValue("toCustomer")
	local oSql   	      := LibSqlObj():newLibSqlObj()	

  cQuery := " SELECT F2_DOC [NUMBER], "
  cQuery += "        F2_SERIE [SERIES], "
  cQUery += "        F2_CLIENTE [CUSTOMER], "
  cQuery += "        A1_NOME [CUSTOMER_NAME], "
  cQuery += "        F2_EMISSAO [DATE], "
  cQuery += "        F2_VALBRUT [TOTAL], "
  cQuery += "        D2_ITEM [ITEM], "
  cQuery += "        D2_COD [PRODUCT_CODE], "
  cQuery += "        B1_DESC [PRODUCT_DESCRIPTION], "
  cQuery += "        D2_QUANT [QUANTITY], "
  cQuery += "        D2_PRCVEN [PRICE], "
  cQuery += "        D2_TOTAL [PRODUCT_TOTAL] "
  cQuery += "   FROM %SF2.SQLNAME% "
  cQuery += "     INNER JOIN %SA1.SQLNAME% ON "
  cQuery += "       %SA1.XFILIAL% AND F2_CLIENTE = A1_COD AND %SA1.NOTDEL% " 
  cQuery += "       INNER JOIN %SD2.SQLNAME% ON "
  cQuery += "         %SD2.XFILIAL% AND D2_DOC = F2_DOC AND D2_SERIE = F2_SERIE AND %SD2.NOTDEL% "
  cQuery += "       INNER JOIN %SB1.SQLNAME% ON "
  cQuery += "         %SB1.XFILIAL% AND B1_COD = D2_COD AND %SB1.NOTDEL% " 
  cQuery += "   WHERE %SF2.XFILIAL% AND "
  cQuery += "         F2_DOC BETWEEN '" + cFromNumber + "' AND '" + cToNumber + "' AND "
  cQuery += "         F2_CLIENTE BETWEEN '" + cFromCustomer + "' AND '" + cToCustomer + "' AND "
  cQuery += "         %SF2.NOTDEL%
  cQuery += " ORDER BY F2_EMISSAO, F2_DOC, F2_SERIE, D2_ITEM "

  oSql:newAlias(cQuery)

  return oSql


