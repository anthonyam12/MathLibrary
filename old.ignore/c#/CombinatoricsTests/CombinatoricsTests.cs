﻿using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Combanatorics;

namespace CombinatoricsTests
{
    [TestClass]
    public class CombinatoricsTests
    {
        [TestMethod]
        public void CombinationsTests()
        {
            int correctCount = 0;

            if (Combinatorics.Combinations(100, 3) == 161700)   // correct
                correctCount++;
            if (Combinatorics.Combinations(100, 4) == 3921225)  // correct
                correctCount++;
            if (Combinatorics.Combinations(100, 4) == 12)       // incorrect
                correctCount++;
            if (Combinatorics.Combinations(100, 1) == 100)      // correct
                correctCount++;
            if (Combinatorics.Combinations(100, 0) == 1)        // correct
                correctCount++;

            Assert.AreEqual(correctCount, 4);
        }

        [TestMethod]
        [ExpectedException(typeof(ApplicationException), "Invalid parameters for Combinations")]
        public void CombinationsInvalidArdsTest()
        {
            Combinatorics.Combinations(1, 10);
        }

        [TestMethod]
        public void PermutationsTests()
        {
            int correctCount = 0;

            if (Combinatorics.Permutations(100, 3) == 970200)     // correct
                correctCount++;
            if (Combinatorics.Permutations(100, 5) == 9034502400) // correct
                correctCount++;

            Assert.AreEqual(correctCount, 2);
        }

        [TestMethod]
        [ExpectedException(typeof(ApplicationException), "Invalid parameters for Permutations")]
        public void PremutationsInvalidArgsTest()
        {
            Combinatorics.Permutations(100, 1000);
        }
    }
}
