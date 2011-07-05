using System;
using System.Collections;
using System.Data;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using OpenFlashChart;
using ToolTip=OpenFlashChart.ToolTip;
using ToolTipStyle=OpenFlashChart.ToolTipStyle;

public partial class _Default : System.Web.UI.Page 
{
    OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        
    protected void Page_Load(object sender, EventArgs e)
    {
        ArrayList data1 = new ArrayList();
        Random rand = new Random(DateTime.Now.Millisecond);
        for (double i = 0; i < 12; i++)
        {
            int temp = rand.Next(30);
            if (temp > 20)
                data1.Add(new LineDotValue(temp, "#fe0"));
            else
            {
                data1.Add(temp);
            }
        }

        OpenFlashChart.LineHollow line1 = new LineHollow();
        line1.Values = data1;
        line1.HaloSize = 0;
        line1.Width = 2;
        line1.DotSize = 5;

        line1.Tooltip = "提示：#val#";

        chart.AddElement(line1);

        chart.Title = new Title("line演示");
        chart.Y_Axis.SetRange(0, 35, 5);
        chart.Tooltip = new ToolTip("全局提示：#val#");
        chart.Tooltip.Shadow = true;
        chart.Tooltip.Colour = "#e43456";
        chart.Tooltip.MouseStyle = ToolTipStyle.CLOSEST;
        OpenFlashChartControl1.EnableCache = false;
        OpenFlashChartControl1.Chart = chart;
    }
    protected void Button1_Click(object sender, EventArgs e)
    {
        chart.Title = new Title("new Title");
        OpenFlashChartControl1.Chart = chart;
    }
    protected void Button2_Click(object sender, EventArgs e)
    {
        chart.Title = new Title("default title");
    }
}
