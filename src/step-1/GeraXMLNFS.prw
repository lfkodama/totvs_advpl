#include "totvs.ch"
#include "rwmake.ch"

#DEFINE CRLF chr(13)+chr(10)  // Constante para quebra de linha


User Function GeraXmlNfs()
    Local cTitle := "GeraXmlNfs"
    Private oParamBox  := LibParamBoxObj():newLibParamBoxObj(cTitle)
    Private oSql := LibSqlObj():NewLibSqlObj()


    // Chama a tela de entrada de parâmetros
    ParamsBox()
    
    // Monta e executa a query de busca dos dados das notas fiscais
    GetNfsData(oParamBox)

    // Monta a Header do arquivo XML
    setXmlFile(oSql)

Return


// Função para apresentar a tela de parâmetros para o usuário 
Static Function ParamsBox()
    Local oParam    := nil
    
    oParamBox:SetTitle("Parâmetros da Geração do XML")
    oParamBox:SetValidation({|| ApMsgYesNo("Confirma os parâmetros?")})  // Verificar no fonte o que é o "Ap" no ApMsgYesNo

    oParam := LibParamObj():NewLibParamObj("NfsIni","get","Nº da NF Inicial","C",9,9)
    oParam:SetF3("SF2")
    oParam:setValidation("Vazio() .or. ExistCpo('SF2')") // Analisar esse método setValidation
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)

    oParam := LibParamObj():NewLibParamObj("NfsFim","get","Nº da NF Final","C",9,9)
    oParam:SetF3("SF2")
    oParam:setValidation("Vazio() .or. ExistCpo('SF2')") // Analisar esse método setValidation
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)

    oParam := LibParamObj():NewLibParamObj("XmlPath", "file", "Selecione o caminho do arquivo", "C", 50)
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)
    
    If !oParamBox:Show()
        Return
    EndIf     
    
Return




// Função para buscar os dados das NFS
Static Function GetNfsData(oParamBox)
    Local cQuery := ""

    cQuery := " SELECT F2_DOC, F2_SERIE, F2_EMISSAO, F2_CLIENTE, A1_NOME, A1_MUN, A1_EST, A1_CGC "
    cQuery += "     FROM SF2990 SF2 "
    cQuery += "         LEFT JOIN SA1990 SA1 ON A1_COD = F2_CLIENTE AND A1_LOJA = F2_LOJA "
    cQuery += "     WHERE F2_DOC BETWEEN '" + oParamBox:getValue("NfsIni") + "' AND '" + oParamBox:getValue("NfsFim") + "' "
    cQuery += " ORDER BY F2_DOC ASC "

    oSql:newAlias(cQuery)
    oSql:setDateFields({"F2_EMISSAO"})

Return oSql


// Função para montar o conteúdo do arquivo XML
Static Function setXmlFile(oSql)
    Local cXmlHeader := ""
    Local cXmlFile := ""
    Local oXmlFile := Nil 


    while oSql:notIsEof()
        cXmlHeader := "<notafiscal>" + CRLF
        cXmlHeader += "<numero>" + oSql:getValue("F2_DOC") + "<numero>" + CRLF
        cXmlHeader += "<serie>" + AllTrim(oSql:getValue("F2_SERIE")) + "<serie>" + CRLF
        cXmlHeader += "<emissao>" + AllTrim(oSql:getValue("DToC(F2_EMISSAO)")) + "<emissao>" + CRLF
        cXmlHeader += "<cliente>" + CRLF
        cXmlHeader += "    <cgc>" + AllTrim(oSql:getValue("A1_CGC")) + "</cgc>" + CRLF
        cXmlHeader += "    <razaoSocial>" + AllTrim(oSql:getValue("A1_NOME")) + "</razaoSocial>" + CRLF
        cXmlHeader += "    <municipio>" + AllTrim(oSql:getValue("A1_MUN")) + "</municipio>" + CRLF
        cXmlHeader += "    <uf>" + AllTrim(oSql:getValue("A1_EST")) + "</uf>" + CRLF
        cXmlHeader += "</cliente>"
        
        // Monta o path e nome do arquivo XML
        cXmlFile := AllTrim(oParamBox:getValue("XmlPath")) + "\" + AllTrim(oSql:getValue("F2_DOC")) + "-" + AllTrim(oSql:getValue("F2_SERIE")) + ".xml"
        oXmlFile := LibFileObj():newLibFileObj(cXmlFile)

        // Grava o conteúdo do XML
        oXmlFile:writeLine(cXmlHeader)


        oSql:skip()
    EndDo

    oSql:close()

Return cXmlHeader




