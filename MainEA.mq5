/*
  v1.1.0 :  v1.0.0 merge v1.0.10.3
*/

#include <Trade\Trade.mqh>
#include "SignalCheck.mqh"
#include "OrderManagement.mqh"
#include "ManageTrailingStopAndTakeProfit.mqh"
#include "UtilityFunctions.mqh"

// 定义止盈方式的枚举
enum ENUM_TAKE_PROFIT_METHOD
{
    TP_NONE,    // 不设止盈
    TP_FIXED,   // 固定止盈
    TP_DYNAMIC, // 动态止盈
    TP_ATR      // ATR止盈
};

// 定义止损方式的枚举
enum ENUM_STOP_LOSS_METHOD
{
    SL_NONE,    // 不设止损
    SL_FIXED,   // 固定止损
    SL_DYNAMIC, // 动态止损
    SL_ATR,     // ATR止损
};

// 定义交易方向的枚举
enum ENUM_TRADE_DIRECTION
{
    TRADE_BUY_ONLY,  // 只做多
    TRADE_SELL_ONLY, // 只做空
    TRADE_BOTH       // 多空都做
};

// 输入参数

input ENUM_TRADE_DIRECTION TradeDirection = TRADE_BOTH;    // 默认多空都做
input string AllowedMonths = "1,2,3,4,5,6,7,8,9,10,11,12"; // 允许交易的月份（用逗号分隔）
input int TradeStartHour = 0;                              // 允许交易的开始时间（小时）
input int TradeEndHour = 24;                               // 允许交易的结束时间（小时）
input ENUM_TIMEFRAMES Timeframe = PERIOD_M5;               // 交易时间周期，默认5分钟
input double Lots = 0.05;                                  // 初始下单手数

input ENUM_MA_METHOD MA_Method = MODE_EMA;            // 移动平均线方法
input ENUM_APPLIED_PRICE Applied_Price = PRICE_CLOSE; // 移动平均线应用价格

input int MinBodyPoints = 50;  // 信号K线最小实体大小（基点）
input int MaxBodyPoints = 300; // 信号K线最大实体大小（基点）

input int StartDelay = 10;               // 当前K线结束前等待时间（秒）
input int MinSignalBars = 1;             // 信号K线后至少要有多少根符合要求的K线
input int MaxCandleBodySizePoints = 300; // 信号K线后最大允许的K线实体大小（基点）

input ENUM_STOP_LOSS_METHOD StopLossMethod = SL_ATR; // 默认使用动态止损方式
input double ATR_StopLoss_Multiplier = 5.0;          // ATR止损倍数(ATR止损生效)
input int MAX_SL = 1000;                             // 最大止损额度(基点)
input int SL_Points_Buffer = 150;                    // 动态止损初始缓存基点
input int DynamicSL_Buffer = 20;                    // 动态止损移动缓存基点
input int FixedSLPoints = 200;                       // 固定止损点数（基点）

input ENUM_TAKE_PROFIT_METHOD TakeProfitMethod = TP_ATR; // 默认使用不设止盈方式
input double ATR_TakeProfit_Multiplier = 15.0;           // ATR止盈倍数(ATR止盈生效)
input int FixedTPPoints = 200;                           // 固定止盈点数（基点）
input int InitialTPPoints = 2000;                        // 初始止盈点数（适用于动态止盈方式）

CTrade trade;

// 全局变量声明和初始化
int MA1_Period = 144; // 移动平均线1周期，默认值为144
int MA2_Period = 169; // 移动平均线2周期，默认值为169
int MA3_Period = 576; // 移动平均线3周期，默认值为576
int MA4_Period = 676; // 移动平均线4周期，默认值为676

datetime lastCloseTime = 0;
bool isOrderClosedThisBar = false; // 标记当前K线内是否已有订单被关闭
double aBarHigh, aBarLow;
datetime aBarTime;
bool orderOpened = false;
int signalBarIndex = -1;
bool stopLossHitThisBar = false;
int maHandle1, maHandle2, maHandle3, maHandle4;
double maxHigh, minLow;
double signalHigh, signalLow;
bool isSignalValid = false;
bool longSignalConfirmed = false;
bool shortSignalConfirmed = false;
datetime entryTime = 0;
double trailingMaxHigh, trailingMinLow;
int validBarCount = 0; // 记录符合要求的已完成K线数量

// 用于记录当前K线的时间
datetime currentBarTime = 0;

