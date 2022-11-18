#include "totvs.ch"

/*/{Protheus.doc} MvcReport

Gera��o de relat�rio anal�tico/sint�tico a partir do Browse MVC
    
@author fernandokodama
@since 17/11/2022
/*/
user function MvcReport()
  
  local oParamBox := paramBox()
  local oUtils    := LibUtilsObj():newLibUtilsObj()

  if oParamBox:show()
    oUtils:msgRun({ || generateReport(oParambox) }, "Gerando relat�rio ...", "Gera��o de Relat�rio de Notas Fiscais")
  endIf

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


static function generateReport(oParamBox)

return
