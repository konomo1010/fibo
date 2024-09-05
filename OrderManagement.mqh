//+------------------------------------------------------------------+
//| 开多单操作                                                       |
//+------------------------------------------------------------------+
void OpenBuyOrder(double high, double low)
{
    static datetime lastOrderTime = 0;
    if (TimeCurrent() - lastOrderTime > 60)
    {
        lastOrderTime = TimeCurrent();
        double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double stopLossPrice = 0;
        double takeProfitPrice = 0;
        
        // 获取前一根K线的最高价和最低价
        double prevBarHigh = iHigh(_Symbol, Timeframe, 1);
        double prevBarLow = iLow(_Symbol, Timeframe, 1);
        printf("前一根K线的最高价: " + prevBarHigh + "，前一根K线的最低价: " + prevBarLow);
        // 设置初始止损
        if (StopLossMethod == SL_FIXED)
        {
            stopLossPrice = askPrice - FixedSLPoints * _Point;
        }
        else if (StopLossMethod == SL_DYNAMIC)
        {
            stopLossPrice = low - SL_Points_Buffer * _Point;
        }

        // 判断初始止损是否大于600个基点
        printf("判断初始止损是否大于600个基点 : " + MathAbs(askPrice - stopLossPrice) / _Point); 
        if (MathAbs(askPrice - stopLossPrice) / _Point > BigPreStopLoss)
        {
            // 如果大于600个基点，将止损设置为前一根K线的最低价减去SL_Points_Buffer个基点
            stopLossPrice = prevBarLow - SL_Points_Buffer * _Point;
            Print("初始止损大于600基点，调整止损位置到前一根K线的最低价减去缓冲: ", stopLossPrice);
        }

        // 设置止盈
        if (TakeProfitMethod == TP_FIXED)
        {
            takeProfitPrice = askPrice + FixedTPPoints * _Point;
        }

        // 下单
        if (trade.Buy(Lots, _Symbol, askPrice, stopLossPrice, TakeProfitMethod != TP_NONE ? takeProfitPrice : 0, "Buy Signal"))
        {
            aBarHigh = iHigh(_Symbol, Timeframe, 1);
            aBarLow = iLow(_Symbol, Timeframe, 1);
            aBarTime = iTime(_Symbol, Timeframe, 1);
            isOrderClosedThisBar = false;
            orderOpened = true;
            entryTime = TimeCurrent();

            trailingMaxHigh = aBarHigh;
            trailingMinLow = low;

            Print("做多订单已下单。");
            ResetSignalState();
        }
    }
}

//+------------------------------------------------------------------+
//| 开空单操作                                                       |
//+------------------------------------------------------------------+
void OpenSellOrder(double high, double low)
{
    static datetime lastOrderTime = 0;
    if (TimeCurrent() - lastOrderTime > 60)
    {
        lastOrderTime = TimeCurrent();
        double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double stopLossPrice = 0;
        double takeProfitPrice = 0;
        
        // 获取前一根K线的最高价和最低价
        double prevBarHigh = iHigh(_Symbol, Timeframe, 1);
        double prevBarLow = iLow(_Symbol, Timeframe, 1);
        printf("前一根K线的最高价: " + prevBarHigh + "，前一根K线的最低价: " + prevBarLow);
        // 设置初始止损
        if (StopLossMethod == SL_FIXED)
        {
            stopLossPrice = bidPrice + FixedSLPoints * _Point;
        }
        else if (StopLossMethod == SL_DYNAMIC)
        {
            stopLossPrice = high + SL_Points_Buffer * _Point;
        }

        // 判断初始止损是否大于600个基点
        printf("判断初始止损是否大于600个基点 : " + MathAbs(bidPrice - stopLossPrice) / _Point); 
        if (MathAbs(bidPrice - stopLossPrice) / _Point > BigPreStopLoss)
        {
            // 如果大于600个基点，将止损设置为前一根K线的最高价加上SL_Points_Buffer个基点
            stopLossPrice = prevBarHigh + SL_Points_Buffer * _Point;
            Print("初始止损大于600基点，调整止损位置到前一根K线的最高价加上缓冲: ", stopLossPrice);
        }

        // 设置止盈
        if (TakeProfitMethod == TP_FIXED)
        {
            takeProfitPrice = bidPrice - FixedTPPoints * _Point;
        }

        // 下单
        if (trade.Sell(Lots, _Symbol, bidPrice, stopLossPrice, TakeProfitMethod != TP_NONE ? takeProfitPrice : 0, "Sell Signal"))
        {
            aBarHigh = iHigh(_Symbol, Timeframe, 1);
            aBarLow = iLow(_Symbol, Timeframe, 1);
            aBarTime = iTime(_Symbol, Timeframe, 1);
            isOrderClosedThisBar = false;
            orderOpened = true;
            entryTime = TimeCurrent();

            trailingMaxHigh = high;
            trailingMinLow = aBarLow;

            Print("做空订单已下单。");
            ResetSignalState();
        }
    }
}
