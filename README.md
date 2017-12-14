# ct-utc
Cryptotrader Universal Trading Constructor bot: a collection of trading strategies and implementation framework

This is an opensource Cryptotrader bot implementation. All are welcome to contribute and use this bot as you see fit. If you are making a fork or using this bot as a base for your work, please contribute the improvements and new strategies back to the community. The value of your bot does not diminish if you do that.

### Introduction
Most people want their bot to be as simple to configure, as possible. This bot is the complete opposite: it has so many configurable parameters, one can go crazy, analyzing them all (and more to come in future versions).

It is called "constructor", as there is no predefined behavior for this bot: almost any indicator-based strategy can be configured. This advanced bot is opensource, so you can see how it works and improve it. I am also eager to hear your ideas and results. Newest version of the software is always available here: https://github.com/lastguru1/ct-utc . Suggestions and code contributions are always welcome. My wish for this bot is for it to be able to execute any indicator-based strategy.

### Main Features
Full list of features can be seen in the code comments, so this is a simplified list:

* Comprehensive (and growing) set of Moving Averages (including EMA, KAMA, MAMA, HMA, FRAMA, ALMA, Hilbert Transform, VWMA and many, many others) with configurable thresholds.
* Feedback based on an additional Moving Average and volume to improve responsiveness.
* MACD with any Moving Averages.
* Many oscillators: Stochastic, RSI, MFI, Laguerre-based LRSI/LMFI, Fisher Transform. Signal trigger based on early or late crossing of the configured threshold line or, alternatively, based on crossing with its MA.
* Stochastic and Inverse Fisher Transform can be used to normalize oscillators (for example, to get StochRSI and similar strategies). Both input and result for oscillators can be smoothed with Moving Averages.
* Trading can be made just with crossing and/or oscillator signals, or they can combine signals for less false trades and better responsiveness (more combination algorithms to come).

### Donations
Donations are also welcome. BTC: 1Gnv7zAm5pyhydheUzEuVRRT4BpCJASFsg, ETH: 0xB643711A58b0b84Ed317BA3E6Cf9BEFf91E27587
