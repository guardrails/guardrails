using System;
using System.Collections.Generic;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using OpenFlashChart;
using ToolTip=OpenFlashChart.ToolTip;

public partial class Tooltip : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        List<double> data3 = new List<double>();
       Random random = new Random(DateTime.Now.Millisecond);
        for (double i = 0; i < 10; i ++)
        {
            data3.Add(random.Next(-10,12));
        }

      
        OpenFlashChart.LineHollow line3 = new LineHollow();
        line3.Values = data3;
        line3.HaloSize = 2;
        line3.Width = 6;
        line3.DotSize = 4;
        line3.FontSize = 12;

       
        line3.Text = "line3";

        line3.Tooltip = "my tip #val#";
       
        chart.AddElement(line3);
        chart.Title = new Title("Tooltip Demo");
        chart.Y_Axis.SetRange(-10, 15, 5);

        chart.Tooltip = new ToolTip("my tip #val#");
        
        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(chart.ToPrettyString());
        Response.End();
    }
}
