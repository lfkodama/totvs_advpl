#include "totvs.ch"

/*/{Protheus.doc} MvcReport

Geração de relatório analítico/sintético a partir do Browse MVC
    
@author fernandokodama
@since 17/11/2022
/*/
user function MvcReport()
  
  local oParamBox := paramBox()
  local oUtils    := LibUtilsObj():newLibUtilsObj()

  if oParamBox:show()
    oUtils:msgRun({ || generateReport(oParambox) }, "Gerando relatório ...", "Geração de Relatório de Notas Fiscais")
  endIf

return


/**
 * Cria a tela de interface com o usuário
 */
static function paramBox()
  
  local oParam    := nil 
  local oParamBox := LibParamBoxObj():newLibParamBoxObj("MvcReport")

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

  oParam := LibParamObj():newLibParamObj("option", "combo", "Tipo do Relatório", "C", 60)
  oParam:setValues({"A=Analítico","S=Sintético"})
  oParamBox:addParam(oParam)    

  oParamBox:addParam(oParam)

return oParamBox


static function generateReport(oParamBox)

return
