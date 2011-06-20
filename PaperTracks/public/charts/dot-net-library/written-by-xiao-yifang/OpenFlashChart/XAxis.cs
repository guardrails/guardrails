using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public class XAxis:Axis
    {
        private string tick_height;
        private XAxisLabels labels;

        [JsonProperty("tick-height")]
        public string TickHeight
        {
            get { return tick_height; }
            set { tick_height = value; }
        }

        [JsonProperty("labels")]
        public XAxisLabels Labels
        {
            get
            {
                if (this.labels == null)
                    this.labels = new XAxisLabels();
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
