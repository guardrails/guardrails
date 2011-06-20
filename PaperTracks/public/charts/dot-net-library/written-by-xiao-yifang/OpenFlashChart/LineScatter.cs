using System;
using System.Collections.Generic;
using System.Text;

namespace OpenFlashChart
{
    public class LineScatter:Scatter
    {
        public LineScatter()
        {
            this.ChartType = "scatter_line";
            this.DotStyleType.Type = DotType.SOLID_DOT;
        }
    }
}
