#! praat
# 
# Plot vowels into a vowel triangle
#
# Unless specified otherwise:
#
# Copyright: 2017-2018, R.J.J.H. van Son and the Netherlands Cancer Institute
# License: GNU GPL v2 or later
# email: r.j.j.h.vanson@gmail.com, r.v.son@nki.nl
# 
#     VowelTriangle.praat: Praat script to practice vowel pronunciation 
#     
#     Copyright (C) 2017  R.J.J.H. van Son and the Netherlands Cancer Institute
# 
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
# 
#
# Initialization
# Get current Locale
uiLanguage$ = "EN"
.defaultLanguage = 1
.preferencesLanguageFile$ = preferencesDirectory$+"/VowelTriangle.prefs"
.preferencesLang$ = ""
if fileReadable(.preferencesLanguageFile$)
	.preferencesLang$ = readFile$(.preferencesLanguageFile$)
	if index_regex(.preferencesLang$, "Language\s*=\s*([^\n]+)") > 0
		.preferencesLang$ = replace_regex$(.preferencesLang$, "^.*Language=([^\n]+).*", "\L\1", 0)
	else
		.preferencesLang$ = ""
	endif
endif

.locale$ = "en"
if .preferencesLang$ <> ""
	.locale$ = .preferencesLang$
else
	if macintosh
		.scratch$ = replace_regex$(temporaryDirectory$+"/scratch"+date$()+".txt", "[^\w.]", "_", 0)
		runSystem_nocheck: "defaults read -g AppleLocale | cut -c 1-2 - > ",.scratch$
		.locale$ = readFile$(.scratch$)
		deleteFile: .scratch$
	elsif unix
		.locale$ = environment$("LANG")
	elsif windows
		.scratch$ = replace_regex$(temporaryDirectory$+"/scratch"+date$()+".txt", "[^\w.]", "_", 0)
		runSystem_nocheck: "dism /online /get-intl > ",.scratch$
		.locale$ = readFile$(.scratch$)
		.locale$ = replace_regex$(.locale$, "\n", " ", 0)	
		.locale$ = replace_regex$(.locale$, "^.*Default System UI language : ([^\s]+).*", "\1", 0)
		deleteFile: .scratch$	
	endif
endif

if startsWith(.locale$, "en")
	uiLanguage$ = "EN"
	.defaultLanguage = 1
elsif startsWith(.locale$, "nl")
	uiLanguage$ = "NL"
	.defaultLanguage = 2
elsif startsWith(.locale$, "de")
	uiLanguage$ = "DE"
	.defaultLanguage = 3
elsif startsWith(.locale$, "fr")
	uiLanguage$ = "FR"
	.defaultLanguage = 4
elsif startsWith(.locale$, "zh")
	uiLanguage$ = "ZH"
	.defaultLanguage = 5
elsif startsWith(.locale$, "es")
	uiLanguage$ = "ES"
	.defaultLanguage = 6
elsif startsWith(.locale$, "pt")
	uiLanguage$ = "PT"
	.defaultLanguage = 7
elsif startsWith(.locale$, "it")
	uiLanguage$ = "IT"
	.defaultLanguage = 8
#elsif startsWith(.locale$, "MYLANGUAGE")
#	uiLanguage$ = "XX"
#	.defaultLanguage = 9
endif

.sp_default = 1
output_table$ = ""

default_Dot_Radius = 0.01
dot_Radius_Cutoff = 300
# 
#######################################################################
# 
# Enter valid file path in input_file$ to run non-interactive
#
#input_file$ = "concatlist.tsv"
#input_file$ = "chunkslist.tsv"
input_file$ = ""

input_table = -1
.continue = 1
#
# The input table should have tab separated columns labeled: 
# Title, Speaker, File, Language, Log, Plotfile
# An example would be a tab separated list:
# F40L2VT2 F IFAcorpus/chunks/F40L/F40L2VT1.aifc NL target/results.tsv target/F40L2VT2.png
# All files are used AS IS, and nothing is drawn unless a "Plotfile" is entered
#
if input_file$ <> "" and fileReadable(input_file$) and index_regex(input_file$, "(?i\.(tsv|Table))")
	input_table = Read Table from tab-separated file: input_file$
	.numRows = Get number of rows
	.i = Get column index: "Log"
	if .i <= 0
		Append column: "Log"
		for .r to .numRows
			Set string value: .r, "Log", "-"
		endfor
	endif 
	.i = Get column index: "Plotfile"
	if .i <= 0
		Append column: "Plotfile"
		for .r to .numRows
			Set string value: .r, "Plotfile", "-"
		endfor
	endif 
endif

# When using a microphone:
.input$ = "Microphone"
.samplingFrequency = 44100
.recordingTime = 4

# Define Language
# Add new targets if necessary
phonLanguage$ = "NL"
numVowels = 12
vowelList$ [1] = "i"
vowelList$ [2] = "I"
vowelList$ [3] = "e"
vowelList$ [4] = "E"
vowelList$ [5] = "a"
vowelList$ [6] = "A"
vowelList$ [7] = "O"
vowelList$ [8] = "o"
vowelList$ [9] = "u"
vowelList$ [10] = "y"
vowelList$ [11] = "Y"
vowelList$ [12] = "@"

color$ ["a"] = "Red"
color$ ["i"] = "Green"
color$ ["u"] = "Blue"
color$ ["@"] = "{0.8,0.8,0.8}"

# UI messages and texts

# English
uiMessage$ ["EN", "PauseRecord"] = "Record continuous speech"
uiMessage$ ["EN", "Record1"] = "Record the ##continuous speech#"
uiMessage$ ["EN", "Record2"] = "Please be ready to start"
uiMessage$ ["EN", "Record3"] = "Select the speech you want to analyse"
uiMessage$ ["EN", "Open1"] = "Open the recording containing the speech"
uiMessage$ ["EN", "Open2"] = "Select the speech you want to analyse"
uiMessage$ ["EN", "Corneri"] = "h##ea#t"
uiMessage$ ["EN", "Corneru"] = "h##oo#t"
uiMessage$ ["EN", "Cornera"] = "h##a#t"
uiMessage$ ["EN", "DistanceTitle"] = "Rel. Distance (N)"
uiMessage$ ["EN", "AreaTitle"] = "Rel. Area"
uiMessage$ ["EN", "Area1"] = "1"
uiMessage$ ["EN", "Area2"] = "2"
uiMessage$ ["EN", "AreaN"] = "N"

uiMessage$ ["EN", "LogFile"] = "Write log to table (""-"" write to the info window)"
uiMessage$ ["EN", "CommentContinue"] = "Click on ""Continue"" if you want to analyze more speech samples"
uiMessage$ ["EN", "CommentOpen"] = "Click on ""Open"" and select a recording"
uiMessage$ ["EN", "CommentRecord"] = "Click on ""Record"" and start speaking"
uiMessage$ ["EN", "CommentList"] = "Record sound, ""Save to list & Close"", then click ""Continue"""
uiMessage$ ["EN", "SavePicture"] = "Save picture"
uiMessage$ ["EN", "DoContinue"] = "Do you want to continue?"
uiMessage$ ["EN", "SelectSound1"] = "Select the sound and continue"
uiMessage$ ["EN", "SelectSound2"] = "It is possible to remove unwanted sounds from the selection"
uiMessage$ ["EN", "SelectSound3"] = "Select the unwanted part and then chose ""Cut"" from the ""Edit"" menu"
uiMessage$ ["EN", "Stopped"] = "Vowel Triangle stopped"
uiMessage$ ["EN", "ErrorSound"] = "Error: Not a sound "
uiMessage$ ["EN", "Nothing to do"] = "Nothing to do"
uiMessage$ ["EN", "No readable recording selected "] = "No readable recording selected "

uiMessage$ ["EN", "Interface Language"] = "Language"
uiMessage$ ["EN", "Speaker is a"] = "Speaker is a"
uiMessage$ ["EN", "Male"] = "Male ♂"
uiMessage$ ["EN", "Female"] = "Female ♀"
uiMessage$ ["EN", "Continue"] = "Continue"
uiMessage$ ["EN", "Done"] = "Done"
uiMessage$ ["EN", "Stop"] = "Stop"
uiMessage$ ["EN", "Open"] = "Open"
uiMessage$ ["EN", "Record"] = "Record"

# Dutch
uiMessage$ ["NL", "PauseRecord"] 	= "Neem lopende spraak op"
uiMessage$ ["NL", "Record1"] 		= "Neem de ##lopende spraak# op"
uiMessage$ ["NL", "Record2"] 		= "Zorg dat u klaar ben om te spreken"
uiMessage$ ["NL", "Record3"] 		= "Selecteer de spraak die u wilt analyseren"
uiMessage$ ["NL", "Open1"] 			= "Open de spraakopname"
uiMessage$ ["NL", "Open2"] 			= "Selecteer de spraak die u wilt analyseren"
uiMessage$ ["NL", "Corneri"] 		= "h##ie#t"
uiMessage$ ["NL", "Corneru"] 		= "h##oe#d"
uiMessage$ ["NL", "Cornera"] 		= "h##aa#t"
uiMessage$ ["NL", "DistanceTitle"] 	= "Rel. Afstand (N)"
uiMessage$ ["NL", "AreaTitle"] 		= "Rel. Oppervlak"
uiMessage$ ["NL", "Area1"] 			= "1"
uiMessage$ ["NL", "Area2"] 			= "2"
uiMessage$ ["NL", "AreaN"] 			= "N"

uiMessage$ ["NL", "LogFile"] 		= "Schrijf resultaten naar log bestand (""-"" schrijft naar info venster)"
uiMessage$ ["NL", "CommentContinue"] = "Klik op ""Doorgaan"" als u meer spraakopnamen wilt analyseren"
uiMessage$ ["NL", "CommentOpen"] 	= "Klik op ""Open"" en selecteer een opname"
uiMessage$ ["NL", "CommentRecord"] 	= "Klik op ""Opnemen"" en start met spreken"
uiMessage$ ["NL", "CommentList"] 	= "Spraak opnemen, ""Save to list & Close"", daarna klik op ""Doorgaan"""
uiMessage$ ["NL", "SavePicture"] 	= "Bewaar afbeelding"
uiMessage$ ["NL", "DoContinue"] 	= "Wilt u doorgaan?"
uiMessage$ ["NL", "SelectSound1"] 	= "Selecteer het spraakfragment en ga door"
uiMessage$ ["NL", "SelectSound2"] 	= "Het is mogelijk om ongewenste geluiden uit de opname te verwijderen"
uiMessage$ ["NL", "SelectSound3"] 	= "Selecteer het ongewenste deel en kies ""Cut"" in het ""Edit"" menu"
uiMessage$ ["NL", "Stopped"] 		= "Vowel Triangle is gestopt"
uiMessage$ ["NL", "ErrorSound"] 	= "Fout: Dit is geen geluid "
uiMessage$ ["NL", "Nothing to do"] 	= "Geen taken"
uiMessage$ ["NL", "No readable recording selected "] = "Geen leesbare opname geselecteerd "

uiMessage$ ["NL", "Interface Language"] = "Taal (Language)"
uiMessage$ ["NL", "Speaker is a"] 	= "De Spreker is een"
uiMessage$ ["NL", "Male"] 			= "Man ♂"
uiMessage$ ["NL", "Female"] 		= "Vrouw ♀"
uiMessage$ ["NL", "Continue"] 		= "Doorgaan"
uiMessage$ ["NL", "Done"] 			= "Klaar"
uiMessage$ ["NL", "Stop"] 			= "Stop"
uiMessage$ ["NL", "Open"] 			= "Open"
uiMessage$ ["NL", "Record"] 		= "Opnemen"

# German
uiMessage$ ["DE", "PauseRecord"] 	= "Zeichne laufende Sprache auf"
uiMessage$ ["DE", "Record1"] 		= "Die ##laufende Sprache# aufzeichnen"
uiMessage$ ["DE", "Record2"] 		= "Bitte seien Sie bereit zu sprechen"
uiMessage$ ["DE", "Record3"] 		= "Wählen Sie die Sprachaufnahme, die Sie analysieren möchten"
uiMessage$ ["DE", "Open1"] 			= "Öffnen Sie die Sprachaufnahme"
uiMessage$ ["DE", "Open2"] 			= "Wählen Sie die Sprachaufnahme, die Sie analysieren möchten"
uiMessage$ ["DE", "Corneri"] 		= "L##ie#d"
uiMessage$ ["DE", "Corneru"] 		= "H##u#t"
uiMessage$ ["DE", "Cornera"] 		= "T##a#l"
uiMessage$ ["DE", "DistanceTitle"] 	= "Rel. Länge (N)"
uiMessage$ ["DE", "AreaTitle"] 		= "Rel. Oberfläche"
uiMessage$ ["DE", "Area1"] 			= "1"
uiMessage$ ["DE", "Area2"] 			= "2"
uiMessage$ ["DE", "AreaN"] 			= "N"
                                     
