//+------------------------------------------------------------------+
//| 管理动态止损和固定止盈                                           |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                                   SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                   SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double floatingProfitPoints = MathAbs(currentPrice - openPrice) / _Point;
            double newStopLoss;

            // 如果浮动利润超过阈值但还没有触发第一次移动止损
            if (floatingProfitPoints >= FloatingProfitThresholdPoints && !firstTrailingStopTriggered)
            {
                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                {
                    newStopLoss = openPrice + BreakEvenStopLossPoints * _Point;
                }
                else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                {
                    newStopLoss = openPrice - BreakEvenStopLossPoints * _Point;
                }

                trade.PositionModify(ticket, newStopLoss, 0); // 设置盈亏平衡止损
                Print("浮动利润达到 ", FloatingProfitThresholdPoints, " 基点，设置盈亏平衡止损到 ", newStopLoss);
                firstTrailingStopTriggered = true; // 标记为已触发第一次移动止损
                continue; // 跳过到下一个仓位
            }

            // 执行原来的动态止损逻辑
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

            // 如果是多头持仓
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                // 做多动态止损逻辑
                if (previousClose > maxHighLocal)
                {
                    newStopLoss = minLowLocal - DynamicSL_Buffer * _Point;
                    trade.PositionModify(ticket, newStopLoss, 0); // 更新止损

                    // 更新aBar
                    aBarHigh = iHigh(_Symbol, Timeframe, 1);
                    aBarLow = iLow(_Symbol, Timeframe, 1);
                    aBarTime = iTime(_Symbol, Timeframe, 1);
                    firstTrailingStopTriggered = true; // 确保标记在第一次触发移动止损时被设置
                }
            }
            // 如果是空头持仓
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                // 做空动态止损逻辑
                if (previousClose < minLowLocal)
                {
                    newStopLoss = maxHighLocal + DynamicSL_Buffer * _Point;
                    trade.PositionModify(ticket, newStopLoss, 0); // 更新止损

                    // 更新aBar
                    aBarHigh = iHigh(_Symbol, Timeframe, 1);
                    aBarLow = iLow(_Symbol, Timeframe, 1);
                    aBarTime = iTime(_Symbol, Timeframe, 1);
                    firstTrailingStopTriggered = true; // 确保标记在第一次触发移动止损时被设置
                }
            }
        }
    }
}
