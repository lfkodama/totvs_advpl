#include "totvs.ch"


/*/{Protheus.doc} M410ALOK

Validação das alterações nos pedidos de vendas gerados pela tela MVC
    
@author fernandokodama
@since 10/10/2022
/*/
user function M410ALOK() 

  //if C5_ZZXML == "S"
  //hasPermission() 
  //else
  // msgerro
  //endIf
  
  
return MsgYesNo("Vai?")

static function hasPermission()

  local cUserId     := RetCodUsr()
  local lPermission := .F.

  
  
  If cUserId $ GetMV("ZZ_XMLUSER") 
    lPermission := .T.
  else
    lPermission := .F.
  endIf  
  
return lPermission
