using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;
namespace OpenFlashChart
{
    public class RadarAxis:XAxis
    {
        private XAxisLabels spokelabels;
        public RadarAxis(double max)
        {
            base.Max = max;
        }
        public RadarAxis()
        {
            
        }
        [JsonProperty("spoke-labels")]
        public XAxisLabels SpokeLabels
        {
            get { return spokelabels; }
            set { spokelabels = value; }
        }
    }
}
