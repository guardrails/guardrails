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
using Bar=OpenFlashChart.Bar;
using ToolTip=OpenFlashChart.ToolTip;
using YAxis=OpenFlashChart.YAxis;

public partial class datafile_GlassBar : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title = new Title("Bar Chart");

        BarGlass bar = new OpenFlashChart.BarGlass();
        Random random = new Random();
        bar.Colour = "#345";

        bar.FillAlpha = 0.4;
        bar.Text = "Test";

        bar.FontSize = 10;
        List<BarGlassValue> values = new List<BarGlassValue>();
        for (int i = 0; i < 11; i++)
        {

            values.Add(new BarGlassValue(random.Next(i, i * 2)));
        }
        BarGlassValue barGlassValue = new BarGlassValue(4);
        barGlassValue.Tip = "#bottom#:top#top#<br>#val#";
        barGlassValue.Color = "#eee";
        values.Add(barGlassValue);
        bar.Values = values;
        chart.AddElement(bar);
        YAxis yaxis = new YAxis();
        yaxis.Steps = 4;
        yaxis.SetRange(0, 20);
        chart.Y_Axis = yaxis;
        chart.Y_Axis.SetRange(0, 24, 3);
        chart.Tooltip = new ToolTip("提示:#val#");
        string s = chart.ToPrettyString();

        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
