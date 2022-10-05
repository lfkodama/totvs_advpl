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

  for nI := to Len(aInvoices)
    createInvoiceFile(aInvoices[nI])
  next nI

return

/**
 * Obtem as notas fiscais
 */
static function getInvoices(oParamBox)

  local aInvoices := {}
 
return aInvoices

/**
 * Cria um arquivo para uma NF
 */
static function createInvoiceFile(oInvoice)

  

return
