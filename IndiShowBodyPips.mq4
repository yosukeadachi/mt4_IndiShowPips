//+------------------------------------------------------------------+
//|                                             IndiShowBodyPips.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property description "バーをクリックすると実体のパーセント、もう一度クリックでpipsが表示されます。もう一度クリックで消えます。"
#property strict


#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1  Red

//text　object
double gUnitPerPips = 0.01;         //pips単位

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
  gUnitPerPips = currencyUnitPerPips(NULL);
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
  return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
  deleteAllPipsTextObj();
}

//+------------------------------------------------------------------+
//| イベント関数                                              |
//+------------------------------------------------------------------+
void OnChartEvent(
                 const int     id,      // イベントID
                 const long&   lparam,  // long型イベント
                 const double& dparam,  // double型イベント
                 const string& sparam)  // string型イベント
{
  if (id == CHARTEVENT_CLICK){
    int _x = (int)lparam;
    int _y = (int)dparam;
    updatePipsTextObj(_x,_y);
  }
}

//+------------------------------------------------------------------+
//|【関数】1pips当たりの価格単位を計算する                           |
//|                                                                  |
//|【引数】 IN OUT  引数名             説明                          |
//|        --------------------------------------------------------- |
//|         ○      aSymbol            通貨ペア                      |
//|                                                                  |
//|【戻値】1pips当たりの価格単位                                     |
//|                                                                  |
//|【備考】なし                                                      |
//+------------------------------------------------------------------+
double currencyUnitPerPips(string aSymbol)
{
  // 通貨ペアに対応する小数点数を取得
  double digits = MarketInfo(aSymbol, MODE_DIGITS);

  // 通貨ペアに対応するポイント（最小価格単位）を取得
  // 3桁/5桁のFX業者の場合、0.001/0.00001
  // 2桁/4桁のFX業者の場合、0.01/0.0001
  double point = MarketInfo(aSymbol, MODE_POINT);

  // 価格単位の初期化
  double _currencyUnit = 0.0;

  // 3桁/5桁のFX業者の場合
  if(digits == 3.0 || digits == 5.0){
    _currencyUnit = point * 10.0;
  // 2桁/4桁のFX業者の場合
  }else{
    _currencyUnit = point;
  }

  return(_currencyUnit);
}

//---------
//Objects
//テキストオブジェクト作成
void CreateTextObj(string aText, datetime aAnchorTime, double aAnchorValue, string aObjName) {
  int chart_id = 0;
  string obj_name = aObjName;
  if(!ObjectCreate(chart_id,obj_name,                                     // オブジェクト作成
              OBJ_TEXT,                                             // オブジェクトタイプ
              0,                                                       // サブウインドウ番号
              aAnchorTime,                                               // 1番目の時間のアンカーポイント
              aAnchorValue                                         // 1番目の価格のアンカーポイント
              )) {
                Print("Error: ObjectCreate: can't create label! code #",GetLastError());
                return;
              }
  color _color = clrRed;
  int _anchor = ANCHOR_BOTTOM;
  ObjectSetInteger(chart_id,obj_name,OBJPROP_COLOR,_color);         // 色設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_WIDTH,1);              // 幅設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_BACK,false);           // オブジェクトの背景表示設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_SELECTABLE,true);      // オブジェクトの選択可否設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_SELECTED,false);       // オブジェクトの選択状態
  ObjectSetInteger(chart_id,obj_name,OBJPROP_HIDDEN,true);          // オブジェクトリスト表示設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_ZORDER,0);             // オブジェクトのチャートクリックイベント優先順位
  ObjectSetInteger(chart_id,obj_name,OBJPROP_ANCHOR,_anchor);       // アンカータイプ
  ObjectSetString(chart_id,obj_name,OBJPROP_TEXT,aText);        // テキスト
  ObjectSetString(chart_id,obj_name,OBJPROP_FONT, "ＭＳ　ゴシック");  // フォント
  ObjectSetInteger(chart_id,obj_name,OBJPROP_FONTSIZE, 15);  // フォントサイズ
}

//オブジェクトに指定文字があるか
bool getStringFromObject(string aObjName, string& aText) {
  int chart_id = 0;
  string _text = "";
  if(!ObjectGetString(chart_id, aObjName,OBJPROP_TEXT,0,_text)) {
    return false;
  }
  aText = _text;
  return true;
}

//オブジェクト命名規則
string getObjName(datetime aTime) {
  return "TEXT_" + TimeToStr(aTime,TIME_DATE|TIME_SECONDS);
}

//Pips表示を更新
void updatePipsTextObj(int aPosX,int aPosY) {
  int _window = 0;
  datetime _dt = 0;
  double _price = 0;
  if(!ChartXYToTimePrice( 
    0,    // チャート識別子 
    aPosX,           // チャートの X 座標 
    aPosY,           // チャートの Y 座標 
    _window,   // サブウィンドウ番号 
    _dt,         // チャートの時間 
    _price       // チャートの価格 
  ))
  {
    Print("Error: ChartXYToTimePrice code #",GetLastError());
    return;
  }

  for(int _shift = 0; _shift < Bars; _shift++)
  {
    if(Time[_shift] != _dt) {
      continue;
    }
    if(_price > High[_shift] || _price < Low[_shift]) {
      return;
    }
    if(ArraySize(High) <= _shift) {
      return;
    }
    string _objName = getObjName(Time[_shift]);

    double _bodyValueAbs = MathAbs(Open[_shift]-Close[_shift]);
    double _allValue = High[_shift]-Low[_shift];
    string _text = "";
    //Pipsかパーセントか
    string _oldText = "";
    getStringFromObject(_objName, _oldText);
    if(_oldText == "") {
      //%表示に切り替え
      double _bodyPercent = _bodyValueAbs / _allValue * 100;
      // Print("_percent:",_percent);
      _text = DoubleToStr(_bodyPercent,0) + "%";
    } else if(StringFind(_oldText,"%") != -1) {
      //p表示に切り替え
      double _bodyPips = _bodyValueAbs / gUnitPerPips;
      _text = DoubleToStr(_bodyPips*10,0) + "p"; //MT4の十字カーソルの計測値が10倍になっているため
    } else if(StringFind(_oldText,"p") != -1) {
      //非表示に切り替え
      _text = "";
    }
    
    ObjectDelete(_objName);
    CreateTextObj(_text, Time[_shift], Open[_shift], _objName);
  }
}

//削除全部
void deleteAllPipsTextObj() {
  for(int _shift = 0; _shift < Bars; _shift++)
  {
    if(ArraySize(Time) <= _shift) {
      return;
    }
    ObjectDelete(getObjName(Time[_shift]));
  }
}

//+------------------------------------------------------------------+