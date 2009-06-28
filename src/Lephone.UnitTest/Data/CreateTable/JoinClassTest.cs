﻿using Lephone.Data;
using Lephone.Data.Definition;
using NUnit.Framework;

namespace Lephone.UnitTest.Data.CreateTable
{
    [TestFixture]
    public class JoinClassTest : SqlTestBase
    {
        public class TestClass1 : DbObject
        {
            public string Name;
        }

        public class TestClass2 : DbObject
        {
            public int Age;
        }

        [JoinOn(0, "Test_Class1.Id", "Test_Class2.Id", CompareOpration.Equal, JoinMode.Inner)]
        [CreateTableList(typeof(TestClass1), typeof(TestClass2))]
        public class JoinClass : IDbObject
        {
            public string Name;
            public int Age;
        }

        [Test]
        public void Test1()
        {
            var list = DbEntry.From<JoinClass>().Where(null).Select();
            Assert.IsNotNull(list);
            Assert.AreEqual(0, list.Count);
        }
    }
}