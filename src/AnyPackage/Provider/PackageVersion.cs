// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace AnyPackage.Provider
{
    /// <summary>
    /// The <c>PackageVersion</c> class.
    /// </summary>
    public sealed class PackageVersion : IComparable, IComparable<PackageVersion>, IEquatable<PackageVersion>
    {
        private static readonly Regex s_semVer = new Regex(@"^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildMetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$");
        private static readonly Regex s_multiNumericSuffix = new Regex(@"^(?<version>[\d\.]+\d+)(?<suffix>\w+)$");
        private static readonly Regex s_multiNumeric = new Regex(@"^[\d\.]+$");

        /// <summary>
        /// Gets the version.
        /// </summary>
        public string Version { get; }

        /// <summary>
        /// Gets the dot separated first position.
        /// </summary>
        public int? Major => _digits.Count > 0 ? _digits[0] : null;

        /// <summary>
        /// Gets the dot separated second position.
        /// </summary>
        public int? Minor => _digits.Count > 1 ? _digits[1] : null;

        /// <summary>
        /// Gets the dot separated third position.
        /// </summary>
        public int? Patch => _digits.Count > 2 ? _digits[2] : null;

        /// <summary>
        /// Gets the dot separated fourth position. 
        /// </summary>
        public int? Revision => _digits.Count > 3 ? _digits[3] : null;

        /// <summary>
        /// Gets all the dot separated values.
        /// </summary>
        public IEnumerable<int> Digits => _digits;

        /// <summary>
        /// Gets if the version is a prerelease.
        /// </summary>
        public bool IsPrerelease => _prerelease.Count > 0;

        /// <summary>
        /// Gets if the version contains a suffix.
        /// </summary>
        public bool HasSuffix => Suffix is not null;

        /// <summary>
        /// Gets the suffix of a multi-part numeric with suffix version.
        /// </summary>
        public string? Suffix { get; }

        /// <summary>
        /// Gets if there
        /// </summary>
        public bool HasMetadata => _metadata.Count > 0;

        /// <summary>
        /// Gets the dot separated values of the prerelease string.
        /// </summary>
        public IEnumerable<string> Prerelease => _prerelease;

        /// <summary>
        /// Gets the dot separated values of the build metadata string.
        /// </summary>
        public IEnumerable<string> BuildMetadata => _metadata;

        /// <summary>
        /// Gets the version scheme.
        /// </summary>
        public PackageVersionScheme Scheme { get; }

        private List<int> _digits = new List<int>();
        private List<string> _prerelease = new List<string>();
        private List<string> _metadata = new List<string>();

        /// <summary>
        /// Constructs an instance of the <c>PackageVersion</c> class.
        /// </summary>
        /// <param name="version">The version.</param>
        public PackageVersion(string version)
        {
            if (version is null)
            {
                throw new ArgumentNullException(version);
            }

            if (string.IsNullOrWhiteSpace(version))
            {
                throw new ArgumentException("Value cannot be whitespace.", version);
            }

            Match match;

            if (s_semVer.IsMatch(version))
            {
                match = s_semVer.Match(version);
                SetDigits(match.Groups[1].Value);
                // TODO: Set prerelease and metadata
                Scheme = PackageVersionScheme.SemanticVersion;
            }
            else if (s_multiNumericSuffix.IsMatch(version))
            {
                match = s_multiNumericSuffix.Match(version);
                SetDigits(match.Groups[1].Value);
                Suffix = match.Groups[2].Value;
                Scheme = PackageVersionScheme.MultiPartNumericSuffix;
            }
            else if (s_multiNumeric.IsMatch(version))
            {
                match = s_multiNumeric.Match(version);
                SetDigits(match.Captures[0].Value);
                Scheme = PackageVersionScheme.AlphaNumeric;
            }

            Version = version;
        }

        private void SetDigits(string abc)
        {
            foreach (var digit in abc.Split('.'))
            {
                _digits.Add(int.Parse(digit));
            }
        }

        /// <summary>
        /// Converts the string representation of a version to an equivalent <c>PackageVersion</c> object.
        /// </summary>
        /// <param name="version">A string that contains a version to convert.</param>
        /// <returns>
        /// An object that is equivalent to the version specified in the version parameter.
        /// </returns>
        public static PackageVersion Parse(string version) => new PackageVersion(version);

        /// <summary>
        /// Tries to convert the string representation of a version to an equivalent <c>PackageVersion</c> object,
        /// and returns a value that indicates whether the conversion succeeded.
        /// </summary>
        /// <param name="version">A string that contains a version to convert.</param>
        /// <param name="result">
        /// When this methods returns, contains the <c>PackageVersion</c> equivalent of the string, if the conversion succeeded.
        /// If <c>version</c> is <c>null</c>, Empty, or if the conversion fails, <c>result</c> is <c>null</c> when the method returns.
        /// </param>
        /// <returns>
        /// <c>true</c> if the <c>version</c> parameter was converted successfully; otherwise, <c>false</c>.
        /// </returns>
        public static bool TryParse(string version, out PackageVersion result)
        {
            throw new NotImplementedException();
        }

        public int CompareTo(object obj)
        {
            throw new NotImplementedException();
        }

        public int CompareTo(PackageVersion other)
        {
            throw new NotImplementedException();
        }

        public bool Equals(PackageVersion other)
        {
            throw new NotImplementedException();
        }

        public override bool Equals(object obj) => Version.Equals(obj);

        public override int GetHashCode() => Version.GetHashCode();

        public override string ToString() => Version;

        // TODO: Override operators
    }
}
