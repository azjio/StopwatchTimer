;- TOP
; AZJIO 10.02.2021 Секундомер / Таймер

EnableExplicit

Structure aTimerID
	; id.i          ; номер таймера
	flag.i          ; флаг запуска таймера
	markstart.i		; метка времени начала
	markend.i		; метка времени конца
	hour.i			; часы
	minute.i		; минуты
	second.i		; секунды
	path.s			; путь к файлу запуска
EndStructure

;- ● Declare
Declare _bk()
Declare StartTimer()
Declare info()
Declare ForceDirectories(Dir.s)
Declare Execute(comstr$)
Declare TestExecute(comstr$)
Declare.s SetWidth(num)
; CompilerIf #PB_Compiler_OS= #PB_OS_Linux
; CompilerEndIf
CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		Declare HideFromTaskBar(hWnd.i, Flag.l)
		Declare SetWindowFocus(wID)
    CompilerCase #PB_OS_Linux
		Declare.s EscapeFilePath(String.s)
CompilerEndSelect
Declare Win_About()
Declare OpenWindow_FastSetTime()

;- ● Global
; Global.i HourTmp, MinTmp, SecTmp, MsecTmp, Date0, Second0, Minute0, Hour0
Global minitem, maxitem, em, DefExe$
Global List1Color, List3Color
Global bTime = 0, tmp$, tmp, tmp1, EvnGd, itemCur = -1, i, fStartTimer
Global Name$, item$, Time$, Execute$, index, WWE
Global ini$
CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		Global PathHelp$ = GetPathPart(ProgramFilename()) + "StopwatchTimer.chm"
    CompilerCase #PB_OS_Linux
		Global PathHelp$ = "/usr/share/help/ru/stopwatchtimer/index.html"
CompilerEndSelect

Define working$
Define offset1 = 0
Define width1, xl1, ListWidth_tmp, ListHeight_tmp



; Определение языка интерфейса и применение
Global UserIntLang, UserIntLang$, PathLang$, *Lang


; Определяет язык ОС
CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		If OpenLibrary(0, "kernel32.dll")
			*Lang = GetFunction(0, "GetUserDefaultUILanguage")
			If *Lang
				UserIntLang = CallFunctionFast(*Lang)
			EndIf
			CloseLibrary(0)
		EndIf
    CompilerCase #PB_OS_Linux
		If ExamineEnvironmentVariables()
		    While NextEnvironmentVariable()
		    	If Left(EnvironmentVariableName(), 4) = "LANG"
; 		    		LANG=ru_RU.UTF-8
; 		    		LANGUAGE=ru
					UserIntLang$ = Left(EnvironmentVariableValue(), 2)
					Break
				EndIf
		    Wend
		EndIf
CompilerEndSelect
; Debug UserIntLang$

