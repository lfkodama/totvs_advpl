#include "totvs.ch"

/*/{Protheus.doc} MvcReport

Gera��o de relat�rio anal�tico/sint�tico a partir do Browse MVC
    
@author fernandokodama
@since 17/11/2022
/*/
user function MvcReport()
  
  local oReport      := nil
  local oParamBox    := paramBox()
  local oUtils       := LibUtilsObj():newLibUtilsObj()
  local cName        := "MvcReport"
  local cTitle       := "Relat�rio de Notas Fiscais"
  local bParams      := { || oParamBox:show() }
  local bRunReport   := { || runReport() }
  local cDescription := "Este relat�rio ir� listas as notas fiscais com op��o anal�tico (listando a se��o de itens da nota fiscal) ou sint�tico (listando somente o cabe�alho da nota fiscal"

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

  TRCell():new(oHeaderSection, "number", nil, "", 9)

return


/**
 * Cria a tela de interface com o usu�rio
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("MvcReport")

  oParamBox:setTitle("Par�metros para gera��o do relat�rio de notas fiscais")
  oParamBox:setValidation({|| ApMsgYesNo("Confirma par�metros ?")})

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
  

  oUtils:msgRun({ || oSql := createSql() }, "Lendo registros ...")

  while oSql:notIsEof()

    oInvoice := JsonObject():new()
    oInvoice["number"] := oSql:getValue("F2_DOC")
    oInvoice["series"] := oSql:getValue("AllTrim(F2_SERIE)")
    oInvoice["customer"] := oSql:getValue("F2_CLIENTE")
    oInvoice["date"] := oSql:getValue("F2_EMISSAO")
    
    aAdd(aInvoices, oInvoice)

  endDo

return


/**
 * Cria o SQL do Relat�rio
 */
static function createSql()

	local cQuery 	      := ""
	local cFromNumber   := oParamBox:getValue("fromNumber")
	local cToNumber     := oParamBox:getValue("toNumber")
  local cFromCustomer := oParamBox:getValue("fromCustomer")
  local cToCustomer   := oParamBox:getValue("toCustomer")
	local oSql   	      := LibSqlObj():newLibSqlObj()	

  cQuery := " SELECT "
  cQuery += "     F2_DOC, F2_SERIE, F2_CLIENTE, F2_EMISSAO "
  cQuery += "   FROM %SF2.SQLNAME% "
  cQuery += "   WHERE %SF2.XFILIAL% AND "
  cQuery += "         F2_DOC BETWEEN '" + cFromNumber + "' AND '" + cToNumber + "' AND "
  cQuery += "         F2_CLIENTE BETWEEN '" + cFromCustomer + "' AND '" + cToCustomer + "' AND "
  cQuery += "         %SF2.NOTDEL%
  cQuery += " ORDER BY F2_DOC, F2_SERIE, F2_EMISSAO "

  oSql:newAlias(cQuery)

return oSql  
