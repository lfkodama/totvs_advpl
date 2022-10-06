#include "totvs.ch"

//TODO:
//1. Popular itens do arquivo XML
//2. Validar diretório informado
//3. Tratar substituição de arquivos já existens
//4. Apresentar mensagem ao final do processamento ( X arquivos gerados ou Nenhum arquivo gerado )

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
    createInvoiceFile(aInvoices[nI], oParamBox)
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
  cQuery += "   F2_DOC     [NUMBER], "
  cQuery += "   F2_SERIE   [SERIES], "
  cQuery += "   F2_EMISSAO [DATE], "
  cQuery += "   A1_CGC     [CGC], "
  cQuery += "   A1_NOME    [CUSTOMER_NAME], "
  cQuery += "   A1_MUN     [CITY], "
  cQuery += "   A1_EST     [STATE] "
  cQuery += " FROM %SF2.SQLNAME% "
  cQuery += "   INNER JOIN %SA1.SQLNAME% ON "
  cQuery += "     %SA1.XFILIAL% AND A1_COD = F2_CLIENTE AND A1_LOJA = F2_LOJA AND %SA1.NOTDEL% "
  cQuery += " WHERE %SF2.XFILIAL% AND "
  cQuery += "       F2_DOC BETWEEN '" + cFromNumber + "' AND '" + cToNumber + "' AND "
  cQuery += "       F2_EMISSAO BETWEEN '" + DtoS(dStartDate) + "' AND '" + DtoS(dEndDate) + "' AND %SF2.NOTDEL% "

  oSql:newAlias(cQuery)
  oSql:setField("DATE", "D")

  while oSql:notIsEof()

    oInvoice                 := JsonObject():new()
    oInvoice["number"]       := oSql:getValue("AllTrim(NUMBER)")
    oInvoice["series"]       := oSql:getValue("AllTrim(SERIES)")
    oInvoice["date"]         := oSql:getValue("DATE")
    oInvoice["cgc"]          := oSql:getValue("AllTrim(CGC)")
    oInvoice["customerName"] := oSql:getValue("AllTrim(CUSTOMER_NAME)")
    oInvoice["city"]         := oSql:getValue("AllTrim(CITY)")
    oInvoice["state"]        := oSql:getValue("AllTrim(STATE)")
    oInvoice["items"]        := getItemsInvoice(oInvoice)

    aAdd(aInvoices, oInvoice)

    oSql:skip()
  endDo

  oSql:close()
 
return aInvoices

/**
 * Retorna os itens de uma NF
 */
static function getItemsInvoice(oInvoice)

  local aItems := {}
  local cQuery := ""
  local oItem  := nil
  local oSql   := LibSqlObj():newLibSqlObj()

  cQuery := " SELECT "
  cQuery += "   D2_COD    [CODE], "
  cQuery += "   B1_DESC   [DESCRIPTION], "
  cQuery += "   D2_QUANT  [QUANTITY], "
  cQuery += "   D2_PRCVEN [PRICE], "
  cQuery += "   D2_TOTAL  [TOTAL], "
  cQuery += "   D2_CF     [CFOP] "
  cQuery += " FROM %SD2.SQLNAME% "
  cQuery += "   INNER JOIN %SB1.SQLNAME% ON "
  cQuery += "     %SB1.XFILIAL% AND B1_COD = D2_COD AND %SB1.NOTDEL% "
  cQuery += " WHERE %SD2.XFILIAL% AND D2_DOC = '" + oInvoice["number"] + "' AND "
  cQuery += "       D2_SERIE = '" + oInvoice["series"] + "' AND %SD2.NOTDEL% "
  cQuery += " ORDER BY D2_COD "

  oSql:newAlias(cQuery)

  while oSql:notIsEof()

    oItem                := JsonObject():new()
    oItem["code"]        := oSql:getValue("AllTrim(CODE)")
    oItem["description"] := oSql:getValue("AllTrim(DESCRIPTION)")
    oItem["quantity"]    := oSql:getValue("QUANTITY")
    oItem["price"]       := oSql:getValue("PRICE")
    oItem["total"]       := oSql:getValue("TOTAL")
    oItem["cfop"]        := oSql:getValue("AllTrim(CFOP)")

    aAdd(aItems, oItem)

    oSql:skip()
  endDo

  oSql:close()

return aItems

/**
 * Cria um arquivo para uma NF
 */
static function createInvoiceFile(oInvoice, oParamBox)

  local cXml    := ""
  local cFolder := AllTrim(oParamBox:getValue("folder"))
  local cNumber := AllTrim(oInvoice["number"]) 
  local cSeries := AllTrim(oInvoice["series"]) 
  local cFile   := cFolder + "\nfs_" + cNumber + "-" + cSeries + ".xml"
  local oFile   := LibFileObj():newLibFileObj(cFile)
  local oUtils  := LibUtilsObj():newLibUtilsObj()

  cXml := "<notafiscal>" + CRLF
  cXml += " <numero>" + oInvoice["number"] + "</numero>" + CRLF
  cXml += " <serie>" + oInvoice["series"] + "</serie>" + CRLF
  cXml += " <emissao>" + DtoC(oInvoice["date"]) + "</emissao>" + CRLF
  cXml += " <cliente>" + CRLF
  cXml += "  <cgc>" + oInvoice["cgc"] + "</cgc>" + CRLF
  cXml += "  <razaoSocial>" + oUtils:noAccent(oInvoice["customerName"]) + "</razaoSocial>" + CRLF
  cXml += "  <municipio>" + oInvoice["city"] + "</municipio>" + CRLF
  cXml += "  <uf>" + oInvoice["state"] + "</uf>" + CRLF
  cXml += " </cliente>" + CRLF
  cXml += "</notafiscal>" + CRLF

  oFile:writeLine(cXml)  

return
