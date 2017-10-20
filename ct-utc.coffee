# Cryptotrader Universal Trading Constructor bot
# Copyright (c) 2017, Dmitry Golubev
# All rights reserved.
# 
# This software uses BSD 2-clause "Simplified" License: https://github.com/lastguru1/ct-utc/blob/master/LICENSE
# 
# Newest version of the software is available here: https://github.com/lastguru1/ct-utc

talib = require "talib"
trading = require "trading"
params = require 'params'

# Strategy definition. If entered, all other options are ignored. Used for fast parameter reuse and sharing.
# STRATEGY = params.add 'Strategy definition', ''

# We can use crossings and/or oscillator to detect opportunities
OSC_MODE = params.addOptions 'Mode', ['Crossing only', 'Oscillator only', 'Any'], 'Any'

# What data input to use for MAs that only take one input: Close Price or Weighted Close Price
DATA_INPUT = params.addOptions 'Data input', ['Close', 'Typical', 'Weighted'], 'Close'

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
SHORT_MA_T = params.addOptions 'Short MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT', 'Laguerre'], 'SMA'
SHORT_MA_P = params.add 'Short MA period', '10'

# Long MA
LONG_MA_T = params.addOptions 'Long MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT', 'Laguerre'], 'SMA'
LONG_MA_P = params.add 'Long MA period', '10'

# Feedback can be applied on the price data used by LONG MA calculations (note: only LONG MA uses feedback)
# Delta feedback works like that:
# - calculate Feedback line using the given MA
# - calculate Short-Feedback delta
# - add the resulting delta to the price data to be used by LONG MA later
# Volume feedback works like that:
# - decide, which sign (positive or negative) would each of the volume data points have
#   (as volume does not have any sign at the beginning - it is always positive);
#   NB: instead of volume data, OBV can be used - it is signed, so it is usable as is
# - add the resulting data to the price data to be used bu LONG MA later
# The feedback can be modified (reduced) before being added
FEED_DELTA_T = params.addOptions 'Delta feedback reduction type (NONE disables this feedback)', ['NONE', 'Division', 'Root', 'Logarithm'], 'NONE'
FEED_DELTA_P = params.add 'Delta feedback reduction value', 1
FEED_MA_T = params.addOptions 'Delta feedback MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT'], 'SMA'
FEED_MA_P = params.add 'Delta feedback MA period', '10'
FEED_VOLUME_T = params.addOptions 'Volume feedback reduction type (NONE disables this feedback)', ['NONE', 'Division', 'Root', 'Logarithm'], 'NONE'
FEED_VOLUME_P = params.add 'Volume feedback reduction value', 1
FEED_VOLUME_S = params.addOptions 'Volume accounting type', ['Price', 'Short MA', 'Feedback MA', 'ShortFeedbackDelta', 'OBV'], 'Price'

# MACD will calculate MA from the resulting ShortLongDelta (the result is MACD Signal line)
# MACD will act on the ShortLongDelta crossing MACD Signal line, instead of Zero line
MACD_MA_T = params.addOptions 'MACD MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT', 'Laguerre'], 'NONE'
MACD_MA_P = params.add 'MACD MA period', '10'

# High and low thresholds
HI_THRESHOLD = params.add 'High threshold', 2
LO_THRESHOLD = params.add 'Low threshold', -1.5

# Which oscillator to use
# Money Flow Index seems like the best one, but some may prefer Relative Strength Index
OSC_TYPE = params.addOptions 'Oscillator type', ['MFI', 'RSI', 'LRSI', 'LMFI'], 'MFI'
OSC_THRESHOLD = params.add 'Oscillator cutoff', 20
OSC_PERIOD = params.add 'Oscillator period (gamma (0..1) for Laguerre)', 14

# We may want to smooth the oscillator results a bit
OSC_MA_T = params.addOptions 'Oscillator MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'HT', 'Laguerre'], 'WMA'
OSC_MA_P = params.add 'Oscillator MA period', '2'

