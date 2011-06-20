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

public partial class Animation_AreaAnimation : System.Web.UI.Page
{
    OpenFlashChart.OpenFlashChart chart = new OpenFlashChart.OpenFlashChart();
    OpenFlashChart.Area area = new Area();

    protected void Page_Load(object sender, EventArgs e)
    {
        ArrayList data1 = new ArrayList();
        Random rand = new Random(DateTime.Now.Millisecond);
        for (double i = 0; i < 12; i++)
        {
            int temp = rand.Next(30);
            data1.Add(temp);
            
        }

        area.Values = data1;
        area.HaloSize = 0;
        area.Width = 2;
        area.DotSize = 5;

        area.Tooltip = "Tooltip：#val#";

        chart.AddElement(area);

        chart.Title = new Title("Area Animation Demo");
        chart.Y_Axis.SetRange(0, 35, 5);
        chart.Tooltip = new ToolTip("Global tip：#val#");
        chart.Tooltip.Shadow = true;
        chart.Tooltip.Colour = "#e43456";
        chart.Tooltip.MouseStyle = ToolTipStyle.CLOSEST;
        OpenFlashChartControl1.EnableCache = false;
        OpenFlashChartControl1.Chart = chart;
    }
    protected void Button1_Click(object sender, EventArgs e)
    {
        Animation animation = new Animation();
        animation.Type = DropDownList1.SelectedValue;
        try
        {
            animation.Cascade = double.Parse(TextBox1.Text);
        }
        catch (Exception)
        {
            TextBox1.Text = "1";
            animation.Cascade = 1;
        }
        try
        {
            animation.Delay = double.Parse(TextBox2.Text);
        }
        catch (Exception)
        {
            TextBox2.Text = "0.5";
            animation.Delay = 0.5;
        }
        area.OnShowAnimation = animation;
        OpenFlashChartControl1.Chart = chart;
    }
}
