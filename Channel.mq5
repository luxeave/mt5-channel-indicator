//+------------------------------------------------------------------+
//|                                                      Channel.mq5 |
//|                                  Copyright 2023, Stephen Antoni. |
//|                                          https://www.luxeave.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Stephen Antoni."
#property link      "https://www.luxeave.com"
#property version   "1.00"

#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots 2

#property indicator_color1 clrWhite 
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID

#property indicator_color2 clrLime
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID

input int InpPeriod = 10; // Period

// Global vars
double BufferDown[];
double BufferUp[];
double BufferHlv[];

int HandleHigh;
int HandleLow;

/*
   @version=3
   study("SSL channel", ovverlay=true)
   len=input(title="Period", defval=10)
   smaHigh=sma(high, len)
   smaLow=sma(low, len)
   
   // Hlv -> wont be stored in buffer, because we wont be displaying this
   Hlv = na
   Hlv := close > smaHigh ? 1 : close < smaLow ? -1 : Hlv[1]
   
   // sslDown & sslUp -> buffer
   sslDown = Hlv < 0 ? smaHigh: smaLow
   sslUp = Hlv < 0 ? smaLow : smaHigh
   
   plot(sslDown, lineWidth=2, color=red)
   plot(sslUp, lineWidth=2, color=lime)
*/
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, BufferDown, INDICATOR_DATA);
   // plot
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(0, PLOT_LABEL, "Down");
   // bar 0 as current bar, bar max-1 as furthest bar
   ArraySetAsSeries(BufferDown, true);
   
   SetIndexBuffer(1, BufferUp, INDICATOR_DATA);
   // plot
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(1, PLOT_LABEL, "Up");
   
   ArraySetAsSeries(BufferUp, true);
   
   SetIndexBuffer(2, BufferHlv);
   ArraySetAsSeries(BufferHlv, true);
   
   HandleHigh = iMA(Symbol(), Period(), InpPeriod, 0, MODE_SMA, PRICE_HIGH);
   HandleLow = iMA(Symbol(), Period(), InpPeriod, 0, MODE_SMA, PRICE_HIGH);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, // how many bars available
                const int prev_calculated, // useful to skip bars already evaluated
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if (rates_total<InpPeriod) return 0;
   
   if (IsStopped()) return 0;
   
   int bars_num_to_evaluate = (prev_calculated==0) ? (rates_total-InpPeriod-1) : (rates_total-prev_calculated);
   
   // make iMA values available
   // iMA could not be treated as array that is readily accessible 
   double highValues[];
   ArraySetAsSeries(highValues, true);
   CopyBuffer(HandleHigh, 0, 0, bars_num_to_evaluate+1, highValues);
   
   double lowValues[];
   ArraySetAsSeries(lowValues, true);
   CopyBuffer(HandleLow, 1, 0, bars_num_to_evaluate+1, lowValues);
   
   // convert close array as onCalculate param
   ArraySetAsSeries(close, true);
   
   for (int i=bars_num_to_evaluate; i>=0 && !IsStopped(); i--){ // start from furthest all the way to 0
     
      /*
      Hlv := close > smaHigh ? 1 : close < smaLow ? -1 : Hlv[1]
      */
      
      BufferHlv[i] = close[i] > highValues[i] ? 1 : close[i] < lowValues[i] ? -1 : BufferHlv[i+1];
      BufferUp[i] = BufferHlv[i]<0 ? lowValues[i] : highValues[i];
      BufferDown[i] = BufferHlv[i]>0 ? lowValues[i] : highValues[i];
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
