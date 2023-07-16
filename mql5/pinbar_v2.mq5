// trailing sl from Rene, only one order at time

//+------------------------------------------------------------------+
//|                                           pinbar_strategy_v1.mq5 |
//|                           iiihar Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "iiihar Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property indicator_chart_window

#define VERSION "1.0"
#property version VERSION



#define PROJECT_NAME MQLInfoString(MQL_PROGRAM_NAME)

#include <Trade\PositionInfo.mqh>
#include <Trade/Trade.mqh>

//
//	Input Section
//

//	Slow moving average
input	int	InpSlowPeriods								=	77;	//	Slow periods
input	ENUM_MA_METHOD	InpSlowMethod					=	MODE_SMA;	//	Slow method
input	ENUM_APPLIED_PRICE	InpSlowAppliedPrice	=	PRICE_CLOSE;	// Slow price

//	Medium moving average
input	int	InpMediumPeriods								=	25;	//	Medium periods
input	ENUM_MA_METHOD	InpMediumMethod					=	MODE_EMA;	//	Medium method
input	ENUM_APPLIED_PRICE	InpMediumAppliedPrice	=	PRICE_CLOSE;	// Medium price

//	Fast moving average
input	int	InpFastPeriods								=	5;	//	Fast periods
input	ENUM_MA_METHOD	InpFastMethod					=	MODE_EMA;	//	Fast method
input	ENUM_APPLIED_PRICE	InpFastAppliedPrice	=	PRICE_CLOSE;	// Fast price

input double pinbarConfirmationValue = 0.3; // Pinbar confirmation

input	double	InpVolume		=	0.01;			//	Default order size

input int OrderDistPoints = 200;
input int TpPoints = 200;
input int SlPoints = 200;
input int TslPoints = 5;
input int TslTriggerPoints = 5;

input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input int Magic = 1333337;

CPositionInfo  m_position=CPositionInfo();// trade position object
CTrade         m_trade=CTrade();          // trading object

MqlTick LastTick;//last tick

ulong buyPos, sellPos;
int barsTotal;

