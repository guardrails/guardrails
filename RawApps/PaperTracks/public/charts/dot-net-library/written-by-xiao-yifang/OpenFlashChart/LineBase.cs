using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    
    public class LineBase : Chart<LineDotValue>
    {
        private int width;
        private int dotsize;
        private int halosize;
        private string onclick;
        private bool loop;
        private Animation onshow=new Animation();
        
        public LineBase()
        {
            this.ChartType = "line";
            this.DotStyleType.Type = DotType.SOLID_DOT;
          
           
        }
        public void SetOnClickFunction(string func)
        {
            this.DotStyleType.OnClick = func;
            this.onclick = func;
        }
        public virtual string OnClick
        {
            set
            {
                SetOnClickFunction(value);
            }
            get { return this.onclick; }
        }
        [JsonProperty("width")]
        public virtual int Width
        {
            set { this.width = value; }
            get { return this.width; }
        }
     
        [JsonProperty("dot-size")]
        public virtual int DotSize
        {
            get { return dotsize; }
            set { dotsize = value; }
        }
        [JsonProperty("halo-size")]
        public virtual int HaloSize
        {
            get { return halosize; }
            set { halosize = value; }
        }
        [JsonProperty("loop")]
        public bool Loop
        {
            get { return loop; }
            set { loop = value; }
        }
        [JsonProperty("on-show")]
        public Animation OnShowAnimation
        {
            get { return onshow; }
            set { onshow = value; }
        }
    }
}
