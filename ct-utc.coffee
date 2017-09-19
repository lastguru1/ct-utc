talib = require "talib"
trading = require "trading"
params = require 'params'

# Strategy definition. If entered, all other options are ignored. Used for fast parameter reuse and sharing
# STRATEGY = params.add 'Strategy definition', ''

# What data input to use for MAs that only take one input: Close Price or Weighted Close Price
DATA_INPUT = params.addOptions 'Data input', ['Close', 'Weighted'], 'Close'

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
SHORT_MA_P = params.add 'Short MA period', '10'

# Long MA
LONG_MA_T = params.addOptions 'Long MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'SMA'
LONG_MA_P = params.add 'Long MA period', '10'

# Feedback can be applied on the price data used by LONG MA calculations
# First type is when we will calculate ShortFeedbackDelta and add it to the prices
# Second type is when we add volume data and add it to the prices
# Unlike Delta, Volume does not have a sign, no one needs to be chosen
#  either from price change, or from Short MA change. Volume can also be read from OBV
# The feedback can be modified (reduced) before being added
FEED_DELTA_T = params.addOptions 'Delta feedback reduction type', ['NONE', 'Division', 'Root', 'Logarithm'], 'NONE'
FEED_DELTA_P = params.add 'Delta feedback reduction value', 1
FEED_MA_T = params.addOptions 'Delta feedback MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'SMA'
FEED_MA_P = params.add 'Delta feedback MA period', '10'
#FEED_VOLUME_T = params.addOptions 'Volume feedback reduction type', ['NONE', 'Division', 'Root', 'Logarithm'], 'NONE'
#FEED_VOLUME_P = params.add 'Volume feedback reduction value', 1
#FEED_VOLUME_S = params.addOptions 'Volume accounting type', ['Price', 'Short MA', 'Feedback MA', 'OBV'], 'Price'

# MACD MA
MACD_MA_T = params.addOptions 'MACD MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'NONE'
MACD_MA_P = params.add 'MACD MA period', '10'

# Use Money Flow Index for additional actions
# USE_MFI = params.add 'MFI cutoff for extremes (0 - disabled)', 0

# High and low thresholds
HI_THRESHOLD = params.add 'High threshold', 2
LO_THRESHOLD = params.add 'Low threshold', -1.5

REDUCE_BY = 1

feedbackDivide = (n) ->
	return n/REDUCE_BY

feedbackRoot = (n) ->
	return Math.sign(n) * Math.pow(Math.abs(n), REDUCE_BY)

feedbackLog = (n) ->
	return Math.sign(n) * Math.log(Math.abs(n)) / Math.log(REDUCE_BY)

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
			# MAMA Fast (0.5) and Slow (0.05) limits
			limits = "#{period}".split " "
			if limits[0]? and limits[0] < 1
				MAMA_FAST = limits[0]
			else
				MAMA_FAST = 0.5
			if limits[1]? and limits[1] < 1
				MAMA_SLOW = limits[1]
			else
				MAMA_SLOW = 0.05
			mama = talib.MAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInFastLimit: MAMA_FAST
				optInSlowLimit: MAMA_SLOW
			mama.outMAMA
		when 'FAMA'
			# MAMA Fast (0.5) and Slow (0.05) limits
			limits = "#{period}".split " "
			if limits[0]? and limits[0] < 1
				MAMA_FAST = limits[0]
			else
				MAMA_FAST = 0.5
			if limits[1]? and limits[1] < 1
				MAMA_SLOW = limits[1]
			else
				MAMA_SLOW = 0.05
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
		# Short MA on data
		Short:
			color: 'darkblue'
		# Feedback MA on data
		Feedback:
			color: 'lightred'
		# Short-Feedback delta		
		ShortFeedbackDelta:
			color: 'lightgreen'
			secondary: true
		# Delta added to data
		CorrectedPrice:
			color: 'lightpink'
		# Long MA on corrected data
		Long:
			color: 'darkred'
		# Short-Long delta
		ShortLongDelta:
			color: 'darkgreen'
			secondary: true
		# MACD MA on Short-Long delta
		MACD:
			color: 'magenta'
			secondary: true
		Zero:
			color: 'darkgrey'
			secondary: true
		HighThreshold:
			color: 'darkseagreen'
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
	plot
		HighThreshold: HI_THRESHOLD
		Zero: 0
		LowThreshold: LO_THRESHOLD
		Short: _.last(short)
	
	lInput = processMA('NONE', 0, instrument)
	if FEED_DELTA_T isnt 'NONE'
		feedback = processMA(FEED_MA_T, FEED_MA_P, instrument)
		if feedback.length > short.length
			feedback = _.drop(feedback, feedback.length - short.length)
		if short.length > feedback.length
			short = _.drop(short, short.length - feedback.length)
		shortFeedbackDelta = talib.SUB
			inReal0: short
			inReal1: feedback
			startIdx: 0
			endIdx: feedback.length-1
		
		REDUCE_BY = FEED_DELTA_P
		switch FEED_DELTA_T
			when 'Division'
				feedDelta = _.map(shortFeedbackDelta, feedbackDivide)
			when 'Root'
				feedDelta = _.map(shortFeedbackDelta, feedbackRoot)
			when 'Logarithm'
				feedDelta = _.map(shortFeedbackDelta, feedbackLog)
		
		if lInput.length > feedDelta.length
			lInput = _.drop(lInput, lInput.length - feedDelta.length)
		if short.length > lInput.length
			feedDelta = _.drop(feedDelta, feedDelta.length - lInput.length)
		lInput = talib.ADD
			inReal0: lInput
			inReal1: feedDelta
			startIdx: 0
			endIdx: feedDelta.length-1
		plot
			Feedback: _.last(feedback)
			ShortFeedbackDelta: _.last(shortFeedbackDelta)
			CorrectedPrice: _.last(lInput)
	
	long = processMA(LONG_MA_T, LONG_MA_P, lInput, true)
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
		Long: _.last(long)
		ShortLongDelta: _.last(shortLongDelta)
	
	if MACD_MA_T isnt 'NONE'
		macd = processMA(MACD_MA_T, MACD_MA_P, shortLongDelta, true)
		if macd.length > shortLongDelta.length
			macd = _.drop(macd, macd.length - shortLongDelta.length)
		if shortLongDelta.length > macd.length
			shortLongDelta = _.drop(shortLongDelta, shortLongDelta.length - macd.length)
		macdDelta = talib.SUB
			inReal0: shortLongDelta
			inReal1: macd
			startIdx: 0
			endIdx: macd.length-1
		plot
			MACD: _.last(macdDelta)

	#	if _.last(shortLongDelta) > HI_THRESHOLD
	#		storage.sldHi = 1
	#	else if storage.sldHi is 1 and _.last(shortLongDelta) > LO_THRESHOLD
	#		storage.sldHi = 1
	#	else
	#		storage.sldHi = 0
