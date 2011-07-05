using System;
using System.Collections;
using System.Text;
using JsonFx.Json;


namespace OpenFlashChart
{
    public  class Chart<T> :ChartBase
    {
        public Chart()
        {
            this.values = new ArrayList();
            FillAlpha = 0.35;
            //fontsize = 20;
        }

        //public override double GetMaxValue()
        //{
        //    if (values.Count == 0)
        //        return 0;
        //    double max = double.MinValue;
        //    Type valuetype = typeof(T);
        //    if (!valuetype.IsValueType)
        //        return 0;
        //    foreach (T d in values)
        //    {
        //        double temp = double.Parse(d.ToString());
        //        if (temp > max)
        //            max = temp;
        //    }
        //    return max;
        //}
        
        //public override double GetMinValue()
        //{
        //    if (values.Count == 0)
        //        return 0;
        //    double min = double.MaxValue;
        //    Type valuetype = typeof (T);
        //    if (!valuetype.IsValueType)
        //        return 0;
        //    foreach (T d in values)
        //    {
        //        double temp = double.Parse(d.ToString());
        //        if(temp<min)
        //            min = temp;
        //    }
        //    return min;
        //}
        public void Add(T v)
        {
            this.values.Add(v);
        }
    }

   
}
