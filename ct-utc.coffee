talib = require "talib"
trading = require "trading"
params = require 'params'

# The following MAs can be used:
# SMA  - Simple Moving Average
# EMA - Exponential Moving Average
# WMA - Weighted Moving Average
# DEMA - Double Exponential Moving Average
# TEMA - Triple Exponential Moving Average
# TRIMA - Triangular Moving Average
# KAMA - Kaufman Adaptive Moving Average
# MAMA - MESA Adaptive Moving Average
# FAMA - Following Adaptive Moving Average
# T3 - Triple Exponential Moving Average
# HMA - Hull Moving Average
# HT - Hilbert Transform - Instantaneous Trendline

# Short MA
SHORT_MA_T = params.addOptions 'Short MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'SMA'
SHORT_MA_P = params.add 'Short MA period', 10

# Long MA
LONG_MA_T = params.addOptions 'Long MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'SMA'
LONG_MA_P = params.add 'Long MA period', 10

# Secondary MA
AUX_MA_T = params.addOptions 'Secondary MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'NONE'
AUX_MA_P = params.add 'Secondary MA period', 10

# The following MA actions can be performed:
# Crossing - Simple crossing of Short and Long MA
# MACD - Crossing of ShortLongDelta and AUX_MA(ShortLongDelta)
# Feedback - Crossing of Short and AUX_MA(Data +/- SQRT(ShortLongDelta))
# Volume Feedback - Crossing of Short and AUX_MA(Data +/- SQRT(ShortLongDelta) +/- LN(Volume))
MA_ACTION = params.addOptions 'MA action', ['Crossing', 'MACD', 'Feedback', 'VFeedback'], 'Crossing'

# What data input to use for MAs that only take one input: Close Price or Weighted Close Price
DATA_INPUT = params.addOptions 'Data input', ['Close', 'Weighted'], 'Close'

# Use Money Flow Index for additional actions
USE_MFI = params.add 'MFI cutoff for extremes (0 - disabled)', 0

# High and low thresholds
HI_THRESHOLD = params.add 'High threshold', 2
LO_THRESHOLD = params.add 'Low threshold', -1.5

# MAMA Fast and Slow limits
MAMA_FAST = params.add 'MAMA Fast limit (shared)', 0.5
MAMA_SLOW = params.add 'MAMA Slow limit (shared)', 0.05

feedbackReduce = (n) ->
	return n/2

processMA = (selector, period, instrument, secondary = false) ->
	if secondary
		sInput = instrument
	else if DATA_INPUT is 'Close'
		sInput = instrument.close
	else
		sInput = talib.WCLPRICE
			high: instrument.high
			low: instrument.low
			close: instrument.close
			startIdx: 0
			endIdx: instrument.close.length-1
	
	switch selector
		when 'NONE'
			sInput
		when 'SMA'
			talib.SMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'EMA'
			talib.EMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'WMA'
			talib.WMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'DEMA'
			talib.DEMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'TEMA'
			talib.TEMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'TRIMA'
			talib.TRIMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'KAMA'
			talib.KAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'MAMA'
			mama = talib.MAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInFastLimit: MAMA_FAST
				optInSlowLimit: MAMA_SLOW
			mama.outMAMA
		when 'FAMA'
			mama = talib.MAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInFastLimit: MAMA_FAST
				optInSlowLimit: MAMA_SLOW
			mama.outFAMA
		when 'T3'
			talib.T3
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
				optInVFactor: 0.7
		when 'HMA'
			halfWMA = talib.WMA
				inReal: sInput
				startIdx: period
				endIdx: sInput.length-1
				optInTimePeriod: Math.round(period/2)
			fullWMA = talib.WMA
				inReal: sInput
				startIdx: period
				endIdx: sInput.length-1
				optInTimePeriod: period
			twiceWMA = talib.ADD
				inReal0: halfWMA
				inReal1: halfWMA
				startIdx: 0
				endIdx: halfWMA.length-1
			avgWMA = talib.SUB
				inReal0: twiceWMA
				inReal1: fullWMA
				startIdx: 0
				endIdx: twiceWMA.length-1
			talib.WMA
				inReal: avgWMA
				startIdx: 0
				endIdx: avgWMA.length-1
				optInTimePeriod: Math.round(Math.sqrt(period))
		when 'HT'
			talib.HT_TRENDLINE
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1

