//+------------------------------------------------------------------+
//| 管理动态止损和固定止盈                                           |
//+------------------------------------------------------------------+
void ManageTrailingStopAndTakeProfit()
{
    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            double previousClose = iClose(_Symbol, Timeframe, 1);
            double maxHighLocal = aBarHigh;
            double minLowLocal = aBarLow;

            // 查找从aBar到上一根K线之间的最大高点和最小低点
            for (int j = iBarShift(_Symbol, Timeframe, aBarTime); j > 1; j--)
            {
                double high = iHigh(_Symbol, Timeframe, j);
                double low = iLow(_Symbol, Timeframe, j);

                if (high > maxHighLocal)
                    maxHighLocal = high;
                if (low < minLowLocal)
                    minLowLocal = low;
            }

            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP); // 获取当前止盈位置
            double newStopLoss, newTakeProfit;

            // 如果是多头持仓
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                // 做多动态止损逻辑
                if (previousClose > maxHighLocal)
                {
                    newStopLoss = minLowLocal - DynamicSL_Buffer * _Point;
                    newTakeProfit = currentTP;
                    // 保持固定止盈设置不变
                    if (TakeProfitMethod == TP_FIXED)
                    {
                        newTakeProfit = currentTP;
                    }
                    
                    // 动态止盈逻辑：根据止损调整相应调整止盈
                    if (TakeProfitMethod == TP_DYNAMIC || TakeProfitMethod == TP_ATR)
                    {
                        newTakeProfit = currentTP + (newStopLoss - currentSL);    // 根据止损调整幅度来调整止盈
                    }

                    trade.PositionModify(ticket, newStopLoss, newTakeProfit); // 更新止损
                    // 更新aBar
                    aBarHigh = iHigh(_Symbol, Timeframe, 1);
                    aBarLow = iLow(_Symbol, Timeframe, 1);
                    aBarTime = iTime(_Symbol, Timeframe, 1);
                }
            }
            
            // printf("currentSL: %f, newStopLoss: %f, currentTP: %f, newTakeProfit: %f", currentSL, newStopLoss, currentTP, newTakeProfit);
            // 如果是空头持仓
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                // 做空动态止损逻辑
                // printf("previousClose: %f, minLowLocal: %f", previousClose, minLowLocal);
                if (previousClose < minLowLocal)
                {
                    newStopLoss = maxHighLocal + DynamicSL_Buffer * _Point;
                    newTakeProfit = currentTP;
                    // 保持固定止盈设置不变
                    if (TakeProfitMethod == TP_FIXED)
                    {
                        newTakeProfit = currentTP;
                    }

                    // 动态止盈逻辑：根据止损调整相应调整止盈
                    if (TakeProfitMethod == TP_DYNAMIC || TakeProfitMethod == TP_ATR)
                    {
                        newTakeProfit = currentTP - (currentSL - newStopLoss);    // 根据止损调整幅度来调整止盈
                        // trade.PositionModify(ticket, newStopLoss, newTakeProfit); // 更新止盈
                    }

                    trade.PositionModify(ticket, newStopLoss, newTakeProfit); // 更新止损
                    // 更新aBar
                    aBarHigh = iHigh(_Symbol, Timeframe, 1);
                    aBarLow = iLow(_Symbol, Timeframe, 1);
                    aBarTime = iTime(_Symbol, Timeframe, 1);
                }
            }
        }
    }
}