# What trigger to use for oscillator
# Early: trigger once crossed
# Extreme: trigger once change direction (provisional top/bottom) after crossing
# Late: trigger when back within the bounds after crossing
OSC_TRIGGER = params.addOptions 'Oscillator trigger', ['Early', 'Extreme', 'Late'], 'Late'

# TODO: Check if Coppock curve (extremes only - not crossings; thresholds could be needed) is useful

REDUCE_BY = 1

LINIT = [0,0,0,0]
LGAMMA = 0

feedbackSign = (n) ->
	return Math.sign(n)

feedbackDivide = (n) ->
	return n/REDUCE_BY

feedbackRoot = (n) ->
	return Math.sign(n) * Math.pow(Math.abs(n), REDUCE_BY)

feedbackLog = (n) ->
	return Math.sign(n) * Math.log(Math.abs(n)) / Math.log(REDUCE_BY)

LaguerreMA = (n) ->
	L0 = (1 - LGAMMA) * n + LGAMMA * LINIT[0]
	L1 = -LGAMMA * L0 + LINIT[0] + LGAMMA * LINIT[1]
	L2 = -LGAMMA * L1 + LINIT[1] + LGAMMA * LINIT[2]
	L3 = -LGAMMA * L2 + LINIT[2] + LGAMMA * LINIT[3]
	LINIT = [L0, L1, L2, L3]
	return (L0 + 2*L1 + 2*L2 + L3) / 6

LaguerreRSI = (n) ->
	L0 = (1 - LGAMMA) * n + LGAMMA * LINIT[0]
	L1 = -LGAMMA * L0 + LINIT[0] + LGAMMA * LINIT[1]
	L2 = -LGAMMA * L1 + LINIT[1] + LGAMMA * LINIT[2]
	L3 = -LGAMMA * L2 + LINIT[2] + LGAMMA * LINIT[3]
	LINIT = [L0, L1, L2, L3]
	cu = 0
	cd = 0
	if L0 >= L1
		cu = L0 - L1
	else
		cd = L1 = L0
	if L1 >= L2
		cu = cu + L1 - L2
	else
		cd = cd + L2 - L1
	if L2 >= L3
		cu = cu + L2 - L3
	else
		cd = cd + L3 - L2
	if cu + cd is 0
		lrsi = 0
	else
		lrsi = cu / (cu + cd)
	return lrsi

processMA = (selector, period, instrument, secondary = false) ->
	if secondary
		sInput = instrument
	else if DATA_INPUT is 'Close'
		sInput = instrument.close
	else if DATA_INPUT is 'Typical'
		sInput = talib.TYPPRICE
			high: instrument.high
			low: instrument.low
			close: instrument.close
			startIdx: 0
			endIdx: instrument.close.length-1
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
		when 'Laguerre'
			LINIT = [0,0,0,0]
			LGAMMA = period
			_.map(sInput, LaguerreMA)

processOSC = (selector, period, instrument) ->
	switch OSC_TYPE
		when 'MFI'
			talib.MFI
				high: instrument.high
				low: instrument.low
				close: instrument.close
				volume: instrument.volumes
				startIdx: 0
				endIdx: instrument.close.length-1
				optInTimePeriod: OSC_PERIOD
		when 'RSI'
			talib.RSI
				inReal: processMA('NONE', 0, instrument)
				startIdx: 0
				endIdx: instrument.close.length-1
				optInTimePeriod: OSC_PERIOD
		when 'LRSI'
			LINIT = [0,0,0,0]
			LGAMMA = OSC_PERIOD
			price = processMA('NONE', 0, instrument)
			lrsi = _.map(price, LaguerreRSI)
			REDUCE_BY = 0.01
			_.map(lrsi, feedbackDivide)
		
		when 'LMFI'
			LINIT = [0,0,0,0]
			LGAMMA = OSC_PERIOD
			price = talib.MULT
				inReal0: processMA('NONE', 0, instrument)
				inReal1: instrument.volumes
				startIdx: 0
				endIdx: instrument.volumes.length-1
			lmfi = _.map(price, LaguerreRSI)
			REDUCE_BY = 0.01
			_.map(lmfi, feedbackDivide)

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
		HighOsc:
			color: 'darkyellow'
			secondary: true
		LowOsc:
			color: 'darkyellow'
			secondary: true
		Oscillator:
			color: 'darkyellow'
			secondary: true

