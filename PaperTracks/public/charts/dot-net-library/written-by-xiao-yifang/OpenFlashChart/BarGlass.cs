using System;
using System.Collections.Generic;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public  class BarGlassValue:BarValue
    {
        public BarGlassValue(double top):base(top)
        {
           
        }
    }
    public class BarGlass : BarBase
    {
        public BarGlass()
        {
            this.ChartType = "bar_glass";
        }
        public  void Add(BarGlassValue barGlassValue)
        {
            this.Values.Add(barGlassValue);
        }
    }
}
