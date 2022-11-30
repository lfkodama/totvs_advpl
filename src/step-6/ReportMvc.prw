#include "totvs.ch"

/*/{Protheus.doc} MvcReport

Geração de relatório analítico/sintético a partir do Browse MVC
    
@author fernandokodama
@since 17/11/2022
/*/
user function ReportMvc()
  
  local oParamBox        := paramBox()
  local oUtils           := LibUtilsObj():newLibUtilsObj()
  local cName            := "MvcReport"
  local cTitle           := "Relatório de Notas Fiscais"
  local bParams          := { || oParamBox:show() }
  local bRunReport       := { || runReport() }
  local cDescription     := "Este relatório irá listas as notas fiscais com opção analítico (listando a seção de itens da nota fiscal) ou sintético (listando somente o cabeçalho da nota fiscal"
  private oReport        := nil
  private oHeaderSection := nil
  private oItemSection   := nil

  oReport := TReport():new(cName, cTitle, bParams, bRunReport, cDescription) 
  oReport:SetLandScape(.T.)
  oReport:init()

  if oParamBox:show()
    oUtils:msgRun({ || runReport(oParamBox) }, "Gerando relatório ...", "Geração de Relatório de Notas Fiscais")
    //oReport:PrintDialog()
  endIf

return


/**
 * Cria a tela de interface com o usuário
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("ReportMvc")

  oParamBox:setTitle("Parâmetros para geração do relatório de notas fiscais")
  oParamBox:setValidation({|| ApMsgYesNo("Confirma parâmetros ?")})

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

  oParam := LibParamObj():newLibParamObj("startDate", "get", "Data Inicial", "D", 60, 8) 
	oParam:setRequired(.T.)
	oParamBox:addParam(oParam)
	
	oParam := LibParamObj():newLibParamObj("endDate", "get", "Data Final", "D", 60, 8)
	oParam:setRequired(.T.) 
	oParamBox:addParam(oParam)
  
  oParam := LibParamObj():newLibParamObj("option", "combo", "Tipo do Relatório", "C", 60)
  oParam:setValues({"A=Analítico","S=Sintético"})
  oParamBox:addParam(oParam)    

  oParamBox:addParam(oParam)

return oParamBox


/**
 * Executa o relatório
 */
static function runReport(oParamBox)

  local nI          := 0
  local aInvoices   := {}
  local aItems      := {}
  local oInvoice    := nil
  local oSql        := createSql(oParamBox)
  
  createSections()
  
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
    
    oHeaderSection:init()

    oHeaderSection:cell("number"):setValue(oInvoice["number"])
    oHeaderSection:cell("series"):setValue(oInvoice["series"])
    oHeaderSection:cell("customer"):setValue(oInvoice["customer"])
    oHeaderSection:cell("customerName"):setValue(oInvoice["customerName"])
    oHeaderSection:cell("date"):setValue(CtoD(oInvoice["date"]))
    oHeaderSection:cell("total"):setValue(oInvoice["total"])
   
    oHeaderSection:printLine()

    aAdd(aInvoices, oInvoice)
    
    if oParamBox:getValue("option") == "A"

      aItems := getItemsData(oInvoice["number"], oInvoice["series"])

      oInvoice["items"] := aItems

      oItemSection:init()

      for nI := 1 to Len(aItems)
        oItem := aItems[nI]

        oItemSection:cell("item"):setValue(oItem["item"])
        oItemSection:cell("productCode"):setValue(oItem["productCode"])
        oItemSection:cell("productDescription"):setValue(oItem["productDescription"])
        oItemSection:cell("quantity"):setValue(oItem["quantity"])
        oItemSection:cell("price"):setValue(oItem["price"])
        oItemSection:cell("productTotal"):setValue(oItem["productTotal"])
        oItemSection:printLine()
      next nI   

      TRFunction():New(oItemSection:cell("productTotal"), nil, "SUM",,"Total dos Produtos",,,.F.,.T.)
    
    endIf
    oReport:incMeter() 
    oSql:skip()
  
  endDo
  oReport:endPage()
  oSql:close()

  oItemSection:finish()
  oHeaderSection:finish()
  oReport:finish()

return


/**
 * Cria as seções do relatório
 */
