using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public class YAxis:Axis
    {
        private int tick_length;
        private YAxisLabels labels;
        [JsonProperty("tick-length")]
        public int TickLength
        {
            get { return tick_length; }
            set { tick_length = value; }
        }
       
        public void SetRange(double min, double max, int step)
        {
            base.Max = max;
            base.Min = min;
            base.Steps = step;
        }



        [JsonProperty("labels")]
        public YAxisLabels Labels
        {
            get
            {
                if (this.labels == null)
                    this.labels = new YAxisLabels();
                return this.labels;
            }
            set { this.labels = value; }
        }
        public void SetLabels(IList<string> labelsvalue)
        {
            Labels.SetLabels(labelsvalue);
        }
    }
}