uiMessage$ ["DE", "LogFile"] 		= "Daten in Tabelle schreiben (""-"" in das Informationsfenster schreiben)"
uiMessage$ ["DE", "CommentContinue"]= "Klicken Sie auf ""Weiter"", wenn Sie mehr Sprachproben analysieren möchten"
uiMessage$ ["DE", "CommentOpen"] 	= "Klicke auf ""Öffnen"" und wähle eine Aufnahme"
uiMessage$ ["DE", "CommentRecord"] 	= "Klicke auf ""Aufzeichnen"" und sprich"
uiMessage$ ["DE", "CommentList"] 	= "Sprache aufnehmen, ""Save to list & Close"", dann klicken Sie auf ""Weitergehen"""
uiMessage$ ["DE", "SavePicture"] 	= "Bild speichern"
uiMessage$ ["DE", "DoContinue"] 	= "Möchten Sie weitergehen?"
uiMessage$ ["DE", "SelectSound1"] 	= "Wählen Sie den Aufnahmebereich und gehen Sie weiter"
uiMessage$ ["DE", "SelectSound2"] 	= "Es ist möglich, unerwünschte Geräusche aus der Auswahl zu entfernen"
uiMessage$ ["DE", "SelectSound3"] 	= "Wählen Sie den unerwünschten Teil und wählen Sie dann ""Cut"" aus dem ""Edit"" Menü"
uiMessage$ ["DE", "Stopped"] 		= "VowelTriangle ist gestoppt"
uiMessage$ ["DE", "ErrorSound"] 	= "Fehler: Keine Sprache gefunden"
uiMessage$ ["DE", "Nothing to do"] 	= "Keine Aufgaben"
uiMessage$ ["DE", "No readable recording selected "] = "Keine verwertbare Aufnahme ausgewählt "
               
uiMessage$ ["DE", "Interface Language"] = "Sprache (Language)"
uiMessage$ ["DE", "Speaker is a"] 	= "Der Sprecher ist ein(e)"
uiMessage$ ["DE", "Male"] 			= "Man ♂"
uiMessage$ ["DE", "Female"] 		= "Frau ♀"
uiMessage$ ["DE", "Continue"] 		= "Weitergehen"
uiMessage$ ["DE", "Done"] 			= "Fertig"
uiMessage$ ["DE", "Stop"] 			= "Halt"
uiMessage$ ["DE", "Open"] 			= "Öffnen"
uiMessage$ ["DE", "Record"] 		= "Aufzeichnen"

# French
uiMessage$ ["FR", "PauseRecord"]	= "Enregistrer un discours continu"
uiMessage$ ["FR", "Record1"]		= "Enregistrer le ##discours continu#"
uiMessage$ ["FR", "Record2"]		= "S'il vous plaît soyez prêt à commencer"
uiMessage$ ["FR", "Record3"]		= "Sélectionnez le discours que vous voulez analyser"
uiMessage$ ["FR", "Open1"]			= "Ouvrir l'enregistrement contenant le discours"
uiMessage$ ["FR", "Open2"]			= "Sélectionnez le discours que vous voulez analyser"
uiMessage$ ["FR", "Corneri"]		= "s##i#"
uiMessage$ ["FR", "Corneru"]		= "f##ou#"
uiMessage$ ["FR", "Cornera"]		= "l##à#"
uiMessage$ ["FR", "DistanceTitle"]	= "Longeur Relative (N)"
uiMessage$ ["FR", "AreaTitle"]		= "Surface Relative"
uiMessage$ ["FR", "Area1"]			= "1"
uiMessage$ ["FR", "Area2"]			= "2"
uiMessage$ ["FR", "AreaN"]			= "N"
                                     
uiMessage$ ["FR", "LogFile"]		= "Écrire un fichier journal dans une table (""-"" écrire dans la fenêtre d'information)"
uiMessage$ ["FR", "CommentContinue"]= "Cliquez sur ""Continuer"" si vous voulez analyser plus d'échantillons de discours"
uiMessage$ ["FR", "CommentOpen"]	= "Cliquez sur ""Ouvrir"" et sélectionnez un enregistrement"
uiMessage$ ["FR", "CommentRecord"]	= "Cliquez sur ""Enregistrer"" et commencez à parler"
uiMessage$ ["FR", "CommentList"]	= "Enregistrer le son, ""Save to list & Close"", puis cliquez sur ""Continuer"""
uiMessage$ ["FR", "SavePicture"]	= "Enregistrer l'image"
uiMessage$ ["FR", "DoContinue"]		= "Voulez-vous continuer?"
uiMessage$ ["FR", "SelectSound1"]	= "Sélectionnez le son et continuez"
uiMessage$ ["FR", "SelectSound2"]	= "Il est possible de supprimer les sons indésirables de la sélection"
uiMessage$ ["FR", "SelectSound3"]	= "Sélectionnez la partie indésirable, puis choisissez ""Cut"" dans le menu ""Edit"""
uiMessage$ ["FR", "Stopped"]		= "VowelTriangle s'est arrêté"
uiMessage$ ["FR", "ErrorSound"]		= "Erreur: pas du son"
uiMessage$ ["FR", "Nothing to do"] 	= "Rien à faire"
uiMessage$ ["FR", "No readable recording selected "] = "Aucun enregistrement utilisable sélectionné "
                  
uiMessage$ ["FR", "Interface Language"] = "Langue (Language)"
uiMessage$ ["FR", "Speaker is a"]	= "Le locuteur est un(e)"
uiMessage$ ["FR", "Male"] 			= "Homme ♂"
uiMessage$ ["FR", "Female"] 		= "Femme ♀"
uiMessage$ ["FR", "Continue"]		= "Continuer"
uiMessage$ ["FR", "Done"]			= "Terminé"
uiMessage$ ["FR", "Stop"]			= "Arrêt"
uiMessage$ ["FR", "Open"]			= "Ouvert"
uiMessage$ ["FR", "Record"]			= "Enregistrer"

# Chinese
uiMessage$ ["ZH", "PauseRecord"] = "录音连续演讲"
uiMessage$ ["ZH", "Record1"] = "录音##连续演讲#"
uiMessage$ ["ZH", "Record2"] = "请准备好开始"
uiMessage$ ["ZH", "Record3"] = "选择你想要分析的语音"
uiMessage$ ["ZH", "Open1"] = "打开包含演讲的录音"
uiMessage$ ["ZH", "Open2"] = "选择你想要分析的语音"
uiMessage$ ["ZH", "Corneri"] = "必"
uiMessage$ ["ZH", "Corneru"] = "不"
uiMessage$ ["ZH", "Cornera"] = "巴"
uiMessage$ ["ZH", "DistanceTitle"] = "相对长度 (N)"
uiMessage$ ["ZH", "AreaTitle"] = "相对表面"
uiMessage$ ["ZH", "Area1"] = "1"
uiMessage$ ["ZH", "Area2"] = "2"
uiMessage$ ["ZH", "AreaN"] = "N"

uiMessage$ ["ZH", "LogFile"] 		= "将日志写入表格 (""-"" 写入信息窗口)"
uiMessage$ ["ZH", "CommentContinue"] = "点击 ""继续"" 如果你想分析更多的语音样本"
uiMessage$ ["ZH", "CommentOpen"] 	= "点击 ""打开录音"" 并选择一个录音"
uiMessage$ ["ZH", "CommentRecord"] 	= "点击 ""录制演讲"" 并开始讲话"
uiMessage$ ["ZH", "CommentList"] 	= "录制声音, ""Save to list & Close"", 然后单击 ""继续"""
uiMessage$ ["ZH", "SavePicture"] 	= "保存图片"
uiMessage$ ["ZH", "DoContinue"] 	= "你想继续吗"
uiMessage$ ["ZH", "SelectSound1"] 	= "选择声音并继续"
uiMessage$ ["ZH", "SelectSound2"] 	= "可以从选择中删除不需要的声音"
uiMessage$ ["ZH", "SelectSound3"] 	= "选择不需要的部分，然后选择 ""Cut"" 从 ""编辑"" 菜单"
uiMessage$ ["ZH", "Stopped"] 		= "VowelTriangle 停了下来"
uiMessage$ ["ZH", "ErrorSound"] 	= "错误：没有声音"
uiMessage$ ["ZH", "Nothing to do"] 	= "无事可做"
uiMessage$ ["ZH", "No readable recording selected "] = "没有选择可读的录音 "

uiMessage$ ["ZH", "Interface Language"] = "语言 (Language)"
uiMessage$ ["ZH", "Speaker is a"]	= "演讲者是"
uiMessage$ ["ZH", "Male"] = "男性 ♂"
uiMessage$ ["ZH", "Female"] = "女性 ♀"
uiMessage$ ["ZH", "Continue"] = "继续"
uiMessage$ ["ZH", "Done"] = "准备"
uiMessage$ ["ZH", "Stop"] = "结束"
uiMessage$ ["ZH", "Open"] = "打开录音"
uiMessage$ ["ZH", "Record"] = "录制演讲"


# Spanish
uiMessage$ ["ES", "PauseRecord"]	= "Grabar un discurso continuo"
uiMessage$ ["ES", "Record1"]		= "Guardar ##discurso continuo#"
uiMessage$ ["ES", "Record2"]		= "Por favor, prepárate para comenzar"
uiMessage$ ["ES", "Record3"]		= "Seleccione el discurso que quiere analizar"
uiMessage$ ["ES", "Open1"]			= "Abre la grabación que contiene el discurso"
uiMessage$ ["ES", "Open2"]			= "Seleccione el discurso que quiere analizar"
uiMessage$ ["ES", "Corneri"]		= "s##i#"
uiMessage$ ["ES", "Corneru"]		= "##u#so"
uiMessage$ ["ES", "Cornera"]		= "h##a#"
uiMessage$ ["ES", "DistanceTitle"]	= "Longitud relativa (N)"
uiMessage$ ["ES", "AreaTitle"]		= "Superficie relativa"
uiMessage$ ["ES", "Area1"]			= "1"
uiMessage$ ["ES", "Area2"]			= "2"
uiMessage$ ["ES", "AreaN"]			= "N"
                                      
uiMessage$ ["ES", "LogFile"]		= "Escribir un archivo de registro en una tabla (""-"" escribir en la ventana de información)"
uiMessage$ ["ES", "CommentContinue"]= "Haga clic en ""Continúa"" si desea analizar más muestras de voz"
uiMessage$ ["ES", "CommentOpen"]	= "Haga clic en ""Abrir"" y seleccione un registro"
uiMessage$ ["ES", "CommentRecord"]	= "Haz clic en ""Grabar"" y comienza a hablar"
uiMessage$ ["ES", "CommentList"]	= "Grabar sonido, ""Save to list & Close"", luego haga clic en ""Continúa"""
uiMessage$ ["ES", "SavePicture"]	= "Guardar imagen"
uiMessage$ ["ES", "DoContinue"]		= "¿Quieres continuar?"
uiMessage$ ["ES", "SelectSound1"]	= "Selecciona el sonido y continúa"
uiMessage$ ["ES", "SelectSound2"]	= "Es posible eliminar sonidos no deseados de la selección"
uiMessage$ ["ES", "SelectSound3"]	= "Seleccione la parte no deseada, luego elija ""Cut"" desde el menú ""Edit"""
uiMessage$ ["ES", "Stopped"]		= "VowelTriangle se ha detenido"
uiMessage$ ["ES", "ErrorSound"]		= "Error: no hay sonido"
uiMessage$ ["ES", "Nothing to do"] 	= "Nada que hacer"
uiMessage$ ["ES", "No readable recording selected "] = "No se ha seleccionado ningún registro utilizable "

uiMessage$ ["ES", "Interface Language"] = "Idioma (Language)"
uiMessage$ ["ES", "Speaker is a"]	= "El hablante es un(a)"
uiMessage$ ["ES", "Male"] 			= "Hombre ♂"
uiMessage$ ["ES", "Female"] 		= "Mujer ♀"
uiMessage$ ["ES", "Continue"]		= "Continúa"
uiMessage$ ["ES", "Done"]			= "Terminado"
uiMessage$ ["ES", "Stop"]			= "Detener"
uiMessage$ ["ES", "Open"]			= "Abrir"
uiMessage$ ["ES", "Record"]			= "Grabar"

# Portugese
uiMessage$ ["PT", "PauseRecord"]	= "Gravar um discurso contínuo"
uiMessage$ ["PT", "Record1"]		= "Salvar ##discurso contínua#"
uiMessage$ ["PT", "Record2"]		= "Por favor, prepare-se para começar"
uiMessage$ ["PT", "Record3"]		= "Selecione o discurso que deseja analisar"
uiMessage$ ["PT", "Open1"]			= "Abra a gravação que contém o discurso"
uiMessage$ ["PT", "Open2"]			= "Selecione o discurso que deseja analisar"
uiMessage$ ["PT", "Corneri"]		= "s##i#"
uiMessage$ ["PT", "Corneru"]		= "r##u#a"
uiMessage$ ["PT", "Cornera"]		= "d##á#"
uiMessage$ ["PT", "DistanceTitle"]	= "Comprimento relativo (N)"
uiMessage$ ["PT", "AreaTitle"]		= "Superfície relativa"
uiMessage$ ["PT", "Area1"]			= "1"
uiMessage$ ["PT", "Area2"]			= "2"
uiMessage$ ["PT", "AreaN"]			= "N"
                                                                            
