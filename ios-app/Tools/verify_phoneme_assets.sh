#!/bin/sh

set -eu

# The source clips are deliberately absent from public git. A local Debug build may still
# be useful without them, but a distributable build must never degrade to “Letter.” plus silence.
if [ "${CONFIGURATION:-}" != "Release" ]; then
    exit 0
fi

asset_dir="${SRCROOT}/MaxPuzzles/Resources/PhonemeAudio/en-GB/v1"
evidence_manifest="${SRCROOT}/LocalAssets/PhonemeAudio/en-GB/v1/import-manifest.local.json"
expected_ids="
c_p c_b c_t c_d c_k c_g c_f c_v c_th_vl c_th_vd c_s c_z c_sh c_zh c_h
c_tsh c_dzh c_m c_n c_ng c_l c_r c_yod c_w
v_fleece v_kit v_dress v_trap v_strut v_lot v_foot v_goose v_face v_price
v_mouth v_goat v_choice v_thought v_nurse v_palm v_square v_near v_schwa v_cure
"

if [ ! -f "${asset_dir}/recording-contract.json" ]; then
    echo "error: Phoneme recording contract is missing: ${asset_dir}/recording-contract.json" >&2
    exit 1
fi

if [ ! -s "${evidence_manifest}" ]; then
    echo "error: Private phoneme import evidence is required for a Release build: ${evidence_manifest}" >&2
    exit 1
fi

missing_count=0
for stable_id in ${expected_ids}; do
    clip="${asset_dir}/phoneme_${stable_id}.m4a"
    if [ ! -s "${clip}" ]; then
        echo "error: Required phoneme clip is missing or empty: ${clip}" >&2
        missing_count=$((missing_count + 1))
    fi
done

actual_count=$(
    /usr/bin/find "${asset_dir}" -maxdepth 1 -type f -name 'phoneme_*.m4a' \
        | /usr/bin/wc -l \
        | /usr/bin/tr -d '[:space:]'
)

if [ "${missing_count}" -ne 0 ] || [ "${actual_count}" -ne 44 ]; then
    echo "error: Release builds require the complete 44-phoneme set; found ${actual_count}." >&2
    exit 1
fi

manifest_count=$(/usr/bin/plutil -extract assetCount raw -o - "${evidence_manifest}")
if [ "${manifest_count}" -ne 44 ]; then
    echo "error: Phoneme import evidence must describe exactly 44 assets; found ${manifest_count}." >&2
    exit 1
fi

# Validate the complete manifest filename set before using any manifest value to construct a path.
# Count alone is insufficient: a malformed manifest could otherwise repeat one valid clip 44 times
# and leave the other expected clips unhashed and undecoded.
manifest_filenames='
'
index=0
while [ "${index}" -lt "${manifest_count}" ]; do
    output_filename=$(
        /usr/bin/plutil -extract "assets.${index}.outputFilename" raw -o - "${evidence_manifest}"
    )

    is_expected_filename=0
    for stable_id in ${expected_ids}; do
        if [ "${output_filename}" = "phoneme_${stable_id}.m4a" ]; then
            is_expected_filename=1
            break
        fi
    done

    if [ "${is_expected_filename}" -ne 1 ]; then
        case "${output_filename}" in
            */*|*\\*|.|..|*".."*)
                echo "error: Unsafe phoneme output filename in import evidence: ${output_filename}" >&2
                ;;
            *)
                echo "error: Unknown phoneme output filename in import evidence: ${output_filename}" >&2
                ;;
        esac
        exit 1
    fi

    case "${manifest_filenames}" in
        *"
${output_filename}
"*)
            echo "error: Duplicate phoneme output filename in import evidence: ${output_filename}" >&2
            exit 1
            ;;
    esac
    manifest_filenames="${manifest_filenames}${output_filename}
"
    index=$((index + 1))
done

for stable_id in ${expected_ids}; do
    expected_filename="phoneme_${stable_id}.m4a"
    case "${manifest_filenames}" in
        *"
${expected_filename}
"*)
            ;;
        *)
            echo "error: Import evidence is missing expected phoneme output: ${expected_filename}" >&2
            exit 1
            ;;
    esac
done

index=0
while [ "${index}" -lt "${manifest_count}" ]; do
    output_filename=$(
        /usr/bin/plutil -extract "assets.${index}.outputFilename" raw -o - "${evidence_manifest}"
    )
    expected_sha=$(
        /usr/bin/plutil -extract "assets.${index}.outputSHA256" raw -o - "${evidence_manifest}"
    )
    clip="${asset_dir}/${output_filename}"
    actual_sha=$(/usr/bin/shasum -a 256 "${clip}" | /usr/bin/awk '{print $1}')
    if [ "${actual_sha}" != "${expected_sha}" ]; then
        echo "error: Phoneme clip does not match private import evidence: ${clip}" >&2
        exit 1
    fi
    if ! /usr/bin/afinfo "${clip}" \
        | /usr/bin/grep -Eq 'Data format:[[:space:]]+1 ch,[[:space:]]+48000 Hz, aac'; then
        echo "error: Phoneme clip is not decodable mono 48 kHz AAC: ${clip}" >&2
        exit 1
    fi
    index=$((index + 1))
done

echo "Verified complete phoneme set: 44 clips, exact hashes, decodable mono 48 kHz AAC."
