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
        double atrValue[1];

        // 复制ATR值
        if (CopyBuffer(atrHandle, 0, 0, 1, atrValue) <= 0)
        {
            Print("无法获取ATR数据");
            return;
        }

        // 设置止损
        if (StopLossMethod == SL_FIXED) // 看多 固定止损
        {
            stopLossPrice = askPrice - FixedSLPoints * _Point;
        }
        else if (StopLossMethod == SL_DYNAMIC) // 看多 动态止损
        {
            stopLossPrice = low - SL_Points_Buffer * _Point;
        }
        else if (StopLossMethod == SL_ATR) // 看多 ATR止损
        {
            stopLossPrice = askPrice - atrValue[0] * ATR_StopLoss_Multiplier;
        }

        // 设置固定止盈
        if (TakeProfitMethod == TP_FIXED) // 看多 固定止盈
        {
            takeProfitPrice = askPrice + FixedTPPoints * _Point;
        }
        else if (TakeProfitMethod == TP_DYNAMIC) // 看多 动态止盈
        {
            takeProfitPrice = askPrice + InitialTPPoints * _Point; // 计算初始止盈价格
        }
        else if (TakeProfitMethod == TP_ATR) // 看多 ATR止盈
        {
            takeProfitPrice = askPrice + atrValue[0] * ATR_TakeProfit_Multiplier;
        }

        if (trade.Buy(Lots, _Symbol, askPrice, StopLossMethod != SL_NONE ? stopLossPrice : 0, TakeProfitMethod != TP_NONE ? takeProfitPrice : 0, "Buy Signal"))
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
        double atrValue[1];

        // 复制ATR值
        if (CopyBuffer(atrHandle, 0, 0, 1, atrValue) <= 0)
        {
            Print("无法获取ATR数据");
            return;
        }

        // 设置止损
        if (StopLossMethod == SL_FIXED) // 看空 固定止损
        {
            stopLossPrice = bidPrice + FixedSLPoints * _Point;
        }
        else if (StopLossMethod == SL_DYNAMIC) // 看空 动态止损
        {
            stopLossPrice = high + SL_Points_Buffer * _Point;
        }
        else if (StopLossMethod == SL_ATR) // 看空 ATR止损
        {
            stopLossPrice = bidPrice + atrValue[0] * ATR_StopLoss_Multiplier;
        }

        // 设置止盈
        if (TakeProfitMethod == TP_FIXED) // 看空 固定止盈
        {
            takeProfitPrice = bidPrice - FixedTPPoints * _Point;
        }
        else if (TakeProfitMethod == TP_DYNAMIC) // 看空 动态止盈
        {
            takeProfitPrice =  bidPrice - InitialTPPoints * _Point; // 计算初始止盈价格
        }
        else if (TakeProfitMethod == TP_ATR) // 看空 ATR止盈
        {
            takeProfitPrice = bidPrice - atrValue[0] * ATR_TakeProfit_Multiplier;
        }

        if (trade.Sell(Lots, _Symbol, bidPrice, StopLossMethod != SL_NONE ? stopLossPrice : 0, TakeProfitMethod != TP_NONE ? takeProfitPrice : 0, "Sell Signal"))
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
