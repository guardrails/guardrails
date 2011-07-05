using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class DotStyle
    {
        private  string type;
        private int? sides;
        private double? alpha;
        private bool? isHollow;
        private string background_colour;
        private  double ? background_alpha;
        private int? width;
        private string tip;
        private string colour;
        private int? dotsize;
        private string onclick;
        private Animation onshow = new Animation();
        [JsonProperty("on-show")]
        public Animation OnShowAnimation
        {
            get { return onshow; }
            set { onshow = value; }
        }
        [JsonProperty("type")]
        public  String Type
        {
            get{ return type;}
            set { type = value; }
        }
        [JsonProperty("sides")]
        public int? Sides
        {
            get { return sides; }
            set { sides = value; }
        }
        [JsonProperty("alpha")]
        public double? Alpha
        {
            get { return alpha; }
            set { alpha = value; }
        }
        [JsonProperty("hollow")]
        public bool? IsHollow
        {
            get { return isHollow; }
            set { isHollow = value; }
        }
        [JsonProperty("background-colour")]
        public string BackgroundColour
        {
            get { return background_colour; }
            set { background_colour = value; }
        }
        [JsonProperty("background-alpha")]
        public double? BackgroundAlpha
        {
            get { return background_alpha; }
            set { background_alpha = value; }
        }
        [JsonProperty("width")]
        public int? Width
        {
            get { return width; }
            set { width = value; }
        }
        [JsonProperty("tip")]
        public string Tip
        {
            get { return tip; }
            set { tip = value; }
        }
        [JsonProperty("colour")]
        public string Colour
        {
            get { return colour; }
            set { colour = value; }
        }
        [JsonProperty("dot-size")]
        public int? DotSize
        {
            get { return dotsize; }
            set { dotsize = value; }
        }
        [JsonProperty("on-click")]
        public string OnClick
        {
            get { return onclick; }
            set { onclick = value; }
        }
    }
}
