using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class BarSketch:BarBase
    {
        private string outlinecolour;
        private int? offset;
        public BarSketch(string colour,string outlinecolor,int? offset)
        {
            this.ChartType = "bar_sketch";
            this.Colour = colour;
            this.outlinecolour = outlinecolor;
            this.offset = offset;
        }
        [JsonProperty("offset")]
        public int? Offset
        {
            get { return offset.Value; }
            set { this.offset = value; }
        }
        [JsonProperty("outline-colour")]
        public string OutlineColour
        {
            get { return outlinecolour; }
            set { this.outlinecolour = value; }
        }

    }
}