static function createSections()

  oHeaderSection := TRSection():New(oReport)
  oHeaderSection:lHeaderSection := .F.
  oHeaderSection:lAutoSize := .T.

  TRCell():new(oHeaderSection, "number", nil, "Nro. NF", nil, 9)
  TRCell():new(oHeaderSection, "series", nil, "Série", nil, 3)
  TRCell():new(oHeaderSection, "date", nil, "Dt. Emissão", nil,  10)
  TRCell():new(oHeaderSection, "customer", nil, "Cód. Cliente", nil, 6)
  TRCell():new(oHeaderSection, "customerName", nil, "Nome/Razão Social", nil, 40)
  TRCell():new(oHeaderSection, "total", nil, "Valor Total da NF", nil, 20)

  oItemSection := TRSection():New(oReport)
  oItemSection:lAutoSize := .T.

  TRCell():new(oItemSection, "item", nil, "Item da NF", nil, 3)
  TRCell():new(oItemSection, "productCode", nil, "Cód. do Produto", nil, 15)
  TRCell():new(oItemSection, "productDescription", nil, "Descrição do Produto", nil, 60)
  TRCell():new(oItemSection, "cfop", nil, "CFOP", nil, 5)
  TRCell():new(oItemSection, "quantity", nil, "Quantidade", nil, 15)
  TRCell():new(oItemSection, "price", nil, "Valor Unit.", nil, 28)
  TRCell():new(oItemSection, "productTotal", nil, "Valor Total", nil, 28)

return


/**
 * Cria o SQL do Relatório
 */
static function createSql(oParamBox)
  
	local cQuery 	      := ""
	local cFromNumber   := oParamBox:getValue("fromNumber")
	local cToNumber     := oParamBox:getValue("toNumber")
  local cFromCustomer := oParamBox:getValue("fromCustomer")
  local cToCustomer   := oParamBox:getValue("toCustomer")
  local dStartDate    := oParamBox:getValue("startDate")
  local dEndDate      := oParamBox:getValue("endDate")
	local oSql   	      := LibSqlObj():newLibSqlObj()	

  cQuery := " SELECT F2_DOC [NUMBER], "
  cQuery += "        F2_SERIE [SERIES], "
  cQUery += "        F2_CLIENTE [CUSTOMER], "
  cQuery += "        A1_NOME [CUSTOMER_NAME], "
  cQuery += "        F2_EMISSAO [DATE], "
  cQuery += "        F2_VALBRUT [TOTAL] "
  cQuery += "   FROM %SF2.SQLNAME% "
  cQuery += "     INNER JOIN %SA1.SQLNAME% ON "
  cQuery += "       %SA1.XFILIAL% AND F2_CLIENTE = A1_COD AND %SA1.NOTDEL% " 
  cQuery += "   WHERE %SF2.XFILIAL% AND "
  cQuery += "         F2_DOC BETWEEN '" + cFromNumber + "' AND '" + cToNumber + "' AND "
  cQuery += "         F2_CLIENTE BETWEEN '" + cFromCustomer + "' AND '" + cToCustomer + "' AND "
  cQuery += "         F2_EMISSAO BETWEEN '" + DtoS(dStartDate) + "' AND '" + DtoS(dEndDate) + "' AND "
  cQuery += "         %SF2.NOTDEL%
  cQuery += " ORDER BY F2_EMISSAO, F2_DOC, F2_SERIE "

  oSql:newAlias(cQuery)

  return oSql


/**
 * Busca os itens de produto da NF
 */
static function getItemsData(cNumber, cSeries) 
  
  local cQuery := ""
  local oItem  := nil
  local aItems := {}
  local oSql2  := LibSqlObj():newLibSqlObj()
  
  cQuery := " SELECT "
  cQuery += "     D2_ITEM [ITEM], "
  cQuery += "     D2_COD [PRODUCT_CODE], "
  cQuery += "     B1_DESC [PRODUCT_DESCRIPTION], "
  cQuery += "     D2_QUANT [QUANTITY], "
  cQuery += "     D2_PRCVEN [PRICE], "
  cQuery += "     D2_TOTAL [PRODUCT_TOTAL] "
  cQuery += "   FROM %SD2.SQLNAME%
  cQuery += "     INNER JOIN %SB1.SQLNAME% ON
  cQuery += "       %SB1.XFILIAL% AND B1_COD = D2_COD AND %SB1.NOTDEL% "
  cQuery += "   WHERE %SD2.XFILIAL% AND "
  cQuery += "         D2_DOC = '" + cNumber + "' AND "
  cQuery += "         D2_SERIE = '" + cSeries + "' AND "
  cQuery += "         %SD2.NOTDEL% "
  cQuery += "ORDER BY D2_ITEM "

  oSql2:newAlias(cQuery)

  while oSql2:isNotEof()
  
      oItem := JsonObject():new()
      oItem["item"] := oSql2:getValue("ITEM")
      oItem["productCode"] := oSql2:getValue("PRODUCT_CODE")
      oItem["productDescription"] := oSql2:getValue("PRODUCT_DESCRIPTION")
      oItem["quantity"] := oSql2:getValue("QUANTITY")
      oItem["price"] := oSql2:getValue("PRICE")
      oItem["productTotal"] := oSql2:getValue("PRODUCT_TOTAL")
  
      aAdd(aItems, oItem)
      
      oSql2:skip()

    endDo  

    oSql2:close()  

return aItems
