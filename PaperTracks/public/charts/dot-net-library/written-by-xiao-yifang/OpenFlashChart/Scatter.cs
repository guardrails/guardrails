using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class ScatterValue
    {
        private double x;
        private double y;
        private int? dotsize;
        private string dottype;
        private string onclick;
        public ScatterValue(double x, double y)
        {
            this.x = x;
            this.y = y;
        }
        public ScatterValue(double x, double y, int dotsize)
        {
            this.x = x;
            this.y = y;
            if (dotsize > 0)
                this.dotsize = dotsize;
            //this.dottype = DotType.HOLLOW_DOT;
        }
        
        [JsonProperty("x")]
        public double X
        {
            get{return x;}
            set{this.x=value;}
        }
         [JsonProperty("y")]
        public double Y
        {
            get{return y;}
            set{this.y=value;}
        }
         [JsonProperty("dot-size")]
        public int DotSize
        {
            get{
                if (dotsize == null)
                    return -1;

                return dotsize.Value;}
            set{this.dotsize=value;}
        }
        [JsonProperty("type")]
        public string DotType
        {
            get { return dottype; }
            set { dottype = value; }
        }
        [JsonProperty("on-click")]
        public string OnClick
        {
            get { return onclick; }
            set { onclick = value; }
        }
    }
   public class Scatter:Chart<ScatterValue>
    {
       private int? dotsize;
       public Scatter()
       {
           this.ChartType = "scatter";
       }
       public Scatter(string color,int? dotsize)
       {
           this.ChartType = "scatter";
           this.Colour = color;
           this.dotsize = dotsize;
           DotStyleType.Type = DotType.SOLID_DOT;
       }
       [JsonProperty("dot-size")]
       public int? DotSize
       {
           get { return this.dotsize; }
           set { this.dotsize = value; }
       }
    }
}
