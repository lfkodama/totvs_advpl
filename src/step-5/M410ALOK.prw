#include "totvs.ch"


/*/{Protheus.doc} M410ALOK

Valida��o das altera��es nos pedidos de vendas gerados pela tela MVC
    
@author fernandokodama
@since 10/11/2022
/*/
user function M410ALOK() 
  local cIsXmlGenerated := ""

  cIsXmlGenerated := SC5->C5_ZZMVCPD
  
  if cIsXmlGenerated == "S"
    if !hasPermission() 
      MsgInfo("O usu�rio n�o tem permiss�o para alterar esse pedido gerado via XML.")
      return .F.
    endIf  
  endIf
  
return .T.


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
