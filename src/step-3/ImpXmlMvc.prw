#include "totvs.ch"
#include "rwmake.ch"
#include "fwmvcdef.ch"

#define MVC_MODEL_STRUCT 1
#define MVC_VIEW_STRUCT 2

#define MVC_MAIN_ID       "ImpXmlMvc"
#define MVC_MODEL_ID      "mImpXml"
#define MVC_VIEW_ID       "vImpXml"
#define MVC_TITLE         "Importação de XML da NF"
#define MVC_ALIAS         "SZ1"
#define MVC_PRIMARY_KEY   {"Z1_FILIAL", "Z1_DOC", "Z1_SERIE"}
#define MVC_ITEMS_ALIASES {"SZ2"}
#define MVC_ITEMS_TITLES  {"Items de Produtos da NF"}
#define MVC_RELATIONS     {{{"Z2_FILIAL","Z1_FILIAL"},{"Z2_DOC","Z1_DOC"},{"Z2_SERIE","Z1_SERIE"}}}


/*/{Protheus.doc} ImpXmlMvc

MVC de Notas Fiscais importadas via XML
    
@author fernandokodama
@since 19/10/2022
/*/
user function ImpXmlMvc() 

  local oBrowse := FwMbrowse():new()
  
  oBrowse:setAlias(MVC_ALIAS)
  oBrowse:setDescription(MVC_TITLE)

  addBrowseLegends(oBrowse)

  oBrowse:activate()

return


/**
 * Opções do browse
 */
static function menuDef()

  local aOptions := {}
  local cViewId := "viewDef." + MVC_MAIN_ID

  aAdd(aOptions, {"Pesquisar", "PesqBrw", 0, 1})
  aAdd(aOptions, {"Visualizar", cViewId, 0, 2})
  aAdd(aOptions, {"Importar", "u_ImportXml", 0, 3})
  aAdd(aOptions, {"Gerar Pedido", "u_GerPedMvc", 0, 4})
  aAdd(aOptions, {"Excluir", cViewId, 0, 5})
  
return aOptions


/**
 * Modelagem
 */
static function modelDef()

  local nI          := 0     
  local cItemAlias  := ""
  local oItemStruct := nil
  local bValidModel := {|oModel| validModel(oModel)}
  local oModel      := MpFormModel():new(MVC_MODEL_ID, nil, bValidModel)
  local oMainStruct := FwFormStruct(MVC_MODEL_STRUCT, MVC_ALIAS)

  oModel:setDescription(MVC_TITLE)
  oModel:addFields(MVC_ALIAS, nil, oMainStruct)
  oModel:getModel(MVC_ALIAS):setDescription(MVC_TITLE)

  for nI := 1 to Len(MVC_ITEMS_ALIASES)
    
    cItemAlias   := MVC_ITEMS_ALIASES[nI]
    oItemStruct := FwFormStruct(MVC_MODEL_STRUCT, cItemAlias)

    oModel:addGrid(cItemAlias, MVC_ALIAS, oItemStruct)
    oModel:getModel(cItemAlias):setDescription(MVC_ITEMS_TITLES[nI])
    oModel:getModel(cItemAlias):setOptional(.T.)
    oModel:setRelation(cItemAlias, MVC_RELATIONS[nI], (cItemAlias)->(IndexKey(1)))

  next nI

  oModel:setPrimaryKey(MVC_PRIMARY_KEY)

return oModel


/**
 * Interface Visual
 */
static function viewDef()

  local nI           := 0
  local cSheet       := ""
  local cItemAlias   := ""
  local oItemsStruct := nil
  local oView        := FwFormView():new()
  local oModel       := FwLoadModel(MVC_MAIN_ID)
  local oMainStruct  := FwFormStruct(MVC_VIEW_STRUCT, MVC_ALIAS)    
  
  oView:setModel(oModel)
  oView:addField(MVC_ALIAS, oMainStruct, MVC_ALIAS)    
  oView:createHorizontalBox("box_top", 30)
  oView:createHorizontalBox("box_bottom", 70)
  oView:createFolder("folder", "box_bottom")    

  for nI := 1 to Len(MVC_ITEMS_ALIASES)

    cItemAlias   := MVC_ITEMS_ALIASES[nI]
    cSheet       := "sheet" + StrZero(nI, 2)
    cBoxFolder   := "boxFolderSheet" + StrZero(nI, 2)
    oItemsStruct := FwFormStruct(MVC_VIEW_STRUCT, cItemAlias)

    oView:addGrid(cItemAlias, oItemsStruct, cItemAlias)
    oView:addSheet("folder", cSheet, MVC_ITEMS_TITLES[nI])
    oView:createHorizontalBox(cBoxFolder, 100, , , "folder", cSheet)
    oView:setOwnerView(MVC_ALIAS, "box_top")
    oView:setOwnerView(cItemAlias, cBoxFolder)

  next nI 

return oView


/**
 * Validação do Model
 */
static function validModel(oActiveModel)     	   	 	        
return .T.


/**
 * Define as legendas do grid
 */
static function addBrowseLegends(oBrowse)
  oBrowse:addLegend("Z1_STATUS = '0'", "BR_AMARELO", "Aguardando processamento")
  oBrowse:addLegend("Z1_STATUS = '1'", "BR_VERDE", "Pedido processado")
  oBrowse:addLegend("Z1_STATUS = '2'", "BR_VERMELHO", "Erro de processamento")
return
