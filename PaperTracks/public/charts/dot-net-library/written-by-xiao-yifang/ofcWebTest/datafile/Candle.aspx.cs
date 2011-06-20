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

public partial class datafile_Candle : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title = new Title("Bar Chart");

        Candle candle = new OpenFlashChart.Candle();
        Random random = new Random();
        candle.Colour = "#345";

        candle.FillAlpha = 0.4;
        candle.Text = "Test";

        candle.FontSize = 10;
        ArrayList values = new ArrayList();
        for (int i = 0; i < 12; i++)
            values.Add(new CandleValue(random.Next(20,30),random.Next(15,20),random.Next(10,15),random.Next(5,10)));
        candle.Values = values;
        chart.AddElement(candle);
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
        candle.Tooltip = "提示:#top#<br>#bottom#<br>#val#";
        string s = chart.ToPrettyString();

        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
