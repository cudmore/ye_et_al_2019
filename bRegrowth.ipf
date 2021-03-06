﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include ":bRegrowth_Interface"

// Author: Robert H Cudmore
// Date: 20180827
// Email: robert.cudmore@gmail.com
//
// Purpose:
//		Run a model to test the null hypothesis
//		"The observed fraction of new spines that are regrowth spines is occuring by chance."
//
// Run:
//		Run the model from command line with:
//			regrowthModel_Init()
//

static constant kRegrowthMaxChar = 256 //once compled, can not change this !!! Igor Problem !!!


////////////////////////////////////////////////////////////////////////////////
Function regrowthModel_Init()
	//load raw data
	Variable loadOk = regrothLoadFile()
	
	if (loadOk)
		//ok
	else
		//error
		print "file not loaded, try again"
		return 0
	endif
	
	//open panel
	String winStr = "regrowthModel_Panel"
	DoWindow $winStr
	if (V_FLAG == 0)
		Execute("regrowthModel_Panel()")
	else
		// already opened
		print "already opened"
	endif
End
////////////////////////////////////////////////////////////////////////////////
Structure regrowthStruct
	Variable row
	
	char mapName[kRegrowthMaxChar] // char : signed 8-bit int, 1 byte
	char condName[kRegrowthMaxChar] // char : signed 8-bit int, 1 byte
	
	//
	// from data analysis
	Variable umLength // (excel)
	Variable numRegrow_obs // (excel)
	Variable totalAdded_obs // (excel)
	
	Variable currentlyOccupied // Total number of spines at OVX session (excel)
	Variable prevOccupied // (excel)

	//
	// intermediate
	//Variable neverOccupied // = totalNumberOfSlots - currentlyOccupied - prevOccupied
	
	//
	// model - fill these in from manually estimating
	Variable slotLength // 0.5 um
	
	Variable totalNumberOfSlots // = (segment length) / slotLength

	Variable numberOfIerations //number of times to run random (monte-carlo) model
	
EndStructure
////////////////////////////////////////////////////////////////////////////////
// initialize a regrowth structure with empty values
Function regrowthStruct_Init(rs)
Struct regrowthStruct &rs

	rs.slotLength = 0.6 // um
	rs.numberOfIerations = 10000
End
////////////////////////////////////////////////////////////////////////////////
Function regrothLoadFile()

	String fullFilePath = ""
	// used locally on development machine
	fullFilePath = "vasculature:Users:cudmore:Dropbox:regrowth model:regrowth data for Bob_V3.csv"
	fullFilePath = "vasculature:Users:cudmore:Dropbox:regrowth model:controlRegrowth.csv"
	// will ask user for the file
	fullFilePath = ""

	String loadedPath
	String loadedFile
	String loadedWave

	 // load body
	 LoadWave /Q /I /J /M /K=2 /U={0,0,1,0} /L={1,2,0,0,0}  fullFilePath // /L switch is telling to start loading at line 1 (line 0 is our new parameter header)
	 	loadedPath = S_path //when given, should be same as hddPath
	 	loadedFile = S_fileName
	 	loadedWave = StringFromList(0,S_waveNames)
	 	if (!cmpstr(loadedWave,""))
	 		print "ERROR: bLoad_CommaDelimited() failed to load data"
	 		return 0
	 	endif
	 
	 String regrowthRawDataStr = "regrowthRawData"
	 Duplicate/O $loadedWave, $regrowthRawDataStr
	 
	 KillWaves $loadedWave
	 
	 Wave/T regrowthRawDataPtr = $regrowthRawDataStr

	 //
	 // prepend an idx column
	 InsertPoints /M=1 0, 1, $regrowthRawDataStr
	 SetDimLabel 1, 0, Idx, $regrowthRawDataStr //set header
	 	regrowthRawDataPtr[][0] = num2str(p+1)
	 	
	 //
	 // append columns for model parameters and output
	 Variable origNumCol = DimSize(regrowthRawDataPtr,1)
	 String newColList = ""
	 	newColList += "obsFraction;"
	 	newColList += "pValue;"
	 	newColList += "iterations;"
	 	newColList += "slotLength;"
	 	newColList += "totalNumberOfSlots;"
	 	newColList += "modelMean;"
	 	newColList += "modelSD;"
	 	newColList += "modelSE;"
	 	//newColList += "modelN;"
	 	// davis resubmit
	 	// 5 neighboring slots
	 	newColList += "pValue_5;"
	 	newColList += "obsFraction_5;"
	 	newColList += "modelMean_5;"
	 	newColList += "modelSD_5;"
	 	newColList += "modelSE_5;"
	 	// 6 neighboring slots
	 	newColList += "pValue_6;"
	 	newColList += "obsFraction_6;"
	 	newColList += "modelMean_6;"
	 	newColList += "modelSD_6;"
	 	newColList += "modelSE_6;"
	 	
	 Variable i
	 for (i=0; i<ItemsInList(newColList); i+=1)
	 	regrowthRawDataPtr[][origNumCol+i] = {""} //expand columns
	 	SetDimLabel 1, origNumCol+i, $StringFromList(i,newColList), $regrowthRawDataStr //set header
	 endfor
	 
	return 1
	
