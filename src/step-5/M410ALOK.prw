#include "totvs.ch"


/*/{Protheus.doc} M410ALOK

Validação das alterações nos pedidos de vendas gerados pela tela MVC
    
@author fernandokodama
@since 10/11/2022
/*/
user function M410ALOK() 
  local cIsXmlGenerated := ""

  cIsXmlGenerated := SC5->C5_ZZMVCPD
  
  if cIsXmlGenerated == "S"
    if !hasPermission() 
      MsgInfo("O usuário não tem permissão para alterar esse pedido gerado via XML.")
      return .F.
    endIf  
  endIf
  
return .T.


/**
 * Função para verificar se o usuário do parâmetro SX6 é o mesmo que está logado
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
