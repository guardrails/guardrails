using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class BarValue
    {
        protected double? bottom;
        protected double? top;
        protected string color;
        protected string tip;
        private string onclick;
        public BarValue()
        {
            
        }
        public BarValue(double top)
        {
            this.top = top;
        }
        public BarValue(double top,double bottom)
        {
            this.bottom = bottom;
            this.top = top;
        }
        [JsonProperty("bottom")]
        public double? Bottom
        {
            get { return bottom; }
            set { bottom = value; }
        }
        [JsonProperty("top")]
        public double? Top
        {
            get { return top; }
            set { top = value; }
        }
        [JsonProperty("colour")]
        public string Color
        {
            get { return color; }
            set { color = value; }
        }
        [JsonProperty("tip")]
        public string Tip
        {
            get { return tip; }
            set { tip = value; }
        }
        [JsonProperty("on-click")]
        public string OnClick
        {
            get { return onclick; }
            set { onclick = value; }
        }
    }
    public class Bar:BarBase
    {
        public Bar()
        {
            this.ChartType = "bar";
        }
        /// <summary>
        /// 
        /// </summary>
        [JsonIgnore]
        public string BarType
        {
            get { return this.ChartType; }
            set { this.ChartType = value; }
        }
        
        public void Add(BarValue barValue)
        {
            this.Values.Add(barValue);
        }
        
    }
}
