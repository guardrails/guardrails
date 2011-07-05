using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public class AxisLabels
    {
        private int? steps;
        protected IList<object> labels;
        private string colour;
        private string rotate;
        private int? fontsize;
        private int? visiblesteps;

        private string formatstring;
       
        [JsonProperty("steps")]
        public int? Steps
        {
            get
            {
                if (this.steps == null)
                    return null;
                return this.steps;
            }
            set { this.steps = value; }
        }
        [JsonProperty("labels")]
        [Obsolete("just for json generation,not used.Use SetLabels()")]
        public IList<object> AxisLabelValues
        {
            get { return labels; }
            set { this.labels = value; }
        }
        public virtual void SetLabels(IList<string> labelsvalue)
        {
            if (labels == null)
                labels = new List<object>();
            foreach (string s in labelsvalue)
            {
                labels.Add(s);
            }
        }
        public  void Add(AxisLabel label)
        {
            if (labels == null)
                labels = new List<object>();
            labels.Add(label);
        }
        [JsonProperty("colour")]
        public string Color
        {
            set { this.colour = value; }
            get { return this.colour; }
        }
        [JsonProperty("rotate")]
        public string Rotate
        {
            set { this.rotate = value; }
            get { return this.rotate; }
        }
        [JsonIgnore]
        public bool Vertical
        {
            set
            {
                if (value)
                    this.rotate = "vertical";
            }
        }
        [JsonProperty("size")]
        public int? FontSize
        {
            get { return fontsize; }
            set { fontsize = value; }
        }
        [JsonProperty("text")]
        public string FormatString
        {
            get { return formatstring; }
            set { formatstring = value; }
        }
        [JsonProperty("visible-steps")]
        public int? VisibleSteps
        {
            get { return visiblesteps; }
            set { visiblesteps = value; }
        }
    }
}
