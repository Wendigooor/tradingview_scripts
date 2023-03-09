//+------------------------------------------------------------------+
//|                                                     Reverse EA.mq5 |
//|                            Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


// Inputs
input int FilterCandle = 12; // Filter Candle

// Global variables
double bufferUp[100];
double bufferDown[100];




#include <Trade/Trade.mqh>

input double Lots = 0.1;

input int TpPoints = 200;

input int SlPoints = 200;

input int TslPoints = 25;

input int TslTriggerPoints = 55;

input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input int Magic = 137;

CTrade trade;







int barsTotal;

//+------------------------------------------------------------------+
//| Expert Advisor initialization function                           |
//+------------------------------------------------------------------+
int OnInit()
{

    return INIT_SUCCEEDED;
}





int shift=0;

void OnTick()
{
    // get the current bar index
    // int currentBar = Bars- 1;
    
    int bars = iBars(_Symbol,PERIOD_CURRENT);

    if(barsTotal < bars){

      barsTotal = bars;
    
    
    
      double   high  = iHigh(Symbol(), Period(), shift);
      double   low   = iLow(Symbol(), Period(), shift);

    
    //int currentBar = bars[0];
    //int prevBar = bars[1];

    // calculate the current and previous bar indices for the indicator
    // int calculatedBars = IndicatorCounted();
    // int prevBars = calculatedBars > 0 ? calculatedBars - 1 : 0;

    // calculate the indicator values for the current bar
    // if (currentBar > prevBars)
    // {
    //    OnCalculate(currentBar, prevBars, iTime, iOpen, iHigh, iLow, iClose, iVolume, iVolume, iSpread);
    // }
    
    

      int limit = 50;
    
    //Print("run for");
    
      for(int i=limit; i>=0; i--) {
         shift++;
         bufferUp[i]=0;
         bufferDown[i]=0;
   
         if(i+FilterCandle+2 < limit)
           {
            if(isUp(i+1))
              {
               bufferUp[i+1]=low;
              }
   
            if(isDown(i+1))
              {
               bufferDown[i+1]=high;
              }
           }
       }
       
       //bool isLastArrowUp = bufferUp[1] != 0;
       //Print("isLastArrowUp"+isLastArrowUp)
       
       bool isLastArrowDown = bufferUp[1] != 0;
       bool isLastArrowUp = bufferDown[1] != 0;
       //Print("isLastArrowUp", isLastArrowUp);
       //Print("isLastArrowDown", isLastArrowDown);
       
       if (isLastArrowUp) {
         Alert(_Symbol, "isLastArrowUp");
         executeBuy();
       }
       
       if (isLastArrowDown) {
         Alert(_Symbol, "isLastArrowDown");
         executeSell();
       }
    }
    
    

    // check if the last arrow was an up arrow or a down arrow
    //bool isLastArrowUp = bufferUp[1] != 0;

}



bool isUp(int index)
  {
   bool flag=true;
   int preIndex=index+1;
   if(
      iLow(Symbol(),0,index)>iLow(Symbol(),0,preIndex)
      && iHigh(Symbol(),0,index)>iHigh(Symbol(),0,preIndex)
      && iClose(Symbol(),0,index)>iClose(Symbol(),0,preIndex)
      )
     {
      int startIndex=preIndex+1;
      int endIndex=preIndex+FilterCandle-1;
      for(int i=startIndex; i<=endIndex; i++)
        {
         if(iLow(Symbol(),0,i)<iLow(Symbol(),0,preIndex))
           {
            flag=false;
            break;
           }
        }
     }
   else
     {
      flag=false;
     }

   return flag;
  }
//+------------------------------------------------------------------+

bool isDown(int index)
  {
   bool flag=true;
   int preIndex=index+1;
   if(
      iLow(Symbol(),0,index)<iLow(Symbol(),0,preIndex)
      && iHigh(Symbol(),0,index)<iHigh(Symbol(),0,preIndex)
      && iClose(Symbol(),0,index)<iClose(Symbol(),0,preIndex)
      )
     {
      int start=preIndex+1;
      int end=preIndex+FilterCandle-1;
      for(int i=start; i<=end; i++)
        {
         if(iHigh(Symbol(),0,i)>iHigh(Symbol(),0,preIndex))
           {
            flag=false;
            break;
           }
        }
     }
   else
     {
      flag=false;
     }

   return flag;
  }
  
  
  
  
  


void executeBuy(){
   double lots = Lots;

//StopLoss & TakeProfit Setup
   double Bid;
   double Ask;

   double TakeProfit;
   double StopLoss;

   double TakeProfitLevel;
   double StopLossLevel;

   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   TakeProfitLevel = Bid + TpPoints * Point();   //0.0001 // Take Profit value defined
   StopLossLevel = Bid - SlPoints * Point(); // Stop loss value defined
   
   /*
   //Code For 5-Digit Brokers
   //Here we are assuming that the TakeProfit and StopLoss are entered in Pips
   
   TakeProfitLevel = Bid + TakeProfit*Point*10;   //0.00001 * 10 = 0.0001
   StopLossLevel = Bid - StopLoss*Point*10;
   */
   
   
   
   if(!trade.Sell(lots,_Symbol,Ask,StopLossLevel,TakeProfitLevel))
     {
      //--- failure message
      Print("Sell() method failed. Return code=",trade.ResultRetcode(),
            ". Code description: ",trade.ResultRetcodeDescription());
     }
   else
     {
      Print("Sell() method executed successfully. Return code=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
     }
}



void executeSell(){
   double lots = Lots;

//StopLoss & TakeProfit Setup
   double Bid;
   double Ask;

   double TakeProfit;
   double StopLoss;

   double TakeProfitLevel;
   double StopLossLevel;

   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   TakeProfit = 60;
   StopLoss = 30;
   
   TakeProfitLevel = Bid + TpPoints * Point();   //0.0001 // Take Profit value defined
   StopLossLevel = Bid - SlPoints * Point(); // Stop loss value defined
   
   /*
   //Code For 5-Digit Brokers
   //Here we are assuming that the TakeProfit and StopLoss are entered in Pips
   
   TakeProfitLevel = Bid + TakeProfit*Point*10;   //0.00001 * 10 = 0.0001
   StopLossLevel = Bid - StopLoss*Point*10;
   */
   
   
   
   if(!trade.Buy(lots,_Symbol,Bid,StopLossLevel,TakeProfitLevel))
     {
      //--- failure message
      Print("Buy() method failed. Return code=",trade.ResultRetcode(),
            ". Code description: ",trade.ResultRetcodeDescription());
     }
   else
     {
      Print("Buy() method executed successfully. Return code=",trade.ResultRetcode(),
            " (",trade.ResultRetcodeDescription(),")");
     }

}
