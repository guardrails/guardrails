using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;

namespace OpenFlashChart
{
    public class AnimationBase
    {
        
    }
    public class Animation : AnimationBase
    {
        private string type;
        private double? cascade;
        private double? delay;
        public Animation()
        {}
        public Animation(string type,int? cascade,double? delay)
        {
            this.Type = type;
            this.Cascade = cascade;
            this.Delay = delay;
        }
        [JsonProperty("type")]
        public string Type
        {
            get { return type; }
            set { type = value; }
        }
        [JsonProperty("cascade")]
        public double? Cascade
        {
            get { return cascade; }
            set { cascade = value; }
        }
        [JsonProperty("delay")]
        public double? Delay
        {
            get { return delay; }
            set { delay = value; }
        }
    }
    public class PieAnimation : AnimationBase
    {
        private string type;
        private int? distance;
        /// <summary>
        /// used in pie animation
        /// </summary>
        /// <param name="type"></param>
        /// <param name="distance"></param>
        public PieAnimation(string type,int?distance)
        {
            this.type = type;
            this.distance = distance;
        }
        [JsonProperty("type")]
        public string Type
        {
            get { return type; }
            set { type = value; }
        }
        [JsonProperty("distance")]
        public int? Distance
        {
            get { return distance; }
            set { distance = value; }
        }
    }
    public class PieAnimationSeries:List<PieAnimation>
    {}
}
