using System;
using System.Data;
using System.Configuration;
using System.Collections.Generic;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using YAxis=OpenFlashChart.YAxis;
using OpenFlashChart;

public partial class datafile_yaxis : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        List<double> data1 = new List<double>();
        Random rand = new Random(DateTime.Now.Millisecond);
        for (double i = 0; i < 12; i++)
        {
            data1.Add(rand.Next(30));
        }

        OpenFlashChart.LineHollow line1 = new LineHollow();
        line1.Values = data1;
        line1.HaloSize = 0;
        line1.Width = 2;
        line1.DotSize = 5;

        line1.Tooltip = "提示：#val#";

        chart.AddElement(line1);

        chart.Title = new Title("line演示");
       // chart.Y_Axis.SetRange(0, 35, 5);
       // chart.Y_Axis.Stroke = 2;
        chart.Y_Axis_Right = new YAxis();
        chart.Y_Axis_Right.TickLength=5;
        chart.Y_Axis_Right.Stroke = 10;
        line1.AttachToRightAxis(true);
        //chart.Y_Axis_Right.Steps = 4;
        chart.Y_Axis_Right.SetRange(0,30,10);
        //chart.Y_Axis_Right
        chart.Tooltip = new ToolTip("全局提示：#val#");
        chart.Tooltip.Shadow = true;
        chart.Tooltip.Colour = "#e43456";
        chart.Tooltip.MouseStyle = ToolTipStyle.CLOSEST;
        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(chart.ToPrettyString());
        Response.End();
    }
}
