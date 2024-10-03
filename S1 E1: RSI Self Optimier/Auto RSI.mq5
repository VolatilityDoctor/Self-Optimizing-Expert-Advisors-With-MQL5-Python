//+------------------------------------------------------------------+
//|                                                     Auto RSI.mq5 |
//|                                        Gamuchirai Zororo Ndawana |
//|                          https://www.mql5.com/en/gamuchiraindawa |
//+------------------------------------------------------------------+
#property copyright "Gamuchirai Zororo Ndawana"
#property link      "https://www.mql5.com/en/gamuchiraindawa"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Libraries                                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
int rsi_handler;
double rsi_buffer[];
int ma_handler;
int system_state;
double ma_buffer[];
double bid,ask;

//--- Custom enumeration
enum close_conditions
  {
   MA_Close  = 0,
   RSI_Close
  };

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "Technical Indicators"
input int rsi_period = 20; //RSI Period
input int ma_period = 20; //MA Period

input group "Money Management"
input double trading_volume = 0.3; //Lot size

input group "Trading Rules"
input close_conditions user_close = RSI_Close; //How should we close the positions?

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Load the indicator
   rsi_handler = iRSI(_Symbol,PERIOD_M1,rsi_period,PRICE_CLOSE);
   ma_handler = iMA(_Symbol,PERIOD_M1,ma_period,0,MODE_EMA,PRICE_CLOSE);

//--- Validate our technical indicators
   if(rsi_handler == INVALID_HANDLE || ma_handler == INVALID_HANDLE)
     {
      //--- We failed to load the rsi
      Comment("Failed to load the RSI Indicator");
      return(INIT_FAILED);
     }

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release our technical indicators
   IndicatorRelease(rsi_handler);
   IndicatorRelease(ma_handler);

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Update market and technical data
   update();

//--- Check if we have any open positions
   if(PositionsTotal() == 0)
     {
      check_setup();
     }

   if(PositionsTotal() > 0)
     {
      manage_setup();
     }
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Manage our open setups                                           |
//+------------------------------------------------------------------+
void manage_setup(void)
  {
   if(user_close == RSI_Close)
     {
      if((system_state == 1) && ((rsi_buffer[0] > 71) && (rsi_buffer[80] <= 80)))
        {
         PositionSelect(Symbol());
         Trade.PositionClose(PositionGetTicket(0));
         return;
        }

      if((system_state == -1) && ((rsi_buffer[0] > 11) && (rsi_buffer[80] <= 20)))
        {
         PositionSelect(Symbol());
         Trade.PositionClose(PositionGetTicket(0));
         return;
        }
     }


   else
      if(user_close == MA_Close)
        {
         if((iClose(_Symbol,PERIOD_CURRENT,0) > ma_buffer[0]) && (system_state == -1))
           {
            PositionSelect(Symbol());
            Trade.PositionClose(PositionGetTicket(0));
            return;
           }

         if((iClose(_Symbol,PERIOD_CURRENT,0) < ma_buffer[0]) && (system_state == 1))
           {
            PositionSelect(Symbol());
            Trade.PositionClose(PositionGetTicket(0));
            return;
           }
        }

  }

//+------------------------------------------------------------------+
//| Find if we have any setups to trade                              |
//+------------------------------------------------------------------+
void check_setup(void)
  {

   if(user_close == RSI_Close)
     {
      if((rsi_buffer[0] > 71) && (rsi_buffer[0] <= 80))
        {
         Trade.Sell(trading_volume,_Symbol,bid,0,0,"Auto RSI");
         system_state = -1;
        }

      if((rsi_buffer[0] > 11) && (rsi_buffer[0] <= 20))
        {
         Trade.Buy(trading_volume,_Symbol,ask,0,0,"Auto RSI");
         system_state = 1;
        }
     }

   if(user_close == MA_Close)
     {
      if(((rsi_buffer[0] > 71) && (rsi_buffer[0] <= 80)) && (iClose(_Symbol,PERIOD_CURRENT,0) < ma_buffer[0]))
        {
         Trade.Sell(trading_volume,_Symbol,bid,0,0,"Auto RSI");
         system_state = -1;
        }

      if(((rsi_buffer[0] > 11) && (rsi_buffer[0] <= 20)) && (iClose(_Symbol,PERIOD_CURRENT,0) > ma_buffer[0]))
        {
         Trade.Buy(trading_volume,_Symbol,ask,0,0,"Auto RSI");
         system_state = 1;
        }
     }
  }

//+------------------------------------------------------------------+
//| Fetch market quotes and technical data                           |
//+------------------------------------------------------------------+
void update(void)
  {
   bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   CopyBuffer(rsi_handler,0,0,1,rsi_buffer);
   CopyBuffer(ma_handler,0,0,1,ma_buffer);
  }
//+------------------------------------------------------------------+
