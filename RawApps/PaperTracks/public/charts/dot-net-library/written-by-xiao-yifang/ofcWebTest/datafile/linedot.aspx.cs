using System;
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
public partial class datafile_linedot : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
        ArrayList data1 = new ArrayList();
        Random rand = new Random(DateTime.Now.Millisecond);
        for (double i = 0; i < 12; i++)
        {
            int temp = rand.Next(30);
            if (temp > 20)
                data1.Add(new LineDotValue(temp, "your tip","#fe0fe0"));
            else
            {
                data1.Add(temp);
            }
        }
        LineDotValue dotValue1 = new LineDotValue(rand.Next(30));
        dotValue1.Sides = 3;

        dotValue1.DotType = DotType.HOLLOW_DOT;
        data1.Add(dotValue1);
        LineDotValue dotValue2 = new LineDotValue(rand.Next(30));
        dotValue2.IsHollow = true;
        dotValue2.DotType = DotType.STAR;
        data1.Add(dotValue2);

        LineDotValue dotValue3 = new LineDotValue(rand.Next(30));
        dotValue3.Sides = 4;

        dotValue3.DotType = DotType.DOT;
        data1.Add(dotValue3);
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
        Response.Clear();
        Response.CacheControl = "no-cache";
        Response.Write(chart.ToPrettyString());
        Response.End();
    }
}
