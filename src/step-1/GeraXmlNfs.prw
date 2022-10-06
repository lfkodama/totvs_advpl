#include "totvs.ch"


/*/{Protheus.doc} GeraXmlNfs

Geracao do XML de Notas Fiscais de Saida
	
@author soulsys:victorhugo
@since 04/10/2022
/*/
user function GeraXmlNfs()

  local oParamBox := createParamBox()

  if oParamBox:show()
    createFiles(oParamBox) 
  endIf

return

/**
 * Cria o objeto para coleta dos parametros
 */
static function createParamBox()

  local cId       := "XmlNfsPrb"
  local cTitle    := "Gerar XML NF Saída"
  local oParamBox := LibParamBoxObj():newLibParamBoxObj(cId, cTitle)  
  local oParam    := nil

  oParamBox:setValidation({ || ApMsgYesNo("Confirma os parâmetros ?") })  

  oParam := LibParamObj():newLibParamObj("fromNumber", "get", "NF Inicial", "C", 60, Len(SF2->F2_DOC))
  oParam:setF3("SF2")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("toNumber", "get", "NF Final", "C", 60, Len(SF2->F2_DOC))
  oParam:setF3("SF2")
  oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("startDate", "get", "Emissão Inicial", "D")
	oParam:setRequired(.T.)
	oParamBox:addParam(oParam)
	
	oParam := LibParamObj():newLibParamObj("endDate", "get", "Emissão Final", "D")
	oParam:setRequired(.T.) 
	oParamBox:addParam(oParam)

  oParam := LibParamObj():newLibParamObj("folder", "file", "Diretório", "C", 80, 1000)
  oParam:setFileTypes("Arquivos XML |*.xml")
  oParam:setFileParams(GETF_LOCALHARD + GETF_NETWORKDRIVE + GETF_RETDIRECTORY)
  oParam:setRequired(.T.)
  oParamBox:addParam(oParam)

return oParamBox

/**
 * Processa a criacao dos arquivos
 */
static function createFiles(oParamBox)

  local nI        := 0
  local aInvoices := getInvoices(oParamBox)

  for nI := 1 to Len(aInvoices)
    createInvoiceFile(aInvoices[nI])
  next nI

return

/**
 * Obtem as notas fiscais
 */
static function getInvoices(oParamBox)

  local cQuery      := ""
  local cFromNumber := oParamBox:getValue("fromNumber")
  local cToNumber   := oParamBox:getValue("toNumber")
  local dStartDate  := oParamBox:getValue("startDate")
  local dEndDate    := oParamBox:getValue("endDate")
  local aInvoices   := {}
  local oInvoice    := nil
  local oSql        := LibSqlObj():newLibSqlObj()

  cQuery := " SELECT "
  cQuery += "   F2_DOC [NUMBER], "
  cQuery += "   F2_SERIE [SERIES], "
  cQuery += "   F2_EMISSAO [DATE] "
  cQuery += " FROM %SF2.SQLNAME% "
  cQuery += " WHERE %SF2.XFILIAL% AND "
  cQuery += "       F2_DOC BETWEEN '" + cFromNumber + "' AND '" + cToNumber + "' AND "
  cQuery += "       F2_EMISSAO BETWEEN '" + DtoS(dStartDate) + "' AND '" + DtoS(dEndDate) + "' AND %SF2.NOTDEL% "

  oSql:newAlias(cQuery)
  oSql:setField("DATE", "D")

  while oSql:notIsEof()

    oInvoice           := JsonObject():new()
    oInvoice["number"] := oSql:getValue("AllTrim(NUMBER)")
    oInvoice["series"] := oSql:getValue("AllTrim(SERIES)")
    oInvoice["date"]   := oSql:getValue("DATE")

    aAdd(aInvoices, oInvoice)

    oSql:skip()
  endDo

  oSql:close()
 
return aInvoices

/**
 * Cria um arquivo para uma NF
 */
static function createInvoiceFile(oInvoice)
  
  MsgInfo(oInvoice:toJson())

return
