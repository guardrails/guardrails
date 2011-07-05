using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public class AxisLabel
    {
        private string colour;
        private string text;
        private int size;
        private string rotate;
        private bool visible = true;
        public AxisLabel()
        {
            this.visible = true;
            size = 12;
        }
        public AxisLabel(string text)
        {
            this.text = text;
            this.visible = true;
            size = 12;
        }
        public static implicit operator AxisLabel(string text)
        {
            return new AxisLabel(text);
        }
        public AxisLabel(string text, string colour, int size, string rotate)
        {
            this.text = text;
            this.colour = colour;
            this.size = size;
            this.rotate = rotate;

            this.visible = true;
        }
        [JsonProperty("colour")]
        public string Color
        {
            set { this.colour = value; }
            get { return this.colour; }
        }
        [JsonProperty("text")]
        public string Text
        {
            set { this.text = value; }
            get { return this.text; }
        }
        [JsonProperty("size")]
        public int Size
        {
            set { this.size = value; }
            get { return this.size; }
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
            set {
                if(value)
                this.rotate = "vertical"; 
            }
        }
        [JsonProperty("visible")]
        public bool Visible
        {
            set { this.visible = value; }
            get { return this.visible; }
        }

    }
}
