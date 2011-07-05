using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class LineDotValue
    {
        private double? val;
        private string tip;
        private string color;
        private int? sides;
        private int? rotation;
        private string type;
        private bool? isHollow;
        private int? dotsize;
        public LineDotValue()
        { }
        public LineDotValue(double val)
        {
            this.val = val;
        }
        public LineDotValue(double val, string tip, string color)
        {
            this.val = val;
            this.tip = tip;
            this.color = color;
        }
        public LineDotValue(double val, string color)
        {
            this.val = val;
            this.color = color;
        }
        [JsonProperty("value")]
        public double? Value
        {
            get { return val; }
            set { val = value; }
        }
        [JsonProperty("tip")]
        public string Tip
        {
            get { return tip; }
            set { tip = value; }
        }
        [JsonProperty("colour")]
        public string Color
        {
            get { return color; }
            set { color = value; }
        }
        [JsonProperty("sides")]
        public int? Sides
        {
            get { return sides; }
            set { sides = value; }
        }
        [JsonProperty("rotation")]
        public int? Rotation
        {
            get { return rotation; }
            set { rotation = value; }
        }
       [JsonProperty("type")]
        public string DotType
        {
            get { return type; }
            set { type = value; }
        }
        [JsonProperty("hollow")]
        public bool? IsHollow
        {
            get { return isHollow; }
            set { isHollow = value; }
        }
        [JsonProperty("dot-size")]
        public int? DotSize
        {
            get { return dotsize; }
            set { dotsize = value; }
        }
    }
}