End
////////////////////////////////////////////////////////////////////////////////
// run all models (rows) in wave regrowthRawData
Function runRegrowth_All()
	print "=== runRegrowth_All() start"
	Wave/T regrowthRawData = root:regrowthRawData
	Variable m = DImSize(regrowthRawData,0) // number of segments
	Variable i
	
	//global pooledRegrowth
	// make one wave to hold all model result
	Make/O/N=(10000*m) pooledRegrowth = nan
	Make/O/N=(m) pooledRegrowth_obs = nan

	//global 2, keep track of each model run (10,000)
	Make/O/N=(10000,m) pooledRegrowth2 = nan

	// davis
	Make/O/N=(10000*m) pooledRegrowth_5 = nan
	Make/O/N=(10000*m) pooledRegrowth_6 = nan

	Variable doPlot = 0
	
	for (i=0; i<m; i+=1)
		runRegrowthModel_Init(i, doPlot) // i is the row into regrowthRawData
	endfor
	
	// histogram of pooled
	
	print "\tDone"
End
////////////////////////////////////////////////////////////////////////////////
Function regrowthPoolAnalysis(davisNum)
Variable davisNum // (0,1,2) corresponds to (original, _5, _6)

	//global pooledRegrowth
	String davisStr = ""
	if (davisNum == 0)
		Wave pooledRegrowth = pooledRegrowth
	elseif (davisNum == 1)
		Wave pooledRegrowth = pooledRegrowth_5
		davisStr = "_5"
	elseif (davisNum == 2)
		Wave pooledRegrowth = pooledRegrowth_6
		davisStr = "_6"
	endif
	
	Variable numBins = 20

	//
	// hist
	String pooledRegrowthHistStr = "pooledRegrowthHist" + davisStr
	Make/O/N=(numBins) $pooledRegrowthHistStr /Wave=pooledRegrowthHist = nan
	Histogram /C /B=3 pooledRegrowth, pooledRegrowthHist //creates W_Histogram

	Display/K=1 /W=(527,160,922,368) pooledRegrowthHist
		ModifyGraph mode=5,hbFill=4,hBarNegFill=4,rgb=(0,0,0)
			ModifyGraph fSize=14
			Label bottom "Regrowth Fraction"
			Label left "Count"
		
	//
	// cum hist, model
	String pooledRegrowthHist_cumStr = "pooledRegrowthHist_cum" + davisStr
	Make/O/N=(numBins) $pooledRegrowthHist_cumStr /Wave=pooledRegrowthHist_cum = nan
	Histogram/B=1 /Cum /P pooledRegrowth, pooledRegrowthHist_cum //creates W_Histogram

	Display/K=1 /W=(529,407,924,615) pooledRegrowthHist_cum
		ModifyGraph mode=5,hbFill=4,hBarNegFill=4,rgb=(0,0,0)
		ModifyGraph mode=4,marker=19,lsize=2,rgb=(0,0,0)
			ModifyGraph fSize=14
			Label bottom "Regrowth Fraction"
			Label left "Fraction"

	//
	// cum hist, pooled observed regrowth
	Wave pooledRegrowth_obs = pooledRegrowth_obs

	Make/O/N=(numBins) pooledRegrowth_obs_hist_cum = nan
	Histogram/B=1 /Cum /P pooledRegrowth_obs, pooledRegrowth_obs_hist_cum //creates W_Histogram
	
	AppendToGraph pooledRegrowth_obs_hist_cum
		ModifyGraph mode=4,marker(pooledRegrowth_obs_hist_cum)=8, lsize=2
			
