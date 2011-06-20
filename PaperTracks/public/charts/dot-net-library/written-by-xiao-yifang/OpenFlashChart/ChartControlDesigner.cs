using System;
using System.Collections.Generic;
using System.Text;

using System.Web.UI.Design;

namespace OpenFlashChart
{
    public class ChartControlDesigner : ControlDesigner
    {
        public override string GetDesignTimeHtml()
        {
            string errorDesignTimeHtml;
            StringBuilder builder = new StringBuilder();
            try
            {
                OpenFlashChartControl component = (OpenFlashChartControl)base.Component;
                OpenFlashChartControl chart = component;
                builder.AppendFormat("<div style='width:{0};height:{1};'>", chart.Width, chart.Height);
                builder.Append("<span style=\"font-size:16px;position:absolute;\">Open Flash Chart Control</span>");

                builder.Append("</div>");
                errorDesignTimeHtml = this.CreatePlaceHolderDesignTimeHtml(builder.ToString());
            }
            catch (Exception e)
            {
                errorDesignTimeHtml = this.GetErrorDesignTimeHtml(e);
            }
            return errorDesignTimeHtml;
        }

        protected override string GetErrorDesignTimeHtml(Exception e)
        {
            string instruction = string.Format("Exception:{0}",  e.Message );
            return this.CreatePlaceHolderDesignTimeHtml(instruction);
        }
    }
}
