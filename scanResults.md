# Chainguard GCC 11 Scan Results

## Scope

This report records the Critical and High findings from the HPCC runtime image
produced with this vcpkg worktree and the LN Chainguard GCC 11 package build.
It is an initial disposition, not a claim that every remaining finding is
reachable in HPCC.

| Item | Value |
| --- | --- |
| Scan date | 2026-09-15 |
| Runtime image | `hpcc-ln-runtime:10.0.93-gcc11-thrift-cve-amd64` |
| vcpkg commit | `88fc32f79191a23bbad2900677b64aec82b1c783` |
| Xray report | `/home/michael/LN/build/chainguard-gcc-11-candidate-10.0.x-thrift-cve-20260915/apk/jfrog/gcc11-thrift-cve-runtime-xray.json` |
| Runtime vcpkg SBOM | `/home/michael/LN/build/chainguard-gcc-11-candidate-10.0.x-thrift-cve-20260915/apk/hpccsystems-platform-10.0.93-r0.runtime-vcpkg.spdx.json` |

Xray reported 98 findings at these severities: 20 Critical and 78 High.

## Disposition Summary

| Disposition | Critical | High | Total |
| --- | ---: | ---: | ---: |
| Confirmed package/ecosystem false positive | 4 | 11 | 15 |
| Confirmed non-applicable configuration or artifact | 1 | 1 | 2 |
| Requires remediation or exposure assessment | 15 | 66 | 81 |

`alpine://chainguard:zlib:1.3.2-r6` is a base-image dependency, not a vcpkg
dependency. It is included for a complete scan record, but must be remediated
by updating the runtime base image rather than an overlay port.

## Confirmed False Positives

These advisories name a different implementation, language binding, or product
than the component packaged in the runtime SBOM.

| Severity | Scanned component | CVEs | Reason |
| --- | --- | --- | --- |
| Critical, High | `aws-sdk-cpp:1.11.591` | `CVE-2018-19981`, `CVE-2022-4725` | Both advisories affect the Android Java AWS SDK, including Android `SharedPreferences` and Java `XpathUtils`, not AWS SDK for C++. |
| Critical | `grpc:1.71.0#2` | `CVE-2026-33186` | Advisory affects gRPC-Go server authorization/interceptor behavior, not gRPC C/C++. |
| High | `opentelemetry-cpp:1.22.0#1` | `CVE-2026-24051`, `CVE-2026-39883` | Advisories affect OpenTelemetry-Go command lookup on Darwin, BSD, or Solaris, not OpenTelemetry C++. |
| Critical, High | `thrift:0.24.0` | `CVE-2021-24028`, `CVE-2019-11938`, `CVE-2019-11939`, `CVE-2019-3552`, `CVE-2019-3553`, `CVE-2019-3558`, `CVE-2019-3559`, `CVE-2019-3564`, `CVE-2019-3565` | All nine advisories explicitly affect Facebook Thrift (`fbthrift`) language implementations. The runtime SBOM contains Apache `thrift 0.24.0` and no `fbthrift` package or file. |
| Critical | `zlib:1.3.1` | `CVE-2026-27820` | Advisory affects the Ruby `zlib` gem's `Zlib::GzipReader`, not native C zlib. |

## Confirmed Non-Applicable Findings

These are valid advisories for the scanned upstream component, but the stated
precondition is absent from this amd64 runtime.

| Severity | Scanned component | CVE | Evidence |
| --- | --- | --- | --- |
| Critical | `openssl:3.5.5` | `CVE-2026-31789` | The advisory states that the excessive ASN.1 OCTET STRING allocation overflow affects only 32-bit platforms. The image is `linux/amd64`. |
| High | `zlib:1.3.1` | `CVE-2026-22184` | The advisory is limited to `contrib/untgz`, a standalone demonstration utility. The runtime contains `libz.so.1.3.1` and no `untgz` executable. |

## Findings Requiring Remediation or Exposure Assessment

The following findings are not package-identification false positives based on
the available evidence. An API/protocol-specific advisory is retained here
until a source and runtime exposure review proves that its precondition is
unreachable. Do not suppress these solely because the runtime image uses a FIPS
base: most affected OpenSSL code is outside the FIPS module boundary but can
still be used by an application linked with OpenSSL.

