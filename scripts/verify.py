#!/usr/bin/env python3
"""Exact Linux/GNU 14.2 certification verifier.

Source/fpm builds are distinct from this pinned certification profile. New INQUIRE
and substring oracle diagnostics require the recorded GNU 14.2 launcher identity;
exclusive-output guards use POSIX filesystem operations. Windows and alternative
compiler verification profiles are not claimed by this script.
Requires fpm, the pinned gfortran launcher and compatible C compiler on PATH.
For a launcher, supply --compiler-binary with its independently verified executable.
"""
from pathlib import Path
import argparse
import hashlib
import shlex
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tests"))
from cli_version_contract import read_project_version


def run(args, capture=False):
    print('+ ' + subprocess.list2cmdline([str(a) for a in args]), flush=True)
    return subprocess.run([str(a) for a in args], cwd=ROOT, check=True,
                          text=True, capture_output=capture)


def debug_profile_args(split_debug=False):
    """Keep all normal FPM debug semantics; optionally separate DWARF storage."""
    if split_debug and not sys.platform.startswith('linux'):
        raise ValueError('--split-debug is validated only with GNU tools on Linux')
    return ['--profile', 'debug'] + (['--flag', '-gsplit-dwarf'] if split_debug else [])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--split-debug', action='store_true',
                        help='Linux/GNU only: preserve debug checks and store DWARF in .dwo files')
    parser.add_argument('--shared-native', action='store_true',
                        help='Linux/GNU only: execute every native test against one shared copy of the same PIC objects')
    parser.add_argument('--compiler-binary', type=Path, help='Actual GNU compiler executable when gfortran is a launcher')
    args = parser.parse_args()
    if args.shared_native and not sys.platform.startswith('linux'):
        parser.error('--shared-native is validated only on Linux/GNU')
    try:
        profile = debug_profile_args(args.split_debug)
    except ValueError as exc:
        parser.error(str(exc))
    fpm = shutil.which('fpm')
    compiler = shutil.which('gfortran')
    if not fpm or not compiler:
        raise SystemExit('Put fpm and gfortran on PATH, then run this verifier again.')
    compiler_binary = Path(args.compiler_binary or compiler).resolve()
    if not compiler_binary.is_file():
        parser.error('--compiler-binary must name an existing compiler executable')
    if hashlib.sha256(Path(compiler).read_bytes()).hexdigest() == '406a8ebf8691187132f55a124d6ca47d99978645f6d03bb1d6926a7e5efcd730':
        if args.compiler_binary is None or hashlib.sha256(compiler_binary.read_bytes()).hexdigest() != '4e3c7636984f745a332049d2f66a80e3709fd8dfc50d2f538be78e71aabbe96d':
            parser.error('This GNU launcher requires the independently pinned underlying compiler via --compiler-binary')
    run([fpm, 'build', *profile])
    if args.shared_native:
        run([sys.executable, 'scripts/verify_native_shared.py', *(['--split-debug'] if args.split_debug else [])])
    else:
        run([fpm, 'test', *profile])
    # An empty --runner asks fpm for the selected profile's executable path.
    # Do not pick a different/stale profile merely because its mtime is newest.
    result = run([fpm, 'run', 'fortfront-interpreter', *profile, '--runner'], capture=True)
    candidates = []
    for line in (result.stdout + '\n' + result.stderr).splitlines():
        path = Path(line.strip().strip('"'))
        if not path.is_absolute():
            path = ROOT / path
        if path.is_file() and path.name.lower() in ('fortfront-interpreter', 'fortfront-interpreter.exe'):
            candidates.append(path.resolve())
    if len(candidates) != 1:
        raise SystemExit('Could not identify the fpm executable path:\n' + result.stdout + result.stderr)
    exe = candidates[0]
    expected_version = read_project_version(ROOT / "fpm.toml")
    run([sys.executable, "tests/test_cli_version_contract.py"])
    run([sys.executable, 'tests/test_verifier_profile.py'])
    run([sys.executable, 'tests/test_verifier_hardening.py'])
    run([sys.executable, 'tests/test_cli_limits.py', exe])
    run([sys.executable, 'tests/test_cli_step_hint.py', exe])
    run([sys.executable, 'tests/allocatable_spec_inquiries/test_runner.py'])
    run([sys.executable, 'tests/allocatable_spec_inquiries/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/associated_target/test_runner.py'])
    run([sys.executable, 'tests/associated_target/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/associated_target/check_optional_target_omission.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/pointer_views/test_runner.py'])
    run([sys.executable, 'tests/pointer_views/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/pointer_frontend/check_frontend_rejections.py', exe])
    run([sys.executable, 'tests/target_attributes/test_runner.py'])
    run([sys.executable, 'tests/target_attributes/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/logical_allocatables/test_runner.py'])
    run([sys.executable, 'tests/logical_allocatables/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/rank_three_allocatables/test_runner.py'])
    run([sys.executable, 'tests/rank_three_allocatables/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/rank_three/test_runner.py'])
    run([sys.executable, 'tests/rank_three/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/optional_character/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/optional_numeric_arrays/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/quoted_operators/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/literal_substrings/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_substrings/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/shape_intrinsic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/array_bounds_inquiry/test_runner.py'])
    run([sys.executable, 'tests/array_bounds_inquiry/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_search/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/repeat_intrinsic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/repeat_intrinsic/run_original.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/generic_intrinsic_repeat/check_original.py'])
    run([sys.executable, 'tests/generic_intrinsic_repeat/test_runner.py'])
    run([sys.executable, 'tests/generic_intrinsic_repeat/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/optional_colons/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/intent_spelling/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/recursion/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/nested_procedures/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/random_seed_empty/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/process_queries/generate_cases.py', '--check'])
    run([sys.executable, 'tests/process_queries/test_runner.py'])
    run([sys.executable, 'tests/process_queries/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/timing_queries/test_runner.py'])
    run([sys.executable, 'tests/timing_queries/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/runtime_output_unit/test_runner.py'])
    run([sys.executable, 'tests/runtime_output_unit/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/random_functions/test_runner.py'])
    run([sys.executable, 'tests/random_functions/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/real_conversion/test_runner.py'])
    run([sys.executable, 'tests/real_conversion/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/norm_scalar_expansion/test_runner.py'])
    run([sys.executable, 'tests/norm_scalar_expansion/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/matrix_norm/test_runner.py'])
    run([sys.executable, 'tests/matrix_norm/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/integer_bits/test_runner.py'])
    run([sys.executable, 'tests/integer_bits/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--with-slash-formats'])
    run([sys.executable, 'tests/eoshift/test_runner.py'])
    run([sys.executable, 'tests/eoshift/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/cshift/test_runner.py'])
    run([sys.executable, 'tests/cshift/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release027_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release028_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release029_integration/test_runner.py'])
    run([sys.executable, 'tests/release029_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release030_integration/test_runner.py'])
    run([sys.executable, 'tests/release031_integration/test_runner.py'])
    run([sys.executable, 'tests/release032_integration/test_runner.py'])
    run([sys.executable, 'tests/release030_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release031_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release032_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/where/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/forall/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocatable_character/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_procedures/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_plus/test_runner.py'])
    run([sys.executable, 'tests/character_plus/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_minmax/test_runner.py'])
    run([sys.executable, 'tests/character_minmax/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--with-constructors'])
    run([sys.executable, 'tests/lexical_comparisons/test_runner.py'])
    run([sys.executable, 'tests/lexical_comparisons/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/degree_trig/test_runner.py'])
    run([sys.executable, 'tests/degree_trig/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/model_character_intrinsics/test_runner.py'])
    run([sys.executable, 'tests/model_character_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--with-colon-formats'])
    run([sys.executable, 'tests/colon_formats/test_runner.py'])
    run([sys.executable, 'tests/colon_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/external_read/self_test.py'])
    run([sys.executable, 'tests/external_read/test_cli.py', '--candidate', exe])
    run([sys.executable, 'tests/external_read/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/external_list_read/self_test.py'])
    run([sys.executable, 'tests/external_list_read/check_generator.py'])
    run([sys.executable, 'tests/external_list_read/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/internal_read/self_test.py'])
    run([sys.executable, 'tests/internal_read/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocatable_character_lengths/self_test.py'])
    run([sys.executable, 'tests/allocatable_character_lengths/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_len_elements/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/explicit_dummy_bounds/test_runner.py'])
    run([sys.executable, 'tests/explicit_dummy_bounds/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release025_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release026_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_parameters/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/stdout_write/test_runner.py'])
    run([sys.executable, 'tests/stdout_write/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/stdout_write/test_staging.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/grouped_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/formatted_arrays/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocatable_output/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocatables/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocatable_assignment/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocatable_dummies/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/findloc/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/location_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/mutable_modules/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/saved_locals/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release039_integration/test_runner.py'])
    run([sys.executable, 'tests/release039_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release038_integration/test_runner.py'])
    run([sys.executable, 'tests/release038_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release037_integration/test_runner.py'])
    run([sys.executable, 'tests/release037_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release036_integration/test_runner.py'])
    run([sys.executable, 'tests/release036_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release035_integration/test_runner.py'])
    run([sys.executable, 'tests/release035_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release034_integration/test_runner.py'])
    run([sys.executable, 'tests/release034_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release033_integration/test_runner.py'])
    run([sys.executable, 'tests/release033_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/pack_intrinsic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/metadata_limits/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/utilities_slices/split_source.py', '--check'])
    run([sys.executable, 'tests/utilities_slices/test_split_source.py'])
    run([sys.executable, 'tests/utilities_slices/check_full_source.py', '--candidate', exe])
    run([sys.executable, 'tests/utilities_slices/run_kind_matrix.py', '--candidate', exe])
    run([sys.executable, 'tests/utilities_slices/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/reshape/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/hyperbolic_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/elementary_math/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/model_decomposition/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/model_decomposition/test_runner.py'])
    run([sys.executable, 'tests/iso_env_aliases/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/iso_env_aliases/test_runner.py'])
    run([sys.executable, 'tests/derived_mixed/test_contracts.py'])
    run([sys.executable, 'tests/derived_mixed/test_oracle_contracts.py'])
    run([sys.executable, 'tests/derived_mixed/run_gnu.py', '--gfortran', compiler])
    run([sys.executable, 'tests/derived_mixed/run_candidate.py', '--candidate', exe, '--results', 'tests/derived_mixed/results.json'])
    run([sys.executable, 'tests/character_components/test_runner.py'])
    run([sys.executable, 'tests/character_components/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/derived_defaults/test_runner.py'])
    run([sys.executable, 'tests/derived_defaults/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/output_unit/test_runner.py'])
    run([sys.executable, 'tests/output_unit/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/spacing_nearest/test_runner.py'])
    run([sys.executable, 'tests/spacing_nearest/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/trigonometric_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/numeric_model_inquiries/test_runner.py'])
    run([sys.executable, 'tests/numeric_model_inquiries/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/rounding_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/array_results/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/count_bounds/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/count_pack_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/count_pack_reshape_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/transform_composition/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/specification_functions/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/generic_spec_guards/test_runner.py'])
    run([sys.executable, 'tests/generic_spec_guards/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/automatic_arrays/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/optional_arguments/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/optional_dim/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/logical_intrinsics/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/parity_intrinsic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/bare_do/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/control_flow/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/do_while/test_harness.py'])
    run([sys.executable, 'tests/do_while/run_gnu.py', compiler])
    run([sys.executable, 'tests/do_while/run_tests.py', '--candidate', exe, '--result', 'tests/do_while/results.json'])
    run([sys.executable, 'tests/defined_operators/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/defined_operators/optional_operands/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/module_use/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/source_limits/run_tests.py', '--candidate', exe,
         '--gfortran', compiler])
    run([sys.executable, 'tests/independent/test_runner.py'])
    run([sys.executable, 'tests/arrays/test_runner.py'])
    run([sys.executable, 'tests/program_forms/test_runner.py'])
    run([sys.executable, 'tests/whole_arrays/test_runner.py'])
    run([sys.executable, 'tests/sections/test_runner.py'])
    run([sys.executable, 'tests/module_functions/test_runner.py'])
    run([sys.executable, 'tests/numerical_procedures/test_runner.py'])
    run([sys.executable, 'tests/argument_association/test_runner.py'])
    run([sys.executable, 'tests/rank_two/test_runner.py'])
    run([sys.executable, 'tests/rank_two_sections/test_runner.py'])
    run([sys.executable, 'tests/array_intrinsics_independent/test_runner.py'])
    run([sys.executable, 'tests/keyword_arguments_independent/test_runner.py'])
    run([sys.executable, 'tests/pure_simple_independent/test_runner.py'])
    run([sys.executable, 'tests/elemental_functions_independent/test_runner.py'])
    run([sys.executable, 'tests/elemental_subroutines_independent/test_runner.py'])
    run([sys.executable, 'tests/mean_programs_independent/test_runner.py'])
    run([sys.executable, 'tests/array_limits/test_runner.py'])
    for suite in ('select_case', 'derived_date_independent', 'integer_kinds_independent', 'array_expression_arguments'):
        run([sys.executable, f'tests/{suite}/test_runner.py'])
    # Both corpus runners parse a shell-like command using shlex without ever
    # executing a shell. Quote as shlex input on every OS, including Windows.
    command = shlex.quote(str(exe))
    for suite in ('independent', 'arrays', 'whole_arrays', 'sections'):
        run([sys.executable, f'tests/{suite}/run_corpus.py', '--gfortran', compiler,
             '--candidate', command, '--results', f'tests/{suite}/results.json'])
    run([sys.executable, 'tests/program_forms/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--output', 'results.json'])
    run([sys.executable, 'tests/procedure_identifiers/test_runner.py'])
    run([sys.executable, 'tests/procedure_identifiers/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/dprod_tand/test_runner.py'])
    run([sys.executable, 'tests/dprod_tand/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/double_precision/test_runner.py'])
    run([sys.executable, 'tests/double_precision/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/rounding_inverse_hyperbolic/test_runner.py'])
    run([sys.executable, 'tests/rounding_inverse_hyperbolic/verify_matrix.py'])
    run([sys.executable, 'tests/rounding_inverse_hyperbolic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/named_formats/test_runner.py'])
    run([sys.executable, 'tests/named_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/unlimited_formats/test_runner.py'])
    run([sys.executable, 'tests/unlimited_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/erf_bessel/test_runner.py'])
    run([sys.executable, 'tests/erf_bessel/test_accuracy.py'])
    run([sys.executable, 'tests/erf_bessel/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/erf_bessel/run_accuracy.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/exponent_inquiries/test_runner.py'])
    run([sys.executable, 'tests/exponent_inquiries/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/main_save/test_runner.py'])
    run([sys.executable, 'tests/main_save/test_promotion.py'])
    run([sys.executable, 'tests/main_save/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/erfc_scaled/test_runner.py'])
    run([sys.executable, 'tests/erfc_scaled/test_accuracy.py'])
    run([sys.executable, 'tests/erfc_scaled/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/erfc_scaled/run_accuracy.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/isnan_intrinsic/test_runner.py'])
    run([sys.executable, 'tests/isnan_intrinsic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/row_gather/test_runner.py'])
    run([sys.executable, 'tests/row_gather/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/rank_three_vectors/test_runner.py'])
    run([sys.executable, 'tests/rank_three_vectors/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/numeric_vector_gather/test_runner.py'])
    run([sys.executable, 'tests/numeric_vector_gather/test_contract.py'])
    run([sys.executable, '-O', 'tests/numeric_vector_gather/test_runner.py'])
    run([sys.executable, '-O', 'tests/numeric_vector_gather/test_contract.py'])
    numeric_runs = (ROOT / 'build').resolve() / 'numeric-vector-validation'
    numeric_runs.mkdir(parents=True, exist_ok=True)
    numeric_run = Path(tempfile.mkdtemp(prefix='verification-', dir=numeric_runs))
    numeric_receipt = numeric_run / 'results.json'
    run([sys.executable, 'tests/numeric_vector_gather/run_tests.py', '--candidate', exe,
         '--expected-candidate-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(),
         '--candidate-version', expected_version, '--gfortran', compiler,
         '--evidence-dir', numeric_run / 'case-evidence', '--result', numeric_receipt])
    print('NUMERIC_VECTOR_RECEIPT', numeric_receipt, flush=True)
    run([sys.executable, 'tests/char_identifiers/test_runner.py'])
    run([sys.executable, 'tests/char_identifiers/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/module_functions/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/numerical_procedures/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/numerical_procedures/run_math_matrix.py', '--candidate', exe,
         '--gfortran', compiler, '--result', 'tests/numerical_procedures/math-matrix-results.json'])
    run([sys.executable, 'tests/argument_association/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/argument_association/run_section_matrix.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'section-matrix-results.json'])
    run([sys.executable, 'tests/rank_two/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/rank_two_sections/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/array_intrinsics_independent/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/keyword_arguments_independent/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/pure_simple_independent/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/elemental_functions_independent/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/elemental_subroutines_independent/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/mean_programs_independent/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    for suite in ('select_case', 'derived_types', 'integer_kinds_independent',
                  'derived_date_independent', 'derived_select_integration', 'array_expression_arguments', 'logical_initializers', 'character_arrays', 'generic_interfaces', 'class_type_bound', 'release_integration'):
        run([sys.executable, f'tests/{suite}/run_tests.py', '--gfortran', compiler,
             '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/array_limits/run_tests.py', '--gfortran', compiler,
         '--candidate', exe, '--result', 'results.json'])
    run([sys.executable, 'tests/inverse_trigonometric/test_runner.py'])
    run([sys.executable, 'tests/inverse_trigonometric/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--with-named-formats'])
    run([sys.executable, 'tests/acos_intrinsic/test_runner.py'])
    run([sys.executable, 'tests/acos_intrinsic/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release040_integration/test_runner.py'])
    run([sys.executable, 'tests/release040_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_len_inquiry/test_runner.py'])
    run([sys.executable, 'tests/character_len_inquiry/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/allocation_errmsg/test_runner.py'])
    run([sys.executable, 'tests/allocation_errmsg/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/move_alloc/test_runner.py'])
    run([sys.executable, 'tests/move_alloc/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/scalar_allocatable_character/test_runner.py'])
    run([sys.executable, 'tests/scalar_allocatable_character/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/multi_allocation/test_runner.py'])
    run([sys.executable, 'tests/multi_allocation/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/normal_mixture/test_runner.py'])
    run([sys.executable, 'tests/normal_mixture/run_tests.py', '--candidate', exe, '--gfortran', compiler,
         '--max-steps', '100000000', '--repeats', '6', '--result', 'tests/normal_mixture/results.json'])
    run([sys.executable, 'tests/release041_integration/test_runner.py'])
    run([sys.executable, 'tests/release041_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/named_formats/run_original.py', '--candidate', exe, '--gfortran', compiler, '--combined-asin'])
    run([sys.executable, 'tests/typed_empty_arrays/test_runner.py'])
    run([sys.executable, 'tests/typed_empty_arrays/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release042_integration/test_runner.py'])
    run([sys.executable, 'tests/release042_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/punctuation_literals/test_runner.py'])
    run([sys.executable, 'tests/punctuation_literals/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release043_integration/test_runner.py'])
    run([sys.executable, 'tests/release043_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release044_integration/test_runner.py'])
    run([sys.executable, 'tests/release044_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/runtime_formats/check_provenance.py'])
    run([sys.executable, 'tests/runtime_formats/test_runner.py'])
    run([sys.executable, 'tests/runtime_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/pure_internal_write/test_runner.py'])
    run([sys.executable, 'tests/pure_internal_write/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/internal_write_element/check_original.py'])
    run([sys.executable, 'tests/internal_write_element/test_runner.py'])
    run([sys.executable, 'tests/internal_write_element/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/runtime_formats/run_original.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/slash_formats/self_test.py'])
    run([sys.executable, 'tests/slash_formats/test_policy.py'])
    run([sys.executable, 'tests/slash_formats/check_generator.py'])
    run([sys.executable, 'tests/slash_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/slash_formats/check_original_utility.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/slash_formats/check_historical.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/position_formats/test_runner.py'])
    run([sys.executable, 'tests/position_formats/check_provenance.py'])
    run([sys.executable, 'tests/position_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/dynamic_character_constructor/self_test.py'])
    run([sys.executable, 'tests/dynamic_character_constructor/check_generator.py'])
    run([sys.executable, 'tests/dynamic_character_constructor/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/fixed_character_length_inquiry/self_test.py'])
    run([sys.executable, 'tests/fixed_character_length_inquiry/check_generator.py'])
    run([sys.executable, 'tests/fixed_character_length_inquiry/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/fixed_character_derived_actuals/self_test.py'])
    run([sys.executable, 'tests/fixed_character_derived_actuals/check_generator.py'])
    run([sys.executable, 'tests/fixed_character_derived_actuals/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/fixed_character_derived_scope/self_test.py'])
    run([sys.executable, 'tests/fixed_character_derived_scope/check_generator.py'])
    run([sys.executable, 'tests/fixed_character_derived_scope/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/constructor_implied_do/run_tests.py', '--self-test'])
    run([sys.executable, 'tests/constructor_implied_do/check_generator.py'])
    run([sys.executable, 'tests/constructor_implied_do/test_runner.py'])
    run([sys.executable, 'tests/constructor_implied_do/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/constructor_implied_do/inquiry-followup/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/output_implied_do/test_runner.py'])
    run([sys.executable, 'tests/output_implied_do/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/utilities_working/test_runner.py'])
    run([sys.executable, 'tests/utilities_working/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release045_integration/test_runner.py'])
    run([sys.executable, 'tests/release045_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release046_integration/test_runner.py'])
    run([sys.executable, 'tests/release046_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release047_integration/test_runner.py'])
    run([sys.executable, 'tests/release047_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/boz_formats/test_runner.py'])
    run([sys.executable, 'tests/boz_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release048_integration/test_runner.py'])
    run([sys.executable, 'tests/release048_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/leadz/run_tests.py', '--candidate', exe, '--expected-version', expected_version, '--expected-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--gfortran', compiler, '--result', 'tests/leadz/results.json'])
    run([sys.executable, 'tests/leadz/test_contracts.py', '--evidence', 'tests/leadz/results.json'])
    run([sys.executable, 'tests/release049_integration/test_runner.py'])
    run([sys.executable, 'tests/release049_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release050_integration/test_runner.py'])
    run([sys.executable, 'tests/release050_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/release051_integration/test_runner.py'])
    run([sys.executable, 'tests/release051_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
    run([sys.executable, 'tests/character_gather/tests/test_contract.py'])
    run([sys.executable, 'tests/character_gather/tests/test_runner_guards.py'])
    run([sys.executable, 'tests/character_gather/run_strict.py', '--candidate', exe, '--expected-sha', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--gfortran', compiler, '--output', 'tests/character_gather/results.json'])
    run([sys.executable, 'tests/character_gather_actual/check_original.py'])
    run([sys.executable, 'tests/character_gather_actual/test_contract.py'])
    run([sys.executable, 'tests/character_gather_actual/run_tests.py', '--candidate', exe, '--expected-sha', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--gfortran', compiler, '--result', 'tests/character_gather_actual/results.json'])
    run([sys.executable, 'tests/release052_integration/test_runner.py'])
    run([sys.executable, 'tests/release052_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--expected-version', expected_version, '--expected-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest()])
    run([sys.executable, 'tests/release053_integration/test_runner.py'])
    run([sys.executable, 'tests/release053_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--expected-version', expected_version, '--expected-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest()])
    # 0.54 owner contracts. Fresh suite-local receipts intentionally fail on reuse.
    run([sys.executable, 'tests/inquire_name/test_runner.py', '--results', 'tests/inquire_name/harness-results.json'])
    run([sys.executable, '-O', 'tests/inquire_name/test_runner.py', '--results', 'tests/inquire_name/harness-optimized-results.json'])
    run([sys.executable, 'tests/inquire_name/run_tests.py', '--exe', exe, '--sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--results', 'tests/inquire_name/results.json', '--gnu', compiler, '--gnu-sha256', '406a8ebf8691187132f55a124d6ca47d99978645f6d03bb1d6926a7e5efcd730'])
    run([sys.executable, 'tests/fzero_formats/test_runner.py'])
    run([sys.executable, 'tests/fzero_formats/test_portable.py'])
    run([sys.executable, 'tests/fzero_formats/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--compiler-binary', compiler_binary, '--expected-version', expected_version])
    run([sys.executable, 'tests/element_substrings/test_strict.py'])
    run([sys.executable, '-O', 'tests/element_substrings/test_strict.py'])
    run([sys.executable, 'tests/element_substrings/run_strict.py', '--candidate', exe, '--expected-sha', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--gfortran', compiler, '--gnu-sha', '406a8ebf8691187132f55a124d6ca47d99978645f6d03bb1d6926a7e5efcd730', '--output', 'tests/element_substrings/results.json'])
    run([sys.executable, 'tests/release054_integration/test_runner.py'])
    run([sys.executable, 'tests/release054_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler, '--expected-version', expected_version, '--expected-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest()])
    # Retain complete physical-build evidence for success and first failure.
    trailz_runs = (ROOT / 'build').resolve() / 'trailz-validation'
    trailz_runs.mkdir(parents=True, exist_ok=True)
    trailz_run = Path(tempfile.mkdtemp(prefix='verification-', dir=trailz_runs))
    trailz_output = trailz_run / 'case-evidence'
    trailz_receipt = trailz_output / 'results.json'
    trailz_export = trailz_run / 'export.json'
    try:
        run([sys.executable, 'tests/trailz/run_tests.py',
             '--candidate', exe, '--expected-version', expected_version,
             '--expected-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(),
             '--gfortran', compiler,
             '--expected-gfortran-sha256', '406a8ebf8691187132f55a124d6ca47d99978645f6d03bb1d6926a7e5efcd730',
             '--expected-gfortran-version-sha256', 'd4c6c90520eb8866c43e5d77a2851fec8be0da9e591670e84f9754a4eff09963',
             '--manifest', 'tests/trailz/manifest.json',
             '--expected-manifest-sha256', 'd4ffa5e1a62724442505447de419617a31026dd1c5932a9f9d6a6b87218aa64f',
             '--output', trailz_output])
    finally:
        import json
        trailz_files = {}
        for trailz_file in sorted(trailz_output.rglob('*')):
            if trailz_file.is_symlink():
                raise RuntimeError('TRAILZ evidence contains an unexpected symlink')
            if trailz_file.is_file():
                trailz_files[str(trailz_file.relative_to(trailz_output))] = {
                    'sha256': hashlib.sha256(trailz_file.read_bytes()).hexdigest(),
                    'bytes': trailz_file.stat().st_size}
        with trailz_export.open('x', encoding='utf-8') as trailz_stream:
            json.dump({'schema': 'trailz-maintained-export-v1',
                       'evidence_root': str(trailz_output),
                       'receipt': 'results.json',
                       'receipt_exists': trailz_receipt.is_file(),
                       'files': trailz_files}, trailz_stream, indent=2)
            trailz_stream.write('\n')
        print('TRAILZ_RECEIPT', trailz_receipt, flush=True)
        print('TRAILZ_EXPORT', trailz_export, flush=True)
    run([sys.executable, 'tests/trailz/test_contracts.py'])
    run([sys.executable, 'tests/trailz/test_hardening.py'])

    run([sys.executable, 'tests/formatted_read_element/test_runner.py'])
    run([sys.executable, '-O', 'tests/formatted_read_element/test_runner.py'])
    run([sys.executable, 'tests/formatted_read_element/run_tests.py', '--candidate', exe, '--expected-candidate-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--candidate-version', expected_version, '--gfortran', compiler, '--result', 'tests/formatted_read_element/results.json', '--evidence-dir', 'tests/formatted_read_element/current-evidence'])

    # 0.56 internal CHARACTER element-file contracts; fresh exclusive outputs.
    run([sys.executable, 'tests/internal_read_element/test_runner.py'])
    run([sys.executable, '-O', 'tests/internal_read_element/test_runner.py'])
    run([sys.executable, 'tests/internal_read_element/run_tests.py', '--candidate', exe, '--expected-candidate-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--candidate-version', expected_version, '--gfortran', compiler, '--result', 'tests/internal_read_element/results.json', '--evidence-dir', 'tests/internal_read_element/current-evidence'])

    run([sys.executable, 'tests/integer_masks/verify_registry.py'])
    run([sys.executable, 'tests/integer_masks/run_tests.py', '--candidate', exe, '--expected-version', expected_version, '--expected-sha256', hashlib.sha256(Path(exe).read_bytes()).hexdigest(), '--gfortran', compiler, '--result', 'tests/integer_masks/results.json'])
    run([sys.executable, 'tests/integer_masks/test_contracts.py', '--evidence', 'tests/integer_masks/results.json', '--result', 'tests/integer_masks/contract-results.json'])
    print('PASS: all native, CLI, scalar, array, procedure, intrinsic, RANDOM_NUMBER, SELECT CASE, wide INTEGER, CHARACTER arrays, generics, CLASS/type-bound, defined operators, OPTIONAL/PRESENT including CHARACTER, scalar substrings, CHARACTER intrinsics, logical intrinsics, control flow, module USE, source limits, utilities, metadata limits, COUNT bounds, PACK, RESHAPE, mutable modules, MINLOC/MAXLOC, automatic arrays, array results, hyperbolic intrinsics, numeric/CHARACTER allocatables, FORALL, rounding/LOG10, formatted arrays and integration checks')


if __name__ == '__main__':
    main()