End
////////////////////////////////////////////////////////////////////////////////
//initialize model with row selection into raw data
Function runRegrowthModel_Init(row, doPlot)
Variable row
Variable doPlot // 20190314 resubmit

	print "\r"
	print"=== runRegrowthModel_Init() row:", row
	
	Wave/T regrowthRawData = root:regrowthRawData
	
	String map = regrowthRawData[row][%map]
	String condition = regrowthRawData[row][%condition]
	Variable currentlyOccupied = str2num(regrowthRawData[row][%currentlyOccupied])
	Variable umLength = str2num(regrowthRawData[row][%umLength])
	Variable prevOccupied = str2num(regrowthRawData[row][%prevOccupied])
	Variable numRegrow = str2num(regrowthRawData[row][%numRegrow])
	Variable totalAdded = str2num(regrowthRawData[row][%totalAdded])
	
	STRUCT regrowthStruct rs
	regrowthStruct_Init(rs)

	rs.row = row //tells us row to fill in model results

	// from original file
	rs.mapName = map
	rs.condName = condition
	
	// target
	rs.totalAdded_obs = totalAdded // 
	rs.numRegrow_obs = numRegrow // 

	rs.umLength = umLength 
	rs.currentlyOccupied = currentlyOccupied //from text file
	// target
	rs.prevOccupied = prevOccupied // from text file
	
	runRegrowthModel(rs)
	plotRegrowthModel(rs, doPlot, 0)
	plotRegrowthModel(rs, doPlot, 1)
	plotRegrowthModel(rs, doPlot, 2)
End
////////////////////////////////////////////////////////////////////////////////
Function scaleModel(rs)
STRUCT regrowthStruct &rs

	Variable target = 20
	
	//uncomment this line for no model scaling (normalization)
	//target = rs.totalAdded_obs

	Variable factor = target / rs.totalAdded_obs

	rs.totalAdded_obs *= factor // totalAdded IS target
	
	print "*** scaleModel() target:", target, "factor:", factor
	
	rs.prevOccupied *= factor
	rs.prevOccupied = ceil(rs.prevOccupied)
	
	//rs.totalNumberOfSlots = (rs.umLength / rs.slotLength) - rs.currentlyOccupied // this is 'open slots'
	rs.totalNumberOfSlots *= factor
	rs.totalNumberOfSlots = ceil(rs.totalNumberOfSlots)
	
