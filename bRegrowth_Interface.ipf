#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

////////////////////////////////////////////////////////////////////////////////
Window regrowthModel_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(167,573,1504,1305) as "Regrowth Model"
	ListBox list0,pos={4.00,39.00},size={1317.00,679.00},proc=regrowthModel_ListBoxProc
	ListBox list0,listWave=root:regrowthRawData,row= 13,mode= 1,selRow= 24
	Button runAll,pos={18.00,11.00},size={50.00,20.00},proc=regrowthModel_ButtonProc,title="Run All"
EndMacro
////////////////////////////////////////////////////////////////////////////////
Function regrowthModel_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			Variable doPlot = 1
			runRegrowthModel_Init(row, doPlot)
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
			
		case 12: // Keystroke, character code is place in row field
			String theKey = num2char(row)
			print "regrowthModel_ListBoxProc key:", theKey
			strswitch (theKey)
				case "e":
					regrowth_EditRawData()
					break
			endswitch
			break
	endswitch

	return 0
End
////////////////////////////////////////////////////////////////////////////////
Function regrowthModel_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String ctrl = ba.ctrlName
			strswitch (ctrl)
				case "runAll":
					runRegrowth_All()
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
////////////////////////////////////////////////////////////////////////////////
Function regrowth_EditRawData()
	String regrowthRawData = "regrowthRawData"
	Wave/T regrowthRawDataPtr = $regrowthRawData
	
	// make a new 2d text table with column headers in first row
	if (WaveExists($regrowthRawData))
		Variable numRow = DimSize($regrowthRawData,0)
		Variable numCol = DimSize($regrowthRawData,1)
		Make/O/T/N=(numRow+1, numCol) $"regrowthTable" = ""
		Wave/T regrowthTablePtr = $"regrowthTable"
		Variable j
		
		//header columns
		for (j=0; j<numCol; j+=1)
			regrowthTablePtr[0][j] = GetDimLabel(regrowthRawDataPtr, 1, j)
		endfor
		
		// body
		regrowthTablePtr[1,numRow-1][] = regrowthRawDataPtr[p-1][q]
		
		//edit
		edit/K=1 regrowthTablePtr
		
	else
		print "did not find igor wave:", regrowthRawData
	endif
End
////////////////////////////////////////////////////////////////////////////////
Function regrowthIsEmpty(str)
String str
	return !cmpstr(str,"")
end
////////////////////////////////////////////////////////////////////////////////
Function regrowthWinExists(wStr)
String wStr

	Variable theRet = 0
	if (!regrowthIsEmpty(wStr))
		//wStr = bGetRootWindow(wStr)
		DoWindow $wStr
		theRet = V_FLAG
	endif
	return theRet
End
////////////////////////////////////////////////////////////////////////////////
//return true if  trace t is in graph g
Function bTraceIsInGraph2(g, t)
String g,t
	Variable theRet = 1
	String traceList = TraceNameList(g, ";", 1 )
	Variable idx = WhichListItem(t, traceList)
	if (idx == -1)
		theRet = 0
	endif
	return theRet
End
