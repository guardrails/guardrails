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


public partial class datafile_chart1 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title=new Title("AreaHollow");

        AreaHollow area = new AreaHollow();
        Random random=new Random();
        area.Colour = "#0fe";
        area.DotSize = 2;
        area.FillAlpha = 0.4;
        area.Text = "Test";
        area.Width = 2;
        area.FontSize = 10;
        IList values = new List<double>();
        for (int i = 0; i < 12; i++)
            values.Add(random.Next(i, i*2));
        area.Values = values;
        chart.AddElement(area);
         XAxis xaxis=new XAxis();
       // xaxis.Labels = new AxisLabel("text","#ef0",10,"vertical");
        xaxis.Steps = 1;
        xaxis.SetRange(0,12);
        chart.X_Axis = xaxis;
        YAxis yaxis = new YAxis();
        yaxis.Steps = 4;
       yaxis.SetRange(0,20);
        chart.Y_Axis = yaxis;
        string s = chart.ToString();
        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
