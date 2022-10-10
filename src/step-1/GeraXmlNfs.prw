#include "totvs.ch"


/*/{Protheus.doc} GeraXmlNfs

Geracao do XML de Notas Fiscais de Saida
	
@author soulsys:fernandokodama
@since 06/10/2022
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
  local cXml      := ""
  local cFolder   := AllTrim(oParamBox:getValue("folder"))
  local aInvoices := getInvoices(oParamBox)
  private nCount  := 0
  
  if !ExistDir(cFolder)
    MsgAlert("O diretório informado, " + cFolder + ", não existe. Verifique.", "Diretório do arquivo XML")
    return
  endIf

  for nI := 1 to Len(aInvoices)

    nCount ++
    cXml := createContentInvoice(aInvoices[nI], cFolder)
    createInvoiceFile(aInvoices[nI], cFolder, cXml)
    
  next nI

  if nCount > 0
    MsgInfo(AllTrim(Str(nCount)) + " arquivo(s) criado(s)", "Arquivos XML gerados")
  else
    MsgInfo("Nenhum arquivo gerado", "Arquivos XML gerados")  
  endIf

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
 * Trata o conteúdo do arquivo XML
 */
static function createContentInvoice(oInvoice, cFolder)

  local cXml    := ""
  local nI      := 0
  local aItems  := oInvoice["items"]
  local oItem   := nil
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
  cXml += " <items>" + CRLF
  
  for nI := 1 to Len(aItems)
  
    oItem := aItems[nI]
    
    cXml += "   <item>" + CRLF
    cXml += "     <codigo>" + oItem["code"] + "</codigo>" + CRLF
    cXml += "     <descricao>" + oItem["description"] + "</descricao>" + CRLF
    cXml += "     <quantidade>" + AllTrim(Str(oItem["quantity"],8,2)) + "</quantidade>" + CRLF
    cXml += "     <preco>" + AllTrim(Str(oItem["price"],8,2)) + "</preco>" + CRLF
    cXml += "     <total>" + AllTrim(Str(oItem["total"],8,2)) + "</total>" + CRLF
    cXml += "     <cfop>" + oItem["cfop"] + "</cfop>" + CRLF
    cXml += "   </item>" + CRLF
  
  next nI 
  
  cXml += " </items>" + CRLF
  cXml += "</notafiscal>" + CRLF

return cXml


/**
 * Cria um arquivo para uma NF
 */
static function createInvoiceFile(oInvoice, cFolder, cXml)

  local cNumber := AllTrim(oInvoice["number"]) 
  local cSeries := AllTrim(oInvoice["series"]) 
  local cFile   := cFolder + "\nfs_" + cNumber + "-" + cSeries + ".xml"
  local oFile   := LibFileObj():newLibFileObj(cFile)
  
  if oFile:exists(cFile)
    nAction := Aviso("Geração de arquivo XML", "O arquivo XML " + cFile + " para essa NF já existe. Deseja apagá-lo e criar novamente?", {"Sim", "Abortar"}, 1)
    if (nAction == 1)
        oFile:delete()
        oFile:writeLine(cXml)
    else
        nCount--
        return
    endIf      
  else
    if !oFile:writeLine(cXml)
      MsgInfo("Ocorreu um erro na geração do arquivo", "Geração de arquivo XML")
    endIf
  endIf 

return
