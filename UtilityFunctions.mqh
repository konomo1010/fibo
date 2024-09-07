

//+------------------------------------------------------------------+
//| 检查当前时间是否在允许的交易时间范围内                           |
//+------------------------------------------------------------------+
bool IsWithinTradingHours(int startHour, int endHour)
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);

    int currentHour = timeStruct.hour;
    return (currentHour >= startHour && currentHour < endHour);
}

//+------------------------------------------------------------------+
//| 检查当前月份是否在允许的交易月份范围内                           |
//+------------------------------------------------------------------+
bool IsMonthAllowed(string allowedMonths)
{
    string months[];
    StringSplit(allowedMonths, ',', months);

    int currentMonth;
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    currentMonth = timeStruct.mon;

    for (int i = 0; i < ArraySize(months); i++)
    {
        if (StringToInteger(months[i]) == currentMonth)
            return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| 重置信号状态                                                     |
//+------------------------------------------------------------------+
void ResetSignalState()
{
    isSignalValid = false;
    longSignalConfirmed = false;
    shortSignalConfirmed = false;
    maxHigh = 0;
    minLow = 0;
    signalHigh = 0;
    signalLow = 0;
    entryTime = 0;
    stopLossHitThisBar = false;
    validBarCount = 0;
    Print("信号状态已重置，等待新信号...");
}


double GetDailyATRValue()
{
    // 创建日线ATR句柄，使用14周期的ATR指标，日线级别
    int dailyATRHandle = iATR(_Symbol, PERIOD_D1, 14);
    double atrValue[1];

    // 获取日线ATR的最新值
    if (CopyBuffer(dailyATRHandle, 0, 0, 1, atrValue) <= 0)
    {
        Print("无法获取日线ATR数据");
        return -1;  // 返回一个无效值
    }

    return atrValue[0];  // 返回ATR的最新值
}