| Severity | Component | CVEs | Initial action |
| --- | --- | --- | --- |
| Critical, High | `apr-util:1.6.3` | `CVE-2026-32327`, `CVE-2026-34191`, `CVE-2025-49506`, `CVE-2026-34501`, `CVE-2026-34502` | Upgrade or backport. `CVE-2026-32327` has a stated fix in APR-util 1.6.4. Assess whether the Oracle DBD provider required by `CVE-2026-34191` is built and shipped before considering a scope waiver. |
| High | `arrow:21.0.0` | `CVE-2026-25087` | Upgrade to Arrow 23.0.1 or later, or confirm that `RecordBatchFileReader::PreBufferMetadata` is never enabled for untrusted IPC files. |
| High | `c-ares:1.34.5#1` | `CVE-2026-33630` | Upgrade to c-ares 1.34.7 or later. |
| Critical, High | `curl:8.16.0` | `CVE-2026-10536`, `CVE-2026-11856`, `CVE-2026-18924`, `CVE-2026-19931`, `CVE-2026-8924`, `CVE-2026-8925`, `CVE-2026-8926`, `CVE-2026-8927`, `CVE-2026-9079`, `CVE-2026-11586`, `CVE-2026-12064`, `CVE-2026-13608`, `CVE-2026-3805`, `CVE-2026-5773`, `CVE-2026-6276`, `CVE-2026-80229`, `CVE-2026-80230`, `CVE-2026-80231`, `CVE-2026-80255`, `CVE-2026-82208`, `CVE-2026-82209`, `CVE-2026-8286`, `CVE-2026-8932`, `CVE-2026-9080`, `CVE-2026-9545`, `CVE-2026-9547` | Determine vendor-fixed release and update the overlay. Xray did not provide fixed-version metadata. |
| High | `expat:2.7.1` | `CVE-2025-59375`, `CVE-2026-25210`, `CVE-2026-41080`, `CVE-2026-45186`, `CVE-2026-76957` | Determine a release containing all fixes and update the overlay. |
| High | `libevent:2.1.12+20230128#1` | `CVE-2026-63382`, `CVE-2026-63383`, `CVE-2026-63385`, `CVE-2026-63387`, `CVE-2026-63388` | Upgrade to 2.1.13 or later. Retain an exposure review for HTTP/DNS/AF_UNIX paths if upgrading is blocked. |
| High | `libgit2:1.9.1` | `CVE-2026-53587`, `CVE-2026-5917` | Upgrade to a release that contains the fixes. `CVE-2026-5917` additionally requires the libssh2 backend and processing an attacker-controlled repository path. |
| Critical, High | `libxml2:2.11.9` | `CVE-2024-56171`, `CVE-2025-24928`, `CVE-2025-27113`, `CVE-2025-32414`, `CVE-2025-32415`, `CVE-2025-49795`, `CVE-2025-6021`, `CVE-2025-7425`, `CVE-2026-11979`, `CVE-2026-86140` | Determine a release containing all fixes and update the overlay. `CVE-2024-56171` is fixed in 2.12.10 or 2.13.6. |
| High | `mongo-c-driver:1.30.3` | `CVE-2026-6231` | Upgrade to MongoDB C Driver 1.30.5 or later. |
| Critical, High | `openssl:3.5.5` | `CVE-2026-34182`, `CVE-2026-63073`, `CVE-2026-75803`, `CVE-2026-14456`, `CVE-2026-14457`, `CVE-2026-18798`, `CVE-2026-28387`, `CVE-2026-28388`, `CVE-2026-28389`, `CVE-2026-28390`, `CVE-2026-31790`, `CVE-2026-34180`, `CVE-2026-34181`, `CVE-2026-34183`, `CVE-2026-42764`, `CVE-2026-45445`, `CVE-2026-45447`, `CVE-2026-54874`, `CVE-2026-63072`, `CVE-2026-63075`, `CVE-2026-63076`, `CVE-2026-7383`, `CVE-2026-9076` | Determine vendor-fixed release and update the overlay. Several findings require explicitly enabled CMS, CMP, DTLS, QUIC, PKCS#7/S/MIME, or EVP one-shot cipher paths; document source-use evidence before any scope waiver. |
| High | `zlib:1.3.1` | `CVE-2026-85091` | Verify the exact upstream version range against the vcpkg source version and update if affected. The same CVE also affects base-image `zlib:1.3.2-r6`. |
| High | `alpine://chainguard:zlib:1.3.2-r6` | `CVE-2026-85091` | Update the Chainguard runtime base image. Xray identifies `1.3.3-r0` as fixed. |

## Remediation Order

1. Add an APR-util 1.6.4 overlay or backport for `CVE-2026-32327`.
2. Upgrade the components with advisory-provided fixed releases: c-ares,
   libevent, libxml2, mongo-c-driver, and Arrow.
3. Establish vendor-fixed target releases for curl, OpenSSL, Expat, and libgit2
   before creating overlays.
4. Refresh the Chainguard runtime base to resolve its zlib finding.
5. Rebuild the APK and runtime image, regenerate both SBOMs, and rescan to
   record the resulting delta.

## Evidence Needed for Scope Waivers

- APR-util Oracle DBD provider build and runtime presence for `CVE-2026-34191`.
- HPCC call-site review for Arrow IPC pre-buffering, libgit2's libssh2 backend,
  and all OpenSSL CMS, CMP, DTLS, QUIC, PKCS#7/S/MIME, and `EVP_Cipher()` paths.
- Exact upstream version applicability for `CVE-2026-85091` against vcpkg zlib
  1.3.1.