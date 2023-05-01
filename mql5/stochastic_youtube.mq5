// Include
//+----
#include <Trade\Trade.mqh>

//+
// Global variables
//+--
enum SIGNAL_MODE {
  EXIT_CROSS_NORMAL,    // exit cross normal
  ENTRY_CROSS_NORMAL,   // entry cross normal
  EXIT_CROSS_REVERSED,  // exit cross reversed
  ENTRY_CROSS_REVERSED, // entry cross reversed
};

int handle;
double bufferMain[];
MqlTick cT;
CTrade trade;

//+----
input group "==== General ====";
static input long InpMagicNumber = 564892; // magicnumber
static input double InpLotSize = 0.01; // lot size
input group "==== Trading ====";
input SIGNAL_MODE InpSignalMode = EXIT_CROSS_NORMAL; // signal mode
input int InpStopLoss = 200; // stop loss in points (0=off)
input int InpTakeProfit = 0; // take profit in points (0=off)
input bool InpCloseSignal = false; // close trades by opposite signal
input group "==== Stochastic ====";
input int InpKPeriod = 21;
input int InpUpperLevel = 80;
input group "==== Clear bars filter ===="
input bool InpClearBarsReversed = false;
input int InpClearBars = 0;


int OnInit()
{
   if(!CheckInputs()) { return INIT_PARAMETERS_INCORRECT; }
   
   trade.SetExpertMagicNumber(InpMagicNumber);
   
   handle = iStochastic(_Symbol, PERIOD_CURRENT, InpKPeriod, 1,3, MODE_SMA, STO_LOWHIGH);
   if (handle == INVALID_HANDLE){
      Alert("Failed to create indicator handle");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(bufferMain, true);
   
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason){
   if(handle!=INVALID_HANDLE){
     IndicatorRelease(handle);
   }

}


void OnTick(){

   if (!IsNewBar()) { return; }

   if (!SymbolInfoTick(_Symbol,cT)) { Print("Failed to get current symbol tick"); return; }

   if (CopyBuffer(handle,0,0,3+InpClearBars,bufferMain)!=(3+InpClearBars)) {
      Print("Failed to get indicator values");
      return;
   }
   
   
   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy,cntSell)){
      Print("Failed to count open positions");
      return;
   }
   
   if(CheckSignal(true, cntBuy) && CheckClearBars(true)) {
      if(InpCloseSignal) { if(!ClosePositions(2)) { return; } }
      double sl = InpStopLoss == 0 ? 0 : cT.bid - InpStopLoss * _Point;
      double tp = InpTakeProfit == 0 ? 0 : cT.bid + InpTakeProfit * _Point;
      if (!NormalizePrice(sl)) {return;}
      if (!NormalizePrice(tp)) {return;}
      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, cT.ask, sl, tp, "Stoch EA");
   }
   
   if(CheckSignal(false, cntSell) && CheckClearBars(false)) {
      if(InpCloseSignal) { if(!ClosePositions(1)) { return; } }
      double sl = InpStopLoss == 0 ? 0 : cT.ask + InpStopLoss * _Point;
      double tp = InpTakeProfit == 0 ? 0 : cT.ask - InpTakeProfit * _Point;
      if (!NormalizePrice(sl)) {return;}
      if (!NormalizePrice(tp)) {return;}
      trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, cT.bid, sl, tp, "Stoch EA");
   }
}

bool CheckInputs(){
   if(InpMagicNumber<=0) {
      Alert("Wront input Magin number");
      return false;
   }

   if (InpLotSize <=0 || InpLotSize>10){
      Alert("wtong lots");
      return false;
   }
   
   if (InpStopLoss < 0 ){
      Alert("wrong stoplocc (<0)");
      return false;
   }

   if (InpTakeProfit < 0 ){
      Alert("wrong TP (<0)");
      return false;
   }
   
   return true;
}

bool IsNewBar() {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(previousTime!=currentTime) {
      previousTime=currentTime;
      return true;
   }
   return false;
}

bool CountOpenPositions(int &cntBuy, int &cntSell) {

   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   
   for(int i=total-1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) { Print("Failed to get position ticket"); return false; }
      if(!PositionSelectByTicket(ticket)) {Print("Failed to get position magicnumber"); return false; }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) { Print("Failed to get position magic"); return false; }
     
      if (magic==InpMagicNumber) {
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type)) { Print("Failed to get position type"); return false; }
         if(type==POSITION_TYPE_BUY){cntBuy++;}
         if(type==POSITION_TYPE_SELL){cntSell++;}
      }
   }

   return true;
}


bool NormalizePrice(double &price) {

   double tickSize=0;
   if (!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) {
      Print("Failed to get tick size");
      return false;
   }
   
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize, _Digits);
   
   return true;
}

bool ClosePositions(int all_buy_sell) {

   int total = PositionsTotal();
   
   for(int i=total-1; i>= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) { Print("Failed to get position ticket"); return false; }
      if(!PositionSelectByTicket(ticket)) {Print("Failed to get position magicnumber"); return false; }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) { Print("Failed to get position magic"); return false; }
     
      if (magic==InpMagicNumber) {
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type)) { Print("Failed to get position type"); return false; }
         
         if (all_buy_sell==1 && type==POSITION_TYPE_SELL) {continue;}
         if (all_buy_sell==2 && type==POSITION_TYPE_BUY) { continue; }
         trade.PositionClose(ticket);
         
         if (trade.ResultRetcode() != TRADE_RETCODE_DONE){
            Print("Failed to close position ticket:", (string)ticket, " result:", (string)trade.ResultRetcode(),":", trade.CheckResultRetcodeDescription());
         }
      }
   }

   return true;
}


bool CheckSignal(bool buy_sell, int cntBuySell) {

   if (cntBuySell>0) { return false; }
   
   int lowerLevel = 100 - InpUpperLevel;
   bool upperExitCross = bufferMain[1]>=InpUpperLevel && bufferMain[2]<InpUpperLevel;
   bool upperEntryCross = bufferMain[1] <= InpUpperLevel && bufferMain[2] > InpUpperLevel;
   
   bool lowerExitCross = bufferMain[1]<=lowerLevel && bufferMain[2]>lowerLevel;
   bool lowerEntryCross = bufferMain[1]>=lowerLevel && bufferMain[2]<lowerLevel;
   
   
   switch(InpSignalMode) {
      case EXIT_CROSS_NORMAL:  return ((buy_sell && lowerExitCross) || (!buy_sell && upperExitCross));
      case ENTRY_CROSS_NORMAL: return ((buy_sell && lowerEntryCross) || (!buy_sell && upperEntryCross));
      case EXIT_CROSS_REVERSED: return ((buy_sell && upperExitCross) || (!buy_sell && lowerExitCross));
      case ENTRY_CROSS_REVERSED: return ((buy_sell && upperEntryCross) || (!buy_sell && lowerEntryCross));
   }
   
   return false;
}


bool CheckClearBars(bool buy_sell) {

   if(InpClearBars==0) {return false;}
   
   bool checkLower = ((buy_sell && (InpSignalMode == EXIT_CROSS_NORMAL || InpSignalMode == ENTRY_CROSS_NORMAL))
                     || (!buy_sell && (InpSignalMode == EXIT_CROSS_REVERSED || InpSignalMode == ENTRY_CROSS_REVERSED)));
   
   for(int i=3; i<(3+InpClearBars); i++){
      
      if(!checkLower && ((bufferMain[i-1]>InpUpperLevel && bufferMain[i] <= InpUpperLevel)
                        || (bufferMain[i-1]<InpUpperLevel && bufferMain[i] >= InpUpperLevel))) {
         
         if(InpClearBarsReversed){return true;}
         else {
            Print("Clear bars filter prevented ", buy_sell ? "buy" : "sell", " signal. Cross of upper level at index ", (i-1), "->", i);
            return false;
         }                  
      }
    


      if(checkLower && ((bufferMain[i-1]<(100-InpUpperLevel) && bufferMain[i]>=(100-InpUpperLevel))
                     || (bufferMain[i-1]>(100-InpUpperLevel) && bufferMain[i]<=(100-InpUpperLevel)))){
                     
                     
         if(InpClearBarsReversed){return true;}
         else {
            Print("Clear bars filter prevented ", buy_sell ? "buy" : "sell", " signal. Cross of upper level at index ", (i-1), "->", i);
            return false;
         }
      }                 
   }
   
   if(InpClearBarsReversed){
      Print("Clear bars filter prevented ", buy_sell ? "buy" : "sell", " signal. No cross detected");
      return false;
   }
   else{return true;}
}
