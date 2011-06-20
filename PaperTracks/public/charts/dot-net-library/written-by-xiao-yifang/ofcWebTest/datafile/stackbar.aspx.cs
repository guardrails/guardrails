using System;
using System.Collections.Generic;
using System.Data;
using System.Configuration;
using System.Collections.Generic;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using OpenFlashChart;

public partial class datafile_stackbar : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title = new Title("Stack Bar");

        BarStack bar = new OpenFlashChart.BarStack();
        List<BarStackValue> barStackValues = new List<BarStackValue>() ;
        barStackValues.Add(2);
           barStackValues.Add( new BarStackValue(3))
        ;
        
       bar.AddStack(barStackValues);
       List<BarStackValue> barStackValues1 = new List<BarStackValue>();
       barStackValues1.Add(new BarStackValue(5,"#ef4565"));
       barStackValues1.Add(new BarStackValue(3,"#876567"));

       bar.AddStack(barStackValues1);
        chart.AddElement(bar);
        chart.X_Axis.Steps = 4;
        chart.X_Axis.Labels.Steps = 1;
        chart.X_Axis.SetLabels( new string[]{"bar1","bar2"});
        chart.X_Axis.Labels.Vertical = true;

        chart.X_Axis.Set3D(12);
        chart.X_Axis.Offset = true;

        chart.Y_Axis.Set3D(3);
        chart.Y_Axis.Steps = 4;

        string s = chart.ToPrettyString();
        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