uiMessage$ ["PT", "LogFile"]		= "Escreva um arquivo de registro em uma tabela (""-"" escreva na janela de informações)"
uiMessage$ ["PT", "CommentContinue"]= "Clique em ""Continuar"" se quiser analisar mais amostras de voz"
uiMessage$ ["PT", "CommentOpen"]	= "Clique em ""Abrir"" e selecione um registro"
uiMessage$ ["PT", "CommentRecord"]	= "Clique ""Gravar"" e comece a falar "
uiMessage$ ["PT", "CommentList"]	= "Gravar som, ""Save to list & Close"", depois clique em ""Continuar"""
uiMessage$ ["PT", "SavePicture"]	= "Salvar imagem"
uiMessage$ ["PT", "DoContinue"]		= "Você quer continuar?"
uiMessage$ ["PT", "SelectSound1"]	= "Selecione o som e continue"
uiMessage$ ["PT", "SelectSound2"]	= "É possível remover sons indesejados da seleção"
uiMessage$ ["PT", "SelectSound3"]	= "Selecione a parte indesejada, então escolha ""Cut"" no menu ""Edit"""
uiMessage$ ["PT", "Stopped"]		= "VowelTriangle parou"
uiMessage$ ["PT", "ErrorSound"]		= "Erro: não há som"
uiMessage$ ["PT", "Nothing to do"] 	= "Nada para fazer"
uiMessage$ ["PT", "No readable recording selected "] = "Nenhum registro utilizável foi selecionado"

uiMessage$ ["PT", "Interface Language"] = "Idioma (Language)"
uiMessage$ ["PT", "Speaker is a"]	= "O falante é um(a)"
uiMessage$ ["PT", "Male"] 			= "Homem ♂"
uiMessage$ ["PT", "Female"] 		= "Mulher ♀"
uiMessage$ ["PT", "Continue"]		= "Continuar"
uiMessage$ ["PT", "Done"]			= "Terminado"
uiMessage$ ["PT", "Stop"]			= "Pare"
uiMessage$ ["PT", "Open"]			= "Abrir"
uiMessage$ ["PT", "Record"]			= "Gravar"

# Italian
uiMessage$ ["IT", "PauseRecord"]	= "Registra un discorso continuo"
uiMessage$ ["IT", "Record1"]		= "Salva ##discorso continuo#"
uiMessage$ ["IT", "Record2"]		= "Per favore, preparati a iniziare"
uiMessage$ ["IT", "Record3"]		= "Seleziona il discorso che vuoi analizzare"
uiMessage$ ["IT", "Open1"]			= "Apri la registrazione che contiene il discorso"
uiMessage$ ["IT", "Open2"]			= "Seleziona il discorso che vuoi analizzare"
uiMessage$ ["IT", "Corneri"]		= "s##ì#"
uiMessage$ ["IT", "Corneru"]		= "##u#si"
uiMessage$ ["IT", "Cornera"]		= "sar##à#"
uiMessage$ ["IT", "DistanceTitle"]	= "Lunghezza relativa (N)"
uiMessage$ ["IT", "AreaTitle"]		= "Superficie relativa"
uiMessage$ ["IT", "Area1"]			= "1"
uiMessage$ ["IT", "Area2"]			= "2"
uiMessage$ ["IT", "AreaN"]			= "N"
                                                                            
uiMessage$ ["IT", "LogFile"]		= "Scrivi un file di registrazione in una tabella (""-"" scrivi nella finestra delle informazioni)"
uiMessage$ ["IT", "CommentContinue"]= "Clicca su ""Continua"" se vuoi analizzare più campioni vocali"
uiMessage$ ["IT", "CommentOpen"]	= "Fare clic su ""Apri"" e selezionare un record"
uiMessage$ ["IT", "CommentRecord"]	= "Fai clic su ""Registra"" e inizia a parlare"
uiMessage$ ["IT", "CommentList"]	= "Registra suono, ""Save to list & Close"", quindi fai clic su ""Continua"""
uiMessage$ ["IT", "SavePicture"]	= "Salva immagine"
uiMessage$ ["IT", "DoContinue"]		= "Vuoi continuare?"
uiMessage$ ["IT", "SelectSound1"]	= "Seleziona il suono e continua"
uiMessage$ ["IT", "SelectSound2"]	= "È possibile rimuovere i suoni indesiderati dalla selezione"
uiMessage$ ["IT", "SelectSound3"]	= "Seleziona la parte indesiderata, quindi scegli ""Cut"" dal menu ""Edit"""
uiMessage$ ["IT", "Stopped"]		= "VowelTriangle si è fermato"
uiMessage$ ["IT", "ErrorSound"]		= "Errore: non c'è suono"
uiMessage$ ["IT", "Nothing to do"] 	= "Niente da fare"
uiMessage$ ["IT", "No readable recording selected "] = "Nessun record utilizzabile è stato selezionato "

uiMessage$ ["IT", "Interface Language"] = "Lingua (Language)"
uiMessage$ ["IT", "Speaker is a"]	= "L‘oratore è un(a)"
uiMessage$ ["IT", "Male"] 			= "Uomo ♂"
uiMessage$ ["IT", "Female"] 		= "Donna ♀"
uiMessage$ ["IT", "Continue"]		= "Continua"
uiMessage$ ["IT", "Done"]			= "Finito"
uiMessage$ ["IT", "Stop"]			= "Fermare"
uiMessage$ ["IT", "Open"]			= "Apri"
uiMessage$ ["IT", "Record"]			= "Registra"

#############################################################
#
# To add a new interface language, translate the text below
# and substitute in the correct places. Keep the double quotes "" intact
# Replace the "EN" in the ''uiMessage$ ["EN",'' to the code you
# need. Then add the new language in the options (following "English" etc.)
# and the code following the endPause below.
#
# "Record continuous speech"
# "Record the ##continuous speech#"
# "Please be ready to start"
# "Select the speech you want to analyse"
# "Open the recording containing the speech"
# "Select the speech you want to analyse"
# "h##ea#t"
# "h##oo#t"
# "h##a#t"
# "Rel. Distance (N)"
# "Rel. Area"
# "1"
# "2"
# "N"

# "Write log to table (""-"" write to the info window)"
# "Click on ""Continue"" if you want to analyze more speech samples"
# "Click on ""Open"" and select a recording"
# "Click on ""Record"" and start speaking"
# "Record sound, ""Save to list & Close"", then click ""Continue"""
# "Save picture"
# "Do you want to continue?"
# "Select the sound and continue"
# "It is possible to remove unwanted sounds from the selection"
# "Select the unwanted part and then chose ""Cut"" from the ""Edit"" menu"
# "Vowel Triangle stopped"
# "Error: Not a sound "
# "Nothing to do"
# "No readable recording selected "

# "Language"
# "Speaker is a"
# "Male"
# "Female"
# "Continue"
# "Done"
# "Stop"
# "Open"
# "Record"
#
##############################################################

# Formant values

# Male 
phonemes [phonLanguage$, "M", "i_corner", "F1"] = 250
phonemes [phonLanguage$, "M", "i_corner", "F2"] = 2100
phonemes [phonLanguage$, "M", "a_corner", "F1"] = 850
phonemes [phonLanguage$, "M", "a_corner", "F2"] = 1290
phonemes [phonLanguage$, "M", "u_corner", "F1"] = 285
phonemes [phonLanguage$, "M", "u_corner", "F2"] = 650
# @_center is not fixed but derived from current corners
phonemes [phonLanguage$, "M", "@_center", "F1"] =(phonemes [phonLanguage$, "M", "i_corner", "F1"]*phonemes [phonLanguage$, "M", "u_corner", "F1"]*phonemes [phonLanguage$, "M", "a_corner", "F1"])^(1/3)
phonemes [phonLanguage$, "M", "@_center", "F2"] = (phonemes [phonLanguage$, "M", "i_corner", "F2"]*phonemes [phonLanguage$, "M", "u_corner", "F2"]*phonemes [phonLanguage$, "M", "a_corner", "F2"])^(1/3)

# Formant values according to 
# IFA corpus averages from FPA isolated vowels
# Using Split-Levinson algorithm
phonemes [phonLanguage$, "M", "A", "F1"] = 695.6000
phonemes [phonLanguage$, "M", "A", "F2"] = 1065.500
phonemes [phonLanguage$, "M", "E", "F1"] = 552.5000
phonemes [phonLanguage$, "M", "E", "F2"] = 1659.200
phonemes [phonLanguage$, "M", "I", "F1"] = 378.0909
phonemes [phonLanguage$, "M", "I", "F2"] = 1868.545
phonemes [phonLanguage$, "M", "O", "F1"] = 482.9000
phonemes [phonLanguage$, "M", "O", "F2"] = 725.800
phonemes [phonLanguage$, "M", "Y", "F1"] = 417.7000
phonemes [phonLanguage$, "M", "Y", "F2"] = 1455.100
phonemes [phonLanguage$, "M", "Y:", "F1"] = 386.3000
phonemes [phonLanguage$, "M", "Y:", "F2"] = 1492.400
phonemes [phonLanguage$, "M", "a", "F1"] = 788.6000
phonemes [phonLanguage$, "M", "a", "F2"] = 1290.600
phonemes [phonLanguage$, "M", "au", "F1"] = 583.8000
phonemes [phonLanguage$, "M", "au", "F2"] = 959.300
phonemes [phonLanguage$, "M", "e", "F1"] = 372.3000
phonemes [phonLanguage$, "M", "e", "F2"] = 1959.700
phonemes [phonLanguage$, "M", "ei", "F1"] = 499.5000
phonemes [phonLanguage$, "M", "ei", "F2"] = 1733.000
phonemes [phonLanguage$, "M", "i", "F1"] = 259.5556
phonemes [phonLanguage$, "M", "i", "F2"] = 1971.889
phonemes [phonLanguage$, "M", "o", "F1"] = 426.7000
phonemes [phonLanguage$, "M", "o", "F2"] = 743.600
phonemes [phonLanguage$, "M", "u", "F1"] = 287.5000
phonemes [phonLanguage$, "M", "u", "F2"] = 666.500
phonemes [phonLanguage$, "M", "ui", "F1"] = 495.3000
phonemes [phonLanguage$, "M", "ui", "F2"] = 1468.600
phonemes [phonLanguage$, "M", "y", "F1"] = 268.4000
phonemes [phonLanguage$, "M", "y", "F2"] = 1581.400
# Guessed
phonemes [phonLanguage$, "M", "@", "F1"] = 417.7000
phonemes [phonLanguage$, "M", "@", "F2"] = 1455.100

# Female
phonemes [phonLanguage$, "F", "i_corner", "F1"] = 280
phonemes [phonLanguage$, "F", "i_corner", "F2"] = 2200
phonemes [phonLanguage$, "F", "a_corner", "F1"] = 900
phonemes [phonLanguage$, "F", "a_corner", "F2"] = 1435
phonemes [phonLanguage$, "F", "u_corner", "F1"] = 370
phonemes [phonLanguage$, "F", "u_corner", "F2"] = 700
# @_center is not fixed but derived from current corners
phonemes [phonLanguage$, "F", "@_center", "F1"] =(phonemes [phonLanguage$, "F", "i_corner", "F1"]*phonemes [phonLanguage$, "F", "u_corner", "F1"]*phonemes [phonLanguage$, "F", "a_corner", "F1"])^(1/3)
phonemes [phonLanguage$, "F", "@_center", "F2"] = (phonemes [phonLanguage$, "F", "i_corner", "F2"]*phonemes [phonLanguage$, "F", "u_corner", "F2"]*phonemes [phonLanguage$, "F", "a_corner", "F2"])^(1/3)

