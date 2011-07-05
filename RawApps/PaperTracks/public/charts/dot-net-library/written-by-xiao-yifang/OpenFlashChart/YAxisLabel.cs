using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class YAxisLabel:AxisLabel
    {
        private int? y;
        [JsonProperty("y")]
        public int? Y
        {
            get { return y; }
            set { y = value; }
        }
        public YAxisLabel(string text,int ypos):base(text)
        {
            y = ypos;
        }
    }
}