End
////////////////////////////////////////////////////////////////////////////////
// given a RegrowthStruct, run the model
Function runRegrowthModel(rs)
STRUCT regrowthStruct &rs

	Variable/D startTime = DateTime
	
	if (rs.totalAdded_obs == 0)
		print "runRegrowthModel() rs.totalAdded_obs is 0 -->> o model run"
		return 0
	endif
	
	// 'eq. 1' : fraction of observed added that were 'regrowth added'
	Variable observedFraction = rs.numRegrow_obs / rs.totalAdded_obs
	
	// we have a total number of slots and number them 1..totalNumberOfSlots
	rs.totalNumberOfSlots = (rs.umLength / rs.slotLength) - rs.currentlyOccupied // this is 'open slots'
	rs.totalNumberOfSlots = ceil(rs.totalNumberOfSlots)
	
	//
	// scale/normalize each segment so we can compare across segments
	scaleModel(rs)
	//

	Make/O/N=(rs.totalNumberOfSlots) regrowthModelSlots = 0 // 0 is important so we can sum(W_Sampled)
	
	//some of these slots will be regrowth slots (or should not matter)
	if (rs.prevOccupied > 0)
		regrowthModelSlots[0, rs.prevOccupied-1] = 1 // value of 1 denotes a regrowth slot
	else
		//regrowthModelSlots[] is 0, no regrowth slots
	endif
	
	// davis resubmit
	//5
	Make/O/N=(rs.totalNumberOfSlots) regrowthModelSlots_5 = 0 // 0 is important so we can sum(W_Sampled)
	if (rs.currentlyOccupied > 0)
		Variable currentlyOccupied_5 = rs.currentlyOccupied * 5
		regrowthModelSlots_5[0, currentlyOccupied_5-1] = 1 // value of 1 denotes a regrowth slot
	endif
	//6
	Make/O/N=(rs.totalNumberOfSlots) regrowthModelSlots_6 = 0 // 0 is important so we can sum(W_Sampled)
	if (rs.prevOccupied > 0)
		Variable prevOccupied_6 = rs.prevOccupied * 6
		regrowthModelSlots_6[0, prevOccupied_6-1] = 1 // value of 1 denotes a regrowth slot
	endif
	
	//build up a list of 'number of regrowth' hits, one element per model iteration
	Make/O/N=(rs.numberOfIerations) regrowthOutput = NaN
	Make/O/N=(rs.numberOfIerations) fractionRegrowth = NaN
	
	//
	// 20190314 for resubmission
	Make/O/N=(rs.numberOfIerations) regrowthOutput_6 = NaN
	Make/O/N=(rs.numberOfIerations) fractionRegrowth_6 = NaN
	Make/O/N=(rs.numberOfIerations) regrowthOutput_5 = NaN
	Make/O/N=(rs.numberOfIerations) fractionRegrowth_5 = NaN

	Variable currentNumberOfRegrowth
	Variable currenFractionRegrowth
	
	Variable i
	for (i=0; i<rs.numberOfIerations; i+=1)
		
		// randomly place observed totalNumberOfAdded_obs into total number of slots
		// count the number that fell into numberOfRegrowthSlots
		// calculate fraction of model added that were 'regrowth added' (see 'eq. 1' for same number of observed)
		
		//	StatsSample - StatsSample creates a random, non-repeating sample from srcWave.
		//		It samples srcWave  by drawing without replacement numPoints  values from srcWave
		//		and storing them in the output wave W_Sampled
		//	Also see StatsResample
		
		StatsSample /N=(rs.totalAdded_obs) regrowthModelSlots //fills in W_Sampled
			Wave W_Sampled = W_Sampled
			// W_Sampled has length rs.totalNumberOfAdded_obs
			//		at [i] will have value
			//			1 : If was regrowth
			//			0 : if no regrowth
			
			
		// count the number of regrowth (hits) in W_Sampled
		currentNumberOfRegrowth = sum(W_Sampled)
		currenFractionRegrowth = currentNumberOfRegrowth / rs.totalAdded_obs
		
		// append this to model output
		regrowthOutput[i] = currentNumberOfRegrowth
		fractionRegrowth[i] = currenFractionRegrowth
		
		//
		// 20190314 for resubmission
		if (rs.prevOccupied > 0)
			//
			// resample by selecting currently occupied * 5
			//
			StatsSample /N=(rs.totalAdded_obs) regrowthModelSlots_5 //fills in W_Sampled
				Wave W_Sampled = W_Sampled
				// W_Sampled has length rs.totalNumberOfAdded_obs
				//		at [i] will have value
				//			1 : If was regrowth
				//			0 : if no regrowth
			// count the number of regrowth (hits) in W_Sampled
			currentNumberOfRegrowth = sum(W_Sampled)
			currenFractionRegrowth = currentNumberOfRegrowth / rs.totalAdded_obs
			// append this to model output
			regrowthOutput_5[i] = currentNumberOfRegrowth
			fractionRegrowth_5[i] = currenFractionRegrowth

			//
			// resample by selecting prev occupied * 6
			//
			StatsSample /N=(rs.totalAdded_obs) regrowthModelSlots_6 //fills in W_Sampled
				Wave W_Sampled = W_Sampled
				// W_Sampled has length rs.totalNumberOfAdded_obs
				//		at [i] will have value
				//			1 : If was regrowth
				//			0 : if no regrowth
			// count the number of regrowth (hits) in W_Sampled
			currentNumberOfRegrowth = sum(W_Sampled)
			currenFractionRegrowth = currentNumberOfRegrowth / rs.totalAdded_obs
			// append this to model output
			regrowthOutput_6[i] = currentNumberOfRegrowth
			fractionRegrowth_6[i] = currenFractionRegrowth

		else
			//regrowthModelSlots[] is 0, no regrowth slots
		endif

	endfor
	
	//global pooledRegrowth
	Wave pooledRegrowth = pooledRegrowth
	Variable startPoolIdx = rs.row * 10000
	pooledRegrowth[startPoolIdx, startPoolIdx + 10000-1] = fractionRegrowth[p-startPoolIdx]
	
	Wave pooledRegrowth_obs = pooledRegrowth_obs
	pooledRegrowth_obs[rs.row] = observedFraction

	//global2
	Wave pooledRegrowth2 = pooledRegrowth2
	pooledRegrowth2[][rs.row] = fractionRegrowth[p]

	// davis global
	Wave pooledRegrowth_5 = pooledRegrowth_5
	Variable startPoolIdx_5 = rs.row * 10000
	pooledRegrowth_5[startPoolIdx_5, startPoolIdx_5 + 10000-1] = fractionRegrowth_5[p-startPoolIdx_5]
	
	Wave pooledRegrowth_6 = pooledRegrowth_6
	Variable startPoolIdx_6 = rs.row * 10000
	pooledRegrowth_6[startPoolIdx_6, startPoolIdx_6 + 10000-1] = fractionRegrowth_6[p-startPoolIdx_6]
	
	//append to pooledRegrowth
	
	//stats for model run
	//WaveStats/Q fractionRegrowth
	//	print "mean:", V_Avg
	//	print "SD:", V_SDEV
	//	print "SE:", V_SDEV / sqrt(V_NPNTS)
	//	print "n:", V_npnts
		
	
	// output how long that took
	//Variable/D stopTime = DateTime
	//print/D "done in", (stopTime-startTime)
	