handle: ->
	instrument = @data.instruments[0]
	storage.botStartedAt ?= data.at
	#	storage.sldHi ?= 0
	debug "price: #{instrument.close[instrument.close.length-1]} #{instrument.base().toUpperCase()} at #{new Date(data.at)}"
	
	plot
		Zero: 0
	
	if OSC_MODE isnt 'Oscillator only'
		short = processMA(SHORT_MA_T, SHORT_MA_P, instrument)
		lInput = processMA('NONE', 0, instrument)
		plot
			HighThreshold: HI_THRESHOLD
			LowThreshold: LO_THRESHOLD
			Short: _.last(short)
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
	
		if FEED_VOLUME_T isnt 'NONE'
			if FEED_VOLUME_S isnt 'OBV'
				switch FEED_VOLUME_S
					when 'Price'
						priceOld = _.dropRight(processMA('NONE', 0, instrument), 1)
						priceNew = _.drop(processMA('NONE', 0, instrument), 1)
					when 'Short MA'
						priceOld = _.dropRight(short, 1)
						priceNew = _.drop(short, 1)
					when 'Feedback MA'
						priceOld = _.dropRight(feedback, 1)
						priceNew = _.drop(feedback, 1)
					when 'ShortFeedbackDelta'
						priceOld = _.dropRight(shortFeedbackDelta, 1)
						priceNew = _.drop(shortFeedbackDelta, 1)
			
				priceDiff = talib.SUB
					inReal0: priceNew
					inReal1: priceOld
					startIdx: 0
					endIdx: priceOld.length-1
				signs = _.map(priceDiff, feedbackSign)
				volume = instrument.volumes
				if signs.length > volume.length
					signs = _.drop(signs, signs.length - volume.length)
				if volume.length > signs.length
					volume = _.drop(volume, volume.length - signs.length)
				volume = talib.MULT
					inReal0: signs
					inReal1: volume
					startIdx: 0
					endIdx: signs.length-1
			else
				price = processMA('NONE', 0, instrument)
				volume = instrument.volumes
				if price.length > volume.length
					price = _.drop(price, price.length - volume.length)
				if volume.length > price.length
					volume = _.drop(volume, volume.length - price.length)
				volume = talib.OBV
					inReal: price
					volume: volume
					startIdx: 0
					endIdx: signs.length-1
		
			REDUCE_BY = FEED_VOLUME_P
			switch FEED_VOLUME_T
				when 'Division'
					feedVolume = _.map(volume, feedbackDivide)
				when 'Root'
					feedVolume = _.map(volume, feedbackRoot)
				when 'Logarithm'
					feedVolume = _.map(volume, feedbackLog)
		
			if lInput.length > feedVolume.length
				lInput = _.drop(lInput, lInput.length - feedVolume.length)
			if short.length > lInput.length
				feedVolume = _.drop(feedVolume, feedVolume.length - lInput.length)
			lInput = talib.ADD
				inReal0: lInput
				inReal1: feedVolume
				startIdx: 0
				endIdx: feedVolume.length-1
	
		if FEED_VOLUME_T isnt 'NONE' or FEED_DELTA_T isnt 'NONE'
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
	
	if OSC_MODE isnt 'Crossing only'
		osc = processOSC(OSC_TYPE, OSC_PERIOD, instrument)
		osc = processMA(OSC_MA_T, OSC_MA_P, osc, true)
		plot
			HighOsc: 100 - OSC_THRESHOLD
			LowOsc: OSC_THRESHOLD
			Oscillator: _.last(osc)

	#	if _.last(shortLongDelta) > HI_THRESHOLD
	#		storage.sldHi = 1
	#	else if storage.sldHi is 1 and _.last(shortLongDelta) > LO_THRESHOLD
	#		storage.sldHi = 1
	#	else
	#		storage.sldHi = 0
