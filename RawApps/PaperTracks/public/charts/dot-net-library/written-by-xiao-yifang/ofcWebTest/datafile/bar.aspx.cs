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
using XAxis=OpenFlashChart.XAxis;
using YAxis=OpenFlashChart.YAxis;

public partial class bar : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title = new Title("Bar Chart");

        Bar bar = new OpenFlashChart.Bar();
        Random random = new Random();
        bar.Colour = "#344565";
        
        bar.Alpha = 0.8;
        
        bar.Text = "Test";
     
        bar.FontSize = 10;
        List<object> values = new List<object>();
        for (int i = 0; i < 12; i++)
            values.Add(random.Next(i, i * 2));
        BarValue barValue = new BarValue(12);
        barValue.OnClick = "http://xiao-yifang.blogspot.com";
        values.Add(barValue);
        bar.Values = values;
        chart.AddElement(bar);
        XAxis xaxis = new XAxis();
        xaxis.Labels.SetLabels(new string[] { "text", "#ef0", "10", "vertical" });
        //xaxis.Steps = 1;
        //xaxis.Offset = true;
        ////xaxis.SetRange(-2, 15);
        chart.X_Axis = xaxis;
        //YAxis yaxis = new YAxis();
        //yaxis.Steps = 4;
        //yaxis.SetRange(0, 20);
        //chart.Y_Axis = yaxis;
        chart.Y_Axis.SetRange(0,24,3);
        bar.Tooltip = "提示:label:#x_label#<br>#top#<br>#bottom#<br>#val#";
        string s = chart.ToPrettyString();

        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