# Formant values according to 
# IFA corpus average from FPA isolated vowels
# Using Split-Levinson algorithm
phonemes [phonLanguage$, "F", "A", "F1"] = 817.7000
phonemes [phonLanguage$, "F", "A", "F2"] = 1197.300
phonemes [phonLanguage$, "F", "E", "F1"] = 667.9000
phonemes [phonLanguage$, "F", "E", "F2"] = 1748.500
phonemes [phonLanguage$, "F", "I", "F1"] = 429.2222
phonemes [phonLanguage$, "F", "I", "F2"] = 1937.333
phonemes [phonLanguage$, "F", "O", "F1"] = 570.8000
phonemes [phonLanguage$, "F", "O", "F2"] = 882.100
phonemes [phonLanguage$, "F", "Y", "F1"] = 495.7000
phonemes [phonLanguage$, "F", "Y", "F2"] = 1635.600
phonemes [phonLanguage$, "F", "Y:", "F1"] = 431.1000
phonemes [phonLanguage$, "F", "Y:", "F2"] = 1695.100
phonemes [phonLanguage$, "F", "a", "F1"] = 853.6000
phonemes [phonLanguage$, "F", "a", "F2"] = 1435.800
phonemes [phonLanguage$, "F", "au", "F1"] = 647.6000
phonemes [phonLanguage$, "F", "au", "F2"] = 1056.700
phonemes [phonLanguage$, "F", "e", "F1"] = 429.9000
phonemes [phonLanguage$, "F", "e", "F2"] = 1861.700
phonemes [phonLanguage$, "F", "ei", "F1"] = 619.9000
phonemes [phonLanguage$, "F", "ei", "F2"] = 1718.500
phonemes [phonLanguage$, "F", "i", "F1"] = 294.3000
phonemes [phonLanguage$, "F", "i", "F2"] = 1855.000
phonemes [phonLanguage$, "F", "o", "F1"] = 527.5000
phonemes [phonLanguage$, "F", "o", "F2"] = 894.100
phonemes [phonLanguage$, "F", "u", "F1"] = 376.0000
phonemes [phonLanguage$, "F", "u", "F2"] = 735.200
phonemes [phonLanguage$, "F", "ui", "F1"] = 612.8000
phonemes [phonLanguage$, "F", "ui", "F2"] = 1559.200
phonemes [phonLanguage$, "F", "y", "F1"] = 321.2000
phonemes [phonLanguage$, "F", "y", "F2"] = 1741.700
# Guessed
phonemes [phonLanguage$, "F", "@", "F1"] = 500.5
phonemes [phonLanguage$, "F", "@", "F2"] = 1706.6

# Run as a non interactive program
if input_table > 0
	selectObject: input_table
	.numInputRows = Get number of rows
	for .r to .numInputRows
		selectObject: input_table
		title$ = Get value: .r, "Title"
		# Skip rows that are commented out
		if startsWith(title$, "#")
			goto NEXTROW
		endif
		.sp$ = Get value: .r, "Speaker"
		file$ = Get value: .r, "File"
		tmp$ = Get value: .r, "Language"
		if index(tmp$, "[A-Z]{2}")
			uiLanguage$ = tmp$
		endif
		.log$ = Get value: .r, "Log"
		if index_regex(.log$, "[\w]")
			log = 1
			output_table$ = .log$
			if not fileReadable(output_table$)
				writeFileLine: output_table$, "Name", tab$, "Speaker", tab$, "N", tab$, "Area2", tab$, "Area1", tab$, "i.dist", tab$, "u.dist", tab$, "a.dist", tab$, "Duration", tab$, "Intensity"
			endif
		else
			log = 0
			output_table$ = "-"
		endif
		
		.plotFile$ = Get value: .r, "Plotfile"
		.plotVowels = 0
		if index_regex(.plotFile$, "\w") <= 0
			.plotFile$ = ""
		else
			.plotVowels = 1
		endif

		# Handle cases where there is a wildcard
		if file$ <> "" and index_regex(file$, "[*]{1}") and index_regex(file$, "(?i\.(wav|mp3|aif[fc]))")
			.preFix$ = ""
			if index(file$, "/") > 0
				.preFix$ = replace_regex$(file$, "/[^/]+$", "/", 0)
			endif
			.fileList = Create Strings as file list: "FileList", file$
			.numFiles = Get number of strings
			.sound = -1
			for .f to .numFiles
				selectObject: .fileList
				.fileName$ = Get string: .f

				.tmp = Read from file: .preFix$ + .fileName$
				if .tmp <= 0 or numberOfSelected("Sound") <= 0
					exitScript: "Not a valid Sound file"
				endif
				name$ = selected$("Sound")
				.soundPart = Convert to mono
				selectObject: .tmp
				Remove
				
				if .sound > 0
					selectObject: .sound, .soundPart
					.tmp = Concatenate
					.duration = Get total duration
					.intensity = Get intensity (dB)
					selectObject: .sound, .soundPart
					Remove
					.sound = .tmp
					.tmp = -1
				else
					.sound = .soundPart
				endif
			endfor
			selectObject: .fileList
			Remove
		elsif file$ <> "" and fileReadable(file$) and index_regex(file$, "(?i\.(wav|mp3|aif[fc]))")
			tmp = Read from file: file$
			if tmp <= 0 or numberOfSelected("Sound") <= 0
				exitScript: "Not a valid Sound file"
			endif
			name$ = selected$("Sound")
			.sound = Convert to mono
			.duration = Get total duration
			.intensity = Get intensity (dB)
			Rename: name$
			selectObject(tmp)
			Remove
		else
			exitScript: "Not a valid file"
		endif
		
		if .plotVowels
			Erase all
			call set_up_Canvas
			call plot_vowel_triangle '.sp$'
			Text special... 0.5 Centre 1.05 bottom Helvetica 18 0 ##'title$'#
		endif
		@plot_vowels: .plotVowels, .sp$, .sound
		@print_output_line: title$, .sp$, plot_vowels.numVowelIntervals, plot_vowels.area2perc, plot_vowels.area1perc, plot_vowels.relDist_i, plot_vowels.relDist_u, plot_vowels.relDist_a, .duration, .intensity

		if index_regex(.plotFile$, "\w")
			Save as 300-dpi PNG file: .plotFile$
		endif
		
		selectObject: .sound
		Remove
		
		label NEXTROW
	endfor
	selectObject: input_table
	Remove
	
	exitScript: "Ready"
endif

# Run master loop
while .continue
	
	.speakerIsA$ = uiMessage$ [uiLanguage$, "Speaker is a"]
	.speakerIsAVar$ = replace_regex$(.speakerIsA$, "^([A-Z])", "\l\1", 0)
	.speakerIsAVar$ = replace_regex$(.speakerIsAVar$, "\s*\(.*$", "", 0)
	.speakerIsAVar$ = replace_regex$(.speakerIsAVar$, "[\s.?!()/\\\\]", "_", 0)
	.languageInput$ = uiMessage$ [uiLanguage$, "Interface Language"]
	.languageInputVar$ = replace_regex$(.languageInput$, "^([A-Z])", "\l\1", 0)
	.languageInputVar$ = replace_regex$(.languageInputVar$, "\s*\(.*$", "", 0)
	.languageInputVar$ = replace_regex$(.languageInputVar$, "[\s.?!()/\\\\]", "_", 0)

	.recording = 0
	beginPause: "Select a recording"
		sentence: "Title", "untitled"
		comment: uiMessage$ [uiLanguage$, "CommentOpen"]
		comment: uiMessage$ [uiLanguage$, "CommentRecord"]
		choice: .speakerIsA$, .sp_default
			option: uiMessage$ [uiLanguage$, "Female"]
			option: uiMessage$ [uiLanguage$, "Male"]
		optionMenu: .languageInput$, .defaultLanguage
			option: "English"
			option: "Nederlands"
			option: "Deutsch"
			option: "Français"
			option: "汉语"
			option: "Español"
			option: "Português"
			option: "Italiano"
		#   option: "MyLanguage"
		boolean: "Log", (output_table$ <> "")
	.clicked = endPause: (uiMessage$ [uiLanguage$, "Stop"]), (uiMessage$ [uiLanguage$, "Record"]), (uiMessage$ [uiLanguage$, "Open"]), 3, 1	
	if .clicked = 1
		.continue = 0
		.message$ = uiMessage$ [uiLanguage$, "Nothing to do"]
		@exitVowelTriangle: .message$
	elsif .clicked = 2
		.recording = 1
	endif

	.sp$ = "M"
	.sp_default = 2
	if uiMessage$ [uiLanguage$, "Female"] = '.speakerIsAVar$'$
		.sp$ = "F"
		.sp_default = 1
	endif
	
	uiLanguage$ = "EN"
	.defaultLanguage = 1
	.display_language$ = '.languageInputVar$'$
	if .display_language$ = "Nederlands"
		uiLanguage$ = "NL"
		.defaultLanguage = 2
	elsif .display_language$ = "Deutsch"
		uiLanguage$ = "DE"
		.defaultLanguage = 3
	elsif .display_language$ = "Français"
		uiLanguage$ = "FR"
		.defaultLanguage = 4
	elsif .display_language$ = "汉语"
		uiLanguage$ = "ZH"
		.defaultLanguage = 5
	elsif .display_language$ = "Español"
		uiLanguage$ = "ES"
		.defaultLanguage = 6
	elsif .display_language$ = "Português"
		uiLanguage$ = "PT"
		.defaultLanguage = 7
	elsif .display_language$ = "Italiano"
		uiLanguage$ = "IT"
		.defaultLanguage = 8
	#
	# Add a new language
	# elsif .display_language$ = "MyLanguage"
	#	uiLanguage$ = "MyCode"
	#	.defaultLanguage = 9
	endif
	
	# Store preferences
	writeFileLine: .preferencesLanguageFile$, "Language=",uiLanguage$
	
	# Start
	if log and output_table$ = ""
		Erase all
		Select inner viewport: 0.5, 7.5, 0.5, 4.5
		Axes: 0, 1, 0, 1
		Blue
		Text special: 0, "left", 0.65, "half", "Helvetica", 16, "0", uiMessage$ [uiLanguage$, "LogFile"]
		
		output_table$ = chooseWriteFile$: uiMessage$ [uiLanguage$, "LogFile"], replace_regex$(uiMessage$ [uiLanguage$, "LogFile"], "^[^\(]+", "", 0) + " -"
		if endsWith(output_table$, "-")
			output_table$ = "-"
		endif
		# Print output
		if output_table$ = "-"
			clearinfo
			appendInfoLine: "Name", tab$, "Speaker", tab$, "N", tab$, "Area2", tab$, "Area1", tab$, "i.dist", tab$, "u.dist", tab$, "a.dist", tab$, "Duration", tab$, "Intensity"
		elsif index_regex(output_table$, "\w") and not fileReadable(output_table$)
			writeFileLine: output_table$, "Name", tab$, "Speaker", tab$, "N", tab$, "Area2", tab$, "Area1", tab$, "i.dist", tab$, "u.dist", tab$, "a.dist", tab$, "Duration", tab$, "Intensity"
		endif
	endif
	
	# Write instruction
	Erase all
	Select inner viewport: 0.5, 7.5, 0.5, 4.5
	Axes: 0, 1, 0, 1
	Blue
	if .recording
		Text special: 0, "left", 0.65, "half", "Helvetica", 16, "0", uiMessage$ [uiLanguage$, "Record1"]
		Text special: 0, "left", 0.45, "half", "Helvetica", 16, "0", uiMessage$ [uiLanguage$, "Record2"]	
	else
		Text special: 0, "left", 0.65, "half", "Helvetica", 16, "0", uiMessage$ [uiLanguage$, "Record3"]
	endif
	Black
	
	# Open sound and select
	.open1$ = uiMessage$ [uiLanguage$, "Open1"]
	.open2$ = uiMessage$ [uiLanguage$, "Open2"]
	@read_and_select_audio: .recording, .open1$ , .open2$
	.sound = read_and_select_audio.sound
	if title$ = "untitled"
		title$ = replace_regex$(read_and_select_audio.filename$, "\.[^\.]+$", "", 0)
		title$ = replace_regex$(title$, "^.*/([^/]+)$", "\1", 0)
		title$ = replace_regex$(title$, "_", " ", 0)
	endif
		
	# Draw vowel triangle
	Erase all
	call set_up_Canvas
	call plot_vowel_triangle '.sp$'
	Text special... 0.5 Centre 1.05 bottom Helvetica 18 0 ##'title$'#
	
	selectObject: .sound
	.duration = Get total duration
	.intensity = Get intensity (dB)
	if .intensity > 50
		@plot_vowels: 1, .sp$, .sound, 
		@print_output_line: title$, .sp$, plot_vowels.numVowelIntervals, plot_vowels.area2perc, plot_vowels.area1perc, plot_vowels.relDist_i, plot_vowels.relDist_u, plot_vowels.relDist_a, .duration, .intensity
	endif
	
	selectObject: .sound
	Remove
	
	
	# Save graphics
	.file$ = chooseWriteFile$: uiMessage$ [uiLanguage$, "SavePicture"], title$+"_VowelTriangle.png"
	if .file$ <> ""
		Save as 300-dpi PNG file: .file$
	endif
	
	# Ready or not?
	beginPause: uiMessage$ [uiLanguage$, "DoContinue"]
		comment: uiMessage$ [uiLanguage$, "CommentContinue"]
	.clicked = endPause: (uiMessage$ [uiLanguage$, "Continue"]), (uiMessage$ [uiLanguage$, "Done"]), 2, 2
	.continue = (.clicked = 1)
	
endwhile

#####################################################################

