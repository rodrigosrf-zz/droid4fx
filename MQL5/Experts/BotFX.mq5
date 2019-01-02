//+------------------------------------------------------------------+
//|                                              Moving Averages.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018 Rodrigo"
#property link      "rodrigosf@outlook.com"
#property version   "1.000"

#include "Estrategia\EST_GRID_MEDIA.mqh"

CEstGridTrend grid;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
{
   ENUM_INIT_RETCODE g;

   grid = new CEstGridTrend();
   
   g = grid.Iniciar();
   if(g!=INIT_SUCCEEDED) return g;
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
{

   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && !IsStopped())
   {
      grid.Executar(); 
   }

}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
