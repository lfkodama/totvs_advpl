#include "totvs.ch"
#include "rwmake.ch"

#DEFINE CRLF chr(13)+chr(10)  // Constante para quebra de linha

User Function GeraXmlNfs()
    Local cTitle       := "GeraXmlNfs"
    Local lDir         := .T.
    Local lError       := .F.
    Private oParamBox  := LibParamBoxObj():newLibParamBoxObj(cTitle)
    Private oSql       := LibSqlObj():NewLibSqlObj()
    
    If !ParamsBox()
        Return
    EndIf 
    
    // Verifica se o diretório informado existe
    lDir := ExistDir(AllTrim(oParamBox:getValue("XmlPath")))
    If !lDir
        lError := .T.
        MessageBox("O diretório informado, " + AllTrim(oParamBox:getValue("XmlPath")) + ", não existe. Verifique.", "Diretório de geração do arquivo XML", 48)
        Return
    EndIf

    GetNfsData(oParamBox)

    If !createXmlFile(oSql)
        lError := .T.
    EndIf

    If lError == .F.
        MessageBox("Arquivos gerados com sucesso", "Confirmação de geração de arquivos", 64)
    EndIf 
Return


// Função para apresentar a tela de parâmetros para o usuário 
Static Function ParamsBox()
    Local oParam    := nil
    
    oParamBox:SetTitle("Parâmetros da Geração do XML")
    oParamBox:SetValidation({|| ApMsgYesNo("Confirma os parâmetros?")})  // Verificar no fonte o que é o "Ap" no ApMsgYesNo

    oParam := LibParamObj():NewLibParamObj("NfsIni","get","Nº da NF Inicial","C",9,9)
    oParam:SetF3("SF2")
    oParamBox:AddParam(oParam)

    oParam := LibParamObj():NewLibParamObj("NfsFim","get","Nº da NF Final","C",9,9)
    oParam:SetF3("SF2")
    oParamBox:AddParam(oParam)

    oParam := LibParamObj():newLibParamObj("DatIni", "get", "Data de Emissão Inicial", "D", 10, 8) 
	oParam:setRequired(.T.)
	oParamBox:addParam(oParam)
	
	oParam := LibParamObj():newLibParamObj("DatFim", "get", "Data de Emissão Final", "D", 10, 8)
	oParam:setRequired(.T.) 
	oParamBox:addParam(oParam)

    oParam := LibParamObj():NewLibParamObj("XmlPath", "file", "Selecione o caminho do arquivo", "C", 50)
    oParam:setRequired(.T.)
    oParamBox:AddParam(oParam)
        
Return oParamBox:Show()


// Função para buscar os dados do cabeçalho das NFS
Static Function GetNfsData(oParamBox)
    Local cQuery := ""

    cQuery := " SELECT F2_DOC, F2_SERIE, F2_EMISSAO, F2_CLIENTE, A1_NOME, A1_MUN, A1_EST, A1_CGC "
    cQuery += "     FROM %SF2.SQLNAME% "
    cQuery += "         LEFT JOIN %SA1.SQLNAME% ON %SA1.XFILIAL% AND A1_COD = F2_CLIENTE AND A1_LOJA = F2_LOJA AND %SA1.NOTDEL% "
    cQuery += "     WHERE %SF2.XFILIAL% AND "
    cQuery += "           F2_EMISSAO BETWEEN '" + DtoS(oParamBox:getValue("DatIni")) + "' AND '" + DtoS(oParamBox:getValue("DatFim")) + "' AND "
    cQuery += "           F2_DOC BETWEEN '" + oParamBox:getValue("NfsIni") + "' AND '" + oParamBox:getValue("NfsFim") + "' AND %SF2.NOTDEL% "
    cQuery += " ORDER BY F2_DOC ASC "

    oSql:newAlias(cQuery)
    oSql:setDateFields({"F2_EMISSAO"})
Return oSql


// Função para buscar os dados dos items das NFS
Static Function GetNfsItems(oSql)
    Local cQuery := ""

    cQuery := " SELECT D2_ITEM, D2_COD, D2_UM, B1_DESC, D2_QUANT, D2_PRCVEN, D2_TOTAL, D2_CF "
    cQuery += "     FROM %SD2.SQLNAME% "
    cQuery += "         LEFT JOIN %SB1.SQLNAME% ON %SB1.XFILIAL% AND B1_COD = D2_COD AND %SB1.NOTDEL% "
    cQuery += "     WHERE %SD2.XFILIAL% AND D2_DOC = '" + AllTrim(oSql:getValue("F2_DOC")) + "' AND D2_SERIE = '" + AllTrim(oSql:getValue("F2_SERIE")) + "' AND %SD2.NOTDEL%  " 
    cQuery += " ORDER BY D2_DOC, D2_ITEM ASC "
    
    oSql2:newAlias(cQuery)

Return oSql2


// Função para montar o conteúdo do arquivo XML
Static Function createXmlFile(oSql)
    nAction := 0
    Local cXmlHeader := ""
    Local cXmlBody := ""
    Local cXmlFile := ""
    Local oXmlFile := Nil
    Local lError := .F. 
    Private oSql2 := LibSqlObj():NewLibSqlObj()
    
    // Monta a seção de cabeçalho do arquivo XML
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
        cXmlFile := AllTrim(oParamBox:getValue("XmlPath")) + "\nfs_" + AllTrim(oSql:getValue("F2_DOC")) + "-" + AllTrim(oSql:getValue("F2_SERIE")) + ".xml"
       
        // Cria o arquivo XML
        oXmlFile := LibFileObj():newLibFileObj(cXmlFile)
       
        // Verifica se o XML da NFS já existe. Caso existir, pergunta se o usuário deseja apagar o arquivo e gerar um novo, ou finalizar.
        If !oXmlFile:exists(cXmlFile)
            
            // Grava o conteúdo do XML
            if !oXmlFile:writeLine(cXmlHeader)
                lError := .T.
                MessageBox(lError, "Deu erro na gravação", 48)
                return lError
            Endif

            // Busca os items da NF e monta as tags XML
            GetNfsItems(oSql)

            // Monta a seção dos items de produtos da NFS no arquivo XML
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
            if !oXmlFile:writeLine(cXmlBody)
                lError := .T.
                Alert("Falha ao gravar o arquivo " + cXmlFile)
                return .F.
            Endif
            cXmlBody = ""

            oSql:skip()    
        Else
            nAction := Aviso("Geração do XML da NFS", "O arquivo XML " + cXmlFile + " para essa NF já existe. Deseja apagá-lo e criar novamente?", {"Apagar arquivos", "Finalizar"}, 1)
            if (nAction == 1)
                If !oXmlFile:writeline()  // Verifica se o arquivo está aberto para edição
                    MessageBox("O arquivo está em uso por outra aplicação. Verifique e tente novamente.", "Geração de Arquivo XML", 48)  
                else
                    oXmlFile:delete()
                EndIf        
            Elseif (nAction == 2)
                oSql:skip() 
            EndIf      
        EndIf    

    EndDo
   
    oSql:close() 
  
Return .T.
