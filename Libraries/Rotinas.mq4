//+------------------------------------------------------------------+
//|                                                      Rotinas.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                            rodrigosf@outlook.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2015, Rodrigo Silva"
#property link      "rodrigosf@outlook.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
// VARIAVEIS
//+------------------------------------------------------------------+
datetime Rotinas_DTHR_OpenBarOperacao = -1;
int      Rotinas_UltOrdemTipo  = -1;
double   Rotinas_UltOrdemLote  = -1;
//+------------------------------------------------------------------+
// FECHA TODAS AS OPERAÇÕES
//+------------------------------------------------------------------+
void FecharOperacoes(int pTipo, int pNumMagico)
{
   for(int i=OrdersTotal()-1;i>=0;i--)    
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol()==_Symbol)
            if(pTipo==-1 || pTipo==OrderType())
               if(pNumMagico==-1 || pNumMagico==OrderMagicNumber())
                  if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, Yellow))
                     Print("Erro ao fechar ordem. Ticket: " + IntegerToString(OrderTicket()));
   }
}   
//+------------------------------------------------------------------+
// GERAR LINHA HORIZONTAL
//+------------------------------------------------------------------+
void GerarLinhaHorizontal(double pValor, string pNome, color pCor, int pEspessura)
{
   if(ObjectFind(pNome)==-1)
   { 
      ObjectCreate(pNome, OBJ_HLINE, 0, 0, pValor);
      ObjectSet(pNome, OBJPROP_COLOR, pCor); 
      ObjectSet(pNome, OBJPROP_WIDTH, pEspessura);
      ObjectSet(pNome, OBJPROP_STYLE, STYLE_SOLID);      
      ObjectSet(pNome, OBJPROP_SELECTABLE, false);      
   }
}
//+------------------------------------------------------------------+
// GERAR LINHA VERTICAL
//+------------------------------------------------------------------+
void GerarLinhaVertical(datetime pTempo, string pNome, color pCor, int pEspessura)
{

   if(ObjectFind(pNome)==-1)
   { 
      ObjectCreate(pNome, OBJ_VLINE, 0, pTempo, 0);   
      ObjectSet(pNome, OBJPROP_COLOR, pCor); 
      ObjectSet(pNome, OBJPROP_WIDTH, pEspessura);
      ObjectSet(pNome, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(pNome, OBJPROP_SELECTABLE, false);      
   }
}
//+------------------------------------------------------------------+
// GERAR OBJETO
//+------------------------------------------------------------------+
void GerarObjeto(
                  double pValor, 
                  datetime pTempo, 
                  string pNome, 
                  color pCor, 
                  int pCodigo,
                  int pEspessura)
{

   // * 159 Bolinha

   if(ObjectFind(pNome)==-1)
   { 
      ObjectCreate(pNome, OBJ_ARROW, 0, pTempo, pValor);
      ObjectSet(pNome, OBJPROP_ARROWCODE, pCodigo); 
      ObjectSet(pNome, OBJPROP_COLOR, pCor); 
      ObjectSet(pNome, OBJPROP_WIDTH, pEspessura);
      ObjectSet(pNome, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(pNome, OBJPROP_SELECTABLE, false);
      ObjectSet(pNome, OBJPROP_SELECTABLE, false);
   }
   
}
//+------------------------------------------------------------------+
// GERAR LINHA NO GRAFICO
//+------------------------------------------------------------------+
double DesvioPadrao(int pPeriodo, const double &price[]) 
{

   int x = 0;
   double media = 0;
   double variancia = 0;   
   double desvio = 0;
   
   while(x<pPeriodo)
   {
      media += price[x];
      x++;
   }
   media = (media / pPeriodo);

   x = 0;
   while(x<pPeriodo)
   {
      variancia += MathPow((price[x] - media), 2);
      x++;
   }
   variancia = (variancia / pPeriodo);
   desvio = MathSqrt(variancia);
   
   return (desvio);

}
//+------------------------------------------------------------------+
// Adicionar PIPs
//+------------------------------------------------------------------+
double AddPIPs(double pValor, double pPIP)
{

   double ponto = (Point * RetornarMultiplicador());
   return (pValor + (pPIP * ponto)); 
   
}
//+------------------------------------------------------------------+
// Remover PIPs
//+------------------------------------------------------------------+
double RemPIPs(double pValor, double pPIP)
{

   double ponto = (Point * RetornarMultiplicador());
   return (pValor - (pPIP * ponto)); 
   
}
//+------------------------------------------------------------------+
// CRIAR CANAL DE DESVIO PADRAO
//+------------------------------------------------------------------+
void GerarCanalDesvioPadrao(
      string   pNome, 
      datetime pT1, 
      datetime pT2, 
      ENUM_TIMEFRAMES pPeriodo,
      int      pDesvio,
      bool     pGerarCanal,
      double   &pVlIni,
      double   &pVlFim,      
      double   &pVlDesvio)
{

   int    i = 0;
   double a=0,b=0,y=0,m=0,n=0,x=0,sumx=0,sumx2=0,sumxy=0,sumy=0,sumy_m2=0;
   double slope=0,intercept=0,dev=0,y1=0,y2=0;

   string canal_meio  = pNome;
   string canal_cima  = "high_" + pNome;
   string canal_baixo = "low_" + pNome;      

   datetime time1 = pT1;
   datetime time2 = pT2;

   int begin = iBarShift(_Symbol, pPeriodo, time1, true);
   int end   = iBarShift(_Symbol, pPeriodo, time2, true);

   //---- get vals for least squares regression
   for(i=begin; i>=end; i--)
   {
      y = iClose(_Symbol, pPeriodo, i);  //-- loop through closes
      x=i;                   	           //-- bars by chart index
      n++;                   	           //-- number of bars in channel
      sumx += x;             	           //-- sum of bars in channel
      sumy += y;             	           //-- sum of close prices
      sumxy += (x*y);        	           //-- sum of bars*close
      sumx2 += (x*x);        	           //-- sum of bars squared
      m = sumy/n;            	           //-- mean of close prices
   }

   //---- get val for deviation
   for(i=begin; i>=end; i--)
   {
      y = iClose(_Symbol, pPeriodo, i);  //-- loop through closes
      sumy_m2 += (y-m)*(y-m);	           //-- sum of closes-mean squared
   }
   
   //---- slope(b) intercept(a)
   b = (n*sumxy-sumx*sumy)/(n*sumx2-sumx*sumx);
   a = (sumy - (b*sumx))/n;
   
   //---- insert first and last testchannel bar numbers into equation
   y1 = a+b*begin;
   y2 = a+b*end;

   //---- calculate deviation
   dev = (MathSqrt(sumy_m2)/MathSqrt(n)) * pDesvio;

   if(pGerarCanal)
   {
      if(ObjectFind(0, canal_meio)==-1)
      {
         ObjectCreate(canal_meio, OBJ_TREND, 0, time1, y1, time2, y2);
         ObjectSet(canal_meio, OBJPROP_COLOR, clrGreen);
         ObjectSet(canal_meio, OBJPROP_RAY, false);
         ObjectSet(canal_meio, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet(canal_meio, OBJPROP_SELECTABLE, false);
         ObjectSetText(canal_meio, "Criado por Droid4FX", 10);
         
         ObjectCreate(canal_cima, OBJ_TREND, 0, time1, y1+dev, time2, y2+dev);
         ObjectSet(canal_cima, OBJPROP_COLOR, clrRed);
         ObjectSet(canal_cima, OBJPROP_RAY, false);
         ObjectSet(canal_cima, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet(canal_cima, OBJPROP_SELECTABLE, false);
         ObjectSetText(canal_cima, "Criado por Droid4FX", 10);
   
         ObjectCreate(canal_baixo, OBJ_TREND, 0, time1, y1-dev, time2, y2-dev);
         ObjectSet(canal_baixo, OBJPROP_COLOR, clrRed);
         ObjectSet(canal_baixo, OBJPROP_RAY, false);
         ObjectSet(canal_baixo, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet(canal_baixo, OBJPROP_SELECTABLE, false);
         ObjectSetText(canal_baixo, "Criado por Droid4FX", 10);
      }   
      else
      {
         ObjectMove(canal_meio, 0, time1, y1);
         ObjectMove(canal_meio, 1, time2, y2);
         
         ObjectMove(canal_cima, 0, time1, y1+dev);
         ObjectMove(canal_cima, 1, time2, y2+dev);
         
         ObjectMove(canal_baixo, 0, time1, y1-dev);
         ObjectMove(canal_baixo, 1, time2, y2-dev);            
      }
      WindowRedraw();
   }
   
   pVlIni    = y1;
   pVlFim    = y2;
   pVlDesvio = dev;
      
}
//+------------------------------------------------------------------+
// Enviar Ordem
//+------------------------------------------------------------------+
int EnviarOrdem(
   int    pTipo, 
   double pLote,
   double pPreco,
   double pStopLoss,
   double pStopProfit,
   bool   pSLPIPs,
   int    pNumMagico,
   string pComentario,
   int    pMartingale,
   bool   pAntiMartingale,
   int    pCicloAntiMartingale)
{

   int ticket = 0;

   double vStopLoss   = 0;
   double vStopProfit = 0;
   double vStopLevel  = 0;
   double vLote       = 0;
   double vLoteMax    = 0;

   double vLoteAnt       = 0;
   int    vTpOrdAnt      = 0;
   double vLucroAnt      = 0;  
   double vProfitAnt     = 0;
   double vStopLossAnt   = 0;
   double vOpenPriceAnt  = 0;
   string vComentarioAnt = "";
   
   if(pSLPIPs)
   {
      if(pTipo==OP_BUY)
      {
         if(pStopLoss>0)   vStopLoss   = RemPIPs(pPreco, pStopLoss);
         if(pStopProfit>0) vStopProfit = AddPIPs(pPreco, pStopProfit);
      }
      else if(pTipo==OP_SELL)
      {
         if(pStopLoss>0)   vStopLoss   = AddPIPs(pPreco, pStopLoss);
         if(pStopProfit>0) vStopProfit = RemPIPs(pPreco, pStopProfit);      
      }
   }
   else
   {
      vStopLoss   = pStopLoss; 
      vStopProfit = pStopProfit;
   }
   
   vStopLevel = StopLevelValor();
  
   if(pTipo==OP_BUY)
   {
      if(vStopLoss>0 && vStopLoss > (Ask - vStopLevel))     vStopLoss   = (Ask - vStopLevel);  
      if(vStopProfit>0 && vStopProfit < (Ask + vStopLevel)) vStopProfit = (Ask + vStopLevel);
   }
   else if(pTipo==OP_SELL)
   {
      if(vStopLoss>0 && vStopLoss < (Bid + vStopLevel))     vStopLoss   = (Bid + vStopLevel);
      if(vStopProfit>0 && vStopProfit > (Bid - vStopLevel)) vStopProfit = (Bid - vStopLevel);   
   }
   
   vLote = pLote;
   if(pMartingale>0 || pAntiMartingale)
   {
      UltimaOrdemFechada(pNumMagico, vTpOrdAnt, vLoteAnt, 
               vOpenPriceAnt, vStopLossAnt, vProfitAnt, vLucroAnt, vComentarioAnt);
   
      if(pMartingale>0 && vLucroAnt<0)
      {
         pComentario = "@";      
         if(!(pMartingale==1 && StringFind(vComentarioAnt, "@")==-1))
         {
            if(StringFind(vComentarioAnt, "#")>-1)
               vLote = (pLote * 2);
            else
               vLote = (vLoteAnt * 2);
         }
      }
      else if(pAntiMartingale && vLucroAnt>0 && StringFind(vComentarioAnt, "@")==-1)
      {
         pComentario = "#";
         vLote = (vLoteAnt * 2);         
      }
   }
   
   ticket = OrderSend(
               _Symbol, 
               pTipo, 
               vLote, 
               pPreco, 
               3, vStopLoss, vStopProfit, pComentario, pNumMagico, 0, Blue);

   if(ticket>0)
   {
      Rotinas_DTHR_OpenBarOperacao = Time[0];
      Rotinas_UltOrdemTipo         = pTipo;
      Rotinas_UltOrdemLote         = pLote;
   }

   return (ticket);

}   
//+------------------------------------------------------------------+
// COMANDOS IMPORTANTES
//+------------------------------------------------------------------+
void RepositorioTestes()
{

   //Excluir um objeto
   ObjectDelete("droid4fx_canal");

   //Excluir todos os objetos
   ObjectsDeleteAll(0, 0);

   //Captura valor do objeto
   double x = ObjectGetValueByShift("droid4fx_canal", 1);

   // Captura valor das bandas de bollinger
   double bandaUp0   = iBands(NULL, 0, 21, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bandaDown0 = iBands(NULL, 0, 21, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);  
   
   double media = iMA(_Symbol, 0, 200, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   //double haOpen = iCustom(NULL,0,"Heiken_Ashi_Smoothed",2,6,3,2,2,1);
   
   double HAHigh   = iCustom(_Symbol, 0, "Heiken Ashi", 0, 1);
   double HALow    = iCustom(_Symbol, 0, "Heiken Ashi", 1, 1);
   double HAOpen   = iCustom(_Symbol, 0, "Heiken Ashi", 2, 1);
   double HAClose  = iCustom(_Symbol, 0, "Heiken Ashi", 3, 1);
   
   //OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, Red);

   double upBand = iEnvelopes(_Symbol, 0, 55, MODE_EMA, 0, PRICE_CLOSE, 1, MODE_UPPER, 1);
   double dwBand = iEnvelopes(_Symbol, 0, 55, MODE_EMA, 0, PRICE_CLOSE, 1, MODE_LOWER, 1);   
   
   //ObjectCreate(nome, OBJ_ARROW, 0, Time[0], preco);
   //ObjectSet(nome, OBJPROP_ARROWCODE, 222);
   //ObjectSet(nome, OBJPROP_COLOR, cor);      


}
//+------------------------------------------------------------------+
// VERIFICA ORDEM ABERTA
//+------------------------------------------------------------------+
bool ExisteOrdemAberta(int pTipo, int pNumMagico)
{

   bool encontrado = false;

   for(int i=OrdersTotal()-1;i>=0;i--)    
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol()==_Symbol)
            if(pTipo==-1 || pTipo==OrderType())
               if(pNumMagico==-1 || pNumMagico==OrderMagicNumber())
               {
                  encontrado = true;
                  break;
               }
   }

   return (encontrado);

}
//+------------------------------------------------------------------+
// DADOS DA ULTIMA ORDEM FECHADA
//+------------------------------------------------------------------+
void UltimaOrdemFechada(
                        int    pNumMagico,
                        int    &pTipoOrd,
                        double &pLote,
                        double &pPrecoAbertura,
                        double &pStopLoss,
                        double &pStopProfit,
                        double &pLucro,
                        string &pComentario)
{

   for(int i=OrdersHistoryTotal()-1;i>=0;i--)    
   {
      if(OrderSelect(i, SELECT_BY_POS , MODE_HISTORY))
         if(OrderSymbol()==_Symbol && pNumMagico==OrderMagicNumber())
         {
            pTipoOrd = OrderType();
            pLote = OrderLots();            
            pPrecoAbertura = OrderOpenPrice();
            pStopLoss = OrderStopLoss();
            pStopProfit = OrderTakeProfit();
            pLucro = OrderProfit();
            pComentario = OrderComment();
         
            break;
         }
   }

}
//+------------------------------------------------------------------+
// STOP LEVEL EM PONTOS
//+------------------------------------------------------------------+
double StopLevelPontos()
{
   return NormalizeDouble(MarketInfo(_Symbol, MODE_STOPLEVEL), 2);
}
//+------------------------------------------------------------------+
// STOP LEVEL EM VALOR
//+------------------------------------------------------------------+
double StopLevelValor()
{
   double ponto = (Point * RetornarMultiplicador());
   return NormalizeDouble(MarketInfo(_Symbol, MODE_STOPLEVEL) * ponto, 5);
}
//+------------------------------------------------------------------+
// SETAR ORDEM NO ZERO A ZERO
//+------------------------------------------------------------------+
void BreakEven(double pDistancia, int pNumMagico)
{

   bool atualiza = false;

   for(int i=OrdersTotal()-1;i>=0;i--)    
   {
      atualiza = false;
      
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol()==_Symbol && pNumMagico==OrderMagicNumber())
         {
            if(OrderType()==OP_BUY)
            {
               atualiza = ((Ask>=AddPIPs(OrderOpenPrice(), pDistancia)) &&
                           (OrderStopLoss()==0 || OrderStopLoss()<=OrderOpenPrice()));
            }
            else if(OrderType()==OP_SELL)
            {
               atualiza = ((Bid<=RemPIPs(OrderOpenPrice(), pDistancia)) &&
                           (OrderStopLoss()==0 || OrderStopLoss()>=OrderOpenPrice()));
            }
         }
         
      if(atualiza)
         if(!OrderModify(OrderTicket(), OrderOpenPrice(), 
             OrderOpenPrice(), OrderTakeProfit(), 0, clrYellow))
             Print("Erro ao setar BreakEven.");      
   }

}
//+------------------------------------------------------------------+
// GERAR RESULTADO DA REGRASSAO POLINOMIAL
//+------------------------------------------------------------------+
void RegressaoPolinomial(
                         int ordem, 
                         int periodo,
                         const double &price[], 
                         double &valorFinal, 
                         double &valorFuturo)
{

   double matrizX[];
   double matrizY[]; 
   int x = 0;
   
   ArrayResize(matrizX, periodo);
   ArrayResize(matrizY, periodo);
     
   ArrayInitialize(matrizX, 0);
   ArrayInitialize(matrizY, 0);      

   while(x<periodo)
   {
      matrizX[x] = x + 1;   
      matrizY[x] = price[x];
      x++;
   }
  
   FindPolynomialLeastSquaresFit(matrizX, matrizY, ordem, periodo, periodo, valorFinal, valorFuturo);
   
}
//+------------------------------------------------------------------+
// CALCULO DA POLINOMIAL 
//+------------------------------------------------------------------+
void FindPolynomialLeastSquaresFit(
                                   const double& arX[], 
                                   const double& arY[], 
                                   const int ordem,
                                   const int periodo,                                   
                                   const int posicao,
                                   double& resultado,
                                   double& resultadoFuturo)
{

   double coeffs[10][10];
   double answer[];
   double total = 0;
   double total_fut = 0;   
   double x_factor = 0;   
   double x_factor_fut = 0;      

   int pt = 0;

   ArrayInitialize(coeffs, 0);
   
   for(int j=0;j<=ordem;j++)
   {
      coeffs[j][ordem + 1] = 0;
   
      for(pt=0;pt<periodo;pt++)
      {
         coeffs[j][ordem + 1] = coeffs[j][ordem + 1] - MathPow(arX[pt], j) * arY[pt];
      }
      
      for(int a_sub=0;a_sub<=ordem;a_sub++)
      {
         coeffs[j][a_sub] = 0;      
         for(pt=0;pt<periodo;pt++)
         {
            coeffs[j][a_sub] = coeffs[j][a_sub] - MathPow(arX[pt], a_sub + j); 
         }
      }      
   }
   
   GaussianElimination(coeffs, answer, ordem, ordem + 1); 

   x_factor = 1;
   x_factor_fut = 1;
   for(int i=0;i<ArraySize(answer);i++)
   {
      total = total + x_factor * answer[i];
      x_factor = x_factor * 1;
      
      total_fut = total_fut + x_factor_fut * answer[i]; 
      x_factor_fut = x_factor_fut * 0;
   } 

   total = NormalizeDouble(total, 5);
   total_fut = NormalizeDouble(total_fut, 5);
   
   resultado = total;
   resultadoFuturo = total_fut;
   
}                                    
//+------------------------------------------------------------------+
// ELIMINAÇÃO DE GAUSS
//+------------------------------------------------------------------+
void GaussianElimination(
                         double& coeffs[10][10], 
                         double& answer[],
                         int max_equation, 
                         int max_coeff)
{

   int i = 0;
   int j = 0;
   int k = 0;
   int d = 0;   
   double temp = 0;
   double coeff_i_i = 0;
   double coef_j_i = 0;
   
   for(i=0;i<=max_equation;i++)
   {
      if(coeffs[i][i]==0)
      {
         for(j=0;j<=max_equation;j++)
         {
            if(coeffs[j][i]!=0)
            {
               for(k=i;k<=max_coeff;k++)
               {
                  temp = coeffs[i][k];
                  coeffs[i][k] = coeffs[j][k];
                  coeffs[j][k] = temp;
               }               
               break;
            }
         }
      }
      
      coeff_i_i = coeffs[i][i];
      if(coeff_i_i==0) return;
      
      for(j=i;j<=max_coeff;j++)
      {
         coeffs[i][j] = coeffs[i][j] / coeff_i_i;
      }
      
      for(j=0;j<=max_equation;j++)
      {
         if(j!=i)
         {
            coef_j_i = coeffs[j][i];
            for(d=0;d<=max_coeff;d++)
            {
               coeffs[j][d] = coeffs[j][d] - coeffs[i][d] * coef_j_i;
            }         
         }
      }
   
   }
   
   ArrayResize(answer, max_equation + 1);
   ArrayInitialize(answer, 0);
      
   for(i=0;i<=max_equation;i++)
   {
      answer[i] = coeffs[i][max_coeff];
   }

}
//+------------------------------------------------------------------+
// SPREAD STUAL
//+------------------------------------------------------------------+
double SpreadAtual() 
{
   
   int multiplicador = RetornarMultiplicador();

   return (MarketInfo(_Symbol, MODE_SPREAD) / multiplicador); 
  
}
//+------------------------------------------------------------------+
// MULTIPLICADOR PARA CALCULOS DE PIPS
//+------------------------------------------------------------------+
int RetornarMultiplicador()
{

   switch (int(MarketInfo(_Symbol, MODE_DIGITS))) 
   {
      case 3  : return (10); break;
      case 5  : return (10); break;         
      default : return (1); break;
   }
   
}
//+------------------------------------------------------------------+
// TEMPO RESTANTE DO CANDLE
//+------------------------------------------------------------------+
string TempoRestanteCandle(int pPeriodo) 
{

	int min, sec;

   min = iTime(_Symbol, pPeriodo, 0) + pPeriodo*60 - TimeCurrent();
   sec = min%60;
   min =(min - min%60) / 60;

   return (IntegerToString(min) + ":" + IntegerToString(sec));   
}

double LoteExponencial(double pMultiplicador)
{

   return NormalizeDouble((pMultiplicador * AccountBalance()) / 1000, 2);
    
}

void PivotPoint(
                int     pPeriodo,
                double& pPivotPoint, 
                double& pS1,
                double& pR1)
{

   double close = iClose(_Symbol, pPeriodo, 1);
   double high  = iHigh(_Symbol, pPeriodo, 1);
   double low   = iLow(_Symbol, pPeriodo, 1);
   
   pPivotPoint = NormalizeDouble((close + high + low) / 3, _Digits);
   pS1         = NormalizeDouble((2 * pPivotPoint) - high, _Digits);
   pR1         = NormalizeDouble((2 * pPivotPoint) - low, _Digits);
   
}