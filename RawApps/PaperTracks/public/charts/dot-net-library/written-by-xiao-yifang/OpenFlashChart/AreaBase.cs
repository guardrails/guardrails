using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public abstract class AreaBase:Chart<double >
    {
        private int? width;
        private double? dotsize;
        private double? halosize;
        private bool loop;
        private string fillcolour;
        private Animation onshow = new Animation();
        protected AreaBase()
        {
            this.ChartType = "area";
        }
        [JsonProperty("fill")]
        public string FillColor
        {
            get { return fillcolour; }
            set { fillcolour = value; }
        }
        
        [JsonProperty("width")]
        public virtual int? Width
        {
            set { this.width = value; }
            get { return this.width; }
        }
     
        [JsonProperty("dot-size")]
        public virtual double? DotSize
        {
            get { return dotsize; }
            set { dotsize = value; }
        }
        [JsonProperty("loop")]
        public bool Loop
        {
            get { return loop; }
            set { loop = value; }
        }
        [JsonProperty("halo-size")]
        public double? HaloSize
        {
            get { return halosize; }
            set { halosize = value; }
        }
        [JsonProperty("on-show")]
        public Animation OnShowAnimation
        {
            get { return onshow; }
            set { onshow = value; }
        }
    }
}