#CountStrLang = 53 ; число строк перевода и соответсвенно массива
Global Dim Lng.s(#CountStrLang)
; Строки интерфейса даже если языковой файл не найден

;- Language En
Lng(1) = "Signal"
Lng(2) = "Hours"
Lng(3) = "Minutes"
Lng(4) = "Seconds"
Lng(5) = "Set"
Lng(6) = "Calculate the interval to a given date"
Lng(7) = "Signal Test"
Lng(8) = "Really check the event (volume, existing path)"
Lng(9) = "Auto start timer"
Lng(10) = "Save"
Lng(11) = "Save new timer in ini"
Lng(12) = "Open ini"
Lng(13) = "Message"
Lng(14) = "Open"
Lng(15) = "Command line"
Lng(16) = "--info --title=Error --text=Failed—to—execute—command"
Lng(17) = "Stopwatch / Timer"
Lng(18) = "Add"
Lng(19) = "Start"
Lng(20) = "Show the present start and end timers"
Lng(21) = "Reset"
Lng(22) = "Delete"
Lng(23) = "End time"
Lng(24) = "Stopwatch"
Lng(25) = "Timer"
Lng(26) = "Show window"
Lng(27) = "Reference"
Lng(28) = "About..."
Lng(29) = "Exit"
Lng(30) = "--info --title=Signal --text="
Lng(31) = "The specified time must be greater than the current"
Lng(32) = "The interval should be no more than 24 hours"
Lng(33) = "Specify timer time"
Lng(34) = "Timer Name"
Lng(35) = "Specify timer name:"
Lng(36) = "Overwrite existing "
Lng(37) = "Test"
Lng(38) = "Event not set"
Lng(39) = "Message - not yet used"
Lng(40) = "--info --title=Signal --text=Time"
Lng(41) = "Time?"
Lng(42) = "--info --title=Time? --text=Time?"
Lng(43) = "Signal file not found"
Lng(44) = "Open file"
Lng(45) = "All (*.*)"
Lng(46) = "Enter"
Lng(47) = "About"
Lng(48) = "site:"
Lng(49) = "Default"
Lng(50) = "Default file?"
Lng(51) = "Do you want to use this file as the default in the future if there is no choice?"
Lng(52) = "The default file is missing. Choose?"
Lng(53) = "Fast"

; определяет пути к языковому файлу
CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		PathLang$ = GetPathPart(ProgramFilename()) + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + "_Lang.txt"
    CompilerCase #PB_OS_Linux
; 		PathLang$ ="/usr/share/locale/" + UserIntLang$ + "/LC_MESSAGES/" + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + ".txt"
		PathLang$ ="/usr/share/locale/" + UserIntLang$ + "/LC_MESSAGES/StopwatchTimer.txt"
CompilerEndSelect
; Debug PathLang$

; Если языковой файл существует, то использует его
If FileSize(PathLang$) > 100
	
	If ReadFile(0, PathLang$) ; Если удалось открыть дескриптор файла, то
		i=0
	    While Eof(0) = 0        ; Цикл, пока не будет достигнут конец файла. (Eof = 'Конец файла')
	    	tmp$ =  ReadString(0) ; читаем строку
; 	    	If Left(tmp$, 1) = ";"
; 	    		Continue
; 	    	EndIf
	    	tmp$ = ReplaceString(tmp$ , #CR$ , "") ; коррекция если в Windows
	    	If tmp$ And Left(tmp$, 1) <> ";"
	    		i+1
	    		If i > #CountStrLang ; массив Lng() уже задан, но если строк больше нужного, то не разрешаем лишнее
	    			Break
	    		EndIf
	    		Lng(i) = tmp$
	    	Else
	    		Continue
	    	EndIf
	    Wend
	    CloseFile(0)
	EndIf
; Else
; 	SaveFile_Buff(PathLang$, ?LangFile, ?LangFileend - ?LangFile)
EndIf

; Конец => Определение языка

CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		Global Font$ = "Arial"
		Global FontSize = 20
    CompilerCase #PB_OS_Linux
		Global Font$ = "Sans"
		Global FontSize = 17
CompilerEndSelect
Global ListWidth = 126
Global ListHeight = 120
; Global message = 0
; Global notify = 0


Procedure WriteINI()
		WriteStringFormat(0, #PB_UTF8)
		WriteStringN(0, "[set]", #PB_UTF8)
		WriteStringN(0, "Font=" + Font$, #PB_UTF8)
		WriteStringN(0, "FontSize=" + Str(FontSize), #PB_UTF8)
		WriteStringN(0, "ListWidth=" + Str(ListWidth), #PB_UTF8)
		WriteStringN(0, "ListHeight=" + Str(ListHeight), #PB_UTF8)
		WriteStringN(0, "List1Color=3a3dc0", #PB_UTF8)
		WriteStringN(0, "List3Color=3ac03d", #PB_UTF8)
; 		WriteStringN(0, "message=0", #PB_UTF8)
; 		WriteStringN(0, "notify=0", #PB_UTF8)
		
		WriteStringN(0, "[timer 1]", #PB_UTF8)
		WriteStringN(0, "Time=0:11:0", #PB_UTF8)
		CompilerSelect #PB_Compiler_OS
		    CompilerCase #PB_OS_Windows
				WriteStringN(0, "Execute=C:\file.mp3", #PB_UTF8)
		    CompilerCase #PB_OS_Linux
				WriteStringN(0, "Execute=/home/user/Music/file.mp3", #PB_UTF8)
		CompilerEndSelect
		CloseFile(0)
EndProcedure


;- ini
ini$ = GetPathPart(ProgramFilename()) + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + ".ini"
If FileSize(ini$) < 8
; 	Если рядом с прогой файла нет, то прога не портабельная и ищем конфиг в папках конфигов
; 		Создаём в AppData\Roaming, если в текущей не удалось
	CompilerSelect #PB_Compiler_OS
	    CompilerCase #PB_OS_Windows
			ini$ = GetUserDirectory(#PB_Directory_ProgramData) + "StopwatchTimer\" + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + ".ini"
	    CompilerCase #PB_OS_Linux
			ini$ = GetHomeDirectory() + ".config/StopwatchTimer/StopwatchTimer.ini"
	CompilerEndSelect
	If FileSize(ini$) < 8 And ForceDirectories(GetPathPart(ini$)) And CreateFile(0, ini$)
		WriteINI()
	EndIf
EndIf

; если нет настроек, то добавляем их. В будущем удалить, только для совместимости со старой версией
If FileSize(ini$) > 3 And OpenPreferences(ini$)
	If Not PreferenceGroup("set")
		WritePreferenceString("Font" , Font$)
		WritePreferenceInteger("FontSize" , FontSize)
		WritePreferenceInteger("ListWidth" , ListWidth)
		WritePreferenceInteger("ListHeight" , ListHeight)
		WritePreferenceString("List1Color" , "3a3dc0")
		WritePreferenceString("List3Color" , "3ac03d")
	EndIf
	ClosePreferences()
EndIf

; читаем настройки
If FileSize(ini$) > 3 And OpenPreferences(ini$)
	If PreferenceGroup("set")
		FontSize = ReadPreferenceInteger("FontSize", FontSize)
		If FontSize > 100 Or FontSize < 7
			FontSize = 20
			WritePreferenceInteger("FontSize" , 20)
		EndIf
		ListWidth = ReadPreferenceInteger("ListWidth", ListWidth)
		If ListWidth > 500 Or ListWidth < 50
			ListWidth = 126
			WritePreferenceInteger("ListWidth" , 126)
		EndIf
		ListHeight = ReadPreferenceInteger("ListHeight", ListHeight)
		If ListHeight > 1000 Or ListHeight < 120
			ListHeight = 120
			WritePreferenceInteger("ListHeight" , 120)
		EndIf
		DefExe$ = ReadPreferenceString("DefExe", DefExe$)
		Font$ = ReadPreferenceString("Font", Font$)
		List1Color = Val("$" + ReadPreferenceString("List1Color", "3a3dc0"))
		List3Color = Val("$" + ReadPreferenceString("List3Color", "3ac03d"))
		; 	message = ReadPreferenceInteger("message", message)
		; 	notify = ReadPreferenceInteger("notify", notify)
	EndIf
	ClosePreferences()
EndIf

#Red1 = $8888FF
#Green1 = $88FF88

Structure button
	x.f
	y.f
	r.f
	tw.i
	th.i
	text.s
	backcolor.i
EndStructure

#MinutesCircle = 30
#WindowSize = 250
Global Dim bMinute.button(#MinutesCircle)


Global NewList ListTimer.aTimerID() ; список структур
;MessageRequester("", ini$)

;- ● Enumeration
; Окна
Enumeration
	#Window_Main
	#Window_AddTimer
	#Win_About
	#WindowFastSetTime
EndEnumeration

; Гаджеты
Enumeration
	#ListBox
	#ListBoxTimer
	#ListBoxEnd
	#btnAdded
	#Border
	#btnStart
	#btnReset
	#btnDelete
	#Minute
	#Hour
	#Text1
	#Text2
	#Text3
	#InpHour
	#InpMinute
	#InpSec
	#label1
	#label2
	#label3
	#ListBoxINI
	#Combo
	#OK
	#Play
	#Save
	#ChAutoStart
	#OpenINI
	#Date
	#DateApply
	#info
	#cnvs
	#btnFastST
	
; 	о программе
	#labelA
	#labelAv
	#labelAs
	#link
	#labelAc
	#labelAf
EndEnumeration

; Меню
Enumeration
	#mClose
	#mAbout
	#mHelp
	#mShow
	#mExit
EndEnumeration

; Шрифты
Enumeration
	#Font_Text_0
EndEnumeration

Define.l Event, EventWindow, EventGadget, EventType, EventMenu

; ImportC "msvcrt.lib"
; 	swprintf(*s, Format.s, Param1=0, Param2=0, Param3=0, Param4=0)
; EndImport

; Отключил, выкидывает сообщение при входе в ждущий режим, не даёт перейти в ждущий режим
; CompilerIf #PB_Compiler_OS = #PB_OS_Windows
;
; 	Procedure WinCallback(hWnd, uMsg, WParam, LParam)
; 		If uMsg = #WM_TIMECHANGE
; 			bTime = 1
; 		EndIf
; 		ProcedureReturn #PB_ProcessPureBasicEvents
; 	EndProcedure
;
; CompilerEndIf

CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		#width2 = 410
		#xl2 = 345
		#width3 = 140
    CompilerCase #PB_OS_Linux
		#width2 = 480
		#xl2 = 395
		#width3 = 170

; 		UsePNGImageDecoder()
		UseGIFImageDecoder()
		; https://www.purebasic.fr/english/viewtopic.php?p=531374#p531374
		ImportC ""
		  gtk_window_set_icon(a.l,b.l)
		EndImport
		
		DataSection
			IconTitle:
; 			IncludeBinary "StopwatchTimer.png"
			IncludeBinary "StopwatchTimer.gif"
			IconTitleend:
			
			folder_png:
			IncludeBinary "StopwatchTimer1.gif"
			folder_pngend:
		EndDataSection
		CatchImage(0, ?IconTitle)
		CatchImage(1, ?folder_png)
CompilerEndSelect

Procedure Window_AddTimer()
	Protected GroupN$
	If OpenWindow(#Window_AddTimer, #PB_Ignore, #PB_Ignore, #width2, 280, Lng(1), #PB_Window_SystemMenu|#PB_Window_MinimizeGadget|#PB_Window_TitleBar|#PB_Window_ScreenCentered, WindowID(#Window_Main))

		CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
			gtk_window_set_icon_(WindowID(#Window_AddTimer), ImageID(0)) ; назначаем иконку в заголовке
		CompilerEndIf
		ListViewGadget(#ListBoxINI, 10, 10, 180, 180) ; WS_VSCROLL + LBS_NOINTEGRALHEIGHT

		TextGadget(#label1, 200, 2, 55, 20, Lng(2))
		TextGadget(#label2, 257, 2, 58, 20, Lng(3))
		TextGadget(#label3, 320, 2, 65, 20, Lng(4))
		
		SpinGadget(#InpHour, 200, 25, 55, 26, 0, 24, #PB_Spin_Numeric)
		SetGadgetText(#InpHour, "0")
		SpinGadget(#InpMinute, 260, 25, 55, 26 , 0 , 59, #PB_Spin_Numeric)
		SetGadgetText(#InpMinute, "0")
		SpinGadget(#InpSec, 320, 25, 55, 26 , 0 , 59, #PB_Spin_Numeric)
		SetGadgetText(#InpSec, "0")

		DateGadget(#Date, 200, 61, #width3, 23, "%dd.%mm.%yyyy  %hh:%ii")
		ButtonGadget(#DateApply, #xl2, 61, 61, 25, Lng(5))
		GadgetToolTip(#DateApply , Lng(6))

		ButtonGadget(#Play, 200, 133, 120, 25, Lng(7))
		GadgetToolTip(#Play , Lng(8))
		CheckBoxGadget(#ChAutoStart, 200, 170, 160, 25, Lng(9))
		SetGadgetState(#ChAutoStart, #PB_Checkbox_Checked)

		ButtonGadget(#Save, 200, 195, 95, 25, Lng(10))
		GadgetToolTip(#Save , Lng(11))
		ButtonGadget(#OpenINI, 310, 195, 95, 25, Lng(12))

		ButtonGadget(#OK, 170, 235, 100, 32, "OK")

		ComboBoxGadget(#Combo, 200, 100, 200, 25)
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			SendMessage_(GadgetID(#Combo), #CB_SETDROPPEDWIDTH, 400, #Null)
		CompilerEndIf
		
		AddGadgetItem(#Combo,-1, Lng(13))
		If Asc(DefExe$)
			AddGadgetItem(#Combo,0, Lng(49))
			SetGadgetText(#Combo , Lng(49))
		Else
			SetGadgetText(#Combo , Lng(13))
		EndIf
		AddGadgetItem(#Combo,-1, Lng(14))
		AddGadgetItem(#Combo,-1, Lng(15))
		
		CompilerIf #PB_Compiler_OS = #PB_OS_Linux
			tmp$ = ";"
		CompilerEndIf
		If OpenPreferences(ini$)
			ExaminePreferenceGroups()
			While NextPreferenceGroup()
				GroupN$ = PreferenceGroupName()
				If GroupN$ = "set"
					Continue
				EndIf
				AddGadgetItem(#ListBoxINI , -1, GroupN$)
				Execute$ = ReadPreferenceString("Execute", "")
				If Execute$
					CompilerIf #PB_Compiler_OS = #PB_OS_Linux
						; 					Для Linux устраняет дубликаты в списке
						If FindString(tmp$, ";" + Execute$ + ";")
							Continue
						EndIf
						tmp$ + Execute$ + ";"
					CompilerEndIf
					AddGadgetItem(#Combo,-1, Execute$)
				EndIf
			Wend
			CompilerIf #PB_Compiler_OS = #PB_OS_Linux
				tmp$ = ""
			CompilerEndIf
			ClosePreferences()
		EndIf
	EndIf
EndProcedure


CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		width1 = ListWidth * 3+96
		xl1 = ListWidth*3+70
    CompilerCase #PB_OS_Linux
		width1 = ListWidth * 3+147
		xl1 = ListWidth * 3+97
CompilerEndSelect
ListWidth_tmp = ListWidth
ListHeight_tmp = ListHeight

Procedure Execute(comstr$)
	Protected Pos, Command$, NotAction = 1, tmp$
; 	Debug "|"+comstr$+"|"
	comstr$ = LTrim(comstr$)
; 	If comstr$ = ""
; 		NotAction = 1
; 	EndIf
	Pos = FindString(comstr$ , " ")
	If Pos
		Command$ = Left(comstr$, Pos-1)
; 		comstr$ = Mid(comstr$, Pos+1)
		If (FileSize("/usr/bin/" + Command$) > 4 Or FileSize(Command$) > 4) And RunProgram(Command$, Mid(comstr$, Pos+1), "") ; выделение работает
			NotAction = 0
; 			Debug NotAction
			Else
; 			Debug NotAction
; 			MessageRequester("Ошибка", "Не удалось выполнить команду:" + #LF$ + comstr$ + #LF$ + "Проверте что эта программа установлена.")
			; 		MessageRequester("|" +Mid(comstr$, 1, Pos-1) + "|", "|" +Mid(comstr$, Pos+1) + "|")
			NotAction = 1
		EndIf
	EndIf
	If NotAction
		CompilerSelect #PB_Compiler_OS
			CompilerCase #PB_OS_Windows
				tmp$ = "Title " + Lng(17) + " & @Echo off & @Echo. & Color 1e & @Echo. " + Lng(16) + "& "
				tmp$ = EscapeString(tmp$)
				RunProgram("cmd.exe", "/c (" + tmp$ + " set /p Ok=^>^>)", "")
			CompilerCase #PB_OS_Linux
				RunProgram("zenity", Lng(16), "")
		CompilerEndSelect
		
	EndIf
EndProcedure

Procedure TestExecute(comstr$)
	Protected Pos, Command$
	comstr$ = LTrim(comstr$)
	If comstr$ = ""
		ProcedureReturn 0
	EndIf
	Pos = FindString(comstr$ , " ")
	If Pos
		Command$ = Left(comstr$, Pos-1)
		If FileSize("/usr/bin/" + Command$) > 4 Or FileSize(Command$) > 4
			ProcedureReturn 1
		EndIf
	EndIf
	ProcedureReturn 0
EndProcedure

;-┌──GUI──┐
If OpenWindow(#Window_Main, #PB_Ignore, #PB_Ignore, width1, ListHeight+30, Lng(17), #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)

	CompilerSelect #PB_Compiler_OS
	    CompilerCase #PB_OS_Windows
			HideFromTaskBar(WindowID(0),1) ; первая, чтобы не успела показать кнопку на панели задач
			AddSysTrayIcon(0, WindowID(0), GetClassLongPtr_(WindowID(0), #GCL_HICON))
	    CompilerCase #PB_OS_Linux
			gtk_window_set_icon_(WindowID(#Window_Main), ImageID(0)) ; назначаем иконку в заголовке
			AddSysTrayIcon(0, WindowID(0), ImageID(1))		  ; иконка в трее
			SysTrayIconToolTip(0, "StopwatchTimer")			  ; Название проги в подсказке
			gtk_window_set_skip_taskbar_hint_(WindowID(#Window_Main), #True) ; скрыть кнопку с панели задач
	CompilerEndSelect
	WindowBounds(#Window_Main, 440, 150, #PB_Ignore, #PB_Ignore)
	ListViewGadget(#ListBox, 3, 23, ListWidth, ListHeight)
	offset1 + ListWidth+4
	ListViewGadget(#ListBoxTimer, offset1, 23, ListWidth, ListHeight)
	offset1 + ListWidth+1
	ListViewGadget(#ListBoxEnd, offset1, 23, ListWidth, ListHeight)

	offset1 + ListWidth+8
	ButtonGadget(#btnAdded, offset1, 3, 80, 27, Lng(18))
	ButtonGadget(#btnStart, offset1, 38, 50, 27, Lng(19))
	ButtonGadget(#info, xl1, 38, 18, 27, "i")
	GadgetToolTip(#info , Lng(20))
	ButtonGadget(#btnReset, offset1, 73, 80, 27, Lng(21))
	ButtonGadget(#btnDelete, offset1, 108, 80, 27, Lng(22))
	ButtonGadget(#btnFastST, offset1, 143, 80, 27, Lng(53))
	_bk()
	; 	SetWindowCallback(@WinCallback())

	GadgetToolTip(#ListBoxEnd , Lng(23))

	TextGadget(#Text1, 3, 3, ListWidth-6, 20 , Lng(24), #PB_Text_Center)
	TextGadget(#Text2, ListWidth+4, 3, ListWidth-6, 20 , Lng(25), #PB_Text_Center)
	TextGadget(#Text3, ListWidth*2 + 8, 3, ListWidth-6, 20 , Lng(1), #PB_Text_Center)
	
	#Menu = 0
	#MenuSmp = 1
	
	If CreatePopupMenu(#Menu) ; Создаёт всплывающее меню
		MenuItem(#mShow, Lng(26))
		If FileSize(PathHelp$) > 10
			MenuItem(#mHelp, Lng(27))
; 			DisableMenuItem(#Menu, #mHelp, 1)
		EndIf
		MenuItem(#mAbout, Lng(28))
		MenuBar()
		MenuItem(#mExit, Lng(29))
	EndIf
	
	If CreatePopupMenu(#MenuSmp) ; Создаёт всплывающее меню
		If OpenPreferences(ini$)
			ExaminePreferenceGroups()
			i = #mExit
			While NextPreferenceGroup()
				tmp$ = PreferenceGroupName()
				If tmp$ = "set"
					Continue
				EndIf
				i + 1
				MenuItem(i, tmp$)
			Wend
			maxitem = i
			If maxitem > #mExit
				minitem = #mExit + 1
			EndIf
			ClosePreferences()
		EndIf
	EndIf
EndIf

;-┌──Loop──┐
; Обработать гаджеты только этого окна
Repeat
	WWE = WaitWindowEvent()
	If WWE = #PB_Event_Timer
		; 		If bTime
		; 			bTime = 0
		; 			MessageRequester(Lng(13), "Изменено системное время, которое влияет на таймер")
		; 		EndIf
		; 			SetWindowTitle(#Window_Main, FormatDate("%hh:%ii:%ss",Date()))
		; 			Debug Str()
		i =- 1
		ForEach ListTimer()
			i = i + 1
			If 1 = ListTimer()\flag ; если таймер включен, то
; 				i = ListIndex(ListTimer())

				SetGadgetItemText(#ListBox , i, FormatDate("%hh:%ii:%ss", Date() - ListTimer()\markstart))
				tmp = ListTimer()\markend - Date()
				If tmp > 0
					SetGadgetItemText(#ListBoxTimer , i, FormatDate("%hh:%ii:%ss", tmp))
				Else
					; 					срабатывание таймера, запуск файла
					SetGadgetItemText(#ListBoxTimer , i , "00:00:00")
					ListTimer()\flag = 0 ; отключаем таймер
					RemoveWindowTimer(#Window_Main, i)
					
					; сделать окно активным, дополнительно напоминая о срабатывании таймера.
					CompilerSelect #PB_Compiler_OS
					    CompilerCase #PB_OS_Windows
							SetWindowFocus(#Window_Main)
; 							SetForegroundWindow_(WindowID(#Window_Main))
					    CompilerCase #PB_OS_Linux
							StickyWindow(#Window_Main, #True)
							StickyWindow(#Window_Main, #False)
					CompilerEndSelect
					
; 					Если путь не существует, то назначаем дефолтный путь общий для всех из ini-файла
					If Not Asc(ListTimer()\path) And Asc(DefExe$)
						ListTimer()\path = DefExe$
					EndIf
					If FileSize(ListTimer()\path) >= 0
						CompilerSelect #PB_Compiler_OS
							CompilerCase #PB_OS_Windows
								RunProgram(ListTimer()\path)
							CompilerCase #PB_OS_Linux
								ListTimer()\path = EscapeFilePath(ListTimer()\path)
								RunProgram("xdg-open", ListTimer()\path, GetPathPart(ListTimer()\path))
; 								If message Or notify
; 								EndIf
; 								If notify
; ; 									RunProgram("notify-send", "'Сигнал' '" + item$ + "'", "")
; 									RunProgram("notify-send", "Сигнал " + item$, "")
; 								EndIf
; 								If message
; 									RunProgram("zenity", Lng(30) + item$, "")
; 								EndIf
						CompilerEndSelect
					ElseIf ListTimer()\path = Lng(13)
;		 				item$ = Str(ListTimer()\hour) + ":" + Str(ListTimer()\minute) + ":" + Str(ListTimer()\second) + "—(" + FormatDate("%hh:%ii:%ss", ListTimer()\markstart) + "—" + FormatDate("%hh:%ii:%ss", ListTimer()\markend) + ")"
						item$ = FormatDate("%hh:%ii:%ss", ListTimer()\markend - ListTimer()\markstart) + "—(" + FormatDate("%hh:%ii:%ss", ListTimer()\markstart) + "—" + FormatDate("%hh:%ii:%ss", ListTimer()\markend) + ")"
						CompilerSelect #PB_Compiler_OS
							CompilerCase #PB_OS_Windows
								; 								придумать универсальное сообщение
								tmp$ = "Title " + Lng(17) + " & @Echo off & @Echo. & Color 1e & @Echo. " + item$ + "& "
								tmp$ = EscapeString(tmp$)
								tmp$ = ReplaceString(tmp$, ")", "^)")
								tmp$ = ReplaceString(tmp$, "(", "^(")
								RunProgram("cmd.exe", "/c (" + tmp$ + " set /p Ok=^>^>)", "")
							CompilerCase #PB_OS_Linux
								RunProgram("zenity", Lng(30) + item$, "")
						CompilerEndSelect
					Else
						Execute(ListTimer()\path)
					EndIf
				EndIf
			EndIf
		Next
	EndIf

	Select EventWindow()
		Case #Window_AddTimer

;- ├ Gadget События 2 окна
			Select WWE
				Case #PB_Event_Gadget
					EvnGd = EventGadget()
					Select EvnGd
						Case #DateApply
							tmp1 = GetGadgetState(#Date) - Date()
							If tmp1 <= 0 ; интервал отрицательный
								MessageRequester(Lng(13), Lng(31))
								Continue
							EndIf
							If tmp1 > 86400 ; 86400 - 24 часа. 359999 - 100 часов без секунды, но в таймер вводится часовая составляющая, а сутки в другом регистре. 
								MessageRequester(Lng(13), Lng(32))
								Continue
							EndIf
							If tmp1 >= 3600
								SetGadgetText(#InpHour, Str(Int(tmp1/3600)))
; 								SetGadgetText(#InpHour, Round(tmp1/3600, #PB_Round_Down))
							EndIf
							tmp1 = Mod(tmp1, 3600)
							If tmp1 >= 60
								SetGadgetText(#InpMinute, Str(Int(tmp1/60)))
; 								SetGadgetText(#InpMinute, Round(tmp1/60, #PB_Round_Down))
							EndIf
							tmp1 = Mod(tmp1, 60)
							SetGadgetText(#InpSec, Str(Int(tmp1)))
; 							SetGadgetText(#InpSec, Round(tmp1, #PB_Round_Down))
						Case #OpenINI
							CompilerSelect #PB_Compiler_OS
								CompilerCase #PB_OS_Windows
									RunProgram(ini$)
								CompilerCase #PB_OS_Linux
									RunProgram("xdg-open", ini$, GetPathPart(ini$))
							CompilerEndSelect
						Case #Save
							Time$ = GetGadgetText(#InpHour) + ":" + GetGadgetText(#InpMinute) + ":" + GetGadgetText(#InpSec)
							If Time$ = "0:0:0"
								MessageRequester(Lng(13), Lng(33))
								Continue
							EndIf
							item$ = InputRequester(Lng(34), Lng(35), "")
							If item$
								OpenPreferences(ini$)
								tmp1 = PreferenceGroup(item$)
								If Not tmp1 Or MessageRequester(Lng(13), Lng(36) + item$ + "?", 4) = #PB_MessageRequester_Yes
									WritePreferenceString("Time" , Time$)
									Execute$ = GetGadgetText(#Combo)
									Select Execute$
										Case Lng(14), Lng(49)
											Execute$ = ""
; 										Case Lng(49)
; 											Execute$ = ""
										Case Lng(13)
											Execute$ = Lng(13)
										Default
											WritePreferenceString("Execute" , Execute$)
									EndSelect
									If Not tmp1
										AddGadgetItem(#ListBoxINI , -1, item$)
									EndIf
								EndIf
								ClosePreferences()
							EndIf
						Case #Play
							Execute$ = GetGadgetText(#Combo)
							Select Execute$
								Case Lng(14), Lng(15)
									MessageRequester(Lng(37), Lng(38))
								Case Lng(13)
									CompilerSelect #PB_Compiler_OS
										CompilerCase #PB_OS_Windows
; 											MessageRequester(Lng(37), Lng(39))
											tmp$ = "Title " + Lng(17) + " & @Echo off & @Echo. & Color 1e & @Echo. " + Lng(17) + "& "
											tmp$ = EscapeString(tmp$)
											RunProgram("cmd.exe", "/c (" + tmp$ + " set /p Ok=^>^>)", "")

										CompilerCase #PB_OS_Linux
											RunProgram("zenity", Lng(40), "")
									CompilerEndSelect
									
; 									MessageRequester(Lng(37), "Стандартный - пока не используется")
									; Execute$ = "" ; пока пусто, надо сделать поиск в папке стандартных звуков
								Case Lng(49), ""
									If Asc(DefExe$)
										If FileSize(DefExe$) >= 0
											CompilerSelect #PB_Compiler_OS
												CompilerCase #PB_OS_Windows
													RunProgram(DefExe$)
												CompilerCase #PB_OS_Linux
													tmp$ = EscapeFilePath(DefExe$)
													RunProgram("xdg-open", tmp$, GetPathPart(tmp$))
											CompilerEndSelect
										Else
											Execute(DefExe$)
										EndIf
									Else
; 										Здесь добавляется DefExe$, но в теории этот код не нужен, так как пункт не будет сущестовать при отсутствии пути.
										If MessageRequester(Lng(50), Lng(52), #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
		 									If working$ = ""
												CompilerSelect #PB_Compiler_OS
													CompilerCase #PB_OS_Windows
														working$ = "C:\Windows\media"
		; 												working$ = GetCurrentDirectory()
													CompilerCase #PB_OS_Linux
														working$ = "/usr/share/sounds/"
												CompilerEndSelect
											EndIf
		 									Execute$ = OpenFileRequester(Lng(44), working$, Lng(45), 0)
											If Execute$
												AddGadgetItem(#Combo,-1, Execute$)
; 												SetGadgetText(#Combo , Execute$)
												working$ = GetPathPart(Execute$) ; запоминаем рабочий каталог
	; 											предлагаем выбрать файл как дефолтный
												If OpenPreferences(ini$)
													If PreferenceGroup("set")
														WritePreferenceString("DefExe", Execute$)
														DefExe$ = Execute$
													EndIf
													ClosePreferences()
												EndIf
											Else
												SetGadgetText(#Combo , Lng(13))
											EndIf
										EndIf
									EndIf

								Default
									If FileSize(Execute$) >= 0
										CompilerSelect #PB_Compiler_OS
											CompilerCase #PB_OS_Windows
												RunProgram(Execute$)
											CompilerCase #PB_OS_Linux
												tmp$ = EscapeFilePath(Execute$)
												RunProgram("xdg-open", tmp$, GetPathPart(tmp$))
; 												Debug tmp$
; 												If message
; 													RunProgram("zenity", "--info --title=Сигнал --text=Время", "")
; 												EndIf
; 												If notify
; 													RunProgram("notify-send", "'Сигнал' 'Время'", "")
; 												EndIf
										CompilerEndSelect
									Else
; 										MessageRequester(Lng(37), "Файл не найден")
										Execute(Execute$)
									EndIf
							EndSelect
							
							
							
						Case #OK
							AddElement(ListTimer())
							ListTimer()\hour = Val(GetGadgetText(#InpHour))
							ListTimer()\minute = Val(GetGadgetText(#InpMinute))
							ListTimer()\second = Val(GetGadgetText(#InpSec))
							If ListTimer()\hour = 0 And ListTimer()\minute = 0 And ListTimer()\second = 0
								; 						MessageRequester(Lng(13), Lng(33))
								DeleteElement(ListTimer(), 1) ; удаляем элемент списка если не собираемся его добавлять в таймеры
								CompilerSelect #PB_Compiler_OS
									CompilerCase #PB_OS_Windows
										MessageRequester(Lng(41), Lng(41))
									CompilerCase #PB_OS_Linux
										RunProgram("zenity", Lng(42), "")
								CompilerEndSelect
								Continue
							EndIf
							Execute$ = GetGadgetText(#Combo)
							If Not Asc(Execute$) Or Execute$ = Lng(49)
								Execute$ = DefExe$
							EndIf
							Select Execute$
								Case Lng(14)
									Execute$ = ""
								Case Lng(13)
									ListTimer()\path = Lng(13)
; 								Case "Стандартный"
; 									Execute$ = "" ; пока пусто, надо сделать поиск в папке стандартных звуков
								Default
									If FileSize(Execute$) >= 0
										ListTimer()\path = Execute$
									Else
										If TestExecute(Execute$)
											ListTimer()\path = Execute$
										Else
											MessageRequester(Lng(37), Lng(43))
										EndIf
									EndIf
							EndSelect
							fStartTimer = GetGadgetState(#ChAutoStart)
							CloseWindow(#Window_AddTimer)
							
							
							AddGadgetItem(#ListBox, -1, "00:00:00")
							AddGadgetItem(#ListBoxEnd, -1, SetWidth(ListTimer()\hour) + ":" + SetWidth(ListTimer()\minute) + ":" + SetWidth(ListTimer()\second))
							AddGadgetItem(#ListBoxTimer, -1, SetWidth(ListTimer()\hour) + ":" + SetWidth(ListTimer()\minute) + ":" + SetWidth(ListTimer()\second))

							ListTimer()\flag = 0
							itemCur = ListSize(ListTimer()) - 1
							If fStartTimer
								StartTimer()
							EndIf


						Case #Combo
							item$ = GetGadgetText(#Combo)
							; item$ = GetGadgetItemText(#Combo, GetGadgetState(#Combo))
; 							If item$ = Lng(14)
; 								Execute$ = OpenFileRequester(Lng(44), GetCurrentDirectory(), Lng(45), 0)
; 								If Execute$
; 									AddGadgetItem(#Combo,-1, Execute$)
; 									SetGadgetText(#Combo , Execute$)
; 								Else
; 									SetGadgetText(#Combo , Lng(13))
; 								EndIf
; 							ElseIf item$ = Lng(15)
; 								Execute$ = InputRequester("Заголовок", "Пожалуйста, сделайте свой ввод:", "Я введён по умолчанию.")
; 								
; 								If Execute$
; 									AddGadgetItem(#Combo,-1, Execute$)
; 									SetGadgetText(#Combo , Execute$)
; 								Else
; 									SetGadgetText(#Combo , Lng(13))
; 								EndIf
; 							EndIf
 							Select item$
 								Case Lng(14)
 									If working$ = ""
										CompilerSelect #PB_Compiler_OS
											CompilerCase #PB_OS_Windows
												working$ = "C:\Windows\media"
; 												working$ = GetCurrentDirectory()
											CompilerCase #PB_OS_Linux
												working$ = "/usr/share/sounds/"
										CompilerEndSelect
									EndIf
 									Execute$ = OpenFileRequester(Lng(44), working$, Lng(45), 0)
									If Execute$
										AddGadgetItem(#Combo,-1, Execute$)
										SetGadgetText(#Combo , Execute$)
										working$ = GetPathPart(Execute$) ; запоминаем рабочий каталог
										If Not Asc(DefExe$) And MessageRequester(Lng(50), Lng(51), #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
; 											предлагаем выбрать файл как дефолтный
											If OpenPreferences(ini$)
												If PreferenceGroup("set")
													WritePreferenceString("DefExe", Execute$)
													DefExe$ = Execute$
													AddGadgetItem(#Combo,0, Lng(49))
													SetGadgetText(#Combo , Lng(49))
												EndIf
												ClosePreferences()
											EndIf
										EndIf
									Else
										SetGadgetText(#Combo , Lng(49))
									EndIf
 								Case Lng(15)
									Execute$ = InputRequester(Lng(15), Lng(46), "")
									If Execute$
										If TestExecute(Execute$)
											AddGadgetItem(#Combo,-1, Execute$)
											SetGadgetText(#Combo , Execute$)
										Else
											MessageRequester(Lng(37), Lng(43))
										EndIf
									Else
										SetGadgetText(#Combo , Lng(49))
									EndIf
 							EndSelect
							
						Case #ListBoxINI
							; indLB =
							item$ = GetGadgetItemText(#ListBoxINI, GetGadgetState(#ListBoxINI))

							If OpenPreferences(ini$)
								ExaminePreferenceGroups()
								While NextPreferenceGroup()
									If PreferenceGroupName() = item$
										Time$ = ReadPreferenceString("Time", "0:0:0")
										SetGadgetText(#InpHour, StringField(Time$, 1, ":"))
										SetGadgetText(#InpMinute,StringField(Time$, 2, ":"))
										SetGadgetText(#InpSec, StringField(Time$, 3, ":"))
										tmp$ = ReadPreferenceString("Execute", "")
										If Not Asc(tmp$)
											tmp$ = Lng(49)
										EndIf
										SetGadgetText(#Combo , tmp$)
										Break
									EndIf
								Wend
								ClosePreferences()
							EndIf

					EndSelect
				Case #PB_Event_CloseWindow
					CloseWindow(#Window_AddTimer)
			EndSelect



; 	If WWE = #PB_Event_SysTray
; 			Select EventType()
; 				Case #PB_EventType_LeftClick, #PB_EventType_RightClick
; 					SetActiveWindow(#Window_Main)
; 			EndSelect
; 	EndIf

;- ├ Gadget События 1 окна
		Case #Window_Main
			Select WWE
; 				Case #PB_Event_RightClick
; 					DisplayPopupMenu(#MenuSmp, WindowID(#Window_Main))  ; показывает всплывающее Меню
; 					попытка варианта отображать кнопку на панели задач, если окно активно, но зачем?
; 				CompilerIf #PB_Compiler_OS= #PB_OS_Windows
; 					Case #PB_Event_MinimizeWindow
; 						HideFromTaskBar(WindowID(0),1)
; 				CompilerEndIf
;- ├ События трея
				Case #PB_Event_SysTray
					Select EventType()
						Case #PB_EventType_LeftClick ; , #PB_EventType_RightClick
							CompilerSelect #PB_Compiler_OS
							    CompilerCase #PB_OS_Windows
; 									HideFromTaskBar(WindowID(0),0)
									SetWindowState(#Window_Main, #PB_Window_Normal)
							    CompilerCase #PB_OS_Linux
									SetActiveWindow(#Window_Main)
							CompilerEndSelect
; 							HideWindow(#Window_Main, #False)
						Case #PB_EventType_RightClick
; 							If GetActiveWindow() = #Window_Main ; нет особого смысла блокировать пункт
; 								DisableMenuItem(0, 2, 1)
; 							Else
; 								DisableMenuItem(0, 2, 0)
; 							EndIf
							DisplayPopupMenu(#Menu, WindowID(#Window_Main))  ; показывает всплывающее Меню
					EndSelect
					

;- ├ Menu События меню
				Case #PB_Event_Menu        ; кликнут элемент всплывающего Меню
					em = EventMenu()
					Select em	   ; получим кликнутый элемент Меню...
						Case #mExit
							CloseWindow(#Window_Main)
							If ((ListWidth <> ListWidth_tmp) Or (ListHeight_tmp <> ListHeight)) And OpenPreferences(ini$)
								PreferenceGroup("set")
								WritePreferenceInteger("ListWidth" , ListWidth)
								WritePreferenceInteger("ListHeight" , ListHeight)
								ClosePreferences()
							EndIf
							Break
						Case #mShow
							CompilerSelect #PB_Compiler_OS
							    CompilerCase #PB_OS_Windows
; 									HideFromTaskBar(WindowID(0),0)
									SetWindowState(#Window_Main, #PB_Window_Normal)
							    CompilerCase #PB_OS_Linux
									SetActiveWindow(#Window_Main)
							CompilerEndSelect
						Case #mAbout
; 							MessageRequester(Lng(28), "Автор AZJIO")
							Win_About()
						Case #mHelp
; 							Справка
							CompilerSelect #PB_Compiler_OS
							    CompilerCase #PB_OS_Windows
									If FileSize(PathHelp$) > 0
										RunProgram(PathHelp$)
									EndIf
							    CompilerCase #PB_OS_Linux
									If FileSize(PathHelp$) > 0
										RunProgram("xdg-open", PathHelp$, GetPathPart(PathHelp$))
							; 			RunProgram(PathHelp$)
										; RunProgram("firefox", PathHelp$, GetPathPart(PathHelp$)) ; что если firefox не браузер по умолчанию?
										; тут наверно преобразование HTML в формат man, чтобы использовать и без флага --html=firefox
										; RunProgram("man", "--html=firefox " + PathHelp$, GetPathPart(PathHelp$))
							
									EndIf
							CompilerEndSelect
						Case minitem To maxitem
							
							; 							добавить время, надо анализировать ini
							
							tmp$ = GetMenuItemText(#MenuSmp, em)
							If Asc(tmp$) And OpenPreferences(ini$)
								If PreferenceGroup(tmp$)
									AddElement(ListTimer())
									Time$ = ReadPreferenceString("Time", "0:0:0")
									
									
									ListTimer()\hour = Val(StringField(Time$, 1, ":"))
									ListTimer()\minute = Val(StringField(Time$, 2, ":"))
									ListTimer()\second = Val(StringField(Time$, 3, ":"))
									If ListTimer()\hour = 0 And ListTimer()\minute = 0 And ListTimer()\second = 0
										; 						MessageRequester(Lng(13), Lng(33))
										DeleteElement(ListTimer(), 1) ; удаляем элемент списка если не собираемся его добавлять в таймеры
										CompilerSelect #PB_Compiler_OS
											CompilerCase #PB_OS_Windows
												MessageRequester(Lng(41), Lng(41))
											CompilerCase #PB_OS_Linux
												RunProgram("zenity", Lng(42), "")
										CompilerEndSelect
										Continue
									EndIf
									Execute$ = ReadPreferenceString("Execute", "")
									Select Execute$
										Case Lng(14)
											Execute$ = ""
										Case Lng(13)
											ListTimer()\path = Lng(13)
		; 								Case "Стандартный"
		; 									Execute$ = "" ; пока пусто, надо сделать поиск в папке стандартных звуков
										Default
											If FileSize(Execute$) >= 0
												ListTimer()\path = Execute$
											Else
												If TestExecute(Execute$)
													ListTimer()\path = Execute$
												Else
													MessageRequester(Lng(37), Lng(43))
												EndIf
											EndIf
									EndSelect
									fStartTimer = 1
									
									
									AddGadgetItem(#ListBox, -1, "00:00:00")
									AddGadgetItem(#ListBoxEnd, -1, SetWidth(ListTimer()\hour) + ":" + SetWidth(ListTimer()\minute) + ":" + SetWidth(ListTimer()\second))
									AddGadgetItem(#ListBoxTimer, -1, SetWidth(ListTimer()\hour) + ":" + SetWidth(ListTimer()\minute) + ":" + SetWidth(ListTimer()\second))
		
									ListTimer()\flag = 0
									itemCur = ListSize(ListTimer()) - 1
									If fStartTimer
										StartTimer()
									EndIf
									
									
									
									
								EndIf
								ClosePreferences()
							EndIf
							
					EndSelect
				Case #PB_Event_SizeWindow
					width1 = WindowWidth(#Window_Main)
					ListHeight = WindowHeight(#Window_Main) - 30
					
; 					старое, изменение только высоты
; 					ResizeGadget(#ListBox, #PB_Ignore, #PB_Ignore, #PB_Ignore, ListHeight)
; 					ResizeGadget(#ListBoxTimer, #PB_Ignore, #PB_Ignore, #PB_Ignore, ListHeight)
; 					ResizeGadget(#ListBoxEnd, #PB_Ignore, #PB_Ignore, #PB_Ignore, ListHeight)

					CompilerSelect #PB_Compiler_OS
					    CompilerCase #PB_OS_Windows
							ListWidth = (width1 - 96)/3
							xl1 = ListWidth*3+70
					    CompilerCase #PB_OS_Linux
							ListWidth = (width1 - 147)/3
							xl1 = ListWidth * 3+97
					CompilerEndSelect
					offset1 = 0
					ResizeGadget(#ListBox, #PB_Ignore, #PB_Ignore, ListWidth, ListHeight)
					ResizeGadget(#Text1, #PB_Ignore, #PB_Ignore, ListWidth, #PB_Ignore)
					offset1 + ListWidth+4
					ResizeGadget(#ListBoxTimer, offset1, #PB_Ignore, ListWidth, ListHeight)
					ResizeGadget(#Text2, offset1, #PB_Ignore, ListWidth, #PB_Ignore)
					offset1 + ListWidth+1
					ResizeGadget(#ListBoxEnd, offset1, #PB_Ignore, ListWidth, ListHeight)
					ResizeGadget(#Text3, offset1, #PB_Ignore, ListWidth, #PB_Ignore)
				
					offset1 + ListWidth+8
					ResizeGadget(#btnStart, offset1, #PB_Ignore, #PB_Ignore, #PB_Ignore)
					ResizeGadget(#btnAdded, offset1, #PB_Ignore, #PB_Ignore, #PB_Ignore)
					ResizeGadget(#btnReset, offset1, #PB_Ignore, #PB_Ignore, #PB_Ignore)
					ResizeGadget(#btnDelete, offset1, #PB_Ignore, #PB_Ignore, #PB_Ignore)
					ResizeGadget(#info, xl1, #PB_Ignore, #PB_Ignore, #PB_Ignore)
					
				Case #PB_Event_Gadget
					EvnGd = EventGadget()
					Select EvnGd
						Case #ListBoxEnd, #ListBoxTimer, #ListBox
							Select EventType()
								Case #PB_EventType_RightClick
									DisplayPopupMenu(#MenuSmp, WindowID(#Window_Main))  ; показывает всплывающее Меню
								Case #PB_EventType_LeftClick
									itemCur = GetGadgetState(EvnGd)
									CompilerIf #PB_Compiler_OS = #PB_OS_Windows
										SetGadgetState(EvnGd, -1)
									CompilerEndIf
; 									MessageRequester("Выбраный", Str(itemCur))
							EndSelect
						Case #btnFastST
							tmp = OpenWindow_FastSetTime()
							
							AddElement(ListTimer())
							ListTimer()\hour = 0
							ListTimer()\minute = tmp
							ListTimer()\second = 0
							If ListTimer()\hour = 0 And ListTimer()\minute = 0 And ListTimer()\second = 0
								DeleteElement(ListTimer(), 1) ; удаляем элемент списка если не собираемся его добавлять в таймеры
								Continue
							EndIf
							ListTimer()\path = Lng(13)
							fStartTimer = 1
							AddGadgetItem(#ListBox, -1, "00:00:00")
							AddGadgetItem(#ListBoxEnd, -1, SetWidth(ListTimer()\hour) + ":" + SetWidth(ListTimer()\minute) + ":" + SetWidth(ListTimer()\second))
							AddGadgetItem(#ListBoxTimer, -1, SetWidth(ListTimer()\hour) + ":" + SetWidth(ListTimer()\minute) + ":" + SetWidth(ListTimer()\second))
							
							ListTimer()\flag = 0
							itemCur = ListSize(ListTimer()) - 1
							If fStartTimer
								StartTimer()
							EndIf
						Case #btnAdded
							Window_AddTimer() ; временно отключил задатчик окончания таймера
						Case #btnStart
							StartTimer()
						Case #btnReset
							; 					itemCur = GetGadgetState(#ListBox)
							; 					If itemCur = -1
							; 						Continue
							; 					EndIf
							If itemCur < 0
								Continue
							EndIf
							RemoveWindowTimer(#Window_Main, itemCur)
							SetGadgetItemText(#ListBox , itemCur , "00:00:00")
							SetGadgetItemText(#ListBoxTimer , itemCur , "00:00:00")
							; 					SetGadgetItemText(#ListBoxEnd , itemCur , "00:00:00")
							SelectElement(ListTimer() , itemCur)
							ListTimer()\flag = 0
							ListTimer()\markstart = 0
							LastElement(ListTimer()) ; возвращаем позицию в конец
							CompilerIf #PB_Compiler_OS = #PB_OS_Linux
								SetGadgetState(#ListBox, -1)
								SetGadgetState(#ListBoxTimer, -1)
								SetGadgetState(#ListBoxEnd, -1)
							CompilerEndIf
						Case #btnDelete
; 							MessageRequester("Выбраный", Str(itemCur))
							If itemCur < 0
								Continue
							EndIf
							RemoveWindowTimer(#Window_Main, itemCur)
							RemoveGadgetItem(#ListBox, itemCur)
							RemoveGadgetItem(#ListBoxTimer, itemCur)
							RemoveGadgetItem(#ListBoxEnd, itemCur)
							SelectElement(ListTimer(), itemCur)
							DeleteElement(ListTimer(), 1)
							i = ListSize(ListTimer())
							itemCur = i-1
							If i
								; SelectElement(ListTimer(), i - 1) ; возвращаем позицию в конец
								LastElement(ListTimer())
							EndIf
							CompilerIf #PB_Compiler_OS = #PB_OS_Linux
								SetGadgetState(#ListBox, -1)
								SetGadgetState(#ListBoxTimer, -1)
								SetGadgetState(#ListBoxEnd, -1)
							CompilerEndIf
						Case #info
							info()
					EndSelect

				Case #PB_Event_CloseWindow
					CloseWindow(#Window_Main)
					If ((ListWidth <> ListWidth_tmp) Or (ListHeight_tmp <> ListHeight)) And OpenPreferences(ini$)
						PreferenceGroup("set")
						WritePreferenceInteger("ListWidth" , ListWidth)
						WritePreferenceInteger("ListHeight" , ListHeight)
						ClosePreferences()
					EndIf
					Break
			EndSelect

;- ├ Gadget События 3 окна
		Case #Win_About
			Select WWE
				Case #PB_Event_Gadget
					Select EventGadget()
						Case #link
							CompilerSelect #PB_Compiler_OS
							    CompilerCase #PB_OS_Windows
									RunProgram("https://azjio.ucoz.ru/")
							    CompilerCase #PB_OS_Linux
									RunProgram("xdg-open", "https://azjio.ucoz.ru/", "")
; 									RunProgram("https://azjio.ucoz.ru/")
; 									RunProgram("firefox", "https://azjio.ucoz.ru/", "")
							CompilerEndSelect
					EndSelect
				Case #PB_Event_CloseWindow
; 					HideWindow(#Window_Main, 0)
					CloseWindow(#Win_About)
			EndSelect



	EndSelect


ForEver
;-└──Loop──┘


Procedure info()
	Protected info$
	If ListSize(ListTimer())
		ForEach ListTimer()
			info$ + FormatDate("%hh:%ii:%ss", ListTimer()\markstart) + " - " + FormatDate("%hh:%ii:%ss", ListTimer()\markend) + #CRLF$
		Next
		MessageRequester(Lng(13), info$)
	EndIf
EndProcedure


Procedure StartTimer()
	If itemCur = -1
; 		itemCur = ListSize(ListTimer()) - 1
		ProcedureReturn 
	EndIf
	SelectElement(ListTimer() , itemCur)
	If ListTimer()\flag = 0
		SetGadgetItemText(#ListBox , itemCur , "00:00:00")
		; SetGadgetText(#btnStart, "Стоп")
		AddWindowTimer(#Window_Main, itemCur, 1000)
		ListTimer()\markstart = Date()
		ListTimer()\flag = 1
		ListTimer()\markend = AddDate(ListTimer()\markstart, #PB_Date_Hour , ListTimer()\hour)
		ListTimer()\markend = AddDate(ListTimer()\markend, #PB_Date_Minute , ListTimer()\minute)
		ListTimer()\markend = AddDate(ListTimer()\markend, #PB_Date_Second , ListTimer()\second)
; 	Else
; 		ListTimer()\flag = 0
		; SetGadgetText(#btnStart, Lng(19))
; 		RemoveWindowTimer(#Window_Main, itemCur)
	EndIf
	LastElement(ListTimer()) ; возвращаем позицию в конец
EndProcedure

Procedure.s SetWidth(num)
	Protected String$ = Str(num)
	If Len(String$) = 1
		String$ = "0" + String$
	EndIf
	ProcedureReturn String$
EndProcedure

Procedure _bk()
	Protected nFont
	nFont = LoadFont(#Font_Text_0, Font$, FontSize, #PB_Font_Bold|#PB_Font_HighQuality)
	If nFont
		SetGadgetFont(#ListBox, nFont)
	EndIf
	; 	SetGadgetColor(#ListBox, #PB_Gadget_BackColor , $ffffff)
	SetGadgetColor(#ListBox, #PB_Gadget_FrontColor , List1Color)

	If nFont
		SetGadgetFont(#ListBoxTimer, nFont)
	EndIf
	; 	SetGadgetColor(#ListBoxTimer, #PB_Gadget_BackColor , $ffffff)
	SetGadgetColor(#ListBoxTimer, #PB_Gadget_FrontColor , List1Color)

	If nFont
		SetGadgetFont(#ListBoxEnd, nFont)
	EndIf
	; 	SetGadgetColor(#ListBoxEnd, #PB_Gadget_BackColor , $ffffff)
	SetGadgetColor(#ListBoxEnd, #PB_Gadget_FrontColor , List3Color)
EndProcedure

;==================================================================
;
; Author:    ts-soft     
; Date:       March 5th, 2010
; Explain:
;     modified version from IBSoftware (CodeArchiv)
;     on vista and above check the Request for "User mode" or "Administrator mode" in compileroptions
;    (no virtualisation!)
;==================================================================
Procedure ForceDirectories(Dir.s)
	Static tmpDir.s, Init, delim$
	Protected result
CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
		delim$ = "\"
    CompilerCase #PB_OS_Linux
		delim$ = "/"
CompilerEndSelect
	
	If Len(Dir) = 0
		ProcedureReturn #False
	Else
		If Not Init
			tmpDir = Dir
			Init   = #True
		EndIf
		If (Right(Dir, 1) = delim$)
			Dir = Left(Dir, Len(Dir) - 1)
		EndIf
		If (Len(Dir) < 3) Or FileSize(Dir) = -2 Or GetPathPart(Dir) = Dir
			If FileSize(tmpDir) = -2
				result = #True
			EndIf
			tmpDir = ""
			Init = #False
			ProcedureReturn result
		EndIf
		ForceDirectories(GetPathPart(Dir))
		ProcedureReturn CreateDirectory(Dir)
	EndIf
EndProcedure

CompilerIf #PB_Compiler_OS= #PB_OS_Linux

Procedure.s EscapeFilePath(String.s)
	If Not FindString(String, " ")
		ProcedureReturn String
	EndIf
; 	String = ReplaceString(String, ".", "\.")
; 	String = ReplaceString(String, "-", "\-")
; 	String = ReplaceString(String, " ", "\ ")
; 	String = ReplaceString(String, Chr(34), "\" + Chr(34))
; 	ProcedureReturn String
	ProcedureReturn Chr(34) + String + Chr(34)
EndProcedure

CompilerEndIf


CompilerIf #PB_Compiler_OS= #PB_OS_Windows
	

; JHPJHP
; https://www.purebasic.fr/english/viewtopic.php?p=492909#p492909
Procedure SetWindowFocus(wID)
	Protected ForeThread, AppThread
	If GetWindowState(wID) <> #PB_Window_Minimize And IsWindowVisible_(WindowID(wID))
		ForeThread = GetWindowThreadProcessId_(GetForegroundWindow_(), #Null)
		AppThread = GetCurrentThreadId_()
		
		If ForeThread <> AppThread
			AttachThreadInput_(ForeThread, AppThread, #True)
			BringWindowToTop_(WindowID(wID))
			ShowWindow_(WindowID(wID), #SW_SHOW)
			AttachThreadInput_(ForeThread, AppThread, #False)
		Else
			BringWindowToTop_(WindowID(wID))
			ShowWindow_(WindowID(wID), #SW_SHOW)
		EndIf
	EndIf
EndProcedure

Procedure HideFromTaskBar(hWnd.i, Flag.l)
  Protected TBL.ITaskbarList
  CoInitialize_(0)
  If CoCreateInstance_(?CLSID_TaskBarList, 0, 1, ?IID_ITaskBarList, @TBL) = #S_OK
    TBL\HrInit()
    If Flag
      TBL\DeleteTab(hWnd)
    Else
      TBL\AddTab(hWnd)
    EndIf
    TBL\Release()
  EndIf
  CoUninitialize_()

  DataSection
    CLSID_TaskBarList:
    Data.l $56FDF344
    Data.w $FD6D, $11D0
    Data.b $95, $8A, $00, $60, $97, $C9, $A0, $90
    IID_ITaskBarList:
    Data.l $56FDF342
    Data.w $FD6D, $11D0
    Data.b $95, $8A, $00, $60, $97, $C9, $A0, $90
  EndDataSection
EndProcedure

CompilerEndIf


Procedure OpenWindow_FastSetTime()
; 	#R1 = 11
	#R2 = 20
	Protected a, dx.f, dy.f, x, y, r1
	Protected w.f = (#WindowSize / 2) - #R2
	Protected h.f = (#WindowSize / 2) - #R2
	Protected color = #Green1
	Protected j, i.f = (360 / #MinutesCircle)
	
	DisableWindow(#Window_Main, 1)
	
	If OpenWindow(#WindowFastSetTime, #PB_Ignore, #PB_Ignore, #WindowSize, #WindowSize, "FastSetTime",
	              #PB_Window_ScreenCentered | #PB_Window_BorderLess, WindowID(#Window_Main))
		
	CanvasGadget(#cnvs, 0 , 0 , #WindowSize, #WindowSize)
		
	For a = 1 To #MinutesCircle
		j + 1
		If j = 5
			j = 0
			color = #Red1
			r1 = 14
		Else
			color = #Green1
			r1 = 11
		EndIf
		bMinute(a)\x = w * Cos(Radian(a * i - 90)) + w + #R2
		bMinute(a)\y = w * Sin(Radian(a * i - 90)) + w + #R2
		bMinute(a)\backcolor = color
		bMinute(a)\text = Str(a)
		bMinute(a)\r = r1
	Next
		
		If StartDrawing(CanvasOutput(#cnvs))
			Box( 0, 0, #WindowSize, #WindowSize, #Red1)
			Box( 1, 1, #WindowSize - 2, #WindowSize - 2, $aaaaaa)
			For a = 1 To #MinutesCircle
				bMinute(a)\tw = TextWidth(Str(a))
				bMinute(a)\th = TextHeight(Str(a))
				Circle(bMinute(a)\x, bMinute(a)\y, bMinute(a)\r, bMinute(a)\backcolor)
				DrawText(bMinute(a)\x - bMinute(a)\tw / 2, bMinute(a)\y - bMinute(a)\th / 2, bMinute(a)\text, 0, bMinute(a)\backcolor)
			Next
			For a = 0 To #MinutesCircle Step 5
				bMinute(a)\tw = TextWidth(Str(a))
				bMinute(a)\th = TextHeight(Str(a))
				Circle(bMinute(a)\x, bMinute(a)\y, bMinute(a)\r, bMinute(a)\backcolor)
				DrawText(bMinute(a)\x - bMinute(a)\tw / 2, bMinute(a)\y - bMinute(a)\th / 2, bMinute(a)\text, 0, bMinute(a)\backcolor)
			Next
			StopDrawing()
		EndIf
		AddKeyboardShortcut(#WindowFastSetTime, #PB_Shortcut_Escape, #mClose)
		
		;- Loop
		Repeat
			Select WaitWindowEvent()
				Case #PB_Event_Menu
					Select EventMenu()
						Case #mClose
							DisableWindow(#Window_Main, 0)
							CloseWindow(#WindowFastSetTime)
							ProcedureReturn 0
					EndSelect

				Case #PB_Event_Gadget
					Select EventGadget()
						Case #cnvs
							If EventType() = #PB_EventType_LeftButtonDown
								x = GetGadgetAttribute(#cnvs, #PB_Canvas_MouseX)
								y = GetGadgetAttribute(#cnvs, #PB_Canvas_MouseY)
								For a = 1 To #MinutesCircle
									dx = (x - bMinute(a)\x)
									dy = (y - bMinute(a)\y)
									If (Abs(dx) < bMinute(a)\r And Abs(dy) < bMinute(a)\r) And
									   (dx * dx + dy * dy) <= (bMinute(a)\r * bMinute(a)\r)
										DisableWindow(#Window_Main, 0)
										CloseWindow(#WindowFastSetTime)
										ProcedureReturn Val(bMinute(a)\text)
									EndIf
								Next
							EndIf
					EndSelect
			EndSelect
		ForEver
	EndIf
EndProcedure

Procedure Win_About()
	Protected nFont
	If OpenWindow(#Win_About, #PB_Ignore, #PB_Ignore, 320, 200, Lng(47), #PB_Window_SystemMenu | #PB_Window_TitleBar|#PB_Window_ScreenCentered, WindowID(#Window_Main))
; 		HideWindow(#Window_Main, 1)
		CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
			gtk_window_set_icon_(WindowID(#Win_About), ImageID(0)) ; назначаем иконку в заголовке
		CompilerEndIf
; 		SetWindowColor(#Win_About, $E1E3E7)

		TextGadget(#labelA, 0, 0, 320, 73, #LF$ + Lng(17), #PB_Text_Center)
		SetGadgetColor(#labelA, #PB_Gadget_FrontColor, $7e6a3a)
		SetGadgetColor(#labelA, #PB_Gadget_BackColor, $EFF1F1)
		nFont = LoadFont(#Font_Text_0, Font$, 16, #PB_Font_Bold|#PB_Font_HighQuality)
		If nFont
			SetGadgetFont(#labelA, nFont)
		EndIf
		
; 		фон
		TextGadget(#labelAf, 0, 73, 320, 136, "")
		SetGadgetColor(#labelAf, #PB_Gadget_BackColor, $E7E3E1)

		TextGadget(#labelAv, 50, 100, 210, 17, "v1.3   2022.11.13")
		SetGadgetColor(#labelAv, #PB_Gadget_FrontColor, 0)
		SetGadgetColor(#labelAv, #PB_Gadget_BackColor, $E7E3E1)
		TextGadget(#labelAs, 50, 125, 40, 17, Lng(48))
		SetGadgetColor(#labelAs, #PB_Gadget_FrontColor, 0)
		SetGadgetColor(#labelAs, #PB_Gadget_BackColor, $E7E3E1)
		HyperLinkGadget(#link, 87, 125, 170, 17, "https://azjio.ucoz.ru/", $aa0000)
		SetGadgetColor(#link, #PB_Gadget_BackColor, $E7E3E1)
		TextGadget(#labelAc, 50, 150, 210, 17, "Copyright AZJIO © 2021")
		SetGadgetColor(#labelAc, #PB_Gadget_FrontColor, 0)
		SetGadgetColor(#labelAc, #PB_Gadget_BackColor, $E7E3E1)
	EndIf
EndProcedure
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 1208
; FirstLine = 1186
; Folding = -8---
; Markers = 952,1092
; EnableXP
; DPIAware
; UseIcon = StopwatchTimer.ico
; Executable = StopwatchTimer.exe
; CompileSourceDirectory
; Compiler = PureBasic 6.04 LTS (Windows - x64)
; DisableCompileCount = 4
; EnableBuildCount = 0
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 1.4.0.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = StopwatchTimer
; VersionField4 = 1.4
; VersionField6 = StopwatchTimer
; VersionField9 = AZJIO