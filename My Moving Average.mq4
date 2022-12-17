// My Moving Average.mq4
// By Joshua Lee

input double Lots = 0.1;
input double MaximumRisk = 0.02;
input double DecreaseFactor = 3;
input int MovingPeriod = 12;
input int MovingShift = 0;

// Calculate open positions
int CalculateCurrentOrders(string symbol)
  {
   int buys = 0;
   int sells = 0;

   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol() == Symbol())
        {
         if(OrderType()== OP_BUY)  buys++;
         if(OrderType()== OP_SELL) sells++;
        }
     }
     
// Order Volume
   if(buys>0) 
   {
      return(buys);
   }
   else
   {
      return(-sells);
   }
  }

// Calculate  lot size
double LotsOptimized()
  {
   double lot = Lots;
   int    orders = HistoryTotal();
   int    losses = 0;  

   lot = NormalizeDouble(AccountFreeMargin() * MaximumRisk / 1000.0, 1);
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
// return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }

// Check for open order conditions

void CheckForOpen()
  {
   double ma;
   double OLDma;
   double slowma;
   double slowOLDma;
   int res;

   if(Volume[0]>1) return;
   
   ma=iMA(NULL,0,6,0,MODE_SMA,PRICE_MEDIAN,0);
   OLDma=iMA(NULL,0,6,0,MODE_SMA,PRICE_MEDIAN,1);
   slowma=iMA(NULL,0,10,0,MODE_SMA,PRICE_MEDIAN,0);
   slowOLDma=iMA(NULL,10,6,0,MODE_SMA,PRICE_MEDIAN,1);

// buy / sell conditions

   // If current moving average is larger than the slower moving average AND the previous moving average is greater than the previous slow moving average, BUY
   if(ma>slowma && OLDma>slowOLDma)
     {
      res=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
   // If current moving average is less than the slower moving average AND the previous moving average is greater than the previous slow moving average, SELL
   if(ma<slowma && OLDma>slowOLDma)
   {
      res=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"",MAGICMA,0,Red);
      return;
   }
  }

// Close order conditions                                 |

void CheckForClose()
  {
   double ma;
   double OLDma;
   double slowma;
   double slowOLDma;

   if(Volume[0]>1) return;

   ma=iMA(NULL,0,3,0,MODE_SMA,PRICE_MEDIAN,0);
   OLDma=iMA(NULL,0,3,0,MODE_SMA,PRICE_MEDIAN,1);
   slowma=iMA(NULL,0,6,0,MODE_SMA,PRICE_MEDIAN,0);
   slowOLDma=iMA(NULL,0,6,0,MODE_SMA,PRICE_MEDIAN,1);

   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;

      if(OrderType()==OP_BUY)
        {
         if(ma<slowma  && Close[1]<Close[2]<Close[3]<Close[4])
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(ma<slowOLDma && Close[1]>Close[2]>Close[3]>Close[4])
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
  }

// OnTick function                                                  |
void OnTick()
  {
// check history
   if(Bars<100 || IsTradeAllowed()==false)
      return;
// calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
  }
