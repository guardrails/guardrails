using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public abstract class BarBase : Chart<double>
    {
        private Animation onshow = new Animation();
        protected BarBase()
        {
            this.ChartType = "bar";
        }
        [JsonProperty("on-show")]
        public Animation OnShowAnimation
        {
            get { return onshow; }
            set { onshow = value; }
        }
    }
}
