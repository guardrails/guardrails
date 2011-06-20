using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class CandleValue:BarValue
    {
        protected double? high;
        protected double? low;

        [JsonProperty("high")]
        public double? High
        {
            get { return high; }
            set { high = value; }
        }
        [JsonProperty("low")]
        public double? Low
        {
            get { return low; }
            set { low = value; }
        }
        public CandleValue()
        {}
        public CandleValue(double high,double top,double bottom,double low)
        {
            this.high = high;
            this.top = top;
            this.bottom = bottom;
            this.low = low;
        }
    }
    public class Candle:BarBase
    {
        public Candle()
        {
            this.ChartType = "candle";
        }
        public void Add(CandleValue candleValue)
        {
            this.values.Add(candleValue);
        }
    }
}