procedure read_and_select_audio .type .message1$ .message2$
	if .type
		Record mono Sound...
		beginPause: (uiMessage$ [uiLanguage$, "PauseRecord"])
			comment: uiMessage$ [uiLanguage$, "CommentList"]
		.clicked = endPause: (uiMessage$ [uiLanguage$, "Stop"]), (uiMessage$ [uiLanguage$, "Continue"]), 2, 1
		if .clicked = 1
			@exitVowelTriangle: (uiMessage$ [uiLanguage$, "Stopped"])
		endif
		if numberOfSelected("Sound") <= 0
			@exitVowelTriangle: (uiMessage$ [uiLanguage$, "ErrorSound"])
		endif
		.source = selected ("Sound")
		.filename$ = "Recorded speech"
	else
		.filename$ = chooseReadFile$: .message1$
		if .filename$ = "" or not fileReadable(.filename$) or not index_regex(.filename$, "(?i\.(wav|mp3|aif[fc]))")
			@exitVowelTriangle: (uiMessage$ [uiLanguage$, "No readable recording selected "])+.filename$
		endif
		
		.source = Open long sound file: .filename$
		.filename$ = selected$("LongSound")
		.fullName$ = selected$()
		.fileType$ = extractWord$ (.fullName$, "")
		if .fileType$ <> "Sound" and .fileType$ <> "LongSound"
			@exitVowelTriangle:  (uiMessage$ [uiLanguage$, "ErrorSound"])+.filename$
		endif
	endif
	
	selectObject: .source
	.fullName$ = selected$()
	.duration = Get total duration
	if startsWith(.fullName$, "Sound") 
		View & Edit
	else
		View
	endif
	editor: .source
	endeditor
	beginPause: .message2$
		comment: (uiMessage$ [uiLanguage$, "SelectSound1"])
		comment: (uiMessage$ [uiLanguage$, "SelectSound2"])
		comment: (uiMessage$ [uiLanguage$, "SelectSound3"])
	.clicked = endPause: (uiMessage$ [uiLanguage$, "Stop"]), (uiMessage$ [uiLanguage$, "Continue"]), 2, 1
	if .clicked = 1
		@exitVowelTriangle: (uiMessage$ [uiLanguage$, "Stopped"])
	endif
	
	editor: .source
		.start = Get start of selection
		.end = Get end of selection
		if .start >= .end
			Select: 0, .duration
		endif
		Extract selected sound (time from 0)
	endeditor
	.tmp = selected ()
	if .tmp <= 0
		selectObject: .source
		.duration = Get total duration
		.tmp = Extract part: 0, .duration, "yes"
	endif
	
	# Recordings can be in Stereo, change to mono
	selectObject: .tmp
	.sound = Convert to mono
	selectObject: .tmp, .source
	Remove

	selectObject: .sound
	Rename: .filename$
endproc

# Set up Canvas
procedure set_up_Canvas
	Select outer viewport: 0, 8, 0, 8
	Select inner viewport: 0.75, 7.25, 0.75, 7.25
	Axes: 0, 1, 0, 1
	Solid line
	Black
	Line width: 1.0
endproc

# Plot the vowels in a sound
# .plot: Actually plot inside picture window or just calculate paramters
procedure plot_vowels .plot .sp$ .sound
	.startT = 0
	.dot_Radius = default_Dot_Radius
	#call syllable_nuclei -25 4 0.3 1 .sound
	#.syllableKernels = syllable_nuclei.textgridid
	call segment_syllables -25 4 0.3 1 .sound
	.syllableKernels = segment_syllables.textgridid
	
	# Calculate the formants
	selectObject: .sound
	.duration = Get total duration
	.soundname$ = selected$("Sound")
	if .sp$ = "M"
		.downSampled = Resample: 10000, 50
		.formants = noprogress To Formant (sl): 0, 5, 5000, 0.025, 50
	else
		.downSampled = Resample: 11000, 50
		.formants = noprogress To Formant (sl): 0, 5, 5500, 0.025, 50
	endif

	call select_vowel_target .sound .formants .syllableKernels
	.vowelTier = select_vowel_target.vowelTier
	.targetTier = select_vowel_target.targetTier
	selectObject: .syllableKernels
	.numTargets = Get number of points: .targetTier
	if .numTargets > dot_Radius_Cutoff
		.dot_Radius = default_Dot_Radius / sqrt(.numTargets/dot_Radius_Cutoff)
	endif

	
	# Set new @_center
	phonemes [phonLanguage$, .sp$, "@_center", "F1"] = (phonemes [phonLanguage$, .sp$, "a", "F1"] * phonemes [phonLanguage$, .sp$, "i", "F1"] * phonemes [phonLanguage$, .sp$, "u", "F1"]) ** (1/3) 
	phonemes [phonLanguage$, .sp$, "@_center", "F2"] = (phonemes [phonLanguage$, .sp$, "a", "F2"] * phonemes [phonLanguage$, .sp$, "i", "F2"] * phonemes [phonLanguage$, .sp$, "u", "F2"]) ** (1/3) 
	
	.f1_c = phonemes [phonLanguage$, .sp$, "@_center", "F1"]
	.f2_c = phonemes [phonLanguage$, .sp$, "@_center", "F2"]
	
	# Plot center
	@vowel2point: .sp$, .f1_c, .f2_c
	.st_c1 = vowel2point.x
	.st_c2 = vowel2point.y
	
	# Near /@/
	.f1_c = phonemes [phonLanguage$, .sp$, "@_center", "F1"]
	.f2_c = phonemes [phonLanguage$, .sp$, "@_center", "F2"]
	@get_closest_vowels: 0, .sp$, .formants, .syllableKernels, .f1_c, .f2_c
	.numVowelIntervals = get_closest_vowels.vowelNum
	# Actually plot the vowels
	if .plot
		for .i to get_closest_vowels.vowelNum
			.f1 = get_closest_vowels.f1_list [.i]
			.f2 = get_closest_vowels.f2_list [.i]
			@vowel2point: .sp$, .f1, .f2
			.x = vowel2point.x
			.y = vowel2point.y
			Paint circle: color$["@"], .x, .y, .dot_Radius
		endfor
	endif
	
	# Near /i/
	.f1_i = phonemes [phonLanguage$, .sp$, "i", "F1"]
	.f2_i = phonemes [phonLanguage$, .sp$, "i", "F2"]
	@get_closest_vowels: 0, .sp$, .formants, .syllableKernels, .f1_i, .f2_i
	.meanDistToCenter ["i"] = get_closest_vowels.meanDistance
	.stdevDistToCenter ["i"] = get_closest_vowels.stdevDistance
	.num_i_Intervals = get_closest_vowels.vowelNum
	# Actually plot the vowels
	if .plot
		for .i to get_closest_vowels.vowelNum
			.f1 = get_closest_vowels.f1_list [.i]
			.f2 = get_closest_vowels.f2_list [.i]
			@vowel2point: .sp$, .f1, .f2
			.x = vowel2point.x
			.y = vowel2point.y
			Paint circle: color$["i"], .x, .y, .dot_Radius
		endfor
	endif
	
	# Near /u/
	.f1_u = phonemes [phonLanguage$, .sp$, "u", "F1"]
	.f2_u = phonemes [phonLanguage$, .sp$, "u", "F2"]
	@get_closest_vowels: 0, .sp$, .formants, .syllableKernels, .f1_u, .f2_u
	.meanDistToCenter ["u"] = get_closest_vowels.meanDistance
	.stdevDistToCenter ["u"] = get_closest_vowels.stdevDistance
	.num_u_Intervals = get_closest_vowels.vowelNum
	# Actually plot the vowels
	if .plot
		for .i to get_closest_vowels.vowelNum
			.f1 = get_closest_vowels.f1_list [.i]
			.f2 = get_closest_vowels.f2_list [.i]
			@vowel2point: .sp$, .f1, .f2
			.x = vowel2point.x
			.y = vowel2point.y
			Paint circle: color$["u"], .x, .y, .dot_Radius
		endfor
	endif
	
	# Near /a/
	.f1_a = phonemes [phonLanguage$, .sp$, "a", "F1"]
	.f2_a = phonemes [phonLanguage$, .sp$, "a", "F2"]
	@get_closest_vowels: 0, .sp$, .formants, .syllableKernels, .f1_a, .f2_a
	.meanDistToCenter ["a"] = get_closest_vowels.meanDistance
	.stdevDistToCenter ["a"] = get_closest_vowels.stdevDistance
	.num_a_Intervals = get_closest_vowels.vowelNum
	# Actually plot the vowels
	if .plot
		for .i to get_closest_vowels.vowelNum
			.f1 = get_closest_vowels.f1_list [.i]
			.f2 = get_closest_vowels.f2_list [.i]
			@vowel2point: .sp$, .f1, .f2
			.x = vowel2point.x
			.y = vowel2point.y
			Paint circle: color$["a"], .x, .y, .dot_Radius
		endfor
	endif
	
	# Print center and corner markers
	# Center
	if .plot
		.x = .st_c1
		.y = .st_c2
		Black
		Solid line
		Draw line: .x-0.007, .y+0.007, .x+0.007, .y-0.007
		Draw line: .x-0.007, .y-0.007, .x+0.007, .y+0.007
		# u
		@vowel2point: .sp$, .f1_u, .f2_u	
		.x = vowel2point.x
		.y = vowel2point.y
		Black
		Solid line
		Draw line: .x-0.007, .y+0.007, .x+0.007, .y-0.007
		Draw line: .x-0.007, .y-0.007, .x+0.007, .y+0.007
		# i
		@vowel2point: .sp$, .f1_i, .f2_i	
		.x = vowel2point.x
		.y = vowel2point.y
		Black
		Solid line
		Draw line: .x-0.007, .y+0.007, .x+0.007, .y-0.007
		Draw line: .x-0.007, .y-0.007, .x+0.007, .y+0.007
		# a
		@vowel2point: .sp$, .f1_a, .f2_a	
		.x = vowel2point.x
		.y = vowel2point.y
		Black
		Solid line
		Draw line: .x-0.007, .y+0.007, .x+0.007, .y-0.007
		Draw line: .x-0.007, .y-0.007, .x+0.007, .y+0.007
	endif
	
	# Draw new triangle
	@vowel2point: .sp$, .f1_i, .f2_i
	.st_i1 = vowel2point.x
	.st_i2 = vowel2point.y
	.ic_dist = sqrt((.st_c1 - .st_i1)^2 + (.st_c2 - .st_i2)^2)
	@vowel2point: .sp$, .f1_u, .f2_u
	.st_u1 = vowel2point.x
	.st_u2 = vowel2point.y
	.uc_dist = sqrt((.st_c1 - .st_u1)^2 + (.st_c2 - .st_u2)^2)
	@vowel2point: .sp$, .f1_a, .f2_a
	.st_a1 = vowel2point.x
	.st_a2 = vowel2point.y
	.ac_dist = sqrt((.st_c1 - .st_a1)^2 + (.st_c2 - .st_a2)^2)
	
	# Vowel tirangle surface area (Heron's formula)
	.auDist = sqrt((.st_a1 - .st_u1)^2 + (.st_a2 - .st_u2)^2)
	.aiDist = sqrt((.st_a1 - .st_i1)^2 + (.st_a2 - .st_i2)^2)
	.uiDist = sqrt((.st_u1 - .st_i1)^2 + (.st_u2 - .st_i2)^2)
	.p = (.auDist + .aiDist + .uiDist)/2
	.areaVT = sqrt(.p * (.p - .auDist) * (.p - .aiDist) * (.p - .uiDist))

	# 1 stdev
	# c - i
	.relDist = (.meanDistToCenter ["i"] + 1 * .stdevDistToCenter ["i"]) / .ic_dist
	.x ["i"] = .st_c1 + .relDist * (.st_i1 - .st_c1)
	.y ["i"] = .st_c2 + .relDist * (.st_i2 - .st_c2)
	# c - u
	.relDist = (.meanDistToCenter ["u"] + 1 * .stdevDistToCenter ["u"]) / .uc_dist
	.x ["u"] = .st_c1 + .relDist * (.st_u1 - .st_c1)
	.y ["u"] = .st_c2 + .relDist * (.st_u2 - .st_c2)
	# c - a
	.relDist = (.meanDistToCenter ["a"] + 1 * .stdevDistToCenter ["a"]) / .ac_dist
	.x ["a"] = .st_c1 + .relDist * (.st_a1 - .st_c1)
	.y ["a"] = .st_c2 + .relDist * (.st_a2 - .st_c2)
	
	if .plot
		Black
		Dotted line
		Draw line: .x ["a"], .y ["a"], .x ["i"], .y ["i"]
		Draw line: .x ["i"], .y ["i"], .x ["u"], .y ["u"]
		Draw line: .x ["u"], .y ["u"], .x ["a"], .y ["a"]
	endif

	# Vowel tirangle surface area (Heron's formula)
	.auDist = sqrt((.x ["a"] - .x ["u"])^2 + (.y ["a"] - .y ["u"])^2)
	.aiDist = sqrt((.x ["a"] - .x ["i"])^2 + (.y ["a"] - .y ["i"])^2)
	.uiDist = sqrt((.x ["u"] - .x ["i"])^2 + (.y ["u"] - .y ["i"])^2)
	.p = (.auDist + .aiDist + .uiDist)/2
	.areaSD1 = sqrt(.p * (.p - .auDist) * (.p - .aiDist) * (.p - .uiDist))
	.area1perc = 100*(.areaSD1 / .areaVT)

	# 2 stdev
	# c - i
	.relDist_i = (.meanDistToCenter ["i"] + 2 * .stdevDistToCenter ["i"]) / .ic_dist
	.x ["i"] = .st_c1 + .relDist_i * (.st_i1 - .st_c1)
	.y ["i"] = .st_c2 + .relDist_i * (.st_i2 - .st_c2)
	# c - u
	.relDist_u = (.meanDistToCenter ["u"] + 2 * .stdevDistToCenter ["u"]) / .uc_dist
	.x ["u"] = .st_c1 + .relDist_u * (.st_u1 - .st_c1)
	.y ["u"] = .st_c2 + .relDist_u * (.st_u2 - .st_c2)
	# c - a
	.relDist_a = (.meanDistToCenter ["a"] + 2 * .stdevDistToCenter ["a"]) / .ac_dist
	.x ["a"] = .st_c1 + .relDist_a * (.st_a1 - .st_c1)
	.y ["a"] = .st_c2 + .relDist_a * (.st_a2 - .st_c2)
	# Convert to percentages
	.relDist_i *= 100
	.relDist_u *= 100
	.relDist_a *= 100
	
	if .plot
		Black
		Solid line
		Draw line: .x ["a"], .y ["a"], .x ["i"], .y ["i"]
		Draw line: .x ["i"], .y ["i"], .x ["u"], .y ["u"]
		Draw line: .x ["u"], .y ["u"], .x ["a"], .y ["a"]
	endif

	# Vowel tirangle surface area (Heron's formula)
	.auDist = sqrt((.x ["a"] - .x ["u"])^2 + (.y ["a"] - .y ["u"])^2)
	.aiDist = sqrt((.x ["a"] - .x ["i"])^2 + (.y ["a"] - .y ["i"])^2)
	.uiDist = sqrt((.x ["u"] - .x ["i"])^2 + (.y ["u"] - .y ["i"])^2)
	.p = (.auDist + .aiDist + .uiDist)/2
	.areaSD2 = sqrt(.p * (.p - .auDist) * (.p - .aiDist) * (.p - .uiDist))
	.area2perc = 100*(.areaSD2 / .areaVT)

	# Print areas as percentage
	if .plot
		Text special: 1, "right", 0.07, "bottom", "Helvetica", 16, "0", uiMessage$ [uiLanguage$, "AreaTitle"]
		Text special: 0.9, "right", 0.02, "bottom", "Helvetica", 14, "0", uiMessage$ [uiLanguage$, "Area1"]
		Text special: 0.9, "left", 0.02, "bottom", "Helvetica", 14, "0", ": '.area1perc:0'\% "
		Text special: 0.9, "right", -0.03, "bottom", "Helvetica", 14, "0", uiMessage$ [uiLanguage$, "Area2"]
		Text special: 0.9, "left", -0.03, "bottom", "Helvetica", 14, "0", ": '.area2perc:0'\% "
		Text special: 0.9, "right", -0.08, "bottom", "Helvetica", 14, "0", uiMessage$ [uiLanguage$, "AreaN"]
		Text special: 0.9, "left", -0.08, "bottom", "Helvetica", 14, "0", ": '.numVowelIntervals' ('.duration:0' s)"

		# Relative distance to corners
		Text special: -0.1, "left", 0.07, "bottom", "Helvetica", 16, "0", uiMessage$ [uiLanguage$, "DistanceTitle"]
		Text special: 0.0, "right", 0.02, "bottom", "Helvetica", 14, "0", "/i/:"
		Text special: 0.16, "right", 0.02, "bottom", "Helvetica", 14, "0", " '.relDist_i:0'\%  ('.num_i_Intervals')"
		Text special: 0.0, "right", -0.03, "bottom", "Helvetica", 14, "0", "/u/:"
		Text special: 0.16, "right", -0.03, "bottom", "Helvetica", 14, "0", " '.relDist_u:0'\%  ('.num_u_Intervals')"
		Text special: 0.0, "right", -0.08, "bottom", "Helvetica", 14, "0", "/a/:"
		Text special: 0.16, "right", -0.08, "bottom", "Helvetica", 14, "0", " '.relDist_a:0'\%  ('.num_a_Intervals')"
	endif
	
	selectObject: .downSampled, .formants, .syllableKernels
	Remove
endproc

procedure print_output_line .title$, .sp$, .numVowelIntervals, .area2perc, .area1perc, .relDist_i, .relDist_u, .relDist_a, .duration, .intensity
	# Uses global variable
	if output_table$ = "-"
		appendInfoLine: title$, tab$, .sp$, tab$, .numVowelIntervals, tab$, fixed$(.area2perc, 0), tab$, fixed$(.area1perc, 0), tab$, fixed$(.relDist_i, 0), tab$, fixed$(.relDist_u, 0), tab$, fixed$(.relDist_a, 0), tab$, fixed$(.duration,0), tab$, fixed$(.intensity,1)
	elsif index_regex(output_table$, "\w")
		appendFileLine: output_table$, title$, tab$, .sp$, tab$, .numVowelIntervals, tab$, fixed$(.area2perc, 0), tab$, fixed$(.area1perc, 0), tab$, fixed$(.relDist_i, 0), tab$, fixed$(.relDist_u, 0), tab$, fixed$(.relDist_a, 0), tab$, fixed$(.duration,0), tab$, fixed$(.intensity,1)
	endif	
endproc

# Plot the standard vowels
procedure plot_standard_vowel .color$ .sp$ .vowel$ .reduction
	.vowel$ = replace_regex$(.vowel$, "v", "y", 0)

	.i = 0
	while .vowel$ <> ""
		.i += 1
		.v$ = replace_regex$(.vowel$, "^\s*(\S[`]?).*$", "\1", 0)
		.f1 = phonemes [phonLanguage$, .sp$, .v$, "F1"]
		.f2 = phonemes [phonLanguage$, .sp$, .v$, "F2"]
		if .reduction
			.factor = 0.9^.reduction
			.f1 = .factor * (.f1 - phonemes [phonLanguage$, .sp$, "@", "F1"]) + phonemes [phonLanguage$, .sp$, "@", "F1"]
			.f2 = .factor * (.f2 - phonemes [phonLanguage$, .sp$, "@", "F2"]) + phonemes [phonLanguage$, .sp$, "@", "F2"]
		endif
		@vowel2point: .sp$, .f1, .f2
		.x [.i] = vowel2point.x
		.y [.i] = vowel2point.y
		.vowel$ = replace_regex$(.vowel$, "^\s*(\S[`]?)", "", 0)
	endwhile
	Arrow size: 2
	Green
	Dotted line
	Paint circle: .color$, .x[1], .y[1], 1
	for .p from 2 to .i
		Draw arrow: .x[.p - 1], .y[.p - 1], .x[.p], .y[.p]
	endfor
	demoShow()
	Black
endproc

# Plot the vowel triangle
procedure plot_vowel_triangle .sp$
	# Draw vowel triangle
	.a_F1 = phonemes [phonLanguage$, .sp$, "a_corner", "F1"]
	.a_F2 = phonemes [phonLanguage$, .sp$, "a_corner", "F2"]

	.i_F1 = phonemes [phonLanguage$, .sp$, "i_corner", "F1"]
	.i_F2 = phonemes [phonLanguage$, .sp$, "i_corner", "F2"]

	.u_F1 = phonemes [phonLanguage$, .sp$, "u_corner", "F1"]
	.u_F2 = phonemes [phonLanguage$, .sp$, "u_corner", "F2"]
	
	Dashed line
	# u - i
	@vowel2point: .sp$, .u_F1, .u_F2
	.x1 = vowel2point.x
	.y1 = vowel2point.y
	Colour: color$ ["u"]
	Text special: .x1, "Centre", .y1, "Bottom", "Helvetica", 20, "0", "/u/ "+uiMessage$ [uiLanguage$, "Corneru"]
	Black
	
	@vowel2point: .sp$, .i_F1, .i_F2
	.x2 = vowel2point.x
	.y2 = vowel2point.y
	Colour: color$ ["i"]
	Text special: .x2, "Centre", .y2, "Bottom", "Helvetica", 20, "0", uiMessage$ [uiLanguage$, "Corneri"]+" /i/"
	Black
	Draw line: .x1, .y1, .x2, .y2
	
	# u - a
	@vowel2point: .sp$, .u_F1, .u_F2
	.x1 = vowel2point.x
	.y1 = vowel2point.y
	@vowel2point: .sp$, .a_F1, .a_F2
	.x2 = vowel2point.x
	.y2 = vowel2point.y
	Colour: color$ ["a"]
	Text special: .x2, "Centre", .y2, "Top", "Helvetica", 20, "0", "/a/ "+uiMessage$ [uiLanguage$, "Cornera"]
	Black
	Draw line: .x1, .y1, .x2, .y2
	
	# i - a
	@vowel2point: .sp$, .i_F1, .i_F2
	.x1 = vowel2point.x
	.y1 = vowel2point.y
	@vowel2point: .sp$, .a_F1, .a_F2
	.x2 = vowel2point.x
	.y2 = vowel2point.y
	Draw line: .x1, .y1, .x2, .y2
endproc

# Convert the frequencies to coordinates
procedure vowel2point .sp$ .f1 .f2
	.spt1 = 12*log2(.f1)
	.spt2 = 12*log2(.f2)
	
	.a_St1 = 12*log2(phonemes [phonLanguage$, .sp$, "a_corner", "F1"])
	.a_St2 = 12*log2(phonemes [phonLanguage$, .sp$, "a_corner", "F2"])

	.i_St1 = 12*log2(phonemes [phonLanguage$, .sp$, "i_corner", "F1"])
	.i_St2 = 12*log2(phonemes [phonLanguage$, .sp$, "i_corner", "F2"])

	.u_St1 = 12*log2(phonemes [phonLanguage$, .sp$, "u_corner", "F1"])
	.u_St2 = 12*log2(phonemes [phonLanguage$, .sp$, "u_corner", "F2"])
	
	.dist_iu = sqrt((.i_St1 - .u_St1)^2 + (.i_St2 - .u_St2)^2)
	.theta = arcsin((.u_St1 - .i_St1)/.dist_iu)

	# First, with i_corner as (0, 0)
	.xp = ((.i_St2 - .spt2)/(.i_St2 - .u_St2))
	.yp = (.spt1 - min(.u_St1, .i_St1))/(.a_St1 - min(.u_St1, .i_St1))
	
	# Rotate around i_corner to make i-u axis horizontal
	.x = .xp * cos(.theta) + .yp * sin(.theta)
	.y = -1 * .xp * sin(.theta) + .yp * cos(.theta)
	
	# Reflect y-axis and make i_corner as (0, 1)
	.y = 1 - .y
	.yp = 1 - .yp
endproc

# Stop the progam
procedure exitVowelTriangle .message$
	select all
	if numberOfSelected() > 0
		Remove
	endif
	exitScript: .message$
endproc

# Get a list of best targets with distances, one for each vowel segment found
# Use DTW to get the best match
procedure get_closest_vowels .cutoff .sp$ .formants .textgrid .f1_o .f2_o
	.f1 = 0
	.f2 = 0
	
	# Convert to coordinates
	@vowel2point: .sp$, .f1_o, .f2_o
	.st_o1 = vowel2point.x
	.st_o2 = vowel2point.y
	
	# Get center coordinates
	.fc1 = phonemes [phonLanguage$, .sp$, "@_center", "F1"]
	.fc2 = phonemes [phonLanguage$, .sp$, "@_center", "F2"]
	@vowel2point: .sp$, .fc1, .fc2
	.st_c1 = vowel2point.x
	.st_c2 = vowel2point.y
	.tcDist_sqr = (.st_o1 - .st_c1)^2 + (.st_o2 - .st_c2)^2

	.vowelTier = 1
	.vowelNum = 0
	selectObject: .textgrid
	.numIntervals = Get number of intervals: .vowelTier
	.tableDistances = -1
	for .i to .numIntervals
		selectObject: .textgrid
		.label$ = Get label of interval: .vowelTier, .i
		if .label$ = "Vowel"
			.numDistance = 100000000000
			.numF1 = -1
			.numF2 = -1
			.num_t = 0
			selectObject: .textgrid
			.start = Get start time of interval: .vowelTier, .i
			.end = Get end time of interval: .vowelTier, .i
			selectObject: .formants
			.t = .start
			while .t <= .end
				.ftmp1 = Get value at time: 1, .t, "Hertz", "Linear"
				.ftmp2 = Get value at time: 2, .t, "Hertz", "Linear"
				@vowel2point: .sp$, .ftmp1, .ftmp2
				.stmp1 = vowel2point.x
				.stmp2 = vowel2point.y
				.tmpdistsqr = (.st_o1 - .stmp1)^2 + (.st_o2 - .stmp2)^2
				# Local
				if .tmpdistsqr < .numDistance
					.numDistance = .tmpdistsqr
					.numF1 = .ftmp1
					.numF2 = .ftmp2
					.num_t = .t
				endif
				.t += 0.005
			endwhile
			
			
			# Calculate the distance along the line between the 
			# center (c) and the target (t) from the best match 'v'
			# to the center.
			# 
			@vowel2point: .sp$, .numF1, .numF2
			.st1 = vowel2point.x
			.st2 = vowel2point.y
			
			.vcDist_sqr = (.st_c1 - .st1)^2 + (.st_c2 - .st2)^2
			.vtDist_sqr = (.st_o1 - .st1)^2 + (.st_o2 - .st2)^2
			.cvDist = (.tcDist_sqr + .vcDist_sqr - .vtDist_sqr)/(2*sqrt(.tcDist_sqr))
			
			# Only use positive distances for plotting
			if .cvDist = undefined or .cvDist >= .cutoff
				.vowelNum += 1
				.distance_list [.vowelNum] = sqrt(.numDistance)
				.f1_list [.vowelNum] = .numF1
				.f2_list [.vowelNum] = .numF2
				.t_list [.vowelNum] = .num_t
	
				if .tableDistances <= 0
					.tableDistances = Create TableOfReal: "Distances", 1, 1
				else
					selectObject: .tableDistances
					Insert row (index): 1
				endif
				selectObject: .tableDistances
				Set value: 1, 1, .cvDist
			endif
		endif
	endfor
	.meanDistance = -1
	.stdevDistance = -1
	if .tableDistances > 0
		selectObject: .tableDistances
		.meanDistance = Get column mean (index): 1
		.stdevDistance = Get column stdev (index): 1
		if .stdevDistance = undefined
			.stdevDistance = .meanDistance/2
		endif
		Remove
	endif
endproc

# Collect all the most distant vowles
procedure get_most_distant_vowels .sp$ .formants .textgrid .f1_o .f2_o
	.f1 = 0
	.f2 = 0
	
	# Convert to coordinates
	@vowel2point: .sp$, .f1_o, .f2_o
	.st_o1 = vowel2point.x
	.st_o2 = vowel2point.y
	
	.vowelTier = 1
	.vowelNum = 0
	selectObject: .textgrid
	.numIntervals = Get number of intervals: .vowelTier
	for .i to .numIntervals
		selectObject: .textgrid
		.label$ = Get label of interval: .vowelTier, .i
		if .label$ = "Vowel"
			.vowelNum += 1
			.numDistance = -1
			.numF1 = -1
			.numF2 = -1
			.num_t = 0
			selectObject: .textgrid
			.start = Get start time of interval: .vowelTier, .i
			.end = Get end time of interval: .vowelTier, .i
			selectObject: .formants
			.t = .start
			while .t <= .end
				.ftmp1 = Get value at time: 1, .t, "Hertz", "Linear"
				.ftmp2 = Get value at time: 2, .t, "Hertz", "Linear"
				@vowel2point: .sp$, .ftmp1, .ftmp2
				.stmp1 = vowel2point.x
				.stmp2 = vowel2point.y
				.tmpdistsqr = (.st_o1 - .stmp1)^2 + (.st_o2 - .stmp2)^2
				# Local
				if .tmpdistsqr > .numDistance
					.numDistance = .tmpdistsqr
					.numF1 = .ftmp1
					.numF2 = .ftmp2
					.num_t = .t
				endif
				.t += 0.005
			endwhile

			.distance_list [.vowelNum] = sqrt(.numDistance)
			.f1_list [.vowelNum] = .numF1
			.f2_list [.vowelNum] = .numF2
			.t_list [.vowelNum] = .num_t
		endif
	endfor
endproc

procedure select_vowel_target .sound .formants .textgrid
	.f1_Lowest = 250
	.f1_Highest = 1050
	selectObject: .textgrid
	.duration = Get total duration
	.firstTier$ = Get tier name: 1
	if .firstTier$ <> "Vowel"
		Insert point tier: 1, "VowelTarget"
		Insert interval tier: 1, "Vowel"
	endif
	.vowelTier = 1
	.targetTier = 2
	.peakTier = 3
	.valleyTier = 4
	.silencesTier = 5
	.vuvTier = 6

	selectObject: .sound
	.samplingFrequency = Get sampling frequency
	.intensity = Get intensity (dB)
	if .samplingFrequency = 10000
		.formantsBurg = noprogress To Formant (burg): 0, 5, 5000, 0.025, 50
	else
		.formantsBurg = noprogress To Formant (burg): 0, 5, 5500, 0.025, 50
	endif
	.totalNumFrames = Get number of frames
		
	# Nothing found, but there is sound. Try to find at least 1 vowel
	
	selectObject: .textgrid
	.numPeaks = Get number of points: .peakTier	
	if .numPeaks <= 0 and .intensity >= 45
		selectObject: .sound
		.t_max = Get time of maximum: 0, 0, "Sinc70"
		.pp = noprogress To PointProcess (periodic, cc): 75, 600
		.textGrid = noprogress To TextGrid (vuv): 0.02, 0.01
		.i = Get interval at time: 1, .t_max
		.label$ = Get label of interval: 1, .i
		.start = Get start time of interval: 1, .i
		.end = Get end time of interval: 1, .i
		if .label$ = "V"
			selectObject: .syllableKernels
			Insert point: .peakTier, .t_max, "P"
			Insert point: .valleyTier, .start, "V"
			Insert point: .valley, .end, "V"
		endif
	endif
	
	selectObject: .sound
	.voicePP = noprogress To PointProcess (periodic, cc): 75, 600
	selectObject: .textgrid
	.numPeaks = Get number of points: .peakTier
	.numValleys = Get number of points: .valleyTier
	for .p to .numPeaks
		selectObject: .textgrid
		.tp = Get time of point: .peakTier, .p
		# Find boundaries
		# From valleys
		.tl = 0
		.vl = Get low index from time: .valleyTier, .tp
		if .vl > 0 and .vl < .numValleys
			.tl = Get time of point: .valleyTier, .vl
		endif
		.th = .duration
		.vh = Get high index from time: .valleyTier, .tp
		if .vh > 0 and .vh < .numValleys
			.th = Get time of point: .valleyTier, .vh
		endif
		# From silences
		.sl = Get interval at time: .silencesTier, .tl
		.label$ = Get label of interval: .silencesTier, .sl
		.tsl = .tl
		if .label$ = "silent"
			.tsl = Get end time of interval: .silencesTier, .sl
		endif
		if .tsl > .tl and .tsl < .tp
			.tl = .tsl
		endif
		.sh = Get interval at time: .silencesTier, .th
		.label$ = Get label of interval: .silencesTier, .sh
		.tsh = .th
		if .label$ = "silent"
			.tsh = Get start time of interval: .silencesTier, .sh
		endif
		if .tsh < .th and .tsh > .tp
			.th = .tsh
		endif
		
		# From vuv
		.vuvl = Get interval at time: .vuvTier, .tl
		.label$ = Get label of interval: .vuvTier, .vuvl
		.tvuvl = .tl
		if .label$ = "U"
			.tvuvl = Get end time of interval: .vuvTier, .vuvl
		endif
		if .tvuvl > .tl and .tvuvl < .tp
			.tl = .tvuvl
		endif
		.vuvh = Get interval at time: .vuvTier, .th
		.label$ = Get label of interval: .vuvTier, .vuvh
		.tvuvh = .th
		if .label$ = "U"
			.tvuvh = Get start time of interval: .vuvTier, .vuvh
		endif
		if .tvuvh < .th and .tvuvh > .tp
			.th = .tvuvh
		endif
		
		# From formants: 300 <= F1 <= 1000
		# F1 >= 300
		selectObject: .formants
		.dt = Get time step

		selectObject: .formants
		.f = Get value at time: 1, .tl, "Hertz", "Linear"
		selectObject: .formantsBurg
		.b = Get bandwidth at time: 1, .tl, "Hertz", "Linear"
		.iframe = Get frame number from time: .tl
		if .iframe > .totalNumFrames
			.iframe = .totalNumFrames
		elsif .iframe < 1
			.iframe = 1
		endif
		.nf = Get number of formants: .iframe
		while (.f < .f1_Lowest or .f > .f1_Highest or .b > 0.7 * .f or .nf < 4) and .tl + .dt < .th
			.tl += .dt
			selectObject: .formants
			.f = Get value at time: 1, .tl, "Hertz", "Linear"
			selectObject: .formantsBurg
			.b = Get bandwidth at time: 1, .tl, "Hertz", "Linear"
			.iframe = Get frame number from time: .tl	
			if .iframe > .totalNumFrames
				.iframe = .totalNumFrames
			elsif .iframe < 1
				.iframe = 1
			endif
			.nf = Get number of formants: .iframe		
		endwhile

		selectObject: .formants
		.f = Get value at time: 1, .th, "Hertz", "Linear"
		selectObject: .formantsBurg
		.b = Get bandwidth at time: 1, .th, "Hertz", "Linear"
		.iframe = Get frame number from time: .th
		if .iframe > .totalNumFrames
			.iframe = .totalNumFrames
		elsif .iframe < 1
			.iframe = 1
		endif
		.nf = Get number of formants: .iframe
		while (.f < .f1_Lowest or .f > .f1_Highest or .b > 0.7 * .f or .nf < 4) and .th - .dt > .tl
			.th -= .dt
			selectObject: .formants
			.f = Get value at time: 1, .th, "Hertz", "Linear"
			selectObject: .formantsBurg
			.b = Get bandwidth at time: 1, .th, "Hertz", "Linear"
			.iframe = Get frame number from time: .th
			if .iframe > .totalNumFrames
				.iframe = .totalNumFrames
			elsif .iframe < 1
				.iframe = 1
			endif
			.nf = Get number of formants: .iframe		
		endwhile
		
		# New points
		if .th - .tl > 0.01
			selectObject: .textgrid
			.numPoints = Get number of points: .targetTier
			
			selectObject: .formants
			if .tp > .tl and .tp < .th
				.tt = .tp
			else
				.tt = (.tl+.th)/2
				.f1_median = Get quantile: 1, .tl, .th, "Hertz", 0.5 
				.f2_median = Get quantile: 2, .tl, .th, "Hertz", 0.5 
				if .f1_median > 400
					.tt = Get time of maximum: 1, .tl, .th, "Hertz", "Parabolic"
				elsif .f2_median > 1600
					.tt = Get time of maximum: 2, .tl, .th, "Hertz", "Parabolic"
				elsif .f2_median < 1100
					.tt = Get time of minimum: 2, .tl, .th, "Hertz", "Parabolic"
				endif
				
				if .tt < .tl + 0.01 or .tt > .th - 0.01
					.tt = (.tl+.th)/2
				endif
			endif
			
			# Insert Target
			selectObject: .textgrid
			.numPoints = Get number of points: .targetTier
			.tmp = 0
			if .numPoints > 0
				.tmp = Get time of point: .targetTier, .numPoints
			endif
			if .tt <> .tmp
				Insert point: .targetTier, .tt, "T"
			endif
			
			# Now find vowel interval from taget
			.ttl = .tt
			# Lower end
			selectObject: .formants
			.f = Get value at time: 1, .ttl, "Hertz", "Linear"
			selectObject: .formantsBurg
			.b = Get bandwidth at time: 1, .ttl, "Hertz", "Linear"
			.iframe = Get frame number from time: .th
			if .iframe > .totalNumFrames
				.iframe = .totalNumFrames
			elsif .iframe < 1
				.iframe = 1
			endif
			.nf = Get number of formants: .iframe	
			
			# Voicing: Is there a voiced point below within 0.02 s?
			selectObject: .voicePP
			.i_near = Get nearest index: .ttl - .dt
			.pp_near = Get time from index: .i_near
			
			while (.f > 300 and .f < 1000 and .b < 0.9 * .f and .nf >= 4) and .ttl - .dt >= .tl and abs((.ttl - .dt) - .pp_near) <= 0.02
				.ttl -= .dt
				selectObject: .formants
				.f = Get value at time: 1, .ttl, "Hertz", "Linear"
				selectObject: .formantsBurg
				.b = Get bandwidth at time: 1, .ttl, "Hertz", "Linear"
				.iframe = Get frame number from time: .ttl
				if .iframe > .totalNumFrames
					.iframe = .totalNumFrames
				elsif .iframe < 1
					.iframe = 1
				endif
				.nf = Get number of formants: .iframe
				# Voicing: Is there a voiced point below within 0.02 s?
				selectObject: .voicePP
				.i_near = Get nearest index: .ttl - .dt
				.pp_near = Get time from index: .i_near
			endwhile
			# Make sure something has changed
			if .ttl > .tt - 0.01
				.ttl = .tl
			endif
			
			# Higher end
			.tth = .tp
			selectObject: .formants
			.f = Get value at time: 1, .tth, "Hertz", "Linear"
			selectObject: .formantsBurg
			.b = Get bandwidth at time: 1, .tth, "Hertz", "Linear"
			.iframe = Get frame number from time: .th
			if .iframe > .totalNumFrames
				.iframe = .totalNumFrames
			elsif .iframe < 1
				.iframe = 1
			endif
			.nf = Get number of formants: .iframe		
			
			# Voicing: Is there a voiced point above within 0.02 s?
			selectObject: .voicePP
			.i_near = Get nearest index: .ttl + .dt
			.pp_near = Get time from index: .i_near
			
			while (.f > 300 and .f < 1000 and .b < 0.9 * .f and .nf >= 4) and .tth + .dt <= .th and abs((.ttl + .dt) - .pp_near) <= 0.02
				.tth += .dt
				selectObject: .formants
				.f = Get value at time: 1, .tth, "Hertz", "Linear"
				selectObject: .formantsBurg
				.b = Get bandwidth at time: 1, .tth, "Hertz", "Linear"
				.iframe = Get frame number from time: .tth
				if .iframe > .totalNumFrames
					.iframe = .totalNumFrames
				elsif .iframe < 1
					.iframe = 1
				endif
				.nf = Get number of formants: .iframe		
				# Voicing: Is there a voiced point above within 0.02 s?
				selectObject: .voicePP
				.i_near = Get nearest index: .ttl + .dt
				.pp_near = Get time from index: .i_near
			endwhile
			# Make sure something has changed
			if .tth < .tt + 0.01
				.tth = .th
			endif
			
			# Insert interval
			selectObject: .textgrid
			.index = Get interval at time: .vowelTier, .ttl
			.start = Get start time of interval: .vowelTier, .index
			.end = Get end time of interval: .vowelTier, .index
			if .ttl <> .start and .ttl <> .end
				Insert boundary: .vowelTier, .ttl
			endif
			.index = Get interval at time: .vowelTier, .tth
			.start = Get start time of interval: .vowelTier, .index
			.end = Get end time of interval: .vowelTier, .index
			if .tth <> .start and .tth <> .end
				Insert boundary: .vowelTier, .tth
			endif
			.index = Get interval at time: .vowelTier, .tt
			.start = Get start time of interval: .vowelTier, .index
			.end = Get end time of interval: .vowelTier, .index
			# Last sanity checks on voicing and intensity
			# A vowel is voiced
			selectObject: .voicePP
			.meanPeriod = Get mean period: .start, .end, 0.0001, 0.02, 1.3
			if .meanPeriod <> undefined
				selectObject: .sound
				.sd = Get standard deviation: 1, .start, .end
				# Is there enough sound to warrant a vowel? > -15dB
				if 20*log10(.sd/(2*10^-5)) - .intensity > -15
					selectObject: .textgrid
					Set interval text: .vowelTier, .index, "Vowel"
				endif
			endif
		endif
	endfor
	
	selectObject: .formantsBurg, .voicePP
	Remove
	
endproc


###########################################################################
#                                                                         #
#  Praat Script Syllable Nuclei                                           #
#  Copyright (C) 2017  R.J.J.H. van Son                                   #
#                                                                         #
#    This program is free software: you can redistribute it and/or modify #
#    it under the terms of the GNU General Public License as published by #
#    the Free Software Foundation, either version 2 of the License, or    #
#    (at your option) any later version.                                  #
#                                                                         #
#    This program is distributed in the hope that it will be useful,      #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
#    GNU General Public License for more details.                         #
#                                                                         #
#    You should have received a copy of the GNU General Public License    #
#    along with this program.  If not, see http://www.gnu.org/licenses/   #
#                                                                         #
###########################################################################
#                                                                         #
# Simplified summary of the script by Nivja de Jong and Ton Wempe         #
#                                                                         #
# Praat script to detect syllable nuclei and measure speech rate          # 
# automatically                                                           #
# de Jong, N.H. & Wempe, T. Behavior Research Methods (2009) 41: 385.     #
# https://doi.org/10.3758/BRM.41.2.385                                    #
# 
procedure segment_syllables .silence_threshold .minimum_dip_between_peaks .minimum_pause_duration .keep_Soundfiles_and_Textgrids .soundid
	# Get intensity
	selectObject: .soundid
	.intensity = noprogress To Intensity: 70, 0, "yes"
	.dt = Get time step
	.maxFrame = Get number of frames
	
	# Determine Peaks
	selectObject: .intensity
	.peaksInt = noprogress To IntensityTier (peaks)
	.peaksPoint = Down to PointProcess
	.peaksPointTier = Up to TextTier: "P"
	Rename: "Peaks"
	
	# Determine valleys
	selectObject: .intensity
	.valleyInt = noprogress To IntensityTier (valleys)
	.valleyPoint = Down to PointProcess
	.valleyPointTier = Up to TextTier: "V"
	Rename: "Valleys"
	
	selectObject: .peaksPointTier, .valleyPointTier
	.segmentTextGrid = Into TextGrid
	
	selectObject: .peaksPointTier, .valleyPointTier, .peaksInt, .peaksPoint, .valleyInt, .valleyPoint
	Remove
	
	# Select the sounding part
	selectObject: .intensity
	.silenceTextGrid = noprogress To TextGrid (silences): .silence_threshold, .minimum_pause_duration, 0.05, "silent", "sounding"
	
	# Determine voiced parts
	selectObject: .soundid
	.voicePP = noprogress To PointProcess (periodic, cc): 75, 600
	.vuvTextGrid = noprogress To TextGrid (vuv): 0.02, 0.01
	plusObject: .segmentTextGrid, .silenceTextGrid
	.textgridid = Merge
	
	selectObject: .vuvTextGrid, .silenceTextGrid, .segmentTextGrid, .voicePP
	Remove
	
	# Remove irrelevant peaks and valleys
	selectObject: .textgridid
	.numPeaks = Get number of points: 1
	for .i to .numPeaks
		.t = Get time of point: 1, .numPeaks + 1 - .i
		.s = Get interval at time: 3, .t
		.soundLabel$ = Get label of interval: 3, .s
		.v = Get interval at time: 4, .t
		.voiceLabel$ = Get label of interval: 4, .v
		if .soundLabel$ = "silent" or .voiceLabel$ = "U"
			Remove point: 1, .numPeaks + 1 - .i
		endif
	endfor
	
	# valleys
	selectObject: .textgridid
	.numValleys = Get number of points: 2
	.numPeaks = Get number of points: 1
	# No peaks, nothing to do
	if .numPeaks <= 0
		goto VALLEYREADY
	endif
	
	for .i from 2 to .numValleys
		selectObject: .textgridid
		.il = .numValleys + 1 - .i
		.ih = .numValleys + 2 - .i
		.tl = Get time of point: 2, .il
		.th = Get time of point: 2, .ih
		
		
		.ph = Get high index from time: 1, .tl
		.tph = 0
		if .ph > 0 and .ph <= .numPeaks
			.tph = Get time of point: 1, .ph
		endif
		# If there is no peak between the valleys remove the highest
		if .tph <= 0 or (.tph < .tl or .tph > .th)
			# If the area is silent for both valleys, keep the one closest to a peak
			.psl = Get interval at time: 3, .tl
			.psh = Get interval at time: 3, .th
			.psl_label$ = Get label of interval: 3, .psl
			.psh_label$ = Get label of interval: 3, .psh
			if .psl_label$ = "silent" and .psh_label$ = "silent"
				.plclosest = Get nearest index from time: 1, .tl
				if .plclosest <= 0
					.plclosest = 1
				endif
				if .plclosest > .numPeaks
					.plclosest = .numPeaks
				endif
				.tlclosest = Get time of point: 1, .plclosest
				.phclosest = Get nearest index from time: 1, .th
				if .phclosest <= 0
					.phclosest = 1
				endif
				if .phclosest > .numPeaks
					.phclosest = .numPeaks
				endif
				.thclosest = Get time of point: 1, .phclosest
				if abs(.tlclosest - .tl) > abs(.thclosest - .th)
					selectObject: .textgridid
					Remove point: 2, .il
				else
					selectObject: .textgridid
					Remove point: 2, .ih
				endif
			else
				# Else Compare valley depths
				selectObject: .intensity
				.intlow = Get value at time: .tl, "Cubic"
				.inthigh = Get value at time: .th, "Cubic"
				if .inthigh >= .intlow
					selectObject: .textgridid
					Remove point: 2, .ih
				else
					selectObject: .textgridid
					Remove point: 2, .il
				endif
			endif
		endif
	endfor

	# Remove superfluous valleys
	selectObject: .textgridid
	.numValleys = Get number of points: 2
	.numPeaks = Get number of points: 1
	for .i from 1 to .numValleys
		selectObject: .textgridid
		.iv = .numValleys + 1 - .i
		.tv = Get time of point: 2, .iv
		.ph = Get high index from time: 1, .tv
		if .ph > .numPeaks
			.ph = .numPeaks
		endif
		.tph = Get time of point: 1, .ph
		.pl = Get low index from time: 1, .tv
		if .pl <= 0
			.pl = 1
		endif
		.tpl = Get time of point: 1, .pl
		
		# Get intensities
		selectObject: .intensity
		.v_int = Get value at time: .tv, "Cubic"
		.pl_int = Get value at time: .tpl, "Cubic"
		.ph_int = Get value at time: .tph, "Cubic"
		# If there is no real dip, remove valey and lowest peak
		if min((.pl_int - .v_int), (.ph_int - .v_int)) < .minimum_dip_between_peaks
			selectObject: .textgridid
			Remove point: 2, .iv
			if .ph <> .pl
				if .pl_int < .ph_int
					Remove point: 1, .pl
				else
					Remove point: 1, .ph
				endif
			endif
			.numPeaks = Get number of points: 1
			if .numPeaks <= 0
				goto VALLEYREADY
			endif
		endif
	endfor
	label VALLEYREADY
	
	selectObject: .intensity
	Remove
	
	selectObject: .textgridid
endproc

# 
# Determine COG as an intensity
#
# .cog_Matrix = Down to Matrix
# call calculateCOG .dt .soundid
# .cog_Tier = calculateCOG.cog_tier
# selectObject: .cog_Tier
# .numPoints = Get number of points
# for .i to .numPoints
# 	selectObject: .cog_Tier
# 	.cog = Get value at index: .i
# 	.t = Get time from index: .i
# 	selectObject: .intensity
# 	.c = Get frame number from time: .t
# 	if .c >= 0.5 and .c <= .maxFrame
# 		selectObject: .cog_Matrix
# 		Set value: 1, round(.c), .cog
# 	endif
# endfor
# selectObject: .cog_Matrix
# .cogIntensity = noprogress To Intensity

procedure calculateCOG .dt .sound
	selectObject: .sound
	.duration = Get total duration
	if .dt <= 0 or .dt > .sound
		.dt = 0.01
	endif
	
	# Create Spectrogram
	selectObject: .sound
	.spectrogram = noprogress To Spectrogram: 0.005, 8000, 0.002, 20, "Gaussian"
	.cog_tier = Create IntensityTier: "COG", 0.0, .duration
	
	.t = .dt / 2
	while .t < .duration
		selectObject: .spectrogram
		.spectrum = noprogress To Spectrum (slice): .t
		.cog_t = Get centre of gravity: 2
		selectObject: .cog_tier
		Add point: .t, .cog_t
		
		.t += .dt
		
		selectObject: .spectrum
		Remove
	endwhile
	
	selectObject: .spectrogram
	Remove
endproc

# Initialize missing columns. Column names ending with a $ are text
procedure initialize_table_collumns .table, .columns$, .initial_value$
	.columns$ = replace_regex$(.columns$, "^\W+", "", 0)
	selectObject: .table
	.numRows = Get number of rows
	while .columns$ <> ""
		.label$ = replace_regex$(.columns$, "^\W*(\w+)\W.*$", "\1", 0)
		.columns$ = replace_regex$(.columns$, "^\W*(\w+)", "", 0)
		.textType = startsWith(.columns$, "$")
		if not .textType and index_regex(.initial_value$, "[0-9]") <= 0
			.textType = 1
		endif
		.columns$ = replace_regex$(.columns$, "^\W+", "", 0)
		.col = Get column index: .label$
		if .col <= 0
			Append column: .label$
			for .r to .numRows
				if .textType
					Set string value: .r, .label$, .initial_value$
				else
					Set value: .r, .label$, '.initial_value$'
				endif
			endfor
		endif
	endwhile
endproc
