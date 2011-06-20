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

public partial class datafile_BarTypeTest : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title = new Title("Bar Chart");

        Bar bar = new OpenFlashChart.Bar();
        Random random = new Random();
        bar.Colour = "#345";
        bar.BarType = BarType.BAR_DOME;
        bar.FillAlpha = 0.4;
        bar.Text = "Test";

        bar.FontSize = 10;
        List<double> values = new List<double>();
        for (int i = 0; i < 12; i++)
            values.Add(random.Next(i, i * 2));
        bar.Values = values;
        chart.AddElement(bar);
        //XAxis xaxis = new XAxis();
        //// xaxis.Labels = new AxisLabel("text","#ef0",10,"vertical");
        //xaxis.Steps = 1;
        //xaxis.Offset = true;
        ////xaxis.SetRange(-2, 15);
        //chart.X_Axis = xaxis;
        //YAxis yaxis = new YAxis();
        //yaxis.Steps = 4;
        //yaxis.SetRange(0, 20);
        //chart.Y_Axis = yaxis;
        chart.Y_Axis.SetRange(0, 24, 3);
        bar.Tooltip = "提示:#top#<br>#bottom#<br>#val#";
        string s = chart.ToPrettyString();

        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
