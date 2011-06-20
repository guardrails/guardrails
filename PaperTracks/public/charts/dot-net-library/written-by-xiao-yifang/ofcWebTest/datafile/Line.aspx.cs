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
using OpenFlashChart;

public partial class datafile_Line : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        List<double> data1 = new List<double>();
        List<double> data2 = new List<double>();
     Random rand = new Random(DateTime.Now.Millisecond);
        for(double i=0;i<12;i++)
        {
            data1.Add(rand.Next(30));
            data2.Add(rand.Next(50));
        }

        OpenFlashChart.Line line1 = new Line();
        line1.Values = data1;
        line1.HaloSize = 0;
        line1.Width = 2;
        line1.DotSize = 5;
        line1.DotStyleType.Tip = "#x_label#<br>#val#";
        //line1.DotStyleType.Type = DotType.ANCHOR;
        //line1.DotStyleType.Type = DotType.BOW;
        line1.DotStyleType.Colour = "#467533";
        line1.Tooltip = "#x_label#<br>提示：#val#";

        OpenFlashChart.Line line2 = new Line();
        line2.Values = data2;
        line2.HaloSize = 1;
        line2.Width = 3;
        line2.DotSize = 4;
        line2.DotStyleType.Tip = "#x_label#<br>#val#";
        line1.DotStyleType.Type = DotType.ANCHOR;
        //line1.DotStyleType.Type = DotType.BOW;
        line2.DotStyleType.Colour = "#fe4567";
        line2.Tooltip = "提示：#val#";
        line2.AttachToRightAxis(true);

        chart.AddElement(line1);
        chart.AddElement(line2);
        chart.Y_Legend=new Legend("中文test");
        chart.Title = new Title("line演示");
        chart.Y_Axis.SetRange(0,35,5);
        chart.X_Axis.Labels.Color = "#e43456";
        chart.X_Axis.Labels.VisibleSteps = 3;
        chart.Y_Axis.Labels.FormatString = "$#val#";
        chart.X_Axis.SetLabels(new string[]{"test1","test2"});
        //chart.Y_Axis.SetLabels(new string[] { "test1", "test2", "test1", "test2", "test1", "test2" });
        chart.X_Axis.Steps = 4;
        chart.Y_Axis.Steps = 3;
        chart.Y_Axis.Colour = "#ef6745";
        chart.Y_Axis.Labels.Color = "#ef6745";
        chart.Y_Axis.Offset = true;
        chart.Y_RightLegend = new Legend("test y legend right");
        chart.Y_Axis_Right = new YAxis();
        chart.Y_Axis_Right.Steps = 8;
        chart.Y_Axis_Right.TickLength = 4;
        chart.Y_Axis.TickLength = 4;
        chart.Y_Axis_Right.SetRange(0,60);

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
