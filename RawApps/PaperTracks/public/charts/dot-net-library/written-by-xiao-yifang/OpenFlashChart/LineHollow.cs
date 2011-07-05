using System;
using System.Collections.Generic;
using System.Text;

namespace OpenFlashChart
{
    public class LineHollow:LineBase
    {
        public LineHollow()
        {
            //this.ChartType = "line_hollow";
            this.DotStyleType.IsHollow = true;
            this.DotStyleType.Type = DotType.HOLLOW_DOT;
        }
    }
}
