using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public  class ChartElement
    {
         private string text;
        private string style;
        [JsonProperty("text")]
        public virtual string Text
        {
            set { this.text = value; }
            get { return this.text; }
        }
        [JsonProperty("style")]
        public string Style
        {
            set { style = value; }
            get
            {
                if (style == null)
                    style = "{font-size: 20px; color:#0000ff; font-family: Verdana; text-align: center;}";
                return this.style;
            }
            //"{font-size: 20px; color:#0000ff; font-family: Verdana; text-align: center;}";		

        }
    }
}
