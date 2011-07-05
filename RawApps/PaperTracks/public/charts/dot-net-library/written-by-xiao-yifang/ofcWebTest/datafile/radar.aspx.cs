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
public partial class datafile_radar : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        List<double> data1 = new List<double>();
        Random rand = new Random(DateTime.Now.Millisecond);
        for (double i = 0; i < 12; i++)
        {
            data1.Add(rand.Next(15,30));
        }

        OpenFlashChart.AreaLine areaLine = new AreaLine();
        areaLine.Values = data1;
        areaLine.Width = 2;
        areaLine.DotSize = 5;
        areaLine.FillColor = "#345";
        areaLine.Colour = "#fe0";
        areaLine.FillAlpha = 0.5;
        areaLine.Tooltip = "提示：#val#";
        areaLine.Loop = true;
        chart.AddElement(areaLine);
        RadarAxis radarAxis = new RadarAxis(12);
        radarAxis.Steps = 4;
        //radarAxis.SetLabels(new string[] { "0", "1", "2", "3", "4", "5", "0", "1", "2", "3", "4", "5" ,"23","34"});
        chart.Radar_Axis = radarAxis;
        radarAxis.SetRange(0,30);
        chart.Title = new Title("Radar Chart");
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