// 新增均线、ATR和RSI指标的句柄
int atrHandle, rsiHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    maHandle1 = iMA(_Symbol, Timeframe, MA1_Period, 0, MA_Method, Applied_Price); // MA1 句柄
    maHandle2 = iMA(_Symbol, Timeframe, MA2_Period, 0, MA_Method, Applied_Price); // MA2 句柄
    maHandle3 = iMA(_Symbol, Timeframe, MA3_Period, 0, MA_Method, Applied_Price); // MA3 句柄（之前的EMA576）
    maHandle4 = iMA(_Symbol, Timeframe, MA4_Period, 0, MA_Method, Applied_Price); // MA4 句柄（之前的EMA676）

    // 创建ATR14指标句柄
    atrHandle = iATR(_Symbol, Timeframe, 14);

    // 创建RSI21指标句柄
    rsiHandle = iRSI(_Symbol, Timeframe, 21, PRICE_CLOSE);

    if (maHandle1 == INVALID_HANDLE || maHandle2 == INVALID_HANDLE || maHandle3 == INVALID_HANDLE || maHandle4 == INVALID_HANDLE ||
        atrHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE)
    {
        Print("无法创建指标句柄");
        return (INIT_FAILED);
    }

    // 初始化当前K线的时间
    currentBarTime = iTime(_Symbol, Timeframe, 0);

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    IndicatorRelease(maHandle1);
    IndicatorRelease(maHandle2);
    IndicatorRelease(maHandle3);
    IndicatorRelease(maHandle4);
    IndicatorRelease(atrHandle);
    IndicatorRelease(rsiHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 显示均线、ATR和RSI指标
    DisplayIndicators();

    // 获取当前K线的时间
    datetime newBarTime = iTime(_Symbol, Timeframe, 0);

    // 判断是否是新K线开始
    if (newBarTime != currentBarTime)
    {
        if (PositionsTotal() > 0)
        {
            // printf("移动止损止盈。。。。");
            ManageTrailingStopAndTakeProfit();
        }
        else
        {
            if (((!IsWithinTradingHours(TradeStartHour, TradeEndHour)) || (!IsMonthAllowed(AllowedMonths))) && PositionsTotal() == 0)
                return;
            currentBarTime = newBarTime;  // 更新当前K线的时间
            isOrderClosedThisBar = false; // 重置标记，表示新K线开始
            stopLossHitThisBar = false;   // 重置止损状态

            // 只有在新K线开始时，才更新信号有效性和检查进场信号
            UpdateSignalValidity();
            CheckEntrySignals();
        }
    }
}

//+------------------------------------------------------------------+
//| 显示指标函数                                                     |
//+------------------------------------------------------------------+
void DisplayIndicators()
{
    double ma1Value[1], ma2Value[1], ma3Value[1], ma4Value[1], atrValue[1], rsiValue[1];

    // 复制指标值
    if (CopyBuffer(maHandle1, 0, 0, 1, ma1Value) < 0 ||
        CopyBuffer(maHandle2, 0, 0, 1, ma2Value) < 0 ||
        CopyBuffer(maHandle3, 0, 0, 1, ma3Value) < 0 ||
        CopyBuffer(maHandle4, 0, 0, 1, ma4Value) < 0 ||
        CopyBuffer(atrHandle, 0, 0, 1, atrValue) < 0 ||
        CopyBuffer(rsiHandle, 0, 0, 1, rsiValue) < 0)
    {
        Print("无法获取指标数据");
        return;
    }

    // 打印均线、ATR和RSI值
    // Print("MA1 (", MA1_Period, "): ", ma1Value[0],
    //       " MA2 (", MA2_Period, "): ", ma2Value[0],
    //       " MA3 (", MA3_Period, "): ", ma3Value[0],
    //       " MA4 (", MA4_Period, "): ", ma4Value[0],
    //       " ATR14: ", atrValue[0], " RSI21: ", rsiValue[0]);

    // 绘制RSI水平线
    ObjectCreate(0, "RSI_Level_30", OBJ_HLINE, 0, TimeCurrent(), 30);
    ObjectSetInteger(0, "RSI_Level_30", OBJPROP_COLOR, clrRed);
    ObjectCreate(0, "RSI_Level_70", OBJ_HLINE, 0, TimeCurrent(), 70);
    ObjectSetInteger(0, "RSI_Level_70", OBJPROP_COLOR, clrRed);
}

//+------------------------------------------------------------------+
//| 交易事件处理函数                                                 |
//+------------------------------------------------------------------+
void OnTrade()
{
    // 检查是否有订单关闭
    if (HistorySelect(TimeCurrent() - PeriodSeconds(Timeframe), TimeCurrent()))
    {
        int historyCount = HistoryOrdersTotal(); // 获取历史订单总数

        // 遍历历史订单
        for (int i = historyCount - 1; i >= 0; i--)
        {
            ulong ticket = HistoryOrderGetTicket(i); // 获取历史订单的票号

            if (HistoryOrderSelect(ticket)) // 选择历史订单
            {
                // 获取订单的关闭原因
                ENUM_ORDER_REASON orderReason = (ENUM_ORDER_REASON)HistoryOrderGetInteger(ticket, ORDER_REASON);

                // 检查订单是否因止损或止盈而关闭
                if (orderReason == ORDER_REASON_SL || orderReason == ORDER_REASON_TP)
                {
                    lastCloseTime = iTime(_Symbol, Timeframe, 0); // 更新最后一次订单关闭的时间为当前K线时间
                    isOrderClosedThisBar = true;                  // 当前K线内订单被止盈或止损
                    stopLossHitThisBar = true;                    // 标记止损被打掉
                    Print("注意: 订单 ", ticket, " 已经被关闭 ", orderReason == ORDER_REASON_SL ? "止损" : "止盈", ".");
                    trailingMaxHigh = 0;
                    trailingMinLow = 0;
                    ResetSignalState(); // 重置信号状态
                }
            }
        }
    }
}

//+------------------------------------------------------------------+