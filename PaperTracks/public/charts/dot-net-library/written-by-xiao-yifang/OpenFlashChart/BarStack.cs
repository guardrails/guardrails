using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
   public class BarStackValue
   {
       private string colour;
       private double val;
       public BarStackValue(double val,string color)
       {
           this.Colour = color;
           this.Val = val;
       }
       public BarStackValue(double val)
       {
           this.Val = val;
       }
       public BarStackValue()
       {
           
       }
       public static implicit operator BarStackValue(double val)
       {
           return new BarStackValue(val);
       }
       [JsonProperty("colour")]
       public string Colour
       {
           get { return colour; }
           set { colour = value; }
       }
       [JsonProperty("val")]
       public double Val
       {
           get { return val; }
           set { val = value; }
       }
   }
    public class BarStack:BarBase
    {
        public BarStack()
        {
            this.ChartType = "bar_stack";
        }
        public void Add(BarStackValue barStackValue)
        {
            this.Values.Add(barStackValue);
        }
        public void AddStack(List<BarStackValue> barStackValues)
        {
            base.Values.Add(barStackValues);
        }
    }
}