End
////////////////////////////////////////////////////////////////////////////////
//todo: have runRegrowthModel(rs) fill in the answer into rs
Function plotRegrowthModel(rs, doPlot, davisNum)
STRUCT regrowthStruct &rs
Variable doPlot
Variable davisNum // 0:original, 1:5x slots, 2:6x slots

	// each [i] is number of regroth slots hit per iteration of the model
	//Wave regrowthOutput = regrowthOutput //created in and output of runRegrowthModel()
	//Display/K=1 regrowthOutput
	
	if (rs.totalAdded_obs == 0)
		print "rs.totalAdded_obs=0 -->> aborted plotRegrowthModel"
		return 0
	endif
	
	
	//
	// observed fraction of new spines that were regrowth spines
	Variable observedFraction = rs.numRegrow_obs / rs.totalAdded_obs
	if (doPlot)
		print "observed fraction:", observedFraction
	endif
	
	// debuggin
	if (observedFraction == 0)
		print ""
	endif
	
	//
	// each [i] is the fraction of regrowth for one iteration of model
	String appendWinStr = ""
	if (davisNum==0)
		//original
		Wave fractionRegrowth = fractionRegrowth //created in and output of runRegrowthModel()
	elseif (davisNum== 1)
		Wave fractionRegrowth = fractionRegrowth_5 //created in and output of runRegrowthModel()
		appendWinStr += "_5"
	elseif (davisNum==2)
		Wave fractionRegrowth = fractionRegrowth_6 //created in and output of runRegrowthModel()
		appendWinStr += "_6"
	else
		print "error: davisNum is", davisNum, "must be (0,1,2)"
	endif
	
	//
	// Histogram
	//
	Variable numBins = 2 ^ rs.prevOccupied + 1
	//
	numBins = rs.totalAdded_obs + 1
	//

	if (doPlot)
		print "histogram bins:", numBins
	endif
	String regrowthModelHistStr = "regrowthModelHist" + appendWinStr
	Make/O/N=(numBins) $regrowthModelHistStr = nan
	Histogram /C /B=3 fractionRegrowth, $regrowthModelHistStr //creates W_Histogram
		// mode /B=3 uses Sturges' method where numBins=1+log2(N)
		//Wave W_Histogram = W_Histogram
		//Variable numBins = DimSize(W_Histogram,0)
		if (doPlot)
			print "plotRegrowthModel() numBins:", numBins
		endif
		
	//just to get max, to plot observed as dotted line
	WaveStats/Q $regrowthModelHistStr 
		Variable regrowthModalHistMax = V_Max
		
	Make/O/N=(2) observedFraction_x = nan
		observedFraction_x[0] = observedFraction
		observedFraction_x[1] = observedFraction
	Make/O/N=(2) observedFraction_y = nan
		observedFraction_y[0] = 0
		observedFraction_y[1] = regrowthModalHistMax

	// move each (0,1,2) window accross screen
	Variable winLeft = 125 + (davisNum * 450)
	
	if (doPlot)
		String histWinStr = "modelHist" + appendWinStr
		if (regrowthWinExists(histWinStr))
			DoWindow/F $histWinStr
		else
			//Display/K=1 /W=(125,159,520,367) regrowthModelHist
			Display/K=1 /W=(winLeft,159,winLeft+400,367) $regrowthModelHistStr
				DoWindow/C $histWinStr
				SetAxis bottom 0,1
				ModifyGraph mode=5,hbFill=5,rgb=(0,0,0)
				ModifyGraph fSize=14
				Label bottom "Regrowth Fraction"
				Label left "Count"
				// put the observedFraction as a vertical dotted line
				AppendToGraph observedFraction_y vs observedFraction_x
					ModifyGraph lstyle(observedFraction_y)=2
		endif
	endif
			
	//
	// to test if observed fraction is an outlier (< 0.05 or > 0.95)
	// 1) decide if observed is on left or right of model histogram
	//		histogram has x bins from 0 .. numBins
	// 2) generate cumulative histogram and sum values of this histogram
	//		case 1 (observed is on left): [0, x val of hist == observed]
	//		case 2 (observed is on right): [x val of hist == observed, numBins-1)
	
	//
	// cumulative histogram
	String regrowthModelHist_cumStr = "regrowthModelHist_cum" + appendWinStr
	Make/O/N=(numBins) $regrowthModelHist_cumStr /Wave=regrowthModelHist_cumPtr = nan
	Histogram/B=1 /Cum /P fractionRegrowth, $regrowthModelHist_cumStr //creates W_Histogram

	if (doPlot)
		String histWinStr_cum = "modelHist_cum" + appendWinStr
		if (regrowthWinExists(histWinStr_cum))
			DoWindow/F $histWinStr_cum
		else
			//Display/K=1 /W=(127,410,522,618) $regrowthModelHist_cumStr
			Display/K=1 /W=(winLeft,410,winLeft+400,618) $regrowthModelHist_cumStr
				DoWindow/C $histWinStr_cum
				SetAxis bottom 0,1
				ModifyGraph mode=4,rgb=(0,0,0)
				ModifyGraph fSize=14
				Label bottom "Regrowth Fraction"
				Label left "Cumulative Probability"
		endif
		
		// plot all three davisNum=(0,1,2) on same plot
		String histWinStr_cum2 = "cumHist_w"
		if (regrowthWinExists(histWinStr_cum2))
			DoWindow/F $histWinStr_cum2
		else
			Display/K=1
			DoWindow/C $histWinStr_cum2
		endif
			// always append
			//Display/K=1 /W=(127,410,522,618) $regrowthModelHist_cumStr
			if (!bTraceIsInGraph2(histWinStr_cum2, regrowthModelHist_cumStr))
				AppendToGraph/W=$histWinStr_cum2 $regrowthModelHist_cumStr
			endif
				SetAxis/W=$histWinStr_cum2 bottom 0,1
				if (davisNum==0)
					ModifyGraph/W=$histWinStr_cum2 mode($regrowthModelHist_cumStr)=4,rgb($regrowthModelHist_cumStr)=(0,0,0)
				elseif (davisNum==1)
					ModifyGraph/W=$histWinStr_cum2 mode($regrowthModelHist_cumStr)=4,rgb($regrowthModelHist_cumStr)=(2^16-1,0,0), marker($regrowthModelHist_cumStr)=8
				elseif (davisNum==2)
					ModifyGraph/W=$histWinStr_cum2 mode($regrowthModelHist_cumStr)=4,rgb($regrowthModelHist_cumStr)=(0,0,2^16-1), marker($regrowthModelHist_cumStr)=6
				endif
				ModifyGraph fSize=14
				Label bottom "Regrowth Fraction"
				Label left "Cumulative Probability"		
	endif // doPlot
			
	//
	// outcome of model
	WaveStats/Q fractionRegrowth
		Variable modelMean = V_Avg
		Variable modelSD = V_SDEV
		Variable modelSE = V_SDEV / sqrt(V_NPNTS)
		Variable modelN = V_npnts
		if (doPlot)
			print "mean:", V_Avg
			print "SD:", V_SDEV
			print "SE:", V_SDEV / sqrt(V_NPNTS)
			print "n:", V_npnts
		endif
		
	//
	// unique bins
	String binList = ""
	Variable m = DimSize(fractionRegrowth,0)
	Variable i
	for (i=0; i<m; i+=1)
		if (WhichListItem(num2str(fractionRegrowth[i]), binList) == -1)
			binList += num2str(fractionRegrowth[i]) + ";"
		endif
	endfor
	if (doPlot)
		print "Number of unique fractionRegrowth bins:", ItemsInList(binList)
	endif
	
	//
	// p
	Variable pValue = nan
	//WaveStats/Q regrowthModelHist_cum
	//Variable cumHistMin = V_Min
	//Variable cumHistMax = V_Max
	if (observedFraction < modelMean)
		if (doPlot)
			print "Observed is to left of model mean"
		endif
		//pValue = sum(regrowthModelHist_cum, -Inf, observedFraction)
		//if (observedFraction < cumHistMin)
		//	pValue = 0
		//	print "\tp not calculated -->> 0"
		//else
			if (observedFraction < leftx($regrowthModelHist_cumStr))
				print "warning: observedFraction:", observedFraction, "leftx:", leftx($regrowthModelHist_cumStr)
				pValue = regrowthModelHist_cumPtr[0]
			else
				pValue = regrowthModelHist_cumPtr(observedFraction)
			endif
		//endif
	else
		if (doPlot)
			print "Observed is to right of model mean"
		endif
		//pValue = sum(regrowthModelHist_cum, observedFraction, Inf)
		//if (observedFraction > cumHistMax)
		//	pValue = 0
		//	print "\tp not calculated -->> 0"
		//else
			if (observedFraction == 0)
				print "warning: observedFraction == 0"
				pValue = 1 - regrowthModelHist_cumPtr[0]
			else
				pValue = 1 - regrowthModelHist_cumPtr(observedFraction)
			endif
		//endif
	endif
	if (doPlot)
		print "\tpValue:", pValue
	endif
	
	//
	// fill in regrowth struct with results
	Wave/T regrowthRawData = root:regrowthRawData

	regrowthRawData[rs.row][%obsFraction] = num2str(observedFraction)
	//
	regrowthRawData[rs.row][%$("pValue"+appendWinStr)] = num2str(pValue)
	//
	regrowthRawData[rs.row][%iterations] = num2str(rs.numberOfIerations)
	regrowthRawData[rs.row][%slotLength] = num2str(rs.slotLength)
	//
	regrowthRawData[rs.row][%totalNumberOfSlots] = num2str(rs.totalNumberOfSlots)
	//
	regrowthRawData[rs.row][%$("modelMean"+appendWinStr)] = num2str(modelMean)
	regrowthRawData[rs.row][%$("modelSD"+appendWinStr)] = num2str(modelSD)
	regrowthRawData[rs.row][%$("modelSE"+appendWinStr)] = num2str(modelSE)
	//regrowthRawData[rs.row][%modelN] = num2str(modelN)
End
////////////////////////////////////////////////////////////////////////////////
