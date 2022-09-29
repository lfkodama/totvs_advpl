#include "totvs.ch"
#include "rwmake.ch"

#DEFINE CRLF chr(13)+chr(10)  // Constante para quebra de linha

User Function GeraXmlNfs()
    Local cTitle := "GeraXmlNfs"
    Private oParamBox  := LibParamBoxObj():newLibParamBoxObj(cTitle)
    Private oSql := LibSqlObj():NewLibSqlObj()
    
    // Chama a tela de entrada de par�metros
    ParamsBox()
    
    // Monta e executa a query de busca dos dados das notas fiscais
    GetNfsData(oParamBox)

    // Monta a Header do arquivo XML
    setXmlFile(oSql)

Return


// Fun��o para apresentar a tela de par�metros para o usu�rio 
Static Function ParamsBox()
    Local oParam    := nil
    
    oParamBox:SetTitle("Par�metros da Gera��o do XML")
    oParamBox:SetValidation({|| ApMsgYesNo("Confirma os par�metros?")})  // Verificar no fonte o que � o "Ap" no ApMsgYesNo

    oParam := LibParamObj():NewLibParamObj("NfsIni","get","N� da NF Inicial","C",9,9)
    oParam:SetF3("SF2")
    oParam:setValidation("Vazio() .or. ExistCpo('SF2')") // Analisar esse m�todo setValidation
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)

    oParam := LibParamObj():NewLibParamObj("NfsFim","get","N� da NF Final","C",9,9)
    oParam:SetF3("SF2")
    oParam:setValidation("Vazio() .or. ExistCpo('SF2')") // Analisar esse m�todo setValidation
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)

    oParam := LibParamObj():NewLibParamObj("XmlPath", "file", "Selecione o caminho do arquivo", "C", 50)
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)
    
    If !oParamBox:Show()
        Return
    EndIf     
    
Return


// Fun��o para buscar os dados do cabe�alho das NFS
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


// Fun��o para buscar os dados dos items das NFS
Static Function GetNfsItems(oSql)
    Local cQuery := ""

    cQuery := " SELECT D2_ITEM, D2_COD, D2_UM, B1_DESC, D2_QUANT, D2_PRCVEN, D2_TOTAL, D2_CF "
    cQuery += "     FROM SD2990 SD2 "
    cQuery += "         LEFT JOIN SB1990 SB1 ON B1_COD = D2_COD "
    cQuery += "     WHERE D2_DOC = '" + AllTrim(oSql:getValue("F2_DOC")) + "' AND D2_SERIE = '" + AllTrim(oSql:getValue("F2_SERIE")) + "' " 
    cQuery += " ORDER BY D2_DOC, D2_ITEM ASC "
    
    oSql2:newAlias(cQuery)

Return oSql2


// Fun��o para montar o conte�do do arquivo XML
Static Function setXmlFile(oSql)
    Local cXmlHeader := ""
    Local cXmlBody := ""
    Local cXmlFile := ""
    Local oXmlFile := Nil 
    Private oSql2 := LibSqlObj():NewLibSqlObj()
    
    // Monta a se��o de cabe�alho do arquivo XML
    while oSql:notIsEof()
        cXmlHeader := "<notafiscal>" + CRLF
        cXmlHeader += "<numero>" + oSql:getValue("F2_DOC") + "</numero>" + CRLF
        cXmlHeader += "<serie>" + AllTrim(oSql:getValue("F2_SERIE")) + "</serie>" + CRLF
        cXmlHeader += "<emissao>" + AllTrim(oSql:getValue("DToC(F2_EMISSAO)")) + "</emissao>" + CRLF
        cXmlHeader += "<cliente>" + CRLF
        cXmlHeader += "    <cgc>" + AllTrim(oSql:getValue("A1_CGC")) + "</cgc>" + CRLF
        cXmlHeader += "    <razaoSocial>" + AllTrim(oSql:getValue("A1_NOME")) + "</razaoSocial>" + CRLF
        cXmlHeader += "    <municipio>" + AllTrim(oSql:getValue("A1_MUN")) + "</municipio>" + CRLF
        cXmlHeader += "    <uf>" + AllTrim(oSql:getValue("A1_EST")) + "</uf>" + CRLF
        cXmlHeader += "</cliente>" + CRLF
        cXmlHeader += "<items>"
        
        // Monta o path e nome do arquivo XML
        cXmlFile := AllTrim(oParamBox:getValue("XmlPath")) + "\" + AllTrim(oSql:getValue("F2_DOC")) + "-" + AllTrim(oSql:getValue("F2_SERIE")) + ".xml"
        oXmlFile := LibFileObj():newLibFileObj(cXmlFile)

        // Grava o conte�do do XML
        oXmlFile:writeLine(cXmlHeader)

        // Busca os items da NF e monta as tags XML
        GetNfsItems(oSql)

        // Monta a se��o dos items de produtos da NFS no arquivo XML
        while oSql2:notIsEof()
            cXmlBody += "    <item>" + CRLF
            cXmlBody += "       <codigo>" + AllTrim(oSql2:getValue("D2_COD")) + "</codigo>" + CRLF
            cXmlBody += "       <descricao>" + AllTrim(oSql2:getValue("B1_DESC")) + "</descricao>" + CRLF
            cXmlBody += "       <quantidade>" + AllTrim(Str(oSql2:getValue("D2_QUANT"),6,2)) + "</quantidade>" + CRLF
            cXmlBody += "       <preco>" + AllTrim(Str(oSql2:getValue("D2_PRCVEN"),8,2)) + "</preco>" + CRLF
            cXmlBody += "       <total>" + AllTrim(Str(oSql2:getValue("D2_TOTAL"),8,2)) + "</total>" + CRLF
            cXmlBody += "       <cfop>" + AllTrim(oSql2:getValue("D2_CF")) + "</cfop>" + CRLF
            cXmlBody += "    </item>" + CRLF
            oSql2:skip()
        EndDo
        oSql2:close()

        cXmlBody += "</items>" + CRLF
        cXmlBody += "</notafiscal>" 
        oXmlFile:writeLine(cXmlBody)
        cXmlBody = ""

        oSql:skip()
        
    EndDo

    oSql:close()

Return
