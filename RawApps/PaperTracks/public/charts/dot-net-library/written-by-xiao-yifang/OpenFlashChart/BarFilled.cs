using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;
namespace OpenFlashChart
{
    public class BarFilledValue:BarValue
    {
        private string outline_color;
        public BarFilledValue():base()
        {}
        public BarFilledValue(double top, double bottom):base(top,bottom)
        {

        }

       
        [JsonProperty("outline-colour")]
        public string OutlineColor
        {
            get { return outline_color; }
            set { outline_color = value; }
        }
    }
    public class BarFilled : BarBase
    {
        public BarFilled()
        {
            this.ChartType = "bar_filled";
        }
        public void Add(BarFilledValue barFilledValue)
        {
            this.Values.Add(barFilledValue);
        }
    }
}