int maSlowHandle;
int maMediumHandle;
int maFastHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   maSlowHandle = iMA(Symbol(),Period(),InpSlowPeriods,0,InpSlowMethod,InpSlowAppliedPrice);
   maMediumHandle = iMA(Symbol(),Period(),InpMediumPeriods,0,InpMediumMethod,InpMediumAppliedPrice);
   maFastHandle = iMA(Symbol(),Period(),InpFastPeriods,0,InpFastMethod,InpFastAppliedPrice);
   
   if(maSlowHandle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create maSlowHandle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

   if(maMediumHandle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create maMediumHandle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

   if(maFastHandle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create maFastHandle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
   
   barsTotal = iBars(_Symbol,Timeframe);
  
  
   m_trade.SetExpertMagicNumber(Magic);

   if(!m_trade.SetTypeFillingBySymbol(_Symbol)){
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }

   static bool isInit = false;

   if(!isInit){

      isInit = true;

      Print(__FUNCTION__," > EA (re)start...");

      Print(__FUNCTION__," > EA version ",VERSION,"...");
      
      
      
   }

   return(INIT_SUCCEEDED);
  }

   
void OnDeinit(const int reason){



}


void OnTick(){
   int bars = iBars(_Symbol,Timeframe);
   
   double   open  = iOpen(Symbol(),Timeframe,1);
   double   high  = iHigh(Symbol(),Timeframe,1);
   double   low   = iLow(Symbol(),Timeframe,1);
   double   close = iClose(Symbol(),Timeframe,1);
   
   //Print("onTick");
   
   TrailingStop();
   
   if ( PositionsTotal() > 0 ) {
      return;
   }
   
   
   ////// TrailingStop TrailingStop TrailingStop TrailingStop
   TrailingStop();
   ///// TrailingStop TrailingStop TrailingStop TrailingStop

   if(barsTotal < bars){
   
      //Print("onnewbar");
      barsTotal = bars;

      double maSlow[];
      CopyBuffer(maSlowHandle,MAIN_LINE,0,1,maSlow);

      
      double maMedium[];
      CopyBuffer(maMediumHandle,MAIN_LINE,0,1,maMedium);

      double maFast[];
      CopyBuffer(maFastHandle,MAIN_LINE,0,1,maFast);


      bool bullishPinBar = (close > open && (open - low) > pinbarConfirmationValue * (high - low)) ||
                  (close < open && close - low > pinbarConfirmationValue * (high - low));
      bool bearishPinBar = (close > open && (high - close) > pinbarConfirmationValue * (high - low)) ||
                  (close < open && (high - open) > pinbarConfirmationValue * (high - low));


      //bool fanUpTrend = fastEMA > medmEMA and medmEMA > slowSMA;
      //fanDnTrend = fastEMA < medmEMA and medmEMA < slowSMA
      bool fanUpTrend = maFast[0] > maMedium[0] && maMedium[0] > maSlow[0];
      bool fanDnTrend = maFast[0] < maMedium[0] && maMedium[0] < maSlow[0];
      
      //bullPierce = low < fastEMA and open > fastEMA and close > fastEMA 
      // or low < medmEMA and open > medmEMA and close > medmEMA 
      // or low < slowSMA and open > slowSMA and close > slowSMA and barstate.isconfirmed
      
      //bearPierce = high > fastEMA and open < fastEMA and close < fastEMA 
      // or high > medmEMA and open < medmEMA and close < medmEMA 
      // or high > slowSMA and open < slowSMA and close < slowSMA and barstate.isconfirmed

//bool bullPierce = true;
      bool bullPierce = (low < maFast[0] && open > maFast[0] &&  close > maFast[0]) ||
                     (low < maMedium[0]  && open > maMedium[0]  && close > maMedium[0]) ||
                     ( low < maSlow[0] && open > maSlow[0] && close > maSlow[0] );

      bool bearPierce = ( high > maFast[0] && open < maFast[0] && close < maFast[0] ) ||
                     ( high > maMedium[0] && open < maMedium[0] && close < maMedium[0] ) ||
                     ( high > maSlow[0] && open < maSlow[0] && close < maSlow[0] );

      //longEntry = fanUpTrend and bullishPinBar and bullPierce and hull_uptrend and barstate.isconfirmed
      //shortEntry = fanDnTrend and bearishPinBar and bearPierce and hull_downtrend and barstate.isconfirmed

      //bool longEntry = fanUpTrend && bullishPinBar && bullPierce;
      //bool shortEntry = fanDnTrend && bearishPinBar && bearPierce;
      
      bool longEntry = fanUpTrend;
      bool shortEntry = fanDnTrend;
      
      Print("longEntry: ", longEntry, " fanUpTrend: ", fanUpTrend, " bullishPinBar: ", bullishPinBar, " bullPierce: ", bullPierce);
      // Print("shortEntry: ", shortEntry);

      
      if (longEntry && PositionsTotal() == 0 ) {
         Print("LONG ENTRY");
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         executeBuy(ask);
         
         /*double tp = ask + TpPoints * _Point;
         tp = NormalizeDouble(tp,_Digits);
         
         double sl = ask - SlPoints * _Point;
         sl = NormalizeDouble(sl,_Digits);
         
         m_trade.Buy(InpVolume,_Symbol, ask, sl, tp);*/
      }
      
      if (shortEntry && PositionsTotal() == 0 ) {
         Print("SHORT ENTRY");
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         executeSell(bid);
         
         /*double tp = bid - TpPoints * _Point;
         tp = NormalizeDouble(tp,_Digits);

         double sl = bid + SlPoints * _Point;
         sl = NormalizeDouble(sl,_Digits);
   
         m_trade.Sell(InpVolume,_Symbol, bid, sl, tp);*/
      }


      /*if(ma[1] > ma[0] && maDirection <= 0){

         maDirection = 1;

         

         trade.PositionClose(_Symbol);

         trade.Buy(Lots);

      }else if(ma[1] < ma[0] && maDirection >= 0){

         maDirection = -1;

         

         trade.PositionClose(_Symbol);
         trade.Sell(Lots);
      }

      

      Comment("\nMa Direction: ",maDirection,

              "\nma[0]: ",DoubleToString(ma[0],_Digits),

              "\nma[1]: ",DoubleToString(ma[1],_Digits));*/

   }

}








void processPos(ulong &posTicket){
   if(posTicket <= 0) return;
   if(OrderSelect(posTicket)) return;
   
   CPositionInfo pos;

   if(!pos.SelectByTicket(posTicket)){
      posTicket = 0;
      return;
   }else{
      if(pos.PositionType() == POSITION_TYPE_BUY){
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         
         if(bid > pos.PriceOpen() + TslTriggerPoints * _Point){
            double sl = bid - TslPoints * _Point;
            sl = NormalizeDouble(sl,_Digits);
            
            if(sl > pos.StopLoss()){
               m_trade.PositionModify(pos.Ticket(),sl,pos.TakeProfit());
            }
         }
      }else if(pos.PositionType() == POSITION_TYPE_SELL){
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         
         if(ask < pos.PriceOpen() - TslTriggerPoints * _Point){
            double sl = ask + TslPoints * _Point;
            sl = NormalizeDouble(sl,_Digits);

            if(sl < pos.StopLoss() || pos.StopLoss() == 0){
               m_trade.PositionModify(pos.Ticket(),sl,pos.TakeProfit());
            }
         }
      }
   }
}



void TrailingStop() {
  for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0)
        {
            int Error = GetLastError();
            Print("ERROR - Unable to select the position - ", Error);
            break;
        }

        // Trading disabled.
        if (SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED) continue;
        
        // Filters.
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

        processPos(ticket);
   }
}





void executeBuy(double entry){
   entry = NormalizeDouble(entry,_Digits);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double tp = entry + TpPoints * _Point;
   tp = NormalizeDouble(tp,_Digits);
   double sl = entry - SlPoints * _Point;
   sl = NormalizeDouble(sl,_Digits);
   double lots = InpVolume;

   m_trade.Buy(lots, _Symbol, entry,sl,tp);
}



void executeSell(double entry) {
   entry = NormalizeDouble(entry,_Digits);  
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double tp = entry - TpPoints * _Point;
   tp = NormalizeDouble(tp,_Digits);
   double sl = entry + SlPoints * _Point;
   sl = NormalizeDouble(sl,_Digits);
   double lots = InpVolume;

//m_trade.Sell(volume, symbol, price, sl, tp, comment)
   m_trade.Sell(lots,_Symbol, entry,sl,tp);
}














/*void TrailingStop()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {

        ulong ticket = PositionGetTicket(i);

        if (ticket <= 0)
        {
            int Error = GetLastError();
            //string ErrorText = ErrorDescription(Error);
            Print("ERROR - Unable to select the position - ", Error);
            //Print("ERROR - ", ErrorText);
            break;
        }

        // Trading disabled.
        if (SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED) continue;
        
        // Filters.
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        //if ((UseMagic) && (PositionGetInteger(POSITION_MAGIC) != MagicNumber)) continue;
        //if ((UseComment) && (StringFind(PositionGetString(POSITION_COMMENT), CommentFilter) < 0)) continue;
        //if ((OnlyType != All) && (PositionGetInteger(POSITION_TYPE) != OnlyType)) continue;

        // Normalize trailing stop value to the point value.
        double TSTP = TrailingStop * _Point;
        double P = Profit * _Point;

        double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double StopLoss = PositionGetDouble(POSITION_SL);
        double TakeProfit = PositionGetDouble(POSITION_TP);

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            if (NormalizeDouble(Bid - OpenPrice, _Digits) >= NormalizeDouble(P, _Digits))
            {
                if ((TSTP != 0) && (StopLoss < NormalizeDouble(Bid - TSTP, _Digits)))
                {
                    ModifyPosition(ticket, OpenPrice, NormalizeDouble(Bid - TSTP, _Digits), TakeProfit);
                }
            }
        }
        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            if (NormalizeDouble(OpenPrice - Ask, _Digits) >= NormalizeDouble(P, _Digits))
            {
                if ((TSTP != 0) && ((StopLoss > NormalizeDouble(Ask + TSTP, _Digits)) || (StopLoss == 0)))
                {
                    ModifyPosition(ticket, OpenPrice, NormalizeDouble(Ask + TSTP, _Digits), TakeProfit);
                }
            }
        }
    }
}

void ModifyPosition(ulong Ticket, double OpenPrice, double SLPrice, double TPPrice)
{
    for (int i = 1; i <= OrderOpRetry; i++) // Several attempts to modify the position.
    {
        bool result = m_trade.PositionModify(Ticket, SLPrice, TPPrice);
        if (result)
        {
            Print("TRADE - UPDATE SUCCESS - Order ", Ticket, " new stop-loss ", SLPrice);
            // NotifyStopLossUpdate(Ticket, SLPrice);
            break;
        }
        else
        {
            Print("ERROR - UPDATE FAILED - error modifying order ");
            //int Error = GetLastError();
            //string ErrorText = ErrorDescription(Error);
            //Print("ERROR - UPDATE FAILED - error modifying order ", Ticket, " return error: ", Error, " Open=", OpenPrice,
            //      " Old SL=", PositionGetDouble(POSITION_SL),
            //      " New SL=", SLPrice, " Bid=", SymbolInfoDouble(Symbol(), SYMBOL_BID), " Ask=", SymbolInfoDouble(Symbol(), SYMBOL_ASK));
            //Print("ERROR - ", ErrorText);
        }
    }
}*/
