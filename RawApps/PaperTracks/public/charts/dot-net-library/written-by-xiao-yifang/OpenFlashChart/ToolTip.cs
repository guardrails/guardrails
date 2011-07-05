using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
        //{       
        //        shadow:		true,
        //        rounded:	1,
        //        stroke:		2,
        //        colour:		'#808080',
        //        background:	'#f0f0f0',
        //        title:		"color: #0000F0; font-weight: bold; font-size: 12;",
        //        body:		"color: #000000; font-weight: normal; font-size: 12;",
        //        mouse:		Tooltip.CLOSEST,
        //        text:		"_default"
        //}
    public class ToolTip
    {
        string text="_default";
        private bool shadow=true ;
        private int rounded=1;
        private int stroke = 2;
        private string colour;//= "#808080";
        private string background;//= "#f0f0f0";
        private string titlestyle;// = "color: #0000F0; font-weight: bold; font-size: 12;";
        private string bodystyle;//= "color: #000000; font-weight: normal; font-size: 12;";
        private ToolTipStyle mousestyle;//= ToolTipStyle.CLOSEST;

        public int mouse;

        public ToolTip(string text)
        {
            this.text = text;
        }
        [JsonProperty("text")]
        public String Text
        {
            get { return text; }
            set { text = value; }
        }
        [JsonProperty("shadow")]
        public bool Shadow
        {
            get { return shadow; }
            set { shadow = value; }
        }
        [JsonProperty("rounded")]
        public int Rounded
        {
            get { return rounded; }
            set { rounded = value; }
        }
        [JsonProperty("stroke")]
        public int Stroke
        {
            get { return stroke; }
            set { stroke = value; }
        }
        [JsonProperty("colour")]
        public string Colour
        {
            get { return colour; }
            set { colour = value; }
        }
        [JsonProperty("background")]
        public string BackgroundColor
        {
            get { return background; }
            set { background = value; }
        }
        [JsonProperty("title")]
        public string TitleStyle
        {
            get { return titlestyle; }
            set { titlestyle = value; }
        }
        [JsonProperty("body")]
        public string BodyStyle
        {
            get { return bodystyle; }
            set { bodystyle = value; }
        }
        [JsonIgnore]
        public ToolTipStyle MouseStyle
        {
            get { return mousestyle; }
            set { mousestyle = value;
                mouse = (int) value;
            }
        }
        public void SetProximity()
        {
            mouse = 1;
        }
        public override string ToString()
        {
            return this.text;
        }
    }
    public enum ToolTipStyle
    {
        CLOSEST=0,
        FOLLOW=1,
        NORMAL=2
    }
}
