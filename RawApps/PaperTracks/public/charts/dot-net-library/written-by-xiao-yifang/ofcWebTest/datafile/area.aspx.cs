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
using AreaLine=OpenFlashChart.AreaLine;
using Legend=OpenFlashChart.Legend;

public partial class datafile_area : System.Web.UI.Page
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

        OpenFlashChart.Area area = new Area();
        area.Values = data1;
        area.HaloSize = 0;
        area.Width = 2;
        area.DotSize = 5;
        area.FontSize = 12;
        area.DotStyleType.Tip = "#x_label#<br>#val#";
        //area.DotStyleType.Type = DotType.ANCHOR;
        area.DotStyleType.Type = DotType.BOW;
        area.DotStyleType.Colour = "#467533";
        area.Tooltip = "提示：#val#";
        area.Colour = "#CC3399";
        area.FillColor = "#343399";
        area.FillAlpha = .5;
        chart.AddElement(area);
        chart.Y_Legend = new Legend("中文test");
        chart.Title = new Title("line演示");
        chart.Y_Axis.SetRange(0, 35, 5);
        chart.X_Axis.Labels.Color = "#e43456";
        chart.X_Axis.Steps = 4;
        chart.Y_Axis.Steps = 3;
        
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
