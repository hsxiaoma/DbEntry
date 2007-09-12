
#region usings

using System;
using Lephone.Data.Dialect;
using Lephone.Data.SqlEntry;

#endregion

namespace Lephone.Data.Builder
{
	public interface IClause
	{
		string ToSqlText(DataParamterCollection dpc, DbDialect dd);
	}
}
