#include "totvs.ch"

/*/{Protheus.doc} MvcReport

Gera��o de relat�rio anal�tico/sint�tico a partir do Browse MVC
    
@author fernandokodama
@since 17/11/2022
/*/
user function ReportMvc()
  
  local oParamBox    := paramBox()
  local oUtils       := LibUtilsObj():newLibUtilsObj()
  local cName        := "MvcReport"
  local cTitle       := "Relat�rio de Notas Fiscais"
  local bParams      := { || oParamBox:show() }
  local bRunReport   := { || runReport() }
  local cDescription := "Este relat�rio ir� listas as notas fiscais com op��o anal�tico (listando a se��o de itens da nota fiscal) ou sint�tico (listando somente o cabe�alho da nota fiscal"
  private oReport      := nil

  oReport := TReport():new(cName, cTitle, bParams, bRunReport, cDescription)

  if oParamBox:show()
    oUtils:msgRun({ || runReport(oParambox) }, "Gerando relat�rio ...", "Gera��o de Relat�rio de Notas Fiscais")
  endIf

return


/**
 * Cria as se��es do relat�rio
 */
static function createSections()
  
  oHeaderSection := TRSection():new(oReport)

  TRCell():new(oHeaderSection, "number", nil, "Nro. NF", nil, 9)
  TRCell():new(oHeaderSection, "series", nil, "S�rie", nil, 3)
  TRCell():new(oHeaderSection, "date", nil, "Dt. Emiss�o", nil,  10)
  TRCell():new(oHeaderSection, "customer", nil, "C�d. Cliente", nil, 6)
  TRCell():new(oHeaderSection, "customerName", nil, "Nome/Raz�o Social", nil, 40)
  TRCell():new(oHeaderSection, "total", nil, "Valor Total da NF", nil, 20)

  oItemSection := TRSection():new(oReport)

  TRCell():new(oItemSection, "item", nil, "Item da NF", nil, 3)
  TRCell():new(oItemSection, "productCode", nil, "C�d. do Produto", nil, 15)
  TRCell():new(oItemSection, "productDescription", nil, "Descri��o do Produto", nil, 60)
  TRCell():new(oItemSection, "cfop", nil, "CFOP", nil, 5)
  TRCell():new(oItemSection, "quantity", nil, "Quantidade", nil, 15)
  TRCell():new(oItemSection, "price", nil, "Valor Unit.", nil, 28)
  TRCell():new(oItemSection, "total", nil, "Valor Total", nil, 28)

return


/**
 * Cria a tela de interface com o usu�rio
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("MvcReport")

  oParamBox:setTitle("Par�metros para gera��o do relat�rio de notas fiscais")
  oParamBox:setValidation({|| ApMsgYesNo("Confirma par�metros ?")})

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

  oParam := LibParamObj():newLibParamObj("option", "combo", "Tipo do Relat�rio", "C", 60)
  oParam:setValues({"A=Anal�tico","S=Sint�tico"})
  oParamBox:addParam(oParam)    

  oParamBox:addParam(oParam)

return oParamBox


static function runReport(oParamBox)
  
  local cReportType := oParamBox:getValue("option")
  local oSql	      := nil
  local aInvoices   := {}
  local oInvoice    := nil
  local oUtils      := LibUtilsObj():newLibUtilsObj()
  
  createSections()

  oUtils:msgRun({ || oSql := createSql(oParambox) }, "Lendo registros ...")

  while oSql:notIsEof()

    oInvoice := JsonObject():new()
    oInvoice["number"] := oSql:getValue("NUMBER")
    oInvoice["series"] := oSql:getValue("SERIES")
    oInvoice["customer"] := oSql:getValue("CUSTOMER")
    oInvoice["customerName"] := oSql:getValue("CUSTOMER_NAME")
    oInvoice["date"] := oSql:getValue("DATE")
    
    aAdd(aInvoices, oInvoice)

  endDo

return


/**
 * Cria o SQL do Relat�rio
 */
static function createSql(oParamBox)

  local cAux := ""  
	local cQuery 	      := ""
	local cFromNumber   := oParamBox:getValue("fromNumber")
	local cToNumber     := oParamBox:getValue("toNumber")
  local cFromCustomer := oParamBox:getValue("fromCustomer")
  local cToCustomer   := oParamBox:getValue("toCustomer")
	local oSql   	      := LibSqlObj():newLibSqlObj()	

  cQuery := " SELECT F2_DOC [NUMBER], "
  cQuery += "        F2_SERIE [SERIES], "
  cQUery += "        F2_CLIENTE [CUSTOMER], "
  cQUery += "        A1_NOME [CUSTOMER_NAME], "
  cQuery += "        F2_EMISSAO [DATE] "
  cQuery += "   FROM %SF2.SQLNAME% "
  cQuery += "     INNER JOIN %SA1.SQLNAME% ON "
  cQuery += "       %SA1.XFILIAL% AND F2_CLIENTE = A1_COD AND %SA1.NOTDEL% "  
  cQuery += "   WHERE %SF2.XFILIAL% AND "
  cQuery += "         F2_DOC BETWEEN '" + cFromNumber + "' AND '" + cToNumber + "' AND "
  cQuery += "         F2_CLIENTE BETWEEN '" + cFromCustomer + "' AND '" + cToCustomer + "' AND "
  cQuery += "         %SF2.NOTDEL%
  cQuery += " ORDER BY F2_DOC, F2_SERIE, F2_EMISSAO "

  oSql:newAlias(cQuery)

  cAux := oSql:toJson()
  MsgInfo(cAux)

return oSql