init: ->
	# All the plotlines
	setPlotOptions
		Short:
			color: 'darkblue'
		Long:
			color: 'darkred'
		ShortLongDelta:
			color: 'green'
			secondary: true
		MACD:
			color: 'magenta'
			secondary: true
		ShortAuxDelta:
			color: 'magenta'
			secondary: true
		Feedback:
			color: 'lightpink'
		Aux:
			color: 'lightgreen'
		Zero:
			color: 'darkgrey'
			secondary: true
		HighThreshold:
			color: 'lightgreen'
			secondary: true
		LowThreshold:
			color: 'lightpink'
			secondary: true

handle: ->
	instrument = @data.instruments[0]
	storage.botStartedAt ?= data.at
	#	storage.sldHi ?= 0
	debug "price: #{instrument.close[instrument.close.length-1]} #{instrument.base().toUpperCase()} at #{new Date(data.at)}"
	
	short = processMA(SHORT_MA_T, SHORT_MA_P, instrument)
	long = processMA(LONG_MA_T, LONG_MA_P, instrument)
	if long.length > short.length
		long = _.drop(long, long.length - short.length)
	if short.length > long.length
		short = _.drop(short, short.length - long.length)
	shortLongDelta = talib.SUB
		inReal0: short
		inReal1: long
		startIdx: 0
		endIdx: long.length-1
	
	plot
		Short: _.last(short)
		Long: _.last(long)
		Zero: 0
		HighThreshold: HI_THRESHOLD
		LowThreshold: LO_THRESHOLD
		ShortLongDelta: _.last(shortLongDelta)

	switch MA_ACTION
		when 'MACD'
			macd = processMA(AUX_MA_T, AUX_MA_P, shortLongDelta, true)
			if macd.length > short.length
				macd = _.drop(macd, macd.length - short.length)
			if short.length > macd.length
				short = _.drop(short, short.length - macd.length)
			macdDelta = talib.SUB
				inReal0: short
				inReal1: macd
				startIdx: 0
				endIdx: macd.length-1
			plot
				MACD: _.last(macdDelta)
		when 'Feedback'
			if DATA_INPUT is 'Close'
				sInput = instrument.close
			else
				sInput = talib.WCLPRICE
					high: instrument.high
					low: instrument.low
					close: instrument.close
					startIdx: 0
					endIdx: instrument.close.length-1
			
			if sInput.length > shortLongDelta.length
				sInput = _.drop(sInput, sInput.length - shortLongDelta.length)
			if shortLongDelta.length > sInput.length
				shortLongDelta = _.drop(shortLongDelta, shortLongDelta.length - sInput.length)
			feedback = talib.ADD
				inReal0: sInput
				inReal1: _.map(shortLongDelta, feedbackReduce)
				startIdx: 0
				endIdx: shortLongDelta.length-1
			
			aux = processMA(AUX_MA_T, AUX_MA_P, feedback, true)
			if aux.length > short.length
				aux = _.drop(aux, aux.length - short.length)
			if short.length > aux.length
				short = _.drop(short, short.length - aux.length)
			shortAuxDelta = talib.SUB
				inReal0: short
				inReal1: aux
				startIdx: 0
				endIdx: aux.length-1
			plot
				Feedback: _.last(feedback)
				Aux: _.last(aux)
				ShortAuxDelta: _.last(shortAuxDelta)
	
	#	if _.last(shortLongDelta) > HI_THRESHOLD
	#		storage.sldHi = 1
	#	else if storage.sldHi is 1 and _.last(shortLongDelta) > LO_THRESHOLD
	#		storage.sldHi = 1
	#	else
	#		storage.sldHi = 0
