using System;
using System.Collections.Generic;
using System.Text;

namespace OpenFlashChart
{
    public class YAxisLabels:AxisLabels
    {
        public override void SetLabels(IList<string> labelsvalue)
        {
            int pos = 0;
            if (labels == null)
                labels = new List<object>();
            foreach (string s in labelsvalue)
            {
                labels.Add(s);
                pos++;
            }
        }
    }
}
