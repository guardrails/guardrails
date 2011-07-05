using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public class HBarValue
    {
        private double left;
        private double right;
        private string tip;
        public HBarValue(double left,double right)
        {
            this.Left = left;
            this.Right = right;
        }
        public HBarValue(double left, double right,string tip)
        {
            this.Left = left;
            this.Right = right;
            this.tip = tip;
        }
        [JsonProperty("left")]
        public double Left
        {
            get { return left; }
            set { left = value; }
        }
        [JsonProperty("right")]
        public double Right
        {
            get { return right; }
            set { right = value; }
        }

        public string Tip
        {
            get { return tip; }
            set { tip = value; }
        }
    }
    public class HBar:BarBase
    {
        public HBar()
        {
            this.ChartType = "hbar";
        }
        public void Add(HBarValue hBarValue)
        {
            this.Values.Add(hBarValue);
        }
    }
}
