//+------------------------------------------------------------------+
//|                                               Droid4FX-MOD37.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                            rodrigosf@outlook.com |
//+------------------------------------------------------------------+
input int    NumMagico           = 1001;
input double Lote                = 0.01;
input int    Periodo             = 21;
input int    Profit              = 100;
input int    Proximidade         = 5;
input int    OrdensTotal         = 50;
input int    OrdensDistancia     = 1;

string versao = "Versão: 1.5";

datetime dtCalculado = 0;
bool     blOperBuy   = false;
bool     blOperSell  = false;
bool     primeiraOrd = true;

int OnInit()
{
   blOperBuy   = false;
   blOperSell  = false;
   primeiraOrd = true;
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   blOperBuy   = false;
   blOperSell  = false;
   primeiraOrd = true;
}

void OnTick()
{

   int    vTicket     = 0;
   int    i           = 0;
   double vStopProfit = 0;
   double vPonto      = (Point() * 10);
   
   double valorEsq = 0;
   double valorDir = 0;   
   
   double valorEnt = 0;
   
   string comentario = "";
   
   if(Volume[0]<5) return;
   
   if(dtCalculado!=Time[0])
   {
   
      CalcRegLinear(Periodo, 1, valorEsq, valorDir);
      
      if(MathIsValidNumber(valorEsq) && MathIsValidNumber(valorDir))
      {
         if(valorEsq>0 && valorDir>0) 
         {
            dtCalculado = Time[0];
            
            if(valorEsq<valorDir)
            {
               FecharOperacoes(OP_SELLSTOP);
               FecharOperacoes(OP_SELL);
               blOperSell = false; 
            }
            else if(valorEsq>valorDir)
            {
               FecharOperacoes(OP_BUYSTOP); 
               FecharOperacoes(OP_BUY); 
               blOperBuy = false;           
            }
         }   
      }
   }
   else if(!blOperBuy && !blOperSell)
   {
   
      CalcRegLinear(Periodo, 0, valorEsq, valorDir);
      
      if(valorEsq<valorDir && Close[0]<=(valorDir + (Proximidade * vPonto)))
      {
      
         if(primeiraOrd) 
         {
            blOperBuy   = true;
            primeiraOrd = false;
            return;
         }
      
         if(Profit > 0) vStopProfit = (Ask + (Profit * vPonto));
      
         valorEnt = Ask;
      
         for(i=1; i<=OrdensTotal; i++)
         {
         
            if(i==1)
            {
               vTicket = OrderSend(
                           _Symbol, 
                           OP_BUY, 
                           Lote, 
                           valorEnt, 
                           3, 0, vStopProfit, "", NumMagico, 0, Blue);
            }         
            else
            {
               vTicket = OrderSend(
                           _Symbol, 
                           OP_BUYSTOP, 
                           Lote, 
                           valorEnt, 
                           3, 0, vStopProfit, "", NumMagico, 0, Blue);         
            }
            valorEnt = valorEnt + (OrdensDistancia * vPonto);
         }
                     
         if(vTicket>0) blOperBuy = true;                     
         
      }
      else if(valorEsq>valorDir && Close[0]>=(valorDir - (Proximidade * vPonto)))
      {

         if(primeiraOrd) 
         {
            blOperSell  = true;
            primeiraOrd = false;
            return;
         }

         if(Profit > 0) vStopProfit = (Bid - (Profit * vPonto));

         valorEnt = Bid;
               
         for(i=1; i<=OrdensTotal; i++)
         {
         
            if(i==1)
            {               
               vTicket = OrderSend(
                           _Symbol, 
                           OP_SELL, 
                           Lote, 
                           valorEnt, 
                           3, 0, vStopProfit, "#1", NumMagico, 0, Blue);         
            }         
            else
            {
               vTicket = OrderSend(
                           _Symbol, 
                           OP_SELLSTOP, 
                           Lote, 
                           valorEnt, 
                           3, 0, vStopProfit, "", NumMagico, 0, Blue);         
            }
            valorEnt = valorEnt - (OrdensDistancia * vPonto);
         }                     
                     
         if(vTicket>0) blOperSell = true;                     
      }
      
   }

   comentario = "Versão: " + versao + "\n" +
           "Valor Esquerda: " + DoubleToString(valorEsq) + "\n" +   
           "Valor Direita: " + DoubleToString(valorDir);
           
   if(valorEsq<valorDir)
      comentario = comentario + "\nAproximidade: " + DoubleToString( valorDir + (Proximidade * vPonto) );
   else if(valorEsq>valorDir)  
      comentario = comentario + "\nAproximidade: " + DoubleToString( valorDir - (Proximidade * vPonto) );
      
   Comment(comentario);
            
}

void FecharOperacoes(int pTipo)
{
   for(int i=OrdersTotal()-1;i>=0;i--)    
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol()==_Symbol)
            if(pTipo==-1 || pTipo==OrderType())
               if(OrderMagicNumber()==NumMagico)
                  if(OrderType()!=OP_BUYSTOP && OrderType()!=OP_SELLSTOP)
                  {
                     if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, Yellow))
                        Print("Erro ao fechar ordem. Ticket: " + IntegerToString(OrderTicket()));
                  }
                  else
                  {
                     if(!OrderDelete(OrderTicket()))
                        Print("Erro ao deletar ordem. Ticket: " + IntegerToString(OrderTicket()));                     
                  }      
   }

}   

void CalcRegLinear(
                  int pPeriodo,
                  int pIndiceBarra,
                  double &pVlrEsq,
                  double &pVlrDir)
{

   double a     = 0,
          b     = 0,
          c     = 0,
          sumy  = 0,
          sumx  = 0,
          sumxy = 0,
          sumx2 = 0;
          
   int i = 0, 
       x = 0;

   pVlrEsq = 0;
   pVlrDir = 0;

   if(pPeriodo<=1)
   {
      Print("Periodo não pode ser menor que 2!");
      return;   
   }

   x = 0;
   while(x<pPeriodo)
   {
      i = (x + pIndiceBarra); 

      sumy+=Close[i];
      sumxy+=Close[i]*i;
      sumx+=i;
      sumx2+=i*i;
   
      x++;
   }

   c=sumx2*pPeriodo-sumx*sumx;
   
   if(c==0.0)
   {
      Print("Erro no calculo da regressão linear!");
      return;
   }

   b=(sumxy*pPeriodo-sumx*sumy)/c;
   a=(sumy-sumx*b)/pPeriodo;

   x = 0;
   while(x<pPeriodo)
   {
      i = (x + pIndiceBarra); 
      
      if(x==0)
         pVlrDir = a+b*i;
      else if(x==(pPeriodo-1))
         pVlrEsq = a+b*i;      
     
      x++;
   }

}

