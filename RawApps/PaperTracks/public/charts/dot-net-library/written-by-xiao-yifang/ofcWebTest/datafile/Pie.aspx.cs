using System;
using System.Collections.Generic;
using OpenFlashChart;

public partial class Pie : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        chart.Title = new Title("Pie Chart");

        OpenFlashChart.Pie pie = new OpenFlashChart.Pie();
        Random random = new Random();

        List<PieValue> values = new List<PieValue>();
        List<string> labels = new List<string>();
        for (int i = 0; i < 12; i++)
        {
            values.Add(new PieValue(random.NextDouble(),"Pie"+i));
            labels.Add(i.ToString());
        }
        //values.Add(0.2);
        PieValue pieValue = new PieValue(10);
        pieValue.Click = "http://xiao-yifang.blogspot.com";
        values.Add(pieValue);
        pie.Values = values;
        pie.FontSize = 20;
        pie.Alpha = .5;
        PieAnimationSeries pieAnimationSeries = new PieAnimationSeries();
        pieAnimationSeries.Add(new PieAnimation("bounce", 5));
        pie.Animate = pieAnimationSeries;
        //pie.GradientFillMode = false;
        
        //pie.FillAlpha = 10;

        //pie.Colour = "#fff";
        pie.Colours = new string[]{"#04f","#1ff","#6ef","#f30"};
        pie.Tooltip="#label#,#val# of #total##percent# of 100%";
        chart.AddElement(pie);
        chart.Bgcolor = "#202020";
        string s = chart.ToPrettyString();
        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(s);
        Response.End();
    }
}
