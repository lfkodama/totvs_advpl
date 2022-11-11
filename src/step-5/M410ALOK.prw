#include "totvs.ch"


/*/{Protheus.doc} M410ALOK

Valida��o das altera��es nos pedidos de vendas gerados pela tela MVC
    
@author fernandokodama
@since 10/10/2022
/*/
user function M410ALOK() 
  local cError := ""
  local cIsXmlGenerated := ""

  SC5->(DbSeek(FWxFilial('SC5') + SC5->C5_NUM))
  
  cIsXmlGenerated := SC5->C5_ZZMVCPD
  
  if cIsXmlGenerated == "S"
    if !hasPermission() 
      cError := "O usu�rio n�o tem permiss�o para alterar esse pedido gerado via XML."
      MsgInfo(cError)
      return
    endIf  
  endIf
  
return 

/**
 * Fun��o para verificar se o usu�rio do par�metro SX6 � o mesmo que est� logado
 */
static function hasPermission()

  local cUserId     := RetCodUsr()
  local lPermission := .F.
  
  if cUserId $ GetMV("ZZ_XMLUSR") 
    lPermission := .T.
  else
    lPermission := .F.
  endIf  
  
return lPermission